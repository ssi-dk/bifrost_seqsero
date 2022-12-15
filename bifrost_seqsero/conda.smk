rule run_seqsero:
    message:
        f"Empty rule to create conda environment"
    conda:
        "../envs/SeqSero.yaml"
    shell:
        "echo Done"
