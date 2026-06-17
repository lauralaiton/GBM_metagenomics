# QIIME2 pipeline for 18S rRNA GBM sequences (fungi)

# Tabulate and visualize sample metadata:
metadata:
	set -uex
	qiime metadata tabulate \
	  --m-input-file sample-metadata.tsv \
	  --o-visualization metadata-summ-1.qzv
	qiime tools view metadata-summ-1.qzv
	mkdir -p info_data
	mv metadata-summ-1.qzv info_data


# Use this block if filenames follow the Casava format: xxx_L[0-9][0-9][0-9]_R[12]_001.fastq.gz
import:
	set -uex
# If data is compressed, unzip first: unzip -d <output_folder> <archive>.zip
	qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --input-path ~/Documents/.............. \
  --output-path demultiplexed-sequences.qza


# Use this block if filenames do not match the Casava format.
# Requires a manifest .tsv file with per-sample file paths.
import_with_manifest:
	set -uex
	qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path ~/Documents/.../Metagenomics/GBM_fungi_data_seq/path_samples.tsv \
  --output-path demultiplexed-sequences.qza \
  --input-format PairedEndFastqManifestPhred33V2


# Trim the 528F/706R primer pair (V4 18S, Novogene):
remove_primers:
	qiime cutadapt trim-paired \
	--i-demultiplexed-sequences demultiplexed-sequences.qza \
	--p-cores 16 \
	--p-front-f GCGGTAATTCCAGCTCCAA \
	--p-front-r AATCCRAGAATTTCACCTCT \
	--o-trimmed-sequences TrimPrim_demultiplexed-sequences.qza \
	--verbose


# Summarize read counts and quality scores per sample:
summary:
	set -uex
	qiime demux summarize \
	--i-data TrimPrim_demultiplexed-sequences.qza \
	--o-visualization demultiplexed-sequences-summ.qzv
	qiime tools view demultiplexed-sequences-summ.qzv
	mkdir -p info_data
	mv demultiplexed-sequences-summ.qzv info_data


# Denoise with DADA2: truncation lengths set to drop positions with median quality < 25.
# Use --p-trim-left-f/r to additionally trim bases from the 5' end if needed.
# On Apple M1, run inside Docker: docker run -t -i -v $(pwd):/data quay.io/qiime2/core:2022.2 make denoising
denoising:
	set -uex
	qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demultiplexed-sequences.qza \
  --p-trunc-len-f 223 \
  --p-trunc-len-r 247 \
  --o-representative-sequences asv-sequences-0.qza \
  --o-table feature-table-0.qza \
  --o-denoising-stats dada2-stats.qza


summary_stats:
	set -uex
# 1) Per-sample read counts and filtering statistics:
	qiime metadata tabulate \
  --m-input-file dada2-stats.qza \
  --o-visualization dada2-stats-summ.qzv

# 2) Feature table: how many times each ASV was observed per sample:
	qiime feature-table summarize \
  --i-table feature-table-0.qza \
  --m-sample-metadata-file sample-metadata.tsv \
  --o-visualization feature-table-0-summ.qzv

# 3) Feature data: representative sequences for each ASV:
	qiime feature-table tabulate-seqs \
  --i-data asv-sequences-0.qza \
  --o-visualization asv-sequences-0-summ.qzv

	qiime tools view dada2-stats-summ.qzv
	qiime tools view feature-table-0-summ.qzv
	qiime tools view asv-sequences-0-summ.qzv
	mv dada2-stats-summ.qzv info_data
	mv feature-table-0-summ.qzv info_data
	mv asv-sequences-0-summ.qzv info_data


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
###### TRAINING THE SILVA TAXONOMIC CLASSIFIER
# Custom training is required because samples target V4 18S (528F/706R);
# all pre-trained QIIME2 classifiers cover V4 16S only.

training_tax_class_silva:
	set -uex
	mkdir -p training-feature-classifiers_silva

# 1) Download SILVA 138 reference sequences and taxonomy:
	wget -O "training-feature-classifiers_silva/silva-138-99-seqs.qza" "https://data.qiime2.org/2022.2/common/silva-138-99-seqs.qza"
	wget -O "training-feature-classifiers_silva/silva-138-99-tax.qza" "https://data.qiime2.org/2022.2/common/silva-138-99-tax.qza"

