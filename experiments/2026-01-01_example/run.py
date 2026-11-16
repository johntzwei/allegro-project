"""Example experiment: fit a one-layer linear network to a dummy dataset with
PyTorch Lightning.

Usage:
    uv run python experiments/2026-01-01_example/run.py --seed 0 \
        --wandb-mode offline
"""

import argparse
import json
import logging
import tempfile
from pathlib import Path

import lightning as L
import pandas as pd
import torch
import wandb
from torch import nn
from torch.utils.data import DataLoader, TensorDataset

from ggl.utils.path import resolve_results_dir
from ggl.utils.wandb import create_slurm_config, init_run


def build_dummy_dataset(
    num_samples: int,
    weight: float = 3.0,
    bias: float = 0.5,
) -> TensorDataset:
    """Build a dummy regression dataset from a noisy linear model,
    y = weight * x + bias + noise. Inputs are drawn uniformly from [-1, 1]
    and the noise is Gaussian with a standard deviation of 0.1.

    Args:
        num_samples (int): The number of samples to generate.
        weight (float): The true slope of the linear model. Defaults to 3.0.
        bias (float): The true intercept of the linear model. Defaults to
            0.5.

    Returns:
        TensorDataset: A dataset of (x, y) pairs, where both tensors have
            shape (num_samples, 1).
    """
    x = torch.rand(num_samples, 1) * 2 - 1
    y = weight * x + bias + 0.1 * torch.randn(num_samples, 1)
    return TensorDataset(x, y)


