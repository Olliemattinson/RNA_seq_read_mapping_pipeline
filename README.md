# RNA_seq_read_mapping_pipeline

Snakemake pipeline for mapping RNA-seq reads to a genome.

#### To run pipeline:
- Place genome file ```<genome>.fa``` in ```data/genomes/```
- Place paired read files ```<reads>_1.fastq``` and ```<reads>_2.fastq``` in ```data/reads/```
- Activate a conda environment with snakemake installed
- Run the following command:
```
snakemake -s RNA_seq_read_mapping_snakefile.smk --cores 10 --use-conda
```
#### Output:
- Read quality reports in: ```fastqc/<reads>/```
- Mapped and sorted reads: ```data/mapped_reads/<reads>_mapped_to_<genome>/<reads>_mapped_to_<genome>.bam```
- Mapped and sorted reads index file: ```data/mapped_reads/<reads>_mapped_to_<genome>/<reads>_mapped_to_<genome>.bam.bai```


#### Pipeline:

![plot](pipeline.svg)
