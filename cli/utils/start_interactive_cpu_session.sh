#!/bin/bash
#
# Start an interactive CPU session on a YCRC cluster.
#
# Defaults to the `devel` partition (6 hour max, 10 CPUs and 70G per user).
# Every default can be overridden with an environment variable.
#
# Usage from the project's root directory:
#   ./cli/utils/start_interactive_cpu_session.sh
#   CPUS=4 MEM=16G TIME=01:00:00 ./cli/utils/start_interactive_cpu_session.sh
#
# Environment variables:
#   PARTITION  Slurm partition (default: devel)
#   CPUS       CPUs per task (default: 4)
#   MEM        Total memory (default: 16G)
#   TIME       Walltime as HH:MM:SS (default: 01:00:00)
#   ACCOUNT    Slurm account (default: unset, uses your default account)

set -e

PARTITION="${PARTITION:-devel}"
CPUS="${CPUS:-8}"
MEM="${MEM:-16G}"
TIME="${TIME:-01:00:00}"

args=(
    --job-name=interactive-cpu
    --partition="$PARTITION"
    --nodes=1
    --ntasks=1
    --cpus-per-task="$CPUS"
    --mem="$MEM"
    --time="$TIME"
)
[[ -n "${ACCOUNT:-}" ]] && args+=(--account="$ACCOUNT")

echo "Requesting interactive job: partition=${PARTITION}, cpus=${CPUS}, mem=${MEM}, time=${TIME}" >&2
exec srun "${args[@]}" --pty bash -l
