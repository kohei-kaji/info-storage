import os
import glob
import re
import pandas as pd
from dataclasses import dataclass
from typing import Optional


IGNORE_DEPS = {"punct", "root", "dep", "reparandum"} 

@dataclass
class UDToken:
    token_id: str
    word: str
    head: str
    deprel: str
    misc: str
    dlt_stor: int = 0

@dataclass
class Sent:
    sent_id: Optional[str]
    tokens: list[UDToken]


def read_conllu_folder(folder_path: str) -> list[Sent]:
    sents: list[Sent] = []
    files = glob.glob(os.path.join(folder_path, "*.conllu"))

    for file_path in files:
        with open(file_path, encoding="utf-8") as f:
            pgs = f.read().strip().split("\n\n")

        for pg in pgs:
            if not pg.strip():
                continue

            sent = Sent(None, [])
            lines = [line.strip() for line in pg.split("\n")]

            for line in lines:
                m = re.match(r"# sent_id = (.*)", line)
                if m:
                    sent.sent_id = m.group(1)
                    continue

                if not line or line.startswith("#"):
                    continue

                cols = line.split("\t")

                if "-" in cols[0]:
                    continue

                sent.tokens.append(
                    UDToken(
                        token_id=str(cols[0]),
                        word=cols[1],
                        head=str(cols[6]),
                        deprel=cols[7],
                        misc=cols[9],
                        dlt_stor=0
                        )
                )
            if sent.tokens:
                sents.append(sent)

    return sents


def precede(a: str, b: str) -> bool:
    try:
        a_val = float(a)
        b_val = float(b)
        return a_val < b_val
    except ValueError:
        return False


def calc_dlt_storage(sent: Sent, ignore_deps: set = IGNORE_DEPS) -> Sent:
    for _, token in enumerate(sent.tokens):
        unseen_nodes: set[str] = set()

        current_idx = float(token.token_id)

        for t in sent.tokens:
            head_id_str = t.head
            dep_rel = t.deprel

            if head_id_str == "0" or head_id_str == "_":
                continue
            if dep_rel in ignore_deps:
                continue

            dep_idx = float(t.token_id)
            head_idx = float(head_id_str)

            dep_is_seen = dep_idx <= current_idx
            head_is_seen = head_idx <= current_idx

            if dep_is_seen and not head_is_seen:
                unseen_nodes.add(head_id_str)

            if not dep_is_seen and head_is_seen:
                unseen_nodes.add(t.token_id)

        token.dlt_stor = len(unseen_nodes)
        
    return sent


def aggregate_and_save(sents: list[Sent], output_path: str):
    data_rows: list[dict] = []

    for sent in sents:
        if not sent.sent_id:
            continue

        current_word_str = ""
        current_dlt_sum = 0
        word_counter = 1

        for i, token in enumerate(sent.tokens):
            current_word_str += token.word
            current_dlt_sum += token.dlt_stor

            is_end_of_word = "SpaceAfter=No" not in token.misc

            if i == len(sent.tokens) - 1:
                is_end_of_word = True

            if is_end_of_word:
                data_rows.append({
                    "sentid": sent.sent_id,
                    "wordid": word_counter,
                    "word": current_word_str,
                    "dlt_stor": current_dlt_sum
                })

                current_word_str = ""
                current_dlt_sum = 0
                word_counter += 1

    df = pd.DataFrame(data_rows)
    df.to_csv(output_path, index=False, encoding="utf-8")


if __name__ == "__main__":
    input_folder = "../data/UD_English-GUM"
    output_path = "../data/gum_dlt.csv"

    sents = read_conllu_folder(input_folder)
    sents = [calc_dlt_storage(sent) for sent in sents]
    aggregate_and_save(sents, output_path)
