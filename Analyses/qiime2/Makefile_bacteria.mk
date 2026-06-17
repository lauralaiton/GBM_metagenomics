##### QIIME2 pipeline for 16S rRNA GBM sequences (bacteria)

metadata:
	set -uex
# Tabulate and visualize sample metadata:
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
  --input-path ~/Documents/.../Metagenomics/GBM_bacteria_data_seq/path_samples.tsv \
  --output-path demultiplexed-sequences.qza \
  --input-format PairedEndFastqManifestPhred33V2


# Trim the 341F/806R primer pair (V3-V4, Novogene):
remove_primers:
	qiime cutadapt trim-paired \
	--i-demultiplexed-sequences demultiplexed-sequences.qza \
	--p-cores 16 \
	--p-front-f CCTAYGGGRBGCASCAG \
	--p-front-r GGACTACNNGGGTATCTAAT \
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


# Denoise with DADA2: truncation lengths set to drop positions with median quality < 20.
# On Apple M1, run inside Docker: docker run -t -i -v $(pwd):/data quay.io/qiime2/core:2022.2 make denoising
denoising:
	set -uex
	qiime dada2 denoise-paired \
  --i-demultiplexed-seqs TrimPrim_demultiplexed-sequences.qza \
  --p-trunc-len-f 225 \
  --p-trunc-len-r 223 \
  --o-representative-sequences asv-sequences-0.qza \
  --o-table feature-table-0.qza \
  --o-denoising-stats dada2-stats.qza \
  --verbose


summary_stats:
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
###### TRAINING TAXONOMIC CLASSIFIERS
# Two classifiers are trained (Greengenes and SILVA) to compare classification accuracy.
# Custom training is required because samples target V3-V4 (341F/806R);
# all pre-trained QIIME2 classifiers cover V4 only.

# --- Greengenes classifier ---
training_tax_class_green:
	set -uex
	mkdir -p training-feature-classifiers_green

# 1) Download Greengenes 13_8 reference sequences and taxonomy:
	wget -O "training-feature-classifiers_green/gg_13_8_otus.tar.gz" "ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz"
	cd training-feature-classifiers_green; tar xzfv gg_13_8_otus.tar.gz
	cd training-feature-classifiers_green; rm gg_13_8_otus.tar.gz
	cd training-feature-classifiers_green/gg_13_8_otus/rep_set/; cp 99_otus.fasta ../../
	cd training-feature-classifiers_green/gg_13_8_otus/taxonomy; cp 99_otu_taxonomy.txt ../../

# 2) Import reference sequences and taxonomy into QIIME2 format:
	cd training-feature-classifiers_green;\
	qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path 99_otus.fasta \
  --output-path 99_otus.qza

	cd training-feature-classifiers_green;\
	qiime tools import \
	--type 'FeatureData[Taxonomy]' \
	--input-format HeaderlessTSVTaxonomyFormat \
	--input-path 99_otu_taxonomy.txt \
	--output-path ref-taxonomy.qza

# 3) Extract the V3-V4 region using the 341F/806R primers:
	cd training-feature-classifiers_green;\
	qiime feature-classifier extract-reads \
	--i-sequences 99_otus.qza \
	--p-f-primer CCTAYGGGRBGCASCAG \
	--p-r-primer GGACTACNNGGGTATCTAAT \
	--p-min-length 100 \
	--p-max-length 600 \
	--o-reads ref-seqs.qza

# 4) Train Naive Bayes classifier on the extracted V3-V4 reads:
	cd training-feature-classifiers_green;\
	qiime feature-classifier fit-classifier-naive-bayes \
	--i-reference-reads ref-seqs.qza \
	--i-reference-taxonomy ref-taxonomy.qza \
	--o-classifier classifier_16S_V3-V4_green.qza


# --- SILVA classifier ---
training_tax_class_silva:
	set -uex
	mkdir -p training-feature-classifiers_silva

