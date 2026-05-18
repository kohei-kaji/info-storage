import os
import glob
import re
import csv
import time
import argparse
from typing import Optional
from tqdm import tqdm
import torch

from bert_kl import compute_stor, load_tokenizer_and_model, SUPPORTED_MODEL_TYPES


def read_conllu_as_space_separated(file_path: str) -> list[tuple[str, list[str]]]:
    sentences: list[tuple[str, list[str]]] = []

    with open(file_path, encoding="utf-8") as f:
        content = f.read().strip()
        if not content:
            return []
        pgs = content.split("\n\n")

    for pg in pgs:
        if not pg.strip():
            continue

        lines = [line.strip() for line in pg.split("\n")]
        sent_id = None
        aggregated_words: list[str] = []
        current_word_parts: str = ""

        valid_lines: list[str] = []
        for line in lines:
            if line.startswith("#"):
                m = re.match(r"# sent_id = (.*)", line)
                if m:
                    sent_id = m.group(1)
                continue
            if not line:
                continue
            valid_lines.append(line)

        for i, line in enumerate(valid_lines):
            cols: list[str] = line.split("\t")
            if "-" in cols[0]:
                continue
            word_form: str = cols[1]
            misc: str = cols[9]

            current_word_parts += word_form

            if "SpaceAfter=No" not in misc or i == len(valid_lines) - 1:
                aggregated_words.append(current_word_parts)
                current_word_parts = ""

        if aggregated_words:
            if sent_id is None:
                sent_id = "unknown"
            sentences.append((sent_id, aggregated_words))

    return sentences


def process_folder(
    input_folder: str,
    output_path: str,
    model_name: str = "bert-base-uncased",
    model_type: str = "bert",
    device: Optional[str] = None,
    subword_aggregation: str = "sum",
):
    if device is None:
        device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Model: {model_name} ({model_type}), Device: {device}, Subword aggregation: {subword_aggregation}")

    tokenizer, model = load_tokenizer_and_model(model_name, model_type, device)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    stor_col = f"{model_type}_stor"
    total_start = time.perf_counter()
    total_sents = 0

    with open(output_path, "w", newline="", encoding="utf-8") as f_out:
        writer = csv.writer(f_out)
        writer.writerow(["sentid", "wordid", "word", stor_col])

        files = glob.glob(os.path.join(input_folder, "*.conllu"))
        if not files:
            print(f"Warning: No .conllu files found in {input_folder}")
            return

        for file_path in tqdm(files, desc="Processing files"):
            file_start = time.perf_counter()
            sentences = read_conllu_as_space_separated(file_path)

            for sent_id, space_separated_words in sentences:
                words_str = " ".join(space_separated_words)

                sent_start = time.perf_counter()
                results = compute_stor(words_str, tokenizer, model, device=device, subword_aggregation=subword_aggregation)
                sent_elapsed = time.perf_counter() - sent_start

                if not results:
                    continue

                res_words, res_stor, _ = results

                if len(space_separated_words) != len(res_stor):
                    print(f"Warning: Length mismatch in sent {sent_id}. "
                          f"Input: {len(space_separated_words)}, Output: {len(res_stor)}")
                    continue

                for i, (word, stor_val) in enumerate(zip(res_words, res_stor)):
                    writer.writerow([sent_id, i + 1, word, f"{stor_val}"])

                total_sents += 1

            file_elapsed = time.perf_counter() - file_start
            tqdm.write(f"  {os.path.basename(file_path)}: {len(sentences)} sents in {file_elapsed:.2f}s")

    total_elapsed = time.perf_counter() - total_start
    avg = total_elapsed / max(total_sents, 1)
    print(f"Done. {total_sents} sentences in {total_elapsed:.2f}s (avg {avg:.3f}s/sent)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Compute STOR values for Universal Dependencies CoNLL-U files"
    )
    parser.add_argument("--input-folder", required=True, help="Folder containing .conllu files")
    parser.add_argument("--output", required=True, help="Output CSV file path")
    parser.add_argument("--model", default="bert-base-uncased", help="HuggingFace model name or local path")
    parser.add_argument("--model-type", choices=list(SUPPORTED_MODEL_TYPES), default="bert", dest="model_type", help="Model architecture")
    parser.add_argument("--device", default=None, help="Device")
    parser.add_argument("--subword-agg", choices=["sum", "mean"], default="sum", dest="subword_agg", help="Aggregation over subword tokens: sum or mean")
    args = parser.parse_args()

    process_folder(
        input_folder=args.input_folder,
        output_path=args.output,
        model_name=args.model,
        model_type=args.model_type,
        device=args.device,
        subword_aggregation=args.subword_agg,
    )
