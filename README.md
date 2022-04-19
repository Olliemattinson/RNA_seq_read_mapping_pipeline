# RNA_seq_read_mapping_pipeline

Snakemake pipeline for mapping RNA-seq reads to a genome.

To run:
- place genome .fa file in data/genomes/
- place paired read .fastq files in data/reads/
- Enter a conda environment with snakemake installed
- Run the following:
```
snakemake -s RNA_seq_read_mapping_snakefile.smk --cores 10
```

![plot](pipeline.svg)
