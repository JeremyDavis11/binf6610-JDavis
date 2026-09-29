# Base Image
mambaorg/micomamba:2.0.5-ubuntu24.04
mambaorg/micromamba@sha256:1c62a28916ad7a4533555a542a5410e55ea2ed2c1e29f00c8fc3f1c8add111d5

# Versions pinned
bwa=0.7.19 fastp=1.3.7 fastqc=0.12.1 gatk4=4.6.2.0 multiqc=1.35 samtools=1.24 git=2.47.1 bcftools=1.24 \

# The pushed image
docker.io/jeremydavis11/variant-call@sha256:3130d0c70496314058779f89996a6cc7fc51860d98e6a1b4e72d1d75eaacf8a0

To re-run this in a year, I would need the pushed image heading with the digest from this specific version of my container. Pull the image by the digest, and I will get the exact versions, regardless of whether the pinned versions are still resolved by conda-forge or if the base tag points elsewhere. I would also need the details for this pipeline and run. The pipeline code and the same reference genome version, samplesheet, and input FASTQs would be necessary to replicate the results. Every program I used is in the container, so I will not have to worry about newer versions of dependencies being potentially incompatible. 
