# ggl — Agent Instructions

If this file still contains `TODO:` placeholders, tell the user to run `/init-project`; don't ask about them yourself.

## Project overview

TODO: 2-4 lines on what this project is, the data, and the main components.

TODO: run /init-project to fill in this file and rename "ggl" (the placeholder project name) to the real one.

Commands, setup and directory structure are in `README.md`. This file holds the rules and context that aren't obvious
from the code.

## How to communicate

The user has ADHD. Write chat replies in ASD-STE100 Simplified Technical
English. These communication rules apply to chat replies. Documentation,
code comments, and commit messages follow the project conventions.

**Language**

- Use one idea in each sentence.
- Use a maximum of 20 words in an instruction sentence and 25 words in a descriptive sentence.
- Use the active voice and the simple present tense when possible.
- Keep the articles "the" and "a".
- Use plain language.

**Words**

- Use one word for one meaning. Do not replace a word with a synonym for variety.
- Do not use idioms, slang, or figures of speech.
- Keep technical names unchanged. This includes files, commands, functions, classes, variables, and error text.
- Explain an unavoidable technical term with a short definition.

**Structure**

- Lead with the action or the outcome. Put the context and reasoning after it.
- Start a completed task with: "Done: <outcome>".
- Do not add a conversational preamble. Do not start with "Let me...", "Great question...", "I would be happy
  to...", or "Based on your request...".
- Use a maximum of six sentences in a procedural paragraph.
- Keep normal answers to six sentences or fewer unless the user asks for depth.

**Lists and steps**

- Use numbered steps for a sequence. Put one bounded action in each step.
- Use a maximum of five items in one list.
- Split a longer list into "Do now" and "Do later".

**Task state**

- Restate the task state during every turn of a multi-step task. Use this format: "Step 3 of 5 done: schema
  updated. Next: backfill."
- Do not assume that the user remembers the previous message.
- Give a concrete time estimate when the task requires user work. Do not use vague estimates such as "This will
  take some work."

**Scope**

- Answer only the requested topic. Do not include unrequested alternatives, comparisons, or tangents.
- If a second issue appears, finish the first issue. Offer the second issue as a separate task.
- End with one concrete next action when work remains.
- Do not end with "Let me know.", "Tell me what you think.", or "I can help with that."
- State assumptions before you act.
- Ask a question only when a requirement is genuinely ambiguous. Otherwise select the sensible default and state it.

**After a change**

- Summarize what changed, where it changed, and why it changed.
- Include exact file paths when files change.
- After a feature change, add a short manual test checklist. The checklist must state what to open, click, enter,
  and confirm.
- For a command-line change, state the command, its input, and the output
  that confirms success.

## Never do

Rules marked *(default)* are template defaults that `/init-project` confirms; the others are always on.

- Never commit `.env`.
- Don't delete `results/` or `done.done` files.
- Add dependencies with `uv add`, not by hand-editing `pyproject.toml`. Commit `uv.lock`.
- *(default)* **NEVER modify anything in the repo-root `data/` directory.** Don't create, edit, move, rename or delete
  files there, and don't run commands that write into it (including re-running download or preprocessing scripts)
  unless the user explicitly asks. This covers only the root-level `data/`, not paths like `src/**/data/` or
  `experiments/*/results/`. Exception: `cli/utils/download_dataset.sh` (and any future script that writes into `data/`)
  may run only when the user explicitly asks.
- *(default)* Confirm before any real (non-dev, `--real`) run that logs to the experiment tracker.
- *(default)* Do NOT read files in `notes/discussions/` unless explicitly requested (private meeting notes). The rest
  of `notes/` is shared context and fine to read.

## Clarify before acting

Don't make silent assumptions. For any non-trivial task, restate the goal in one or two sentences, then ask about what
is ambiguous and would change what you build or run: outcome, scope, success criteria, constraints, and which files,
data or experiments are affected.

- Look things up first (repo, configs, scripts, docs); only ask what you couldn't determine.
- Ask in one batch of at most five numbered questions that can be answered in a few words, with likely options and a
  recommended default. If a detail is unresolved, say so rather than filling it in. You may proceed on the clear parts meanwhile.
