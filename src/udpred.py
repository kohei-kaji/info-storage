import os
import glob
import re
import csv
from collections import defaultdict
import numpy as np
from tqdm import tqdm
import torch

from bert_kl import compute_info_matrix, load_tokenizer_and_model, SUPPORTED_MODEL_TYPES


def read_conllu_as_space_separated(file_path: str) -> list[tuple[str, list[str]]]:
    sentences = []

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
        aggregated_words = []
        current_word_parts = ""

        valid_lines = []
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
            cols = line.split("\t")
            if "-" in cols[0]:
                continue
            word_form = cols[1]
            misc = cols[9]
            current_word_parts += word_form
            if "SpaceAfter=No" not in misc or i == len(valid_lines) - 1:
                aggregated_words.append(current_word_parts)
                current_word_parts = ""

        if aggregated_words:
            if sent_id is None:
                sent_id = "unknown"
            sentences.append((sent_id, aggregated_words))

    return sentences


def collect_info_by_distance(
    input_folder: str,
    model_name: str = "bert-base-uncased",
    model_type: str = "bert",
    device: str | None = None,
    max_distance: int = 50,
    subword_aggregation: str = "sum",
) -> dict[int, list[float]]:
    if device is None:
        device = "cuda:0" if torch.cuda.is_available() else "cpu"
    print(f"Model: {model_name} ({model_type}), Device: {device}, Subword aggregation: {subword_aggregation}")

    tokenizer, model = load_tokenizer_and_model(model_name, model_type, device)

    info_by_distance: dict[int, list[float]] = defaultdict(list)

    files = glob.glob(os.path.join(input_folder, "*.conllu"))
    if not files:
        print(f"Warning: No .conllu files found in {input_folder}")
        return info_by_distance

    total_sents = 0

    for file_path in tqdm(files, desc="Processing files"):
        sentences = read_conllu_as_space_separated(file_path)

        for sent_id, space_separated_words in tqdm(sentences, desc=f"  {os.path.basename(file_path)}", leave=False):
            words_str = " ".join(space_separated_words)

            words, info_matrix = compute_info_matrix(
                words_str, tokenizer, model, device=device, subword_aggregation=subword_aggregation
            )

            if len(words) == 0:
                continue

            N = len(words)

            for t in range(N):
                for i in range(t + 1, N + 1):
                    d = i - t
                    if d > max_distance:
                        continue
                    info_by_distance[d].append(info_matrix[t][i])

            total_sents += 1

    print(f"Processed {total_sents} sentences.")
    return dict(info_by_distance)


def compute_bootstrap_ci(
    values: np.ndarray,
    n_bootstrap: int = 10000,
    ci: float = 0.95,
    seed: int = 42,
) -> tuple[float, float]:
    rng = np.random.default_rng(seed)
    n = len(values)

    boot_means = np.empty(n_bootstrap)
    for b in range(n_bootstrap):
        sample = rng.choice(values, size=n, replace=True)
        boot_means[b] = np.mean(sample)

    alpha = 1 - ci
    lower = np.percentile(boot_means, 100 * alpha / 2)
    upper = np.percentile(boot_means, 100 * (1 - alpha / 2))

    return lower, upper


def compute_stats_by_distance(
    info_by_distance: dict[int, list[float]],
    use_bootstrap: bool = True,
    n_bootstrap: int = 10000,
) -> list[dict]:
    results = []

    for d in sorted(info_by_distance.keys()):
        values = np.array(info_by_distance[d])
        n = len(values)
        mean = np.mean(values)
        se = np.std(values, ddof=1) / np.sqrt(n)

        if use_bootstrap and n >= 30:
            ci_lower, ci_upper = compute_bootstrap_ci(values, n_bootstrap=n_bootstrap)
        else:
            ci_lower = mean - 1.96 * se
            ci_upper = mean + 1.96 * se

        results.append({
            "distance": d,
            "n": n,
            "mean": mean,
            "se": se,
            "ci_lower": ci_lower,
            "ci_upper": ci_upper,
        })

    return results


def save_results(results: list[dict], output_path: str):
    os.makedirs(os.path.dirname(output_path) if os.path.dirname(output_path) else ".", exist_ok=True)

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["distance", "n", "mean", "se", "ci_lower", "ci_upper"])
        writer.writeheader()
        writer.writerows(results)

    print(f"Saved results to {output_path}")


if __name__ == "__main__":
    input_folder = "/home/kajikawa/depinfo/UD_English-GUM"
    output_csv = "./ud_preds.csv"
    model_name = "bert-base-uncased"
    model_type = "bert"
    device = None
    max_distance = 30
    subword_aggregation = "sum"
    n_bootstrap = 10000

    info_by_distance = collect_info_by_distance(
        input_folder=input_folder,
        model_name=model_name,
        model_type=model_type,
        device=device,
        max_distance=max_distance,
        subword_aggregation=subword_aggregation,
    )

    results = compute_stats_by_distance(
        info_by_distance,
        use_bootstrap=True,
        n_bootstrap=n_bootstrap,
    )

    save_results(results, output_csv)
