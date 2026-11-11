-- q2 - Which runs included NA12878 and as what? columns: run_id, condition
SELECT runs.run_id, run_samples.condition 
FROM run_samples
JOIN runs ON runs.run_id = run_samples.run_id
WHERE run_samples.sample_id = 'NA12878';