# 2) Extract the V4 18S region using the 528F/706R primers:
	cd training-feature-classifiers_silva;\
	qiime feature-classifier extract-reads \
	--i-sequences silva-138-99-seqs.qza \
	--p-f-primer GCGGTAATTCCAGCTCCAA \
	--p-r-primer AATCCRAGAATTTCACCTCT \
	--p-min-length 100 \
	--p-max-length 400 \
	--o-reads ref-seqs_silva.qza

# 3) Train Naive Bayes classifier on the extracted V4 18S reads:
	cd training-feature-classifiers_silva;\
	qiime feature-classifier fit-classifier-naive-bayes \
	--i-reference-reads ref-seqs_silva.qza \
	--i-reference-taxonomy silva-138-99-tax.qza \
	--o-classifier classifier_18S_V4_silva.qza


tax_annot:
# 1) Assign taxonomy to ASVs using the SILVA classifier:
	qiime feature-classifier classify-sklearn \
	--i-classifier classifier_18S_V4_silva.qza \
	--i-reads asv-sequences-0.qza \
	--o-classification taxonomy_silva.qza

# 2) Tabulate taxonomy assignments and confidence scores:
	qiime metadata tabulate \
	--m-input-file taxonomy_silva.qza \
	--o-visualization taxonomy_silva.qzv
	qiime tools view taxonomy_silva.qzv
	mkdir -p taxonomy_class
	mv taxonomy_silva.qzv taxonomy_class


filt_tax:
# 1) Remove non-fungal features: keeps only ASVs assigned to a phylum (p__),
#    excludes host, plant, protist, bacterial, and other non-target sequences:
	qiime taxa filter-table \
	--i-table feature-table-0.qza \
	--i-taxonomy taxonomy_silva.qza \
	--p-mode contains \
	--p-include p__ \
	--p-exclude 'p__;,Arthropoda,Mitochondria,Protalveolata,Chlorophyta,Cercozoa,Rotifera,Diatomea,Nematozoa,\
	Xenacoelomorpha,Vertebrata,Nemertea,Ochrophyta,Annelida,Dinoflagellata,Ciliophora,Cryptophyceae,Apicomplexa,\
	Cnidaria,Platyhelminthes,Phragmoplastophyta,Labyrinthulomycetes,Holozoa,Preaxostyla,Echinodermata,Hemichordata,\
	Mollusca,Centrohelida,Gastrotricha,Pavlovophyceae,Bicosoecida,Nucleariidae,Bicosoecida,Bacteria,MAST-1,MAST-2,MAST-3,\
	MAST-7,MAST-12,Mollusca,Cnidaria,Protosporangiida,Xenacoelomorpha,Schizoplasmodiida,Apusomonadidae,Rigifilida,MAST-7' \
	--o-filtered-table filtered-table-1.qza

# 2) Remove samples with fewer than 1,000 sequences (poor amplification or sequencing):
	qiime feature-table filter-samples \
	--i-table filtered-table-1.qza \
	--p-min-frequency 1000 \
	--o-filtered-table filtered-table-2.qza

# 3) Drop ASV sequences no longer present in the filtered table:
	qiime feature-table filter-seqs \
	--i-data asv-sequences-0.qza \
	--i-table filtered-table-2.qza \
	--o-filtered-data filtered-sequences-1.qza

# 4) Summarize the filtered feature table:
	qiime feature-table summarize \
	--i-table filtered-table-2.qza \
	--m-sample-metadata-file sample-metadata.tsv \
	--o-visualization filtered-table-2-summ.qzv
	qiime tools view filtered-table-2-summ.qzv

# 5) Generate taxonomy barplots for an initial view of sample composition:
	qiime taxa barplot \
	--i-table filtered-table-2.qza \
	--i-taxonomy taxonomy_silva.qza \
	--m-metadata-file sample-metadata.tsv \
	--o-visualization taxa-bar-plots.qzv
	qiime tools view taxa-bar-plots.qzv
	mkdir -p taxonomy_class
	mv taxa-bar-plots.qzv taxonomy_class


phylo_tree:
# Build a rooted phylogenetic tree: aligns ASVs with MAFFT,
# masks hypervariable positions, and infers tree with FastTree:
	set -uex
	qiime phylogeny align-to-tree-mafft-fasttree \
	--i-sequences filtered-sequences-1.qza \
	--output-dir phylogeny-align-to-tree-mafft-fasttree

