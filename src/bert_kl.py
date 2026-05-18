import csv
import math
import time
import argparse
from typing import Optional
from tqdm import tqdm
import torch
import torch.nn.functional as F
from transformers import BertTokenizerFast, BertForMaskedLM, RobertaTokenizerFast, RobertaForMaskedLM

LOG2E: float = 1.0 / math.log(2)
SUPPORTED_MODEL_TYPES: tuple[str] = ("bert", "roberta")


def load_tokenizer_and_model(model_name: str, model_type: str, device: str):
    model_type = model_type.lower()
    if model_type == "bert":
        tokenizer = BertTokenizerFast.from_pretrained(model_name)
        model = BertForMaskedLM.from_pretrained(model_name).to(device)
    elif model_type == "roberta":
        tokenizer = RobertaTokenizerFast.from_pretrained(model_name, add_prefix_space=True)
        model = RobertaForMaskedLM.from_pretrained(model_name).to(device)
    else:
        raise ValueError(f"Unsupported model_type: '{model_type}'. Choose from: {SUPPORTED_MODEL_TYPES}")
    model.eval()
    return tokenizer, model


def _detect_model_type(tokenizer) -> str:
    name = type(tokenizer).__name__.lower()
    if "roberta" in name:
        return "roberta"
    return "bert"


def _word_to_token_positions(enc) -> dict[int, list[int]]:
    mapping: dict[int, list[int]] = {}
    for tok_pos, w_id in enumerate(enc.word_ids()):
        if w_id is None:
            continue
        mapping.setdefault(w_id, []).append(tok_pos)
    return mapping


def _encode_with_variable_future_masks(
    words_prefix: list[str],
    words_suffix: list[str],
    tokenizer,
    device: str,
) -> tuple[torch.Tensor, torch.Tensor, dict[int, list[int]], list[int], dict[int, list[int]]]:
    model_type = _detect_model_type(tokenizer)

    if model_type == "roberta":
        start_id = tokenizer.bos_token_id
        end_id = tokenizer.eos_token_id
    else:  # bert
        start_id = tokenizer.cls_token_id
        end_id = tokenizer.sep_token_id

    if len(words_suffix) == 0:
        n_suffix_tokens = 0
        future_word_groups: dict[int, list[int]] = {}
    else:
        suffix_enc = tokenizer(
            words_suffix,
            is_split_into_words=True,
            add_special_tokens=False,
        )
        n_suffix_tokens = len(suffix_enc["input_ids"])
        future_word_groups = {}
        for local_pos, w_id in enumerate(suffix_enc.word_ids()):
            if w_id is None:
                continue
            future_word_groups.setdefault(w_id, []).append(local_pos)

    if len(words_prefix) == 0:
        prefix_ids = torch.tensor([[start_id]])
        prefix_attn = torch.ones((1, 1), dtype=torch.long)
        mapping = {}
    else:
        enc = tokenizer(
            words_prefix,
            is_split_into_words=True,
            return_tensors="pt",
            add_special_tokens=True,
            truncation=True,
            max_length=512 - n_suffix_tokens - 1,
        )
        mapping = _word_to_token_positions(enc)

        input_ids = enc["input_ids"]
        attention_mask = enc["attention_mask"]

        end_positions = (input_ids[0] == end_id).nonzero(as_tuple=True)[0]
        if len(end_positions) > 0:
            end_pos = int(end_positions[0])
            prefix_ids = input_ids[:, :end_pos]
            prefix_attn = attention_mask[:, :end_pos]
        else:
            prefix_ids = input_ids
            prefix_attn = attention_mask

    mask_id = tokenizer.mask_token_id

    if n_suffix_tokens == 0:
        end_token = torch.tensor([[end_id]], dtype=prefix_ids.dtype)
        end_attn = torch.ones((1, 1), dtype=prefix_attn.dtype)
        final_ids = torch.cat([prefix_ids, end_token], dim=1)
        final_attn = torch.cat([prefix_attn, end_attn], dim=1)
        future_mask_positions = []
    else:
        masks = torch.full((1, n_suffix_tokens), mask_id, dtype=prefix_ids.dtype)
        masks_attn = torch.ones((1, n_suffix_tokens), dtype=prefix_attn.dtype)
        end_token = torch.tensor([[end_id]], dtype=prefix_ids.dtype)
        end_attn = torch.ones((1, 1), dtype=prefix_attn.dtype)

        final_ids = torch.cat([prefix_ids, masks, end_token], dim=1)
        final_attn = torch.cat([prefix_attn, masks_attn, end_attn], dim=1)

        prefix_len = prefix_ids.size(1)
        future_mask_positions = list(range(prefix_len, prefix_len + n_suffix_tokens))

    return (final_ids.to(device), final_attn.to(device), mapping, future_mask_positions, future_word_groups)


