#!/bin/bash

DATA_DIR="ccle_vs_gdsc"
URL="https://bimsbstatic.mdc-berlin.de/akalin/buyar/flexynesis-benchmark-datasets/ccle_vs_gdsc.tgz"

if [ ! -d "$DATA_DIR" ]; then
    echo "Downloading dataset..."
    wget -O dataset.tgz "$URL"
    echo "Unpacking dataset..."
    tar -xvzf dataset.tgz
    rm dataset.tgz
else
    echo "Dataset already exists. Skipping download."
fi

echo "Checking dataset structure..."
ls -lh "$DATA_DIR"

echo "Counting number of files in dataset..."
find "$DATA_DIR" -type f | wc -l

echo "Checking first few lines of a data file..."
head -n 10 "$DATA_DIR/ccle_expression.csv"

echo "Checking summary statistics of expression data..."
awk -F',' '{for (i=2; i<=NF; i++) sum[i]+=$i; count++} END {for (i=2; i<=NF; i++) print "Feature", i-1, "Mean:", sum[i]/count}' "$DATA_DIR/ccle_expression.csv" | head -n 10

python3 << EOF
import pandas as pd
import numpy as np
from sklearn.feature_selection import VarianceThreshold

# Load mutation data
mutation_data = pd.read_csv("$DATA_DIR/ccle_mutation.csv", index_col=0)

# Variance-based filtering (keeping top 10% most variant features)
selector = VarianceThreshold(threshold=np.percentile(mutation_data.var(), 90))
filtered_data = mutation_data.loc[:, selector.get_support()]

# Save filtered data
filtered_data.to_csv("$DATA_DIR/filtered_mutation.csv")
print("Filtered mutation data saved.")
EOF

echo "Feature selection completed. Ready for model training."
