#!/bin/bash

# Exit on error
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# project path:
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project root: $PROJECT_ROOT"

DATA_DIR="$PROJECT_ROOT/data/bacteria/input"
OUTPUT_DIR="$PROJECT_ROOT/outs/bacteria"

TABLE="$DATA_DIR/filtered-table-2.qza"
TAXONOMY="$DATA_DIR/taxonomy_green.qza"
METADATA="$DATA_DIR/sample-metadata.tsv"

# Create main output directory
mkdir -p "$OUTPUT_DIR"


# Activate QIIME2 environment
source "/Users/.../miniconda3/etc/profile.d/conda.sh"
conda activate /Users/.../miniconda3/envs/qiime2-2023

echo "Using QIIME version:"
qiime --version

##### Function to run ANCOM-BC by taxonomic level:
run_ancombc_level () {
    TAX_LABEL="$1"
    TAX_LEVEL="$2"
    TAX_OUTDIR="$OUTPUT_DIR/$TAX_LABEL"

    mkdir -p "$TAX_OUTDIR"

    echo "Running analysis for: $TAX_LABEL (level $TAX_LEVEL)"
    echo "Output directory: $TAX_OUTDIR"

    ### 1) Collapse to target taxonomic level
    qiime taxa collapse \
      --i-table "$TABLE" \
      --i-taxonomy "$TAXONOMY" \
      --p-level "$TAX_LEVEL" \
      --o-collapsed-table "$TAX_OUTDIR/${TAX_LABEL}-table.qza"

    ### 2) Filter low-frequency taxa
    qiime feature-table filter-features \
      --i-table "$TAX_OUTDIR/${TAX_LABEL}-table.qza" \
      --p-min-frequency 3 \
      --o-filtered-table "$TAX_OUTDIR/${TAX_LABEL}-table-filt.qza"

    ### 3) Run ANCOM-BC
    qiime composition ancombc \
      --i-table "$TAX_OUTDIR/${TAX_LABEL}-table-filt.qza" \
      --m-metadata-file "$METADATA" \
      --p-formula GrapeStage \
      --o-differentials "$TAX_OUTDIR/${TAX_LABEL}-ancombc.qza"

    ### 4) Visualize results
    qiime composition tabulate \
      --i-data "$TAX_OUTDIR/${TAX_LABEL}-ancombc.qza" \
      --o-visualization "$TAX_OUTDIR/${TAX_LABEL}-ancombc.qzv"

    echo "Completed: $TAX_LABEL"

    ### 5) Export ANCOM-BC result tables
    qiime tools export \
      --input-path "$TAX_OUTDIR/${TAX_LABEL}-ancombc.qza" \
      --output-path "$EXPORT_DIR"

    echo "Completed: $TAX_LABEL"
    echo "Exported ANCOM-BC tables to: $EXPORT_DIR"

}

###### Run analyses

run_ancombc_level "order" 4
run_ancombc_level "family" 5
run_ancombc_level "genus" 6

echo "All ANCOM-BC analyses completed successfully!"






