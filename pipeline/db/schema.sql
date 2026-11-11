CREATE TABLE pipelines (
    pipeline_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    version TEXT NOT NULL,
    implementation TEXT NOT NULL CHECK (implementation IN ('nextflow', 'snakemake'))
) STRICT;

CREATE TABLE runs (
    run_id TEXT NOT NULL PRIMARY KEY,
    pipeline_id INTEGER NOT NULL REFERENCES pipelines(pipeline_id),
    started_at TEXT NOT NULL,
    finished_at TEXT NOT NULL,
    exit_status TEXT NOT NULL CHECK (exit_status IN ('success', 'failure', 'partial')),
    platform TEXT NOT NULL,
    executor TEXT NOT NULL, 
    samplesheet TEXT NOT NULL,
    reference TEXT NOT NULL,
    region TEXT NOT NULL,
    folder TEXT NOT NULL
) STRICT;

CREATE TABLE samples (
    sample_id TEXT NOT NULL PRIMARY KEY,
    phenotype TEXT,
    sex TEXT,
    population TEXT,
    family TEXT,
    father TEXT,
    mother TEXT,
    run TEXT,
    read_length INTEGER,
    bases_gb REAL,
    study TEXT,
    native_layout TEXT,
    is_synthetic_phenotype TEXT
) STRICT;

CREATE TABLE run_samples (
    run_id TEXT NOT NULL REFERENCES runs(run_id),
    sample_id TEXT NOT NULL REFERENCES samples(sample_id),
    library_type TEXT NOT NULL CHECK (library_type in('single', 'paired')),
    condition TEXT NOT NULL,
    PRIMARY KEY (run_id, sample_id)
) STRICT;

CREATE TABLE variants (
    chrom TEXT NOT NULL,
    pos INTEGER NOT NULL,
    ref TEXT NOT NULL,
    alt TEXT NOT NULL,
    qual REAL,
    filter TEXT,
    run_id TEXT NOT NULL REFERENCES runs(run_id),
    PRIMARY KEY (run_id, chrom, pos, ref, alt)
) STRICT;

CREATE TABLE outputs (
    run_id TEXT NOT NULL REFERENCES runs(run_id),
    path TEXT NOT NULL,
    sha256 TEXT NOT NULL,
    PRIMARY KEY (run_id, path)
) STRICT;