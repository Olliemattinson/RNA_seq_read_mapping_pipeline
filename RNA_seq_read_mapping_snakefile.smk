configfile: 'RNA_seq_read_mapping_config.yaml'

rule all:
    input:
        expand('data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}.bam.bai',experiment=config['experiment'],reads=config['reads'],genome=config['genome']),
        expand('fastqc/{experiment}_{reads}/{experiment}_{reads}_2_fastqc.html',experiment=config['experiment'],reads=config['reads'])
    wildcard_constraints:
        experiment='[^_]+_[^_]+',
        reads='[^_]+_[^_]+'

rule read_quality_report:
    input:
        #reads1='data/reads/{experiment}_{reads}_1.fastq',
        #reads2='data/reads/{experiment}_{reads}_2.fastq'
        reads1='data/reads/{experiment}_{reads}_1.fq.gz',
        reads2='data/reads/{experiment}_{reads}_2.fq.gz'
    threads: 2
    conda:
        'envs/RNA_seq_read_mapping_env.yaml'
    params:
        output_stem='fastqc/{experiment}_{reads}'
    output:
        'fastqc/{experiment}_{reads}/{experiment}_{reads}_2_fastqc.html'
    shell:
        'mkdir -p {params.output_stem};'
        'fastqc {input.reads1} {input.reads2} --threads {threads} -o {params.output_stem}'

rule trim_reads:
    input:
        adaptors='all_adaptors.fasta',
        #reads1='data/reads/{experiment}_{reads}_1.fastq',
        #reads2='data/reads/{experiment}_{reads}_2.fastq'
        reads1='data/reads/{experiment}_{reads}_1.fq.gz',
        reads2='data/reads/{experiment}_{reads}_2.fq.gz'
    threads:10
    conda:
        'envs/RNA_seq_read_mapping_env.yaml'
    params:
        leading=20,
        trailing=20,
        sliding_window_x=20,
        sliding_window_y=5,
        headcrop=0,
        minlen=35
    output:
        tp1=temp('data/trimmed_reads/{experiment}_{reads}_trimmed_paired_1.fq'),
        tu1=temp('data/trimmed_reads/{experiment}_{reads}_trimmed_unpaired_1.fq'),
        tp2=temp('data/trimmed_reads/{experiment}_{reads}_trimmed_paired_2.fq'),
        tu2=temp('data/trimmed_reads/{experiment}_{reads}_trimmed_unpaired_2.fq')
    shell:
        'trimmomatic PE -threads {threads} {input.reads1} {input.reads2} '
        '{output.tp1} {output.tu1} {output.tp2} {output.tu2} '
        'ILLUMINACLIP:{input.adaptors}:2:30:10 LEADING:{params.leading} '
        'TRAILING:{params.trailing} '
        'SLIDINGWINDOW:{params.sliding_window_x}:{params.sliding_window_y} '
        'HEADCROP:{params.headcrop} MINLEN:{params.minlen}'

rule index_genome:
    input:
        'data/genomes/{genome}.fa'
    threads: 10
    conda:
        'envs/RNA_seq_read_mapping_env.yaml'
    params:
        genome_index_dir='data/genomes/{genome}_genome_index',
        genome_index_stem='data/genomes/{genome}_genome_index/{genome}_genome_index'
    output:
        'data/genomes/{genome}_genome_index/{genome}_genome_index.1.ht2'
    shell:
        'mkdir -p {params.genome_index_dir};'
        'hisat2-build {input} {params.genome_index_stem} -p {threads}'

rule map_reads:
    input:
        tp1='data/trimmed_reads/{experiment}_{reads}_trimmed_paired_1.fq',
        tu1='data/trimmed_reads/{experiment}_{reads}_trimmed_unpaired_1.fq',
        tp2='data/trimmed_reads/{experiment}_{reads}_trimmed_paired_2.fq',
        tu2='data/trimmed_reads/{experiment}_{reads}_trimmed_unpaired_2.fq',
        genome_index_file='data/genomes/{genome}_genome_index/{genome}_genome_index.1.ht2'
    threads: 10
    conda:
        'envs/RNA_seq_read_mapping_env.yaml'
    params:
        genome_index_stem='data/genomes/{genome}_genome_index/{genome}_genome_index'
    output:
        temp('data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}_unsorted.sam')
    shell:
        'hisat2 -q -x {params.genome_index_stem} -1 {input.tp1} -2 {input.tp2} '
        '-U {input.tu1} -U {input.tu2} -S {output} -p {threads}'

rule SAM_to_BAM:
    input:
        'data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}_unsorted.sam'
    threads: 10
    conda:
        'envs/RNA_seq_read_mapping_env.yaml'
    output:
        temp('data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}_unsorted.bam')
    shell:
        'samtools view -S -b {input} > {output} -@ {threads}'

rule sort_mapped_reads:
    input:
        'data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}_unsorted.bam'
    threads: 10
    conda:
        'envs/RNA_seq_read_mapping_env.yaml'
    output:
        'data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}.bam'
    shell:
        'samtools sort {input} -o {output} -@ {threads}'

rule index_reads:
    input:
        'data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}.bam'
    conda:
        'envs/RNA_seq_read_mapping_env.yaml'
    output:
        'data/mapped_reads/{experiment}_{reads}_mapped_to_{genome}/{experiment}_{reads}_mapped_to_{genome}.bam.bai'
    shell:
        'samtools index {input}'
