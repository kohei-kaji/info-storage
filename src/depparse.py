import stanza

stanza.download("en")

nlp = stanza.Pipeline("en")


with open("../data/OneStop/sentences.txt", "r") as f_in, open("../data/parse/onestop_stanza.txt", "w") as f_out:
    for line in f_in:
        line = line.strip()
        if line:
            doc = nlp(line)
            for sentence in doc.sentences:
                print("{:C}\n".format(doc), file=f_out)
