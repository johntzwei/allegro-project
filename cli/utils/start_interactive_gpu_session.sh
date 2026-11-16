#!/bin/bash
#
# Start an interactive GPU session on a YCRC cluster.
#
# Defaults to the `gpu_devel` partition (6 hour max, 1 A40 GPU, 4 CPUs and 32G
# per user), which is meant for debugging. Use PARTITION=gpu for larger or
# longer jobs (48 hour max; H100, H200, A100, A40, L40S; 4 GPUs per node).
# Every default can be overridden with an environment variable.
#
# Usage from the project's root directory:
#   ./cli/utils/start_interactive_gpu_session.sh
#   PARTITION=gpu GPU_TYPE=h100 CPUS=8 MEM=64G TIME=01:00:00 ./cli/utils/start_interactive_gpu_session.sh
#
# Environment variables:
#   PARTITION  Slurm partition (default: gpu_devel)
#   GPUS       Number of GPUs (default: 1)
#   GPU_TYPE   GPU type, e.g. h100, a100 (default: unset, any GPU in partition)
#   CPUS       CPUs per task (default: 4)
#   MEM        Total memory (default: 32G)
#   TIME       Walltime as HH:MM:SS (default: 01:00:00)
#   ACCOUNT    Slurm account (default: unset, uses your default account)

set -e

PARTITION="${PARTITION:-gpu_devel}"
GPUS="${GPUS:-1}"
CPUS="${CPUS:-4}"
MEM="${MEM:-16G}"
TIME="${TIME:-01:00:00}"

gres="gpu:${GPUS}"
[[ -n "${GPU_TYPE:-}" ]] && gres="gpu:${GPU_TYPE}:${GPUS}"

args=(
    --job-name=interactive-gpu
    --partition="$PARTITION"
    --nodes=1
    --ntasks=1
    --cpus-per-task="$CPUS"
    --mem="$MEM"
    --gres="$gres"
    --time="$TIME"
)
[[ -n "${ACCOUNT:-}" ]] && args+=(--account="$ACCOUNT")

echo "Requesting interactive job: partition=${PARTITION}, gres=${gres}, cpus=${CPUS}, mem=${MEM}, time=${TIME}" >&2
exec srun "${args[@]}" --pty bash -l
