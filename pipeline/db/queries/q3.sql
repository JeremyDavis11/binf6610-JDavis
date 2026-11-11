-- q3 - How many variants, and how many PASS, in each run? columns: run_id, n_variants, n_pass
SELECT run_id,
    COUNT(*) AS n_variants,
    SUM(filter = 'PASS') as n_pass
FROM variants
GROUP BY run_id;