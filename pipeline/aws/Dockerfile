# pipeline - pinned versions from class conda environment

FROM mambaorg/micromamba:2.0.5-ubuntu24.04

RUN micromamba install -y -n base \
	-c conda-forge -c bioconda --override-channels \
	bwa=0.7.19 \
	fastp=1.3.7 \
	fastqc=0.12.1 \
	gatk4=4.6.2.0 \
	multiqc=1.35 \
	samtools=1.24 \
	git=2.47.1 \
	bcftools=1.24 \
&& micromamba clean --all --yes

# container path
ENV PATH=/opt/conda/bin:$PATH

# runs as whichever user invokes it using `apptainer exec`
USER mambauser

# new: the AWS CLI, copied from AWS's own image
COPY --from=public.ecr.aws/aws-cli/aws-cli:2.37.12 /usr/local/aws-cli /usr/local/aws-cli
USER root
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
USER $MAMBA_USER

# new: the pipeline, and the script the job runs
COPY --chown=$MAMBA_USER:$MAMBA_USER . /pipeline/
COPY --chown=$MAMBA_USER:$MAMBA_USER aws/batch_run.sh /usr/local/bin/batch_run.sh
