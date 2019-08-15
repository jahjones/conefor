#!/bin/bash --login
###
#project code
#SBATCH --account=scw1466
#job name
#SBATCH --job-name=cone4
#job stdout file
#SBATCH --output=cone4.out.%J
#job stderr file
#SBATCH --error=cone4.err.%J
#maximum job time in D-HH:MM
#SBATCH --time=00-10:00
#number of parallel processes (tasks) you are requesting - maps to MPI processes
#SBATCH --ntasks=40
#memory per process in MB
#SBATCH --mem-per-cpu=800
#tasks to run per node (change for hybrid OpenMP/MPI)
###

#now run normal batch commands
module load R/3.5.1
module load parallel

chmod 777 ./conefor2.7.3Linux

# Only use one thread per copy of conefor (in case there is internal parallelism)
export OMP_NUM_THREADS=1

# Define srun arguments:
srun="srun --nodes 1 --ntasks 1"

# Define parallel arguments:
logfile="joblog-$(date +"%Y-%m-%d--%H:%M:%S")--$SLURM_JOB_ID"
parallel="parallel --header 1 --colsep=, --max-procs $SLURM_NTASKS --joblog ${logfile}"

script='./conefor2.7.3Linux -nodeFile {1} -conFile {2} -confAdj {3} -IIC -prefix {4}'

$parallel "$srun $script" :::: dIICoutlets.csv
