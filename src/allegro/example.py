"""Example reusable module. Your shared training/evaluation logic goes here."""

import argparse
from dataclasses import dataclass, asdict
import torch


@dataclass
class Config:
    model_name: str
    learning_rate: float
    batch_size: int
    seed: int = 42


def run(config: Config):
    torch.manual_seed(config.seed)
    print(f"Running with model={config.model_name}, lr={config.learning_rate}, bs={config.batch_size}")
    print(f"CUDA available: {torch.cuda.is_available()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_name", type=str, default="gpt2")
    parser.add_argument("--learning_rate", type=float, default=5e-5)
    parser.add_argument("--batch_size", type=int, default=16)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    run(Config(**vars(args)))
