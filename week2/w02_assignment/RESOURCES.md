
### per sample efficiency (stages 1-5):

| Cores | Wall time (seconds)| CPU time (seconds) | CPU / wall time | MaxRSS |
|---|---|---|---|---|
| 4 | 9:25 (565) | 20:06 (1206s) | 2.1 | 6.3GB | 
| 8 | 8:10 (490) | 20:55 (1255) | 2.5 | 7.6GB | 
| 16 | 6:52 (412) | 22:03 (1323) | 3.2 | 13.6GB |

I will use 8 cores for this pipeline run. The wall clock is better than 4 cores but halves the waste from 16 cores.

For 8 cores, the greatest amount of RAM used was 7.6GB. Testing with 16 cores revealed a sample with 14.8GB max memory usage.  Sizing the --mem to 8 would be cutting it too close and miss outliers. Explorer. I will use 16GB of memory to cover the observed outlier with some margin.

The longest single sample run was 8:10 at 8 cores, running alone. With 8 tasks contenting for shared storage, the runs could be slower. --time is enforced so setting it too low could kill the jobs. I will set it to 20:00 to allow for a buffer.

4 cores seff file:
Job ID: 10628231
Array Job ID: 10628231_1
Cluster: explorer
User/Group: davis.jer/users
State: COMPLETED (exit code 0)
Nodes: 1
Cores per node: 4
CPU Utilized: 00:20:06
CPU Efficiency: 53.36% of 00:37:40 core-walltime
Job Wall-clock time: 00:09:25
Memory Utilized: 5.97 GB
Memory Efficiency: 18.67% of 32.00 GB
Job ID: 10628391

8 cores seff file:
Array Job ID: 10628391_1
Cluster: explorer
User/Group: davis.jer/users
State: COMPLETED (exit code 0)
Nodes: 1
Cores per node: 8
CPU Utilized: 00:20:55
CPU Efficiency: 32.02% of 01:05:20 core-walltime
Job Wall-clock time: 00:08:10
Memory Utilized: 7.24 GB
Memory Efficiency: 22.63% of 32.00 GB
Job ID: 10628531

16 cores seff file:
Array Job ID: 10628531_1
Cluster: explorer
User/Group: davis.jer/users
State: COMPLETED (exit code 0)
Nodes: 1
Cores per node: 16
CPU Utilized: 00:22:03
CPU Efficiency: 20.07% of 01:49:52 core-walltime
Job Wall-clock time: 00:06:52
Memory Utilized: 13.00 GB
Memory Efficiency: 40.62% of 32.00 GB

Cohort (stages 6-9) resource choices:

### Cohort job (stages 6–9)

| Run | Cores | Mem | Time limit | Elapsed | CPU busy | Peak mem | Outcome |
|---|---|---|---|---|---|---|---|
| 10642528 | 8 | 32G | 1:00:00 | 28:21 | 0.36 | 1.69 GB | COMPLETED |
| 10647115 | 2 | 4G | 1:00:00 | 60:04 | — | — | TIMEOUT |
| final | 4 | 16G | 2:00:00 | | | | |

cores busy: 10:18 / 28:21 = 618 / 1701 = 0.36 cores. I asked for 8 cores and used about 1/3 of 1 core. Everything in stages 6-9 is single threaded and most of the wall clock is I/O waiting for GenomicsDBImport, not computational time.

memory: 1.69GB of 32GB allotted. Very over-asked, but resulted in a TIMEOUT if I set it low to 4G. 16G is a reasonable middle ground.

At 0.36 busy cores, comparing across 4/8/16 cores tells me nothing. Extra cores cannot help a single-threaded workload. At 2 cores I got a TIMEOUT. I will use 4 cores to have a buffer.

The 28 minute run is mostly I/O time and not CPU working time. Allotting an hour (02:00:00) of maximum run time provides a buffer for larger samples while not letting a stalled program run and eat resources for too long.
 
Becuase only 1 core is s used at any time with low memory requirements, I will use 4 cores and 16GB of memory for the cohort steps. This keeps me aboive the 1.69GB maximum memory utilization with some buffer.

8 nodes seff file (10642528):
Job ID: 10642528
Cluster: explorer
User/Group: davis.jer/users
State: COMPLETED (exit code 0)
Nodes: 1
Cores per node: 8
CPU Utilized: 00:10:18
CPU Efficiency: 4.54% of 03:46:48 core-walltime
Job Wall-clock time: 00:28:21
Memory Utilized: 1.69 GB
Memory Efficiency: 5.27% of 32.00 GB

2 nodes seff file (10647115) - resulted in timeout
Job ID: 10647115
Cluster: explorer
User/Group: davis.jer/users
State: TIMEOUT (exit code 0)
Nodes: 1
Cores per node: 2
CPU Utilized: 00:03:51
CPU Efficiency: 3.20% of 02:00:08 core-walltime
Job Wall-clock time: 01:00:04
Memory Utilized: 1.02 GB
Memory Efficiency: 25.53% of 4.00 GB
