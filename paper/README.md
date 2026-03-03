# Paper (Overleaf Submodule)

This is a placeholder directory. Replace it with a git submodule linked to your Overleaf project via GitHub.

## Setup

1. **Link Overleaf to GitHub.** In your Overleaf project, go to Menu > Sync > GitHub and follow the prompts to create a linked GitHub repo. See: https://www.overleaf.com/learn/how-to/Using_Git_and_GitHub

2. **Remove this placeholder and add the submodule:**
   ```bash
   rm -rf paper/
   git submodule add https://github.com/<org>/<paper-repo>.git paper
   git commit -m "Add paper submodule"
   ```

3. **After cloning the repo** (for collaborators):
   ```bash
   git submodule update --init
   ```

## Syncing with Overleaf

Changes sync through GitHub as the intermediary:

- **Overleaf → local:** Push from Overleaf to GitHub (Menu > Sync > GitHub > Push), then pull locally:
  ```bash
  cd paper/ && git pull && cd ..
  git add paper && git commit -m "Update paper submodule"
  ```

- **Local → Overleaf:** Push to GitHub, then pull into Overleaf (Menu > Sync > GitHub > Pull):
  ```bash
  cd paper/
  git add -A && git commit -m "Update from local"
  git push
  cd ..
  git add paper && git commit -m "Update paper submodule"
  ```