class LinearRegressor(L.LightningModule):
    """A one-layer linear network trained with MSE loss and SGD.

    Attributes:
        lr (float): The learning rate of the SGD optimizer.
        linear (nn.Linear): The model's single linear layer, which maps one
            input feature to one output.
        criterion (nn.MSELoss): The loss function.
    """

    def __init__(self, lr: float) -> None:
        """Initialize the model.

        Args:
            lr (float): The learning rate of the SGD optimizer.
        """
        super().__init__()
        self.lr = lr
        self.linear = nn.Linear(1, 1)
        self.criterion = nn.MSELoss()

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Predict the target for each input.

        Args:
            x (torch.Tensor): The inputs, with shape (batch_size, 1).

        Returns:
            torch.Tensor: The predictions, with shape (batch_size, 1).
        """
        return self.linear(x)

    def training_step(
        self,
        batch: tuple[torch.Tensor, torch.Tensor],
        batch_idx: int,
    ) -> torch.Tensor:
        """Compute the MSE loss on a batch and log its epoch mean as "loss".

        Args:
            batch (tuple[torch.Tensor, torch.Tensor]): The (x, y) inputs and
                targets, each with shape (batch_size, 1).
            batch_idx (int): The index of the batch within the epoch.

        Returns:
            torch.Tensor: The batch's loss, which Lightning backpropagates.
        """
        x, y = batch
        loss = self.criterion(self.linear(x), y)
        self.log("loss", loss, on_step=False, on_epoch=True, batch_size=len(x))
        return loss

    def configure_optimizers(self) -> torch.optim.Optimizer:
        """Create the optimizer.

        Returns:
            torch.optim.Optimizer: An SGD optimizer over the model's
                parameters.
        """
        return torch.optim.SGD(self.parameters(), lr=self.lr)


class EpochLossRecorder(L.Callback):
    """Record the mean training loss at the end of each epoch.

    Attributes:
        losses (list[dict[str, float]]): One {"epoch", "loss"} row per
            completed epoch, with epochs numbered from 1.
    """

    def __init__(self) -> None:
        """Initialize the recorder with no recorded losses."""
        self.losses: list[dict[str, float]] = []

    def on_train_epoch_end(
        self,
        trainer: L.Trainer,
        pl_module: L.LightningModule,
    ) -> None:
        """Record the epoch's mean training loss.

        Args:
            trainer (L.Trainer): The trainer running the fit.
            pl_module (L.LightningModule): The model being trained.
        """
        self.losses.append(
            {
                "epoch": trainer.current_epoch + 1,
                "loss": trainer.callback_metrics["loss"].item(),
            }
        )


def main(args: argparse.Namespace) -> None:
    L.seed_everything(args.seed, workers=True, verbose=True)
    logging.basicConfig(level=args.level, format=args.format)
    logger = logging.getLogger(__name__)

    dataset = build_dummy_dataset(
        args.num_samples,
        args.true_weight,
        args.true_bias,
    )
    loader = DataLoader(
        dataset,
        batch_size=args.batch_size,
        shuffle=True,
    )
    model = LinearRegressor(lr=args.lr)

    run = init_run(
        args,
        job_type="training",
        name="linear-regression-example",
        config={
            "seed": args.seed,
            "true_weight": args.true_weight,
            "true_bias": args.true_bias,
            "epochs": args.epochs,
            "lr": args.lr,
            **create_slurm_config(),
        },
    )

    loss_recorder = EpochLossRecorder()
    trainer = L.Trainer(
        max_epochs=args.epochs,
        accelerator="cpu",
        callbacks=[loss_recorder],
        logger=False,
        enable_checkpointing=False,
        enable_model_summary=False,
        deterministic=True,
    )
    trainer.fit(model, loader)

    weight = model.linear.weight.item()
    bias = model.linear.bias.item()
    logger.info(
        f"learned weight={weight:.4f} (true {args.true_weight}), "
        f"bias={bias:.4f} (true {args.true_bias})"
    )
    logger.info(f"final loss={trainer.callback_metrics['loss']:.6f}")

    results_dir = resolve_results_dir(args.experiment)
    pd.DataFrame(loss_recorder.losses).to_csv(
        results_dir / "losses.csv", index=False
    )
    results = {
        "learned_weight": weight,
        "learned_bias": bias,
        "true_weight": args.true_weight,
        "true_bias": args.true_bias,
        "final_loss": trainer.callback_metrics["loss"].item(),
        "args": vars(args),
    }
    (results_dir / "results.json").write_text(json.dumps(results, indent=2))

    checkpoints_dir = resolve_results_dir(args.experiment, ["checkpoints"])
    trainer.save_checkpoint(checkpoints_dir / "model.ckpt")

    if not run.disabled:
        run.log(results)
        with tempfile.TemporaryDirectory() as tmp_dir:
            checkpoint_path = Path(tmp_dir) / "model.ckpt"
            trainer.save_checkpoint(checkpoint_path)
            artifact = wandb.Artifact(name=f"model-{run.id}", type="model")
            artifact.add_file(str(checkpoint_path))
            run.log_artifact(artifact)
        run.finish()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--experiment",
        type=str,
        default="2026-01-01_example",
        help="Name of the experiment",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducibility",
    )
    parser.add_argument(
        "--level",
        type=str,
        default="INFO",
        help="Logging level",
    )
    parser.add_argument(
        "--format",
        type=str,
        default="%(levelname)s: %(message)s",
        help="Logging message format",
    )
    parser.add_argument(
        "--true-weight",
        type=float,
        default=3.0,
        help="True weight of the dataset",
    )
    parser.add_argument(
        "--true-bias",
        type=float,
        default=0.5,
        help="True bias of the dataset",
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=50,
        help="Number of training epochs",
    )
    parser.add_argument(
        "--lr",
        type=float,
        default=0.1,
        help="Optimizer learning rate",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=32,
        help="Training batch size",
    )
    parser.add_argument(
        "--num-samples",
        type=int,
        default=256,
        help="Number of dummy samples",
    )
    parser.add_argument(
        "--wandb-mode",
        type=str,
        default="disabled",
        choices=["disabled", "online", "offline"],
        help="Whether to enable W&B tracking",
    )
    args = parser.parse_args()
    main(args)
