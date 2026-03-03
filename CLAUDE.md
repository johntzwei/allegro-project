# Allegro Project — Claude Instructions

## Environment

- USC CARC SLURM cluster
- Package manager: uv (NOT conda, NOT pip directly)
- Python: managed by uv, pinned in pyproject.toml (>=3.11)
- Virtual env: `.venv/` at project root (managed by uv)

## Cluster Info

- **Partitions:** `nlp_hiprio` (high priority, no preemption) and `nlp` (preemptable)
- **Account:** `robinjia_875`
- **GPUs:** ~60 A6000s, 4 A100s
- **Default resources per job:** 8 CPUs, 1 GPU, 40G RAM
- **Max walltime:** typically 2 days default in templates

## How to Run Things

```bash
uv sync                                                          # install dependencies
uv run python experiments/<experiment>/run.py                    # run locally
uv run pytest                                                    # run tests
sbatch slurm/run_gpu.sbatch experiments/00_example/run.py        # submit job (high priority)
sbatch slurm/run_preempt.sbatch experiments/00_example/run.py    # submit job (preemptable)
sbatch --array=0-2 slurm/run_array.sbatch                       # array job
```

Array jobs set `SLURM_ARRAY_TASK_ID` env var; experiments can read it via `os.environ.get("SLURM_ARRAY_TASK_ID")`.

## Project Layout

- `src/allegro/` — shared library code (reusable modules with argparse)
- `experiments/` — numbered experiment folders (00_xxx/, 01_xxx/, ...) each with `run.py`, `results/`, `logs/`, `figures/`
- `data/` — datasets (gitignored)
- `notes/` — writeups, paper summaries, meeting notes (see `notes/README.md`)
- `slurm/` — SLURM job templates
- `tests/` — pytest tests

## Conventions

- Experiments: numbered folders in `experiments/` (00_xxx/, 01_xxx/, ...) each with a `run.py`. Create new folders, don't edit old ones.
- Each experiment folder should have a `README.md` with detailed setup, results, and observations. The top-level `experiments/README.md` should only contain brief descriptions of each experiment.
- Reusable code goes in `src/allegro/` with argparse for flexibility
- Tracking: wandb (disable with `WANDB_MODE=disabled`)
- Do NOT read files in `notes/discussions/` (meeting notes) unless explicitly requested by the user
