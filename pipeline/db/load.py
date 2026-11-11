import sys, csv, sqlite3, os, json

db_path = sys.argv[1] # runs.db
meta_path = sys.argv[2] # cohort.tsv
folders = sys.argv[3:] # run folders

con = sqlite3.connect(db_path)
con.execute("PRAGMA foreign_keys = ON")

# metadata file: skip # note lines and read it in as a tsv
with open(meta_path) as meta:
    lines = [line for line in meta if not line.startswith('#')]

with con:
    for row in csv.DictReader(lines, delimiter="\t"):
        con.execute("INSERT OR IGNORE INTO samples (sample_id, phenotype, sex, population, family, " \
        "father, mother, run, read_length, bases_gb, study, native_layout, is_synthetic_phenotype) " \
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
        (row["sample_id"], row["phenotype"], row["sex"], row["population"], row["family"], row["father"],
        row["mother"], row["run"], row["read_length"], row["bases_gb"], row["study"], row["native_layout"], row["is_synthetic_phenotype"]))



for folder in folders:
    with open(os.path.join(folder, "manifest.json")) as fh:
        m = json.load(fh)
    
    p = m["pipeline"]
    run_id = m["pipeline"]["run_id"]

    if con.execute("SELECT 1 FROM runs WHERE run_id = ?", (run_id,)).fetchone():
        print(f"{folder}: run {run_id} already loaded, skipped")
        continue

    with con:
        found = con.execute(
            "SELECT pipeline_id FROM pipelines WHERE name = ? and version = ? and implementation = ?",
            (p["name"], p["version"], p["implementation"]),
        ).fetchone()
        if found:
            pipeline_id = found[0]
        else:
            pipeline_id = con.execute(
                "INSERT INTO pipelines (name, version, implementation) VALUES (?, ?, ?)",
                (p["name"], p["version"], p["implementation"]),
            ).lastrowid


        con.execute("INSERT INTO runs (run_id, pipeline_id, started_at, finished_at, exit_status, " \
        "platform, executor, samplesheet, reference, region, folder)"
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", (run_id, pipeline_id, p["started_at"], p["finished_at"], p["exit_status"], 
                                                     m["platform"]["kind"], m["platform"]["executor"], m["params"]["samplesheet"], 
                                                     m["params"]["ref"], m["params"]["region"], os.path.abspath(folder)))


        for item in m["samples"]:
            con.execute("INSERT OR IGNORE INTO samples (sample_id) VALUES (?)", (item["sample_id"],)),
            con.execute("INSERT INTO run_samples (run_id, sample_id, library_type, condition)" " VALUES (?, ?, ?, ?)",
                        (run_id, item["sample_id"], item["library_type"], item["condition"]))

        with open(os.path.join(folder, "variants.tsv")) as vf:
                for row in csv.DictReader(vf, delimiter="\t"):
                    qual = row["qual"]
                    if qual == ".":
                        qual = None
                    con.execute("INSERT INTO variants (run_id, chrom, pos, ref, alt, qual, filter)"
                                " VALUES (?, ?, ?, ?, ?, ?, ?)", (run_id, row["chrom"], row["pos"], row["ref"], row["alt"], 
                                                              qual, row["filter"]))
        for output in m["outputs"]:
            con.execute("INSERT INTO outputs (run_id, path, sha256)" " VALUES (?, ?, ?)", 
                        (run_id, output["path"], output["checksum"].removeprefix("sha256:")))

    print(f"{folder}: run {run_id} loaded")