#!/usr/bin/env bash
set -euo pipefail

uv run python ../src/dltstor.py

uv run python ../src/udstor.py \
    --input ../data/UD_English-GUM \
    --output ../data/gum_bert_sum.csv \
    --model bert-base-uncased \
    --model-type bert \
    --device cuda:2

uv run python ../src/udstor.py \
    --input ../data/UD_English-GUM \
    --output ../data/gum_bertlarge_sum.csv \
    --model bert-large-uncased \
    --model-type bert \
    --device cuda:2

uv run python ../src/udstor.py \
    --input ../data/UD_English-GUM \
    --output ../data/gum_roberta_sum.csv \
    --model FacebookAI/roberta-base \
    --model-type roberta \
    --device cuda:2

cd ../analysis
Rscript ud-analysis.R
