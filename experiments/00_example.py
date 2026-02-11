"""Example experiment. Create new numbered files (01_xxx.py, 02_xxx.py, ...) for new experiments."""

import os
from dataclasses import asdict
from allegro.example import Config, run
from allegro.tracking import init_wandb

array_id = os.environ.get("SLURM_ARRAY_TASK_ID")  # None if not an array job

config = Config(model_name="gpt2", learning_rate=1e-4, batch_size=16)
init_wandb(asdict(config), project="allegro")
run(config)
