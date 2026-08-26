# toxicwind dotfiles (2025 rev)

Curated snapshot of the HypeBrut shell environment: thin Bash loader, segmented `.bashrc.d` modules, Starship theming, and helper scripts like the Geeqie Wayland clipboard bridge. Everything in `home/` mirrors the real file layout so it can be staged or applied without extra tooling.

## Layout

- `home/` – Files that map 1:1 onto `$HOME` (Bash loader, Starship config, `.local/bin-core` helpers, Geeqie module, etc.).
- `manifest.txt` – Canonical list of tracked paths. Edit this before adding new material.
- `scripts/update-from-home.sh` – Pulls the current workstation state into the repo (non-interactive, prints `[update] …`).
- `scripts/deploy-to-home.sh` – Writes repo contents back to `$HOME` with timestamped backups in `~/.local/share/dotfiles-backups/` (non-interactive, prints `[deploy] …`).
- `docs/AGENTS.md` – Archived copy of the active HypeBrut charter.
- `home/tests/` – Bats test suite to sanity check the shell stack.
- `docs/AGENTS.md` – Source-of-truth charter; review it before modifying shell behaviour or directory structure.

## Usage

```bash
# Refresh repo from live system
./scripts/update-from-home.sh

# Deploy repo contents back to $HOME (backs up existing files)
./scripts/deploy-to-home.sh
```

Backups land under `~/.local/share/dotfiles-backups/<timestamp>/`. Restore by copying files back from there if needed.

## Size & content guardrails

- Keep individual tracked files under **1 MB**. Compiled binaries (e.g. `micromamba`, third-party CLI builds) stay out of git; install them separately.
- `.gitignore` whitelists only the curated shell helpers inside `home/.local/bin-core/`. Anything not whitelisted is ignored to prevent accidental binary uploads.
- Secrets, API keys, wallets, caches, node data, or runtime logs must never be added. Update `manifest.txt` whenever you onboard new files so they can be reviewed deliberately.

> ⚠️ **HypeBrut Charter**  
> `docs/AGENTS.md` mirrors the live instructions that govern shell layout, PATH order, module policy, and reporting. Every change to the dotfiles must keep that contract intact; update the charter copy alongside any structural change so new clones stay compliant.

## GitHub automation

The repo is designed to live at `git@github.com:toxicwind/dotfiles.git` (private). Use the GitHub CLI for routine sync:

```bash
# Commit latest edits
./scripts/update-from-home.sh
git add -A
git commit -m "chore: refresh dotfiles"

# Push to GitHub via gh
gh repo sync
```

If the remote ever needs to be rebuilt from scratch:

```bash
gh repo delete toxicwind/dotfiles --yes
gh repo create toxicwind/dotfiles --private --source . --push
```

## Roadmap ideas

- Mirror additional modules (tmux, kitty, neovim) by appending to `manifest.txt`.
- Add CI lint to smoke-test shell scripts (e.g. `shellcheck`, `shfmt`).
- Integrate secrets with `pass` or age if encrypted files become necessary.
