"""Wandb experiment tracking. Respects WANDB_MODE env var for disabling."""

import wandb


def init_wandb(config, project="allegro", **kwargs):
    """Initialize a wandb run. Pass config dict to log hyperparameters."""
    return wandb.init(project=project, config=config, **kwargs)
