# ggl

<!-- project-badges:start -->
[![CI](https://github.com/mpg05883/ggl-project/actions/workflows/ci.yml/badge.svg)](https://github.com/mpg05883/ggl-project/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/mpg05883/ggl-project/graph/badge.svg)](https://codecov.io/gh/mpg05883/ggl-project)
<!-- project-badges:end -->

> [!IMPORTANT]
> **Just created a repo from this template? Run `/init-project` first.**
> Open Claude Code in the repo root and run `/init-project` before doing anything else below. It fills in
> `AGENTS.md` and this README, renames the placeholder `ggl` to your project name, and checks that the environment,
> linter and tests work.

TODO: one-paragraph description of the project (what it studies, the data, the main components).

TODO: where this project runs (cluster name, or local only). Package management is done with
[uv](https://docs.astral.sh/uv/).

## Starting a New Project

*Template-only section. Delete it once the project is initialized.*

1. Click **"Use this template"** on GitHub to create your repo, then clone it:

   ```bash
   git clone git@github.com:<your-username>/<your-project>.git
   cd <your-project>
   ```

2. **Run `/init-project` in Claude Code.** This is the first step. It asks about your project (name, data, where it
   runs, tracker, gotchas), fills in the `TODO:` items in `AGENTS.md` and this README, sets `#SBATCH --mail-user=`,
   renames `ggl` everywhere (package, imports, `pyproject.toml`, scripts), then runs `uv sync`, `ruff`
   and `pytest`. It also configures Codecov coverage uploads and checks
   whether the new repository is connected to Codecov. It updates the CI
   and Codecov badges beneath the README title for the new GitHub repository.
3. Continue with [Setup](#setup).

Without Claude Code, find every place to rename by hand with:

```bash
grep -rIlw ggl . --exclude-dir=.git --exclude-dir=.venv --exclude-dir=worktrees --exclude=uv.lock
```

You will also need to fill in the `TODO:` items in `AGENTS.md` and this README, and set `#SBATCH --mail-user=` in the
`cli/` scripts.

## Setup

Assumes `/init-project` has been run. Run all commands from the repo root.

```bash
./cli/utils/build_environment.sh    # install uv (if needed) and create .venv
uv sync                            # install dependencies and dev tools
```

The default dev group includes pytest, pytest-cov, ruff, and mutmut.
`uv sync` installs these tools without extra flags. mutmut installs on
Linux; use WSL for mutation testing on Windows.
Add development tools with `uv add --dev <package>` and commit `uv.lock`.

The environment builder installs these extensions for Claude Code and Codex,
the current user across projects: [find-skills][find-skills],
[Superpowers][superpowers], [Claude-Mem][claude-mem],
[Task Observer][task-observer], and [data-viz-plots][data-viz-plots].
This step requires Node.js 22.20 or later and Git. It installs Bun if
missing because Claude-Mem needs it. The plotting packages already belong
to the Python environment.

To install only these extensions, run the installer for the tool you use:

```bash
bash cli/utils/install_claude_extensions.sh
bash cli/utils/install_codex_extensions.sh
```

Both installers enable Task Observer by default with user-level guidance
and a `SessionStart` hook. The configuration preserves existing hooks and
personal rules. Changed files receive a `.before-task-observer` backup.
Both tools use one shared observation workspace at `~/.task-observer`,
or an existing observation workspace under `~/.claude` or `~/.codex`.
Set `TASK_OBSERVER_WORKSPACE` before installing to select another durable
location. Proposed skill changes still require your approval. Restricted
runs report pending observations in task output instead of blocking work.

Verify the setup after installation:

1. Restart Claude Code. Run `/plugin` and confirm Superpowers and
   Claude-Mem appear under installed plugins. Start a new session and
   confirm Task Observer runs without a manual `/task-observer` command.
2. Start a new Codex chat. Open `/hooks` and review the new Task Observer
   and Claude-Mem hook definitions. Codex requires you to trust new or
   changed hooks before they run; the installer does not bypass this.
   Persistent `AGENTS.md` guidance also requests Task Observer activation.
3. In that new Codex chat, confirm Task Observer uses the same workspace
   as Claude Code. Invoke `$find-skills` or `$data-viz-plots` to verify
   standalone skill discovery.

Claude-Mem's Codex installer registers its native plugin and capture hooks.
It retains an existing provider configuration and uses upstream defaults
on a fresh installation. It does not start its worker during installation.
Complete any provider or account setup on first use. A successful hook
test verifies the generated context; automatic
skill activation must be checked in a new session.

[find-skills]: https://github.com/vercel-labs/skills/tree/main/skills/find-skills
[superpowers]: https://github.com/obra/superpowers
[claude-mem]: https://github.com/thedotmack/claude-mem
[task-observer]: https://github.com/rebelytics/one-skill-to-rule-them-all
[data-viz-plots]: https://github.com/Microck/ordinary-claude-skills/tree/main/skills_all/data-viz-plots

`uv sync` installs the local project package in editable mode, so changes under
`src/` take effect without reinstalling. This also applies after renaming the
project during `/init-project`.

Create a `.env` file in the repo root for secrets and local settings (e.g. your W&B API key). It is gitignored and
loaded by `load_env_vars` in `cli/utils/utils.sh`.

## Usage

```bash
# Run an experiment locally (uv run handles the venv)
uv run python experiments/<experiment>/run.py

# SLURM only (skip if the project runs locally): submit as a job (dev run: tracking disabled)
sbatch --job-name=<name> cli/<experiment>/run.sh
# Real run: tracking online
sbatch --job-name=<name> cli/<experiment>/run.sh --real

# Interactive nodes (SLURM only)
./cli/utils/start_interactive_cpu_session.sh
./cli/utils/start_interactive_gpu_session.sh

# Lint, format, test
uv run ruff check .
uv run ruff format .
uv run pytest
```

Don't run heavy compute on login nodes. Always do a dev run before `--real`. The `data/` directory is gitignored and
read-only; `cli/utils/download_dataset.sh` populates it.
For long-running real jobs, use the validated launch checkout described
in [Git Workflow](#git-workflow).

Document each dataset and model you use in `docs/` (e.g. `docs/datasets.md`, `docs/models.md`): source, version or
checkpoint, how `data/` is populated, and for datasets the exact splits (sizes, how they were made, seeds) and any
preprocessing. Claude Code reads these when scaffolding experiments, so keep them current.

## Automated Checks

New repositories created from this template include two GitHub Actions
workflows. Enable GitHub Actions in the new repository if organization
settings disable them.

1. **CI** (`.github/workflows/ci.yml`) runs on pull requests to `main`,
   and pushes to `main`. It checks lint, formatting, and tests with branch
   coverage. CI uploads the coverage report to Codecov with GitHub OIDC
   authentication; no `CODECOV_TOKEN` secret is required. `/init-project`
   follows the [Codecov setup guide](docs/codecov.md) to connect the new
   repository and verify its first upload. Account authorization can
   require a repository owner or organization administrator. Upload
   failures do not fail CI.
2. **Mutation testing** (`.github/workflows/mutation.yml`) runs each Monday
   at 06:00 UTC and on manual requests. It changes source code temporarily
   and checks whether the tests detect each change. It reports surviving
   changes without blocking merges. Mutation run errors also do not fail
   the job. Read the run summary or download the `mutmut-results` artifact
   for the results.

Both workflows install dependencies from the committed `uv.lock`. Coverage and
mutation testing target `src/`, so package renaming with `/init-project`
does not require workflow changes. Mutation testing restores the `mutants`
cache for the current commit, with a fallback to previous mutation caches.

Run the same checks locally:

```bash
uv sync --locked
uv run --locked ruff check .
uv run --locked ruff format --check src tests experiments cli
uv run --locked pytest --cov --cov-report=xml --cov-report=term-missing

# Mutation testing requires Linux or WSL.
uv run --locked mutmut run
uv run --locked mutmut results
```

To verify CI, open a PR to `main` and inspect its `ci` check and Codecov
upload step. To verify mutation testing, open **Actions**, select
**mutation**, and click **Run workflow**. Select the branch containing the
workflow and confirm that the run produces its results artifact. Manual
runs require the mutation workflow file to exist on the default branch first.
Repository rules requiring the `ci` check are configured separately in
GitHub settings; template files do not enable those rules automatically.

## Project Structure

```text
src/ggl/           # Reusable library code
tests/             # pytest; mirrors src/
experiments/       # One date-prefixed folder per experiment, plus an index README
cli/               # bash/sbatch scripts: per experiment, plus utils/ (setup, data download, interactive nodes)
notebooks/         # Exploratory notebooks
data/              # Datasets (gitignored, read-only)
docs/              # Project guides: datasets (splits, preprocessing), models, hyperparameter_tuning.md
notes/             # Working notes: ideas/ experiment proposals, read/ paper summaries, writeups/ reports, other/, discussions/ (private)
```

## Experiments

Each experiment lives in `experiments/YYYY-MM-DD_<short-name>/` with a `README.md` (setup, results, observations), a
results notebook, and optionally a `run.py`. Its sbatch scripts go in `cli/<experiment>/`. Start a new folder for each
new experiment rather than rewriting old ones, and add a brief entry to `experiments/README.md`.

Copy [`experiments/2026-01-01_example/`](experiments/2026-01-01_example) and
[`cli/2026-01-01_example/`](cli/2026-01-01_example) as a starting point. They are examples only: delete them (and
their entries in `experiments/README.md`) once you have your own experiments.

## Git Workflow

Branches are named `<type>/<short-description>`: lowercase, hyphen-separated, 2-4 words. Don't put dates or run IDs in
branch names; those belong in commit messages, tags, or your experiment tracker. In multi-person repos, prefix your name
(`mike/exp/lora-rank-sweep`); skip the prefix for solo projects.

| Type | Use for |
|------|---------|
| `exp` | Experiments: new runs, sweeps, ablations, hypothesis tests |
| `feat` | New functionality in the codebase |
| `fix` | Bug fixes |
| `refactor` | Restructuring with no behavior change |
| `docs` | README, `AGENTS.md`, and other documentation |
| `chore` | Dependency bumps, config, tooling |

Examples: `exp/lora-rank-sweep`, `feat/lr-warmup-scheduler`,
`fix/dataloader-seed`, `chore/bump-torch`. The agent rules are in
[`AGENTS.md`](AGENTS.md).

### Rules

1. **Use one branch for one pull request (PR).** Open a draft PR when you
   first push the branch. Use a new branch for work after that PR merges.
   Delete the merged branch after checking for local work and results.
2. **Keep at most five branches in progress.** Before starting a sixth,
   finish one, mark its draft PR as parked, or archive it. A parked PR
   must state what is needed before work resumes.
3. **Change `main` through a passing PR.** Do not push directly to `main`.
   Require the `ci` check and use a squash merge. CI checks lint,
   formatting, and tests with coverage. Mutation testing reports results
   separately; it is not a required merge check.
4. **Use a validated commit for long-running real jobs.** Follow the
   launch checkout procedure below. Do not change source files under a
   running job.
5. **Review branches and worktrees weekly.** Allow two minutes for the
   inspection commands below. Confirm before deleting any branch or
   worktree. Check ignored files for results before removing a worktree.

```bash
git fetch --prune
git branch -vv
git worktree list
gh pr list --author @me
```

A missing remote branch does not prove that local work is disposable.
Preserve experiment outputs before branch or worktree cleanup.

### Launch checkout and worktrees

Use this procedure for projects that submit long-running real jobs.
Projects without those jobs can use the PR workflow without a launch
checkout. A checkout is a directory containing one version of the code.
A worktree is another checkout that shares the same Git repository.

1. **Validate the merged commit.** Run a small dev check with tracking
   disabled against the real inputs and services used by the changed
   code. A synthetic example alone does not validate real-data behavior.
   Record the commit and the validation command in the experiment README.
2. **Mark the validated commit with `stable`.** The tag identifies a
   commit on `main` that passes the real-data dev check. Move this shared
   tag only with user authorization. Keep the existing tag if validation
   fails; fix the code through a new PR.
3. **Launch real jobs from a dedicated checkout at `stable`.** Keep its
   source files unchanged. Record the tag's commit hash with each run.
   Confirm with the user before a `--real` run that enables tracking.
4. **Develop in separate worktrees.** Use one worktree per active branch,
   for example under a sibling `<project>-wt/` directory. Follow the
   project's data and environment setup instructions for each worktree.
   Gitignored `data/` and `.env` do not appear in a new worktree.
5. **Preserve results before removing a worktree.** Run
   `git status --ignored` inside the target worktree. Check for outputs,
   logs, checkpoints, and untracked files. Do not force removal while
   files that must be retained remain there.

### Experiment lifecycle

1. **Create `exp/<name>` from `main`.** Name the question or variable,
   such as `exp/lora-rank-sweep`. Keep dates in experiment folder names.
   Scaffold the experiment and get a clean dev run before the PR merges.
2. **Run the merged experiment.** For long-running real jobs, validate
   the merged commit, update `stable` with authorization, and launch from
   the dedicated checkout. Obtain approval before tracked real runs.
3. **Create `exp/<name>-results` from current `main`.** Add the results
   notebook and the README's Results and Observations sections in a new
   PR. Do not reuse the merged experiment branch.
4. **Archive a dead end.** Tag its final commit as `archive/exp/<name>`.
   Preserve the tag remotely when a remote exists. Verify configs, seeds,
   and retained outputs before requesting branch deletion. Do not merge
   an abandoned experiment only to preserve its history.

Commit configs and seeds so another run can reproduce the merged or
tagged experiment. Record the code commit with results and tracker runs.

### One-time GitHub setup

An administrator configures these settings separately for each new
repository. Template files alone do not configure GitHub settings.

1. Open **Settings > General > Pull Requests**. Enable squash merging
   and automatic deletion of merged branches. Disable other merge methods
   if squash merging must be enforced.
2. Open **Settings > Rules**. Add a branch ruleset for `main` that
   requires a PR and the `ci` status check, and blocks force pushes and
   deletion. The first CI run must report the check before you select it.
3. Confirm that **Actions** shows the `ci` check on a test PR. Verify the
   repository's merge settings and required checks before merging.

Ruleset availability depends on the GitHub plan and repository visibility.
If enforcement is unavailable, follow the same PR rules manually.
See GitHub's documentation for [rulesets][github-rulesets],
[squash merges][github-squash], and [branch deletion][github-delete].
Agents must obtain authorization before changing repository settings.

[github-rulesets]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
[github-squash]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/configuring-commit-squashing-for-pull-requests
[github-delete]: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-the-automatic-deletion-of-branches

## Test and Writing Conventions

Tests mirror `src/`. Keep shared fakes and builders in `tests/helpers/`
and reusable fixtures in `conftest.py`. Do not import one test module
from another. Use `test_<name>_integration.py` for tests that combine
modules. Keep those tests independent of network access and real models
unless a project explicitly defines a separate external test suite.
If duplicate test filenames require pytest's importlib mode, configure
that mode before relying on it; the template does not enable it.

Use explicit section names such as `Decision 1` or `Stop Point 1` in
technical documents. Avoid ambiguous one-letter labels such as `D1` or
`S1`. Keep established technical abbreviations such as MAE and AUC.

## Example Workflow with Claude Code

A typical loop from idea to results. Conventions (naming, layout, tracking) are in [`AGENTS.md`](AGENTS.md), which
Claude Code reads automatically.

1. **Draft the idea.** Ask Claude Code to write a short proposal in `notes/writeups/<short-name>.md`:

   > Draft an experiment idea for `<topic>` in `notes/writeups/`. Check `docs/datasets.md` and `docs/models.md` for the
   > available data, splits, and models. Include the hypothesis, variables, baselines, metrics, and what result would
   > change our plans.

   Read and edit it before moving on. This is the cheapest place to catch a bad design.

2. **Scaffold the experiment.** Once you're happy with the idea:

   > Create `experiments/YYYY-MM-DD_<short-name>/` from the idea in `notes/writeups/<short-name>.md`, following the
   > example experiment. Add `run.py` and the matching sbatch script at `cli/YYYY-MM-DD_<short-name>/run.sh`, and add
   > an entry to `experiments/README.md`.

3. **Dev run.** Smoke-test locally or on an interactive node with tracking disabled, then submit a dev job:

   ```bash
   uv run python experiments/YYYY-MM-DD_<short-name>/run.py
   sbatch --job-name=<name> cli/YYYY-MM-DD_<short-name>/run.sh
   ```

   Fix problems here, before spending compute on a real run.

4. **Real run.** Once the dev run is clean:

   Merge the experiment PR after CI passes. For long-running jobs,
   validate the merged commit with real inputs, obtain authorization to
   update `stable`, and use the dedicated launch checkout. Confirm the
   tracked real run with the user before submission.

   ```bash
   sbatch --job-name=<name> cli/YYYY-MM-DD_<short-name>/run.sh --real
   ```

5. **View results.** After the run finishes:

   > Create a results notebook in `experiments/YYYY-MM-DD_<short-name>/` that loads the outputs of this run and plots
   > <metrics>. Then fill in the Results and Observations sections of the experiment's `README.md`.

## Experiment Tracking

Runs are tracked with Weights & Biases by default. `--real` turns it on (`online`); otherwise it is `disabled`. To
disable it manually:

```bash
export WANDB_MODE=disabled
```

TODO: if this project uses a different tracker, or none, update this section.

For hyperparameter tuning, see [`docs/hyperparameter_tuning.md`](docs/hyperparameter_tuning.md).

## For AI Agents

Project instructions for Claude Code live in [`AGENTS.md`](AGENTS.md) (imported by `CLAUDE.md`).
