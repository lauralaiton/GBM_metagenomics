

#### Kraken 2       
# Activate environment:
conda activate kraken2
# Install kraken2:
conda install -c bioconda kraken2 

# Create a taxonomy database:
kraken2-build --download-taxonomy fungi --db fungi_database

# Install the library "fungi" in the database:
kraken2-build --download-library fungi --db fungi_database  
    # If the issue related to "https" appears, the solution is:
    # Go to this location "miniconda3/envs/kraken2/libexec" and modify the "rsync_from_ncbi.pl" file as follows:
    cd miniconda3/envs/kraken2/libexec
    vim rsync_from_ncbi.pl
    # look the line "if (! ($full_path =~ s#^ftp://${qm_server}${qm_server_path}/##)) {   "   and modify it as "https"

#  Build the database: #install blast first "conda install ncbi-blast+"
kraken2-build --build --db fungi_database 

# Classify the set of sequences:
    # Immature samples:
kraken2 --db fungi_database  \
--paired --classified-out Immature1_claseqs_#.fq seq/Immature1_1.fq seq/Immature1_2.fq \
--output output/Immature1.kraken \
--report output/Immature1.report

kraken2 --db fungi_database \
--paired --classified-out Immature2_claseqs_#.fq seq/Immature2_1.fq seq/Immature2_2.fq \
--output output/Immature2.kraken \
--report output/Immature2.report

kraken2 --db fungi_database \
--paired --classified-out Immature3_claseqs_#.fq seq/Immature3_1.fq seq/Immature3_2.fq \
--output output/Immature3.kraken \
--report output/Immature3.report

    #  Mature samples:
kraken2 --db fungi_database \
--paired --classified-out Mature1_claseqs_#.fq seq/Mature1_1.fq seq/Mature1_2.fq \
--output output/Mature1.kraken \
--report output/Mature1.report

kraken2 --db fungi_database \
--paired --classified-out Mature2_claseqs_#.fq seq/Mature2_1.fq seq/Mature2_2.fq \
--output output/Mature2.kraken \
--report output/Mature2.report

kraken2 --db fungi_database \
--paired --classified-out Mature3_claseqs_#.fq seq/Mature3_1.fq seq/Mature3_2.fq \
--output output/Mature3.kraken \
--report output/Mature3.report

kraken2 --db fungi_database \
--paired --classified-out Mature4_claseqs_#.fq seq/Mature4_1.fq seq/Mature4_2.fq \
--output output/Mature4.kraken \
--report output/Mature4.report

# Visualize classification results:
    # conda install -c bioconda krona
    # Go to the directory where .kraken files are located (in my case "cd /storage/work/l/lal5792/miniconda3/envs/kraken2/opt/krona/taxonomy") ... 
    # and run:
        # ./updateTaxonomy.sh
ktImportTaxonomy -q 2 -t 3 \
output/Immature1.kraken output/Immature2.kraken output/Immature3.kraken \
output/Mature1.kraken output/Mature2.kraken output/Mature3.kraken output/Mature4.kraken \
-o output/all_samples.kraken.html