- Ask only when a wrong guess would cost more than a dev run. Don't over-ask on trivial or fully specified tasks (a
  typo fix, an explicit command): just do them.
- Stop and ask before anything expensive, slow or hard to undo: large job arrays or GPU-heavy jobs, deleting or
  overwriting files, changing dependencies, touching shared config. Cheap dev runs don't need a question.
- If the user can't be reached (unattended or scheduled run), do only the safe, reversible part, list every
  assumption at the top of your final summary, and stop before the risky step.
- When finished, list any assumptions you did make so they can be corrected.

## Environment

- Package manager: uv (NOT conda, NOT pip directly). Python version: see `pyproject.toml`. Virtual env: `.venv/` at
  the project root.
- `uv sync` installs the default dev group. Add development tools with
  `uv add --dev <package>`. mutmut runs on Linux or WSL, not native Windows.
- Secrets and local settings live in `.env` (gitignored), loaded by `load_env_vars` in `cli/utils/utils.sh`.
- `.claude/settings.json` runs `ruff format` automatically after every edit, so don't run it again by hand.
- Compute: TODO: where this project runs (cluster name, or "local only"). For cluster-specific notes, read
  `~/.claude/clusters/<cluster>.md` if it exists. Partition, account and resource defaults are set in the header of
  each `cli/` script (the interactive launchers also read `PARTITION` and `ACCOUNT` env vars).
- Outputs: TODO: where results, checkpoints and large outputs are stored (use persistent storage, not purgeable
  scratch space, for anything you need to keep).

## Cluster rules

Skip this section if the project is local only.

- Don't run heavy compute on login nodes; use `sbatch` or the interactive launchers in `cli/utils/`.
- Ask before submitting large job arrays.
- Cluster-specific setup (SLURM conventions, storage paths, module/env quirks) lives in `docs/clusters/<name>.md`.
  Before submitting or configuring any job, read the file for the cluster you're on (e.g. `docs/clusters/misha.md`).

## Conventions

- Experiments: one `experiments/YYYY-MM-DD_<short-name>/` folder per experiment, with a `README.md` (setup, results,
  observations) and a results notebook. `experiments/README.md` holds only brief descriptions.
- When writing each experiment's `view_results.ipynb`, pull results from
  Weights & Biases (wandb).
- Experiment ideas are drafted in `notes/writeups/<short-name>.md` (hypothesis, variables, baselines, metrics, what
  result would change our plans) and reviewed by the user before any code is scaffolded.
- Use explicit section names in Markdown, such as `Decision 1` or
  `Stop Point 1`. Avoid ambiguous one-letter labels such as `D1` and `S1`.
  Keep established technical abbreviations such as MAE and AUC.
- Don't rewrite old experiments; start a new folder. Bug fixes to old experiments are allowed *(default)*.
- Reusable code goes in `src/ggl/`; runnable scripts use argparse. TODO: add a `scripts/` dir if the project needs one.
- sbatch scripts for an experiment go in `cli/<experiment>/` and source `cli/utils/utils.sh`. Logs go under
  `experiments/<experiment>/logs/`, plus a `done.done` marker written via `get_done_file`.
- Tests mirror `src/` (`src/ggl/utils/wandb.py` is tested in `tests/ggl/utils/test_wandb.py`).
- Keep shared fakes and builders in `tests/helpers/` and reusable fixtures
  in `conftest.py`. Never import one test module from another.
- Use `test_<name>_integration.py` for tests that combine modules. Avoid
  network access and real model calls unless the project defines a
  separate external test suite. Configure pytest's importlib mode before
  relying on duplicate test filenames; it is not enabled by the template.
- Code style: ruff, line length 79. Comments and docstrings must wrap at 79 characters; rewrap the text instead of
  shortening its meaning. This is enforced by ruff (E501, W505) and a PostToolUse hook
  (`.claude/hooks/check_line_length.py`); fix any hook violation before continuing.
