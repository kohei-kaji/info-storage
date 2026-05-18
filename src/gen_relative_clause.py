import pandas as pd
import random
import time
import argparse
import numpy as np

from bert_kl import compute_stor, load_tokenizer_and_model


def calc_stor(sentence: str, tokenizer, model, device: str) -> list[float]:
    _, stors, _ = compute_stor(sentence, tokenizer, model, device)
    return [float(x) for x in stors]


def generate_stimuli_data():
    nouns_vocab = ["reporter", "senator", "president", "doctor", "lawyer", "artist", "banker", "student", "teacher", "soldier", "detective", "neighbor", "chef", "pilot", "baker", "driver", "nurse", "guard", "judge", "thief", "actor", "writer", "singer", "dancer"]
    verbs_vocab = ["met", "attacked", "ignored", "visited", "called", "helped", "warned", "admired", "stopped", "questioned", "avoided", "praised", "noticed", "watched", "trusted"]

    NUM_ITEMS = 30
    random.seed(42)

    sentence_data = []
    word_data = []

    for i in range(1, NUM_ITEMS + 1):
        n_list = random.sample(nouns_vocab, 3)
        v_list = random.sample(verbs_vocab, 2)

        roles = {"N1": n_list[0], "N2": n_list[1], "N3": n_list[2], "V1": v_list[0], "V2": v_list[1]}

        def _make_np(noun_str, region_label):
            return [{"word": "the", "label": "THE"}, {"word": noun_str, "label": region_label}]

        def _make_v(verb_str, region_label):
            return [{"word": verb_str, "label": region_label}]

        def _make_func(word, region_label):
            return [{"word": word, "label": region_label}]

        parts = {
            "N1": _make_np(roles["N1"], "N1"),
            "N2": _make_np(roles["N2"], "N2"),
            "N3": _make_np(roles["N3"], "N3"),
            "V1": _make_v(roles["V1"], "V1"),
            "V2": _make_v(roles["V2"], "V2"),
            "WHO": _make_func("who", "WHO")
        }

        sr_tokens = (parts["N1"] + parts["WHO"] + parts["V2"] + parts["N2"] + parts["V1"] + parts["N3"])
        or_tokens = (parts["N1"] + parts["WHO"] + parts["N2"] + parts["V2"] + parts["V1"] + parts["N3"])

        sr_head = sr_tokens[0].copy()
        sr_head["word"] = "The"
        sr_tokens[0] = sr_head
        or_head = or_tokens[0].copy()
        or_head["word"] = "The"
        or_tokens[0] = or_head

        sentence_data.append({"item": i, "condition": "SR", "sentence": " ".join([t["word"] for t in sr_tokens])})
        sentence_data.append({"item": i, "condition": "OR", "sentence": " ".join([t["word"] for t in or_tokens])})

        for idx, token in enumerate(sr_tokens, 1):
            word_data.append({"item": i, "condition": "SR", "word_position": idx, "word": token["word"], "region": token["label"]})
        for idx, token in enumerate(or_tokens, 1):
            word_data.append({"item": i, "condition": "OR", "word_position": idx, "word": token["word"], "region": token["label"]})

    return pd.DataFrame(sentence_data), pd.DataFrame(word_data)


def write_latex(df_sent, output_path):
    with open(output_path, "w") as f:
        f.write("\\begin{enumerate}")
        items = sorted(df_sent["item"].unique())
        for item_id in items:
            sent_sr = df_sent[(df_sent["item"] == item_id) & (df_sent["condition"] == "SR")]["sentence"].values[0]
            sent_or = df_sent[(df_sent["item"] == item_id) & (df_sent["condition"] == "OR")]["sentence"].values[0]
            f.write(f"  \\item a. {sent_sr} \\\\ b. {sent_or}\n")
        f.write("\\end{enumerate}")


def main(model_name: str, model_type: str, device: str, output_path: str, latex_output_path: str = None):

    print(f"Model: {model_name} ({model_type}), Device: {device}")
    tokenizer, model = load_tokenizer_and_model(model_name, model_type, device)

    df_sent, df_word = generate_stimuli_data()

    total_start = time.perf_counter()
    stor_map = {}
    for _, row in df_sent.iterrows():
        item = row["item"]
        cond = row["condition"]
        sentence = row["sentence"]
        sent_start = time.perf_counter()
        stor_map[(item, cond)] = calc_stor(sentence, tokenizer, model, device)
        print(f"  item {item} {cond}: {time.perf_counter() - sent_start:.3f}s")

    total_elapsed = time.perf_counter() - total_start
    print(f"STOR computation done. {len(df_sent)} sentences in {total_elapsed:.2f}s "
          f"(avg {total_elapsed / max(len(df_sent), 1):.3f}s/sent)")

    df_word["stor"] = np.nan
    for (item, cond), group in df_word.groupby(["item", "condition"]):
        values = stor_map.get((item, cond))
        if values:
            if len(group) != len(values):
                values = values + [None] * (len(group) - len(values))
            df_word.loc[group.index, "stor"] = values[:len(group)]

    df_word.to_csv(output_path, index=False)
    print(f"Saved: {output_path}")

    if latex_output_path:
        write_latex(df_sent, latex_output_path)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="bert-base-uncased", help="HuggingFace model name or local path")
    parser.add_argument("--model-type")
    parser.add_argument("--device")
    parser.add_argument("--output-path")
    parser.add_argument("--latex-output-path", default=None)
    args = parser.parse_args()

    main(model_name=args.model, model_type=args.model_type, device=args.device, output_path=args.output_path, latex_output_path=args.latex_output_path)
