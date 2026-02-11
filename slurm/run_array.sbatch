#!/bin/bash
#SBATCH --partition=nlp_hiprio
#SBATCH --account=robinjia_875
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --gres=gpu:1
#SBATCH --time=2-00:00:00
#SBATCH --output=slurm_logs/%A_%a.out
#SBATCH --error=slurm_logs/%A_%a.err

# Usage: sbatch --array=0-2 slurm/run_array.sbatch
# Runs experiments/00_*/run.py, experiments/01_*/run.py, experiments/02_*/run.py

mkdir -p slurm_logs

module purge
module load gcc/13.3.0
module load cuda/12.4.0

cd $SLURM_SUBMIT_DIR

EXPERIMENT=$(ls -d experiments/$(printf "%02d" $SLURM_ARRAY_TASK_ID)_*/run.py 2>/dev/null | head -1)

if [ -z "$EXPERIMENT" ]; then
    echo "No experiment found for task ID $SLURM_ARRAY_TASK_ID"
    exit 1
fi

echo "Running $EXPERIMENT"
uv run python "$EXPERIMENT"