# 1) Download SILVA 138 reference sequences and taxonomy:
	wget -O "training-feature-classifiers_silva/silva-138-99-seqs.qza" "https://data.qiime2.org/2022.2/common/silva-138-99-seqs.qza"
	wget -O "training-feature-classifiers_silva/silva-138-99-tax.qza" "https://data.qiime2.org/2022.2/common/silva-138-99-tax.qza"

# 2) Extract the V3-V4 region using the 341F/806R primers:
	cd training-feature-classifiers_silva;\
	qiime feature-classifier extract-reads \
	--i-sequences silva-138-99-seqs.qza \
	--p-f-primer CCTAYGGGRBGCASCAG \
	--p-r-primer GGACTACNNGGGTATCTAAT \
	--p-min-length 100 \
	--p-max-length 600 \
	--o-reads ref-seqs_silva.qza

# 3) Train Naive Bayes classifier on the extracted V3-V4 reads:
	cd training-feature-classifiers_silva;\
	qiime feature-classifier fit-classifier-naive-bayes \
	--i-reference-reads ref-seqs_silva.qza \
	--i-reference-taxonomy silva-138-99-tax.qza \
	--o-classifier classifier_16S_V3-V4_silva.qza


# After comparing both classifiers, Greengenes was selected for downstream analysis.
tax_annot:
# 1) Assign taxonomy to ASVs using the Greengenes classifier:
	qiime feature-classifier classify-sklearn \
	--i-classifier training-feature-classifiers_green/classifier_16S_V3-V4_green.qza \
	--i-reads asv-sequences-0.qza \
	--o-classification taxonomy_green.qza

# 2) Tabulate taxonomy assignments and confidence scores:
	qiime metadata tabulate \
	--m-input-file taxonomy_green.qza \
	--o-visualization taxonomy_green.qzv
	qiime tools view taxonomy_green.qzv
	mkdir -p taxonomy_class
	mv taxonomy_green.qzv taxonomy_class


filt_tax:
# 1) Remove non-bacterial features: keeps only ASVs assigned to a phylum (p__),
#    excludes Eukaryote-derived sequences (Chloroplast, Mitochondria):
	qiime taxa filter-table \
	--i-table feature-table-0.qza \
	--i-taxonomy taxonomy_green.qza \
	--p-mode contains \
	--p-include p__ \
	--p-exclude 'p__;,Chloroplast,Mitochondria' \
	--o-filtered-table filtered-table-1.qza

# 2) Remove samples with fewer than 10,000 sequences (poor amplification or sequencing):
	qiime feature-table filter-samples \
	--i-table filtered-table-1.qza \
	--p-min-frequency 10000 \
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

# 5) Generate taxonomy barplots for an initial view of sample composition:
	qiime taxa barplot \
	--i-table filtered-table-2.qza \
	--i-taxonomy taxonomy_green.qza \
	--m-metadata-file sample-metadata.tsv \
	--o-visualization taxa-bar-plots.qzv
	qiime tools view taxa-bar-plots.qzv
	mkdir -p taxonomy_class
	mv taxa-bar-plots.qzv taxonomy_class


phylo_tree:
# Build a rooted phylogenetic tree: aligns ASVs with MAFFT,
# masks hypervariable positions, and infers tree with FastTree:
	qiime phylogeny align-to-tree-mafft-fasttree \
	--i-sequences filtered-sequences-1.qza \
	--output-dir phylogeny-align-to-tree-mafft-fasttree

# Visualize tree with sample and taxonomy metadata:
	qiime empress community-plot \
	--i-tree phylogeny-align-to-tree-mafft-fasttree/rooted_tree.qza \
	--i-feature-table filtered-table-2.qza \
	--m-sample-metadata-file sample-metadata.tsv \
	--m-feature-metadata-file taxonomy_green.qza \
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
# Selected depth: 100,141 → retains 700,987 features (87.40%) across all samples.

