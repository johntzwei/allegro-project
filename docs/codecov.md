# Codecov setup during project initialization

Run these steps as part of `/init-project` in a new repository. Keep
coverage enabled by default. Do not run project initialization against
the template repository itself just to configure coverage.

1. Identify the GitHub owner and repository from
   `gh repo view --json nameWithOwner -q .nameWithOwner`, or from the
   `origin` remote. Use the new repository, not the template or MTBench.
   If no GitHub remote exists, leave connection pending until one exists.
2. Confirm that `pyproject.toml` includes `pytest-cov` in the default dev group
   and `[tool.coverage.run]` targets `src/` with branch coverage enabled.
   Confirm CI generates `coverage.xml` and
   runs `codecov/codecov-action` with `use_oidc: true` and job permission
   `id-token: write`. Keep `fail_ci_if_error: false` so a service failure
   does not block the test checks. If the dependency is missing, add it
   with `uv add --dev pytest-cov` and retain the updated lockfile.
3. Connect the new repository at `https://app.codecov.io/gh/OWNER/REPO`.
   Use available authenticated tools to check its connection and enable
   it when account permissions allow. If Codecov requests GitHub App
   access, have the user select this repository and authorize access.
   Organization restrictions can require an administrator. If access is
   unavailable, give the exact dashboard URL and remaining action.
   OIDC authenticates uploads without a `CODECOV_TOKEN` secret; it does
   not grant Codecov access to a private repository by itself.
4. Run `uv sync`, then
   `uv run pytest --cov --cov-report=xml --cov-report=term-missing`.
   Confirm the tests pass and `coverage.xml` contains source coverage.
   Record the measured coverage and the repository's dashboard URL in
   the README's Automated Checks section. Coverage measures test
   execution, not whether tests detect incorrect behavior.
   Initialize the README badge block with
   `uv run python cli/utils/init_readme_badges.py --repository OWNER/REPO`,
   using the GitHub slug from step 1. This replaces the template's CI and
   Codecov URLs without changing other README content. Repeat runs replace
   the same block instead of adding duplicate badges. If a specific branch
   is needed, pass `--branch BRANCH` using the GitHub default branch name.
   For a private repository, open Codecov **Configuration**, then
   **Badges & Graphs**, and obtain that repository's badge image URL.
   Pass it with `--codecov-badge-url 'https://codecov.io/gh/...'`.
   This URL can include a badge access token; never reuse MTBench's token
   or substitute an upload token. If badge access is unavailable, keep
   the new repository's URL and report the private badge as pending.
5. After the user publishes the changes and opens a PR to `main`, open
   its `ci` check on GitHub. Confirm the upload step succeeds, then open the
   Codecov dashboard and confirm coverage for the same commit. Do not
   push, commit, or change repository rules as part of `/init-project`.
   If the first CI run has not happened, report remote verification as
   pending. Local coverage alone does not verify a Codecov connection.
   Open the rendered README and confirm both badges link to the new
   repository. Confirm the CI status and Codecov percentage appear after
   the first successful CI run and coverage upload. Before that run, the
   badge URLs can be initialized while their status is still unavailable.

No coverage percentage threshold is imposed by the template. Codecov
status checks and branch protection can be configured separately.

References:

- [Codecov Action: OIDC authentication](https://github.com/codecov/codecov-action#using-oidc)
- [Codecov status badges](https://docs.codecov.com/docs/status-badges)
- [Codecov GitHub integration](https://docs.codecov.com/docs/github-2-getting-a-codecov-account-and-uploading-coverage)
