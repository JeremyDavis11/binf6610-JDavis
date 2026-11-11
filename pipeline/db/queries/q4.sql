-- q4 - Every sample, its sex, and how many runs use it. Columns: sample_id, sex, n_runs
SELECT samples.sample_id,
    sex,
    COUNT(run_samples.sample_id) as n_runs
FROM samples
LEFT JOIN run_samples ON run_samples.sample_id = samples.sample_id
GROUP BY samples.sample_id
ORDER BY samples.sample_id;