# 1) Alpha rarefaction curves — evaluate richness stabilization across depths:
	qiime diversity alpha-rarefaction \
  --i-table filtered-table-2.qza \
  --p-metrics shannon \
  --m-metadata-file sample-metadata.tsv \
  --p-max-depth 129127 \
  --o-visualization shannon-rarefaction-plot.qzv
	qiime tools view shannon-rarefaction-plot.qzv
	mkdir -p diversity
	mv shannon-rarefaction-plot.qzv diversity
# Selected sampling depth for diversity analysis: 90,000.

# 2) Beta rarefaction — assess stability of between-sample distances across depths:
	qiime diversity beta-rarefaction \
	--i-table filtered-table-2.qza \
	--p-metric braycurtis \
	--p-clustering-method nj \
	--p-sampling-depth 90000 \
	--m-metadata-file sample-metadata.tsv \
	--o-visualization braycurtis-rarefaction-plot.qzv
	qiime tools view braycurtis-rarefaction-plot.qzv
	mv braycurtis-rarefaction-plot.qzv diversity


# Compute alpha and beta diversity metrics and generate PCoA plots (sampling depth: 90,000):
diversity_metrics:
	qiime diversity core-metrics-phylogenetic \
  --i-phylogeny phylogeny-align-to-tree-mafft-fasttree/rooted_tree.qza \
  --i-table filtered-table-2.qza \
  --p-sampling-depth 90000 \
  --m-metadata-file sample-metadata.tsv \
  --output-dir diversity-core-metrics-phylogenetic

# Additional alpha diversity metrics not included in core-metrics-phylogenetic:

# ACE (Abundance-based Coverage Estimator):
	qiime diversity alpha \
  --i-table filtered-table-2.qza \
  --p-metric ace \
  --o-alpha-diversity ace_vector.qza
	mv ace_vector.qza diversity-core-metrics-phylogenetic

# Chao1 (richness estimator):
	qiime diversity alpha \
  --i-table filtered-table-2.qza \
  --p-metric chao1 \
  --o-alpha-diversity chao1_vector.qza
	mv chao1_vector.qza diversity-core-metrics-phylogenetic

# Fisher's alpha (log-series diversity):
	qiime diversity alpha \
  --i-table filtered-table-2.qza \
  --p-metric fisher_alpha \
  --o-alpha-diversity fisher_vector.qza
	mv fisher_vector.qza diversity-core-metrics-phylogenetic

# Simpson index:
	qiime diversity alpha \
  --i-table filtered-table-2.qza \
  --p-metric simpson \
  --o-alpha-diversity simpson_vector.qza
	mv simpson_vector.qza diversity-core-metrics-phylogenetic


# Alpha diversity group significance tests:
alpha_div_visualizations:
	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/observed_features_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization observed-features-significance.qzv
	qiime tools view observed-features-significance.qzv
	mv observed-features-significance.qzv diversity

	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/shannon_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization shannon-significance.qzv
	qiime tools view shannon-significance.qzv
	mv shannon-significance.qzv diversity

	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/faith_pd_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization Faith-Phylogenetic-Div-significance.qzv
	qiime tools view Faith-Phylogenetic-Div-significance.qzv
	mv Faith-Phylogenetic-Div-significance.qzv diversity

	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/alpha-ace.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization alpha-ace-significance.qzv
	qiime tools view alpha-ace-significance.qzv
	mv alpha-ace-significance.qzv diversity

	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/evenness_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization evenness-significance.qzv
	qiime tools view evenness-significance.qzv
	mv evenness-significance.qzv diversity

	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/chao1_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization chao1-significance.qzv
	qiime tools view chao1-significance.qzv
	mv chao1-significance.qzv diversity

	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/fisher_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization fisher-significance.qzv
	qiime tools view fisher-significance.qzv
	mv fisher-significance.qzv diversity

	qiime diversity alpha-group-significance \
  --i-alpha-diversity diversity-core-metrics-phylogenetic/simpson_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization simpson-significance.qzv
	qiime tools view simpson-significance.qzv
	mv simpson-significance.qzv diversity


# Beta diversity group significance tests by GrapeStage:
beta_div_visualizations:
# Weighted UniFrac (accounts for phylogeny and abundance):
	qiime diversity beta-group-significance \
  --i-distance-matrix diversity-core-metrics-phylogenetic/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column GrapeStage \
  --o-visualization weighted-unifrac-significance.qzv \
  --p-pairwise
	qiime tools view weighted-unifrac-significance.qzv
	mv weighted-unifrac-significance.qzv diversity

# Unweighted UniFrac (phylogeny only, presence/absence):
	qiime diversity beta-group-significance \
	--i-distance-matrix diversity-core-metrics-phylogenetic/unweighted_unifrac_distance_matrix.qza \
    --m-metadata-file sample-metadata.tsv \
    --m-metadata-column GrapeStage \
	--o-visualization unweighted-unifrac-significance.qzv \
	--p-pairwise
	qiime tools view unweighted-unifrac-significance.qzv
	mv unweighted-unifrac-significance.qzv diversity

# PCoA ordination plots (generated by core-metrics-phylogenetic):
	qiime tools view diversity-core-metrics-phylogenetic/bray_curtis_emperor.qzv
	qiime tools view diversity-core-metrics-phylogenetic/weighted_unifrac_emperor.qzv


# UMAP ordination — non-linear alternative to PCoA for resolving fine-scale sample differences:
beta_diversity_umap:

# 1) Compute UMAP from beta diversity distance matrices:
	qiime diversity umap \
	--i-distance-matrix diversity-core-metrics-phylogenetic/weighted_unifrac_distance_matrix.qza \
	--o-umap wu-umap.qza

	qiime diversity umap \
	--i-distance-matrix diversity-core-metrics-phylogenetic/bray_curtis_distance_matrix.qza \
	--o-umap Bray-Curtis-umap.qza

# 2) Visualize UMAP ordinations:
	qiime emperor plot \
	--i-pcoa wu-umap.qza \
	--m-metadata-file sample-metadata.tsv \
	--o-visualization wu-umap.qzv
	qiime tools view wu-umap.qzv
	mkdir -p diversity
	mv wu-umap.qzv diversity

	qiime emperor plot \
	--i-pcoa Bray-Curtis-umap.qza \
	--m-metadata-file sample-metadata.tsv \
	--o-visualization Bray-Curtis-umap.qzv
	qiime tools view Bray-Curtis-umap.qzv
	mkdir -p diversity
	mv Bray-Curtis-umap.qzv diversity


expanded_taxonomy_barplot:
# 1) Merge diversity metrics into a single metadata table for export and visualization:
	qiime metadata tabulate \
	--m-input-file sample-metadata.tsv \
	  Bray-Curtis-umap.qza \
	  diversity-core-metrics-phylogenetic/faith_pd_vector.qza \
	  diversity-core-metrics-phylogenetic/evenness_vector.qza \
	  diversity-core-metrics-phylogenetic/shannon_vector.qza \
	  diversity-core-metrics-phylogenetic/alpha-ace.qza \
	--o-visualization expanded-metadata-summ.qzv
	qiime tools view expanded-metadata-summ.qzv

# 2) Taxonomy barplot annotated with expanded metadata (UMAP axes, Faith PD, evenness, Shannon):
	qiime taxa barplot \
	--i-table filtered-table-2.qza \
	--i-taxonomy taxonomy_green.qza \
	--m-metadata-file sample-metadata.tsv \
	  Bray-Curtis-umap.qza \
	  diversity-core-metrics-phylogenetic/faith_pd_vector.qza \
	  diversity-core-metrics-phylogenetic/evenness_vector.qza \
	  diversity-core-metrics-phylogenetic/shannon_vector.qza \
	--o-visualization taxa-bar-plots-expanded.qzv
	qiime tools view taxa-bar-plots-expanded.qzv
	mv expanded-metadata-summ.qzv info_data
	mv taxa-bar-plots-expanded.qzv taxonomy_class


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
	--input-path taxonomy_green.qza \
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