- Experiment tracking defaults to Weights & Biases (`--real` turns it on, otherwise it is `disabled`). TODO: if this
  project uses a different tracker, or none, say so here and update `src/ggl/utils/wandb.py` and the `cli/` scripts.
- Before tuning hyperparameters or writing sweep/tuning scripts, read `docs/hyperparameter_tuning.md`.
- Before designing an experiment or writing data-loading, preprocessing or model code, read `docs/datasets.md` (sources,
  splits, preprocessing) and `docs/models.md` (checkpoints, configs). Take splits from there; never re-derive or guess
  them. If a doc is missing, a stub, or doesn't cover what you need, ask the user rather than filling it in.
- Keep those docs current: when you change a split, preprocessing step or model, update the doc in the same change. They
  should describe what the code does (e.g. name the function that builds each split and its seed), not replace it.

## Git conventions

- Branch names: `<type>/<short-description>`. Lowercase, hyphen-separated, 2-4 words. No dates or run IDs (those go in
  commit messages, tags, or the experiment tracker).
- Types: `exp` (experiments: new runs, sweeps, ablations, hypothesis tests), `feat` (new functionality), `fix` (bug
  fixes), `refactor` (restructuring with no behavior change), `docs` (README, AGENTS.md, other documentation), `chore`
  (dependency bumps, config, tooling).
- Multi-person repos may add a collaborator prefix (`mike/exp/lora-rank-sweep`); skip it for solo projects.
- Keep `main` runnable. Change it only through a PR whose `ci` check
  passes, using a squash merge. Never push directly to `main`.
- Use one branch for one PR. Open a draft PR when first pushing a branch.
  Never push to a branch after its PR merges. Start a new branch instead.
- Keep at most five branches in progress. Finish, park, or archive one
  before starting a sixth. A parked draft PR states what blocks progress.
- `exp/` branches: create from `main`. Name the question or variable being tested, not the outcome
  (`exp/lora-rank-sweep`, not `exp/best-lora-config`). Scaffold and dev run
  go in `exp/<name>`. Results go in a new `exp/<name>-results` branch from
  current `main`. Tag a dead end as `archive/exp/<name>` instead of merging
  it. Preserve its history and outputs before requesting branch deletion.
- For projects with long-running real jobs, launch from a dedicated
  checkout at `stable` and keep its source files unchanged. Develop in
  separate worktrees, for example under a sibling `<project>-wt/` folder.
- `stable` identifies a commit on `main` that passes a small dev check
  with real inputs and tracking disabled. A synthetic example alone does
  not qualify. Record the validation command and commit in the experiment
  README. Obtain authorization before moving `stable` or changing GitHub
  repository settings.
- Review branches and worktrees weekly. Before removing a worktree, run
  `git status --ignored` inside it and preserve results, checkpoints, and
  untracked files. Do not force removal while needed outputs remain.
  Confirm before deleting branches or worktrees.
- Record configs, seeds, and the code commit so results are reproducible
  from the merged or tagged commit.
- Full lifecycle and examples: "Git Workflow" in `README.md`.

## New-Experiment Checklist

1. Read `docs/datasets.md` and `docs/models.md`; ground the idea in `notes/writeups/<short-name>.md` in what exists
   there.
2. Create `experiments/YYYY-MM-DD_<short-name>/` with a `README.md` and a results notebook; copy the example
   experiment as a starting point. `run.py` is optional.
3. Mirror it in `cli/<experiment>/` with sbatch scripts that source `cli/utils/utils.sh`.
4. Add a brief entry to `experiments/README.md`.
5. Run it as a dev run first; use `--real` only after confirming with the user.

## Gotchas

TODO: project-specific data-integrity rules. Examples to adapt or delete:

- Never tune hyperparameters or choose checkpoints on the test split.
- Fit preprocessing (scalers, tokenizers, normalization statistics) on training data only.
- Split by the right unit (subject, series, document), not by row, to avoid leakage across splits.
- Fix random seeds and record them in each experiment's README.
