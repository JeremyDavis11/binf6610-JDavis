-- q6 - For each run, how many samples of each sex? Columns: run_id, sex, n_samples
SELECT run_id,
    sex,
    COUNT(*) as n_samples
FROM samples
JOIN run_samples ON run_samples.sample_id = samples.sample_id
GROUP BY run_samples.run_id, samples.sex;