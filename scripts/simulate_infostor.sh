#!/usr/bin/env bash
set -euo pipefail

uv run ../src/gen_center_embedding.py \
    --model bert-base-uncased \
    --model-type bert \
    --device cpu \
    --output-path ../data/center_embedding_bert.csv \
    --latex-output-path ../data/center_embedding_sents.txt

uv run ../src/gen_relative_clause.py \
    --model bert-base-uncased \
    --model-type bert \
    --device cpu \
    --output-path ../data/relative_clause_bert.csv \
    --latex-output-path ../data/relative_clause_sents.txt

cd ../analysis
Rscript illustrate.R