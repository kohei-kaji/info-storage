from dltstor import Sent, UDToken, calc_dlt_storage
import pandas as pd

treebank: str = "../data/naturalstories/parses/ud/stories-aligned.conllx"

sents: list[Sent] = []
sentid: int = 0
with open(treebank, encoding="utf8", errors="ignore") as f:
    sent = Sent(None, [])
    for line in f:
        sent.sent_id = f"{sentid}"
        if line == "\n":
            sentid += 1
            sent = calc_dlt_storage(sent)
            sents.append(sent)
            sent = Sent(None, [])
        else:
            contents: list[str] = line.strip().split()
            tokenid = contents[9].replace("TokenId=", "")
            if tokenid.count(".") == 2:
                tokenid = tokenid[:-2]
            sent.tokens.append(
                UDToken(
                    token_id=contents[0],
                    word=contents[1].replace("``", "'").replace("''", "'").replace("-LRB-", "(").replace("-RRB-", ")"),
                    head=contents[6],
                    deprel=contents[7],
                    misc=contents[9].replace("TokenId=", ""),
                    dlt_stor=0
                ))

words = []
with open("../data/naturalstories/stories.txt", encoding="utf8") as f:
    for line in f:
        words.extend(line.strip().split())

data_rows = []

word_index = 0

for sent in sents:
    current_word_str = ""
    current_dlt_sum = 0

    for i, token in enumerate(sent.tokens):
        current_word_str += token.word
        current_dlt_sum += token.dlt_stor
        if words[word_index] != current_word_str:
            pass
        else:
            data_rows.append({"word": current_word_str, "dlt_stor": current_dlt_sum})

            current_word_str = ""
            current_dlt_sum = 0
            word_index += 1

df = pd.DataFrame(data_rows)
df.to_csv("../data/ns_dlt.csv", index=False, encoding="utf-8")


parse: str = "../data/parse/onestop_stanza.txt"

sents: list[Sent] = []
sentid: int = 0
with open(parse, encoding="utf8", errors="ignore") as f:
    sent = Sent(None, [])
    for line in f:
        sent.sent_id = f"{sentid}"
        if line == "\n":
            sentid += 1
            sent = calc_dlt_storage(sent)
            sents.append(sent)
            sent = Sent(None, [])
        elif line.startswith("#"):
            pass
        else:
            contents: list[str] = line.strip().split()
            if "-" in contents[0]:
                pass
            else:
                sent.tokens.append(
                    UDToken(
                        token_id=contents[0],
                        word=contents[1],
                        head=contents[6],
                        deprel=contents[7],
                        misc=None,
                        dlt_stor=0
                    ))

words = []
df = pd.read_csv("../data/OneStop/articles.csv")
for i, row in df.iterrows():
    words.extend(row["article"].split())

data_rows = []
word_index = 0

for sent in sents:
    current_word_str = ""
    current_dlt_sum = 0

    for i, token in enumerate(sent.tokens):
        current_word_str += token.word
        current_dlt_sum += token.dlt_stor
        if words[word_index] != current_word_str:
            pass
        else:
            data_rows.append({"word": current_word_str, "dlt_stor": current_dlt_sum})

            current_word_str = ""
            current_dlt_sum = 0
            word_index += 1

df = pd.DataFrame(data_rows)
df.to_csv("../data/os_dlt.csv", index=False, encoding="utf-8")