@torch.no_grad()
def compute_info_matrix(
    sentence: str,
    tokenizer,
    model,
    device: str,
    subword_aggregation: str = "sum",
) -> tuple[list[str], list[list[float]]]:
    words = sentence.split()
    N = len(words)

    if N == 0:
        return [], []

    if subword_aggregation not in ("sum", "mean"):
        raise ValueError(f"subword_aggregation must be 'sum' or 'mean', got '{subword_aggregation}'")

    model.eval()
    mask_id = tokenizer.mask_token_id

    info_matrix = [[0.0] * (N + 1) for _ in range(N)]

    for i in range(1, N + 1):
        words_prefix = words[:i]
        words_suffix = words[i:]

        input_ids, attention_mask, mapping, future_tokpos, future_word_groups = _encode_with_variable_future_masks(
            words_prefix, words_suffix, tokenizer, device
        )

        if len(future_tokpos) == 0:
            continue

        logits_with_all = model(input_ids=input_ids, attention_mask=attention_mask).logits[0]
        logp_with_all = F.log_softmax(logits_with_all, dim=-1)
        p_with_all_future = logp_with_all[future_tokpos].exp()

        for t in range(i):
            target_tokpos = mapping.get(t, [])
            if len(target_tokpos) == 0:
                continue

            input_without_t = input_ids.clone()
            input_without_t[0, target_tokpos] = mask_id

            logits_without_t = model(input_ids=input_without_t, attention_mask=attention_mask).logits[0]
            logp_without_t = F.log_softmax(logits_without_t, dim=-1)

            kl_per_position = (p_with_all_future * (logp_with_all[future_tokpos] - logp_without_t[future_tokpos])).sum(dim=-1)
            if subword_aggregation == "mean":
                # Average KL within each future word, then sum across words
                info_nats = sum(
                    float(kl_per_position[positions].mean().item())
                    for positions in future_word_groups.values()
                )
            else:
                info_nats = float(kl_per_position.sum().item())
            info_bits = info_nats * LOG2E

            info_matrix[t][i] = info_bits

    return words, info_matrix


def _calculate_stor_from_matrix(words: list[str], info_matrix: list[list[float]]) -> list[float]:
    N = len(words)

    if N == 0:
        return []

    stor = [0.0] * (N + 1)

    for i in range(1, N + 1):
        stor[i] = sum(info_matrix[t][i] for t in range(i))

    return stor[:N]


@torch.no_grad()
def compute_stor(
    sentence: str,
    tokenizer,
    model,
    device: str,
    subword_aggregation: str = "sum",
) -> tuple[list[str], list[float], list[list[float]]]:
    words, info_matrix = compute_info_matrix(sentence, tokenizer, model, device, subword_aggregation=subword_aggregation)

    if len(words) == 0:
        return [], [], []

    stor = _calculate_stor_from_matrix(words, info_matrix)

    return words, stor, info_matrix


def process_file_to_csv(
    input_path: str,
    output_path: str,
    model_name: str = "bert-base-uncased",
    model_type: str = "bert",
    device: Optional[str] = None,
    encoding: str = "utf-8",
    subword_aggregation: str = "sum",
):
    if device is None:
        device = "cuda" if torch.cuda.is_available() else "cpu"

    print(f"Model: {model_name} ({model_type}), Device: {device}, Subword aggregation: {subword_aggregation}")
    tokenizer, model = load_tokenizer_and_model(model_name, model_type, device)

    total_start = time.perf_counter()
    sent_id = 0

    with open(input_path, "r", encoding=encoding) as f_in, open(output_path, "w", newline="", encoding="utf-8") as f_out:

        writer = csv.writer(f_out)
        writer.writerow(["sent_id", "word_pos", "word", "stor"])

        for line in tqdm(f_in, desc="Sentences"):
            sent = line.strip()
            if not sent:
                continue

            sent_id += 1
            sent_start = time.perf_counter()
            results = compute_stor(sent, tokenizer, model, device=device, subword_aggregation=subword_aggregation)
            sent_elapsed = time.perf_counter() - sent_start

            if not results:
                continue

            words, stor, _ = results
            for idx in range(len(words)):
                writer.writerow([sent_id, idx + 1, words[idx], float(stor[idx])])

            tqdm.write(f"  sent {sent_id}: {sent_elapsed:.3f}s")

    total_elapsed = time.perf_counter() - total_start
    avg = total_elapsed / max(sent_id, 1)
    print(f"Done. {sent_id} sentences in {total_elapsed:.2f}s (avg {avg:.3f}s/sent)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Input text file (one sentence per line)")
    parser.add_argument("--output", required=True, help="Output CSV file path")
    parser.add_argument("--model", default="bert-base-uncased", help="HuggingFace model name")
    parser.add_argument("--model-type", choices=list(SUPPORTED_MODEL_TYPES), default="bert", dest="model_type", help="Model architecture")
    parser.add_argument("--device", default=None, help="Device (e.g. cuda:0)")
    parser.add_argument("--subword-agg", choices=["sum", "mean"], default="sum", dest="subword_agg", help="Aggregation over subword tokens: sum or mean")
    args = parser.parse_args()

    process_file_to_csv(
        input_path=args.input,
        output_path=args.output,
        model_name=args.model,
        model_type=args.model_type,
        device=args.device,
        subword_aggregation=args.subword_agg,
    )
