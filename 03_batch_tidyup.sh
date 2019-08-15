#!/bin/bash --login
###
#project code
#SBATCH --account=scw1466
#job name
#SBATCH --job-name=tidy
#job stdout file
#SBATCH --output=tidy.out.%J
#job stderr file
#SBATCH --error=tidy.err.%J
#maximum job time in D-HH:MM
#SBATCH --time=00-20:00
#number of parallel processes (tasks) you are requesting - maps to MPI processes
#SBATCH --ntasks=1
#memory per process in MB 
#SBATCH --mem-per-cpu=800 
#tasks to run per node (change for hybrid OpenMP/MPI) 
#SBATCH --cpus-per-task=1
###

#now run normal batch commands 
module load R/3.5.1

rm *events.txt

Rscript tidyup.R 5 10 DdamL DdamLS

cp *importances.txt coneforOut