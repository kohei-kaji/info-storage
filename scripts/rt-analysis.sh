#!/usr/bin/env bash
set -euo pipefail

uv run python ../src/depparse.py
uv run python ../src/ns_os_stor.py

uv run python ../src/bert_kl.py \
    --input ../data/naturalstories/sentences.txt \
    --output ../data/ns_bert_stor_sum.csv \
    --model bert-base-uncased \
    --model-type bert \
    --device cuda:3

uv run python ../src/bert_kl.py \
    --input ../data/naturalstories/sentences.txt \
    --output ../data/ns_bertlarge_stor_sum.csv \
    --model bert-large-uncased \
    --model-type bert \
    --device cuda:3

uv run python ../src/bert_kl.py \
    --input ../data/naturalstories/sentences.txt \
    --output ../data/ns_roberta_stor_sum.csv \
    --model FacebookAI/roberta-base \
    --model-type roberta \
    --device cuda:3


uv run python ../src/bert_kl.py \
    --input ../data/OneStop/sentences.txt \
    --output ../data/os_bert_stor_sum.csv \
    --model bert-base-uncased \
    --model-type bert \
    --device cuda:3

uv run python ../src/bert_kl.py \
    --input ../data/OneStop/sentences.txt \
    --output ../data/os_bertlarge_stor_sum.csv \
    --model bert-large-uncased \
    --model-type bert \
    --device cuda:3

uv run python ../src/bert_kl.py \
    --input ../data/OneStop/sentences.txt \
    --output ../data/os_roberta_stor_sum.csv \
    --model FacebookAI/roberta-base \
    --model-type roberta \
    --device cuda:3

cd ../analysis
Rscript rt-analysis.R
Rscript rt-analysis-across-models.R