# Visualize tree with sample and taxonomy metadata:
	qiime empress community-plot \
	--i-tree phylogeny-align-to-tree-mafft-fasttree/rooted_tree.qza \
	--i-feature-table filtered-table-2.qza \
	--m-sample-metadata-file sample-metadata.tsv \
	--m-feature-metadata-file taxonomy_silva.qza \
	--o-visualization empress-tree-tax-table.qzv
	qiime tools view empress-tree-tax-table.qzv
	mkdir -p taxonomy_class
	mv empress-tree-tax-table.qzv taxonomy_class


rarefraction:
# Rarefaction standardizes sequencing depth across samples by subsampling.
# Note: samples below the chosen depth are dropped; rare ASVs may also be lost.

# Inspect the feature table to choose an appropriate sampling depth
# (maximize features retained while keeping all samples):
	qiime tools view filtered-table-2-summ.qzv
	mv filtered-table-2-summ.qzv taxonomy_class
# Selected depth: 1,830 → retains 12,810 features (9.91%) across all samples.

# 1) Alpha rarefaction curves — evaluate richness stabilization across depths:
	qiime diversity alpha-rarefaction \
  --i-table filtered-table-2.qza \
  --p-metrics shannon \
  --m-metadata-file sample-metadata.tsv \
  --p-max-depth 3000 \
  --o-visualization shannon-rarefaction-plot.qzv
	qiime tools view shannon-rarefaction-plot.qzv
	mkdir -p diversity
	mv shannon-rarefaction-plot.qzv diversity

# 2) Beta rarefaction — assess stability of between-sample distances across depths:
	qiime diversity beta-rarefaction \
  --i-table filtered-table-2.qza \
  --p-metric braycurtis \
  --p-clustering-method nj \
  --p-sampling-depth 1830 \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization braycurtis-rarefaction-plot.qzv
	qiime tools view braycurtis-rarefaction-plot.qzv
	mv braycurtis-rarefaction-plot.qzv diversity

# NOTE: Rarefaction plots showed large sequencing depth differences between sample groups;
# diversity analyses were not carried out for this dataset.


export_for_R:
# Export pipeline outputs for downstream analysis in R:
	mkdir -p export

# 1) Unrooted phylogenetic tree in Newick format:
	qiime tools export \
	--input-path phylogeny-align-to-tree-mafft-fasttree/tree.qza \
	--output-path export

# 2) Feature table as BIOM v2.1.0, then convert to TSV:
	qiime tools export \
	--input-path filtered-table-2.qza \
	--output-path export
	biom convert \
	-i export/feature-table.biom \
	-o export/feature-table.tsv \
	--to-tsv

# 3) Taxonomy classifications as TSV:
	qiime tools export \
	--input-path taxonomy_silva.qza \
	--output-path export

# 4) Format all exported files for R import:
# Remove BIOM header line and convert to CSV:
	sed '1d' export/feature-table.tsv > export/feature-table_final.tsv
	sed 's/\t/,/g' export/feature-table_final.tsv > export/feature-table_final.csv
	sed 's/\t/,/g' sample-metadata.tsv > export/sample-metadata.csv
# Taxonomy: convert to CSV, keep only Feature ID and Taxon columns, split semicolon-delimited ranks into columns:
	sed 's/\t/,/g' export/taxonomy.tsv > export/taxonomy.csv
	cut -d, -f1,2 export/taxonomy.csv > export/taxonomy_f.csv
	sed 's/;/,/g' export/taxonomy_f.csv > export/taxonomy_final.csv
# Note: headers in taxonomy_final.csv are edited manually after export.

# Remove intermediate files:
	rm -f export/taxonomy.tsv export/taxonomy.csv export/taxonomy_f.csv export/feature-table.tsv


export_for_PICRUSt2:
# Export files required for functional prediction with PICRUSt2:
	mkdir -p PICRUSt2

# 1) Filtered ASV sequences in FASTA format:
	qiime tools export \
	--input-path filtered-sequences-1.qza \
	--output-path PICRUSt2/

# 2) Filtered feature table in BIOM format:
	qiime tools export \
	--input-path filtered-table-2.qza \
	--output-path PICRUSt2/
	biom summarize-table \
	-i PICRUSt2/feature-table.biom


# Run the full PICRUSt2 functional prediction pipeline:
PICRUSt2_run:
picrust2_pipeline.py -s PICRUSt2/dna-sequences.fasta -i PICRUSt2/feature-table.biom -o picrust2_out_pipeline -p 1
