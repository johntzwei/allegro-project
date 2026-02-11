#!/bin/bash
#SBATCH --partition=nlp
#SBATCH --account=robinjia_875
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --gres=gpu:1
#SBATCH --time=2-00:00:00
#SBATCH --signal=B:USR1@120
#SBATCH --requeue
#SBATCH --output=slurm_logs/%j.out
#SBATCH --error=slurm_logs/%j.err

# NOTE: Jobs on 'nlp' partition can be preempted.
# --signal=B:USR1@120 sends USR1 120s before preemption.
# --requeue automatically resubmits after preemption.

mkdir -p slurm_logs

module purge
module load gcc/13.3.0
module load cuda/12.4.0

cd $SLURM_SUBMIT_DIR

# Usage: sbatch slurm/run_preempt.sbatch experiments/00_example/run.py
uv run python "$@"
