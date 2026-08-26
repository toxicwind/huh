# Hypebrut Shell Operations Charter (rev 2025-10-27)

## 0 — Reading Map (LLM Orientation)
- **Purpose:** Equip any successor agent with every constraint needed to run the Hypebrut shell stack safely, reproducibly, and autonomously.
- **Bias:** Optimise for semantic clarity. Verbosity > brevity when it prevents ambiguity. Every directive includes the reason, enforcement location, and rollback cues.
- **Notation:**
  - `MUST` = hard requirement; breaking it counts as regression.
  - `SHOULD` = recommended best practice; document if you diverge.
  - `[Anchor]` tags allow fast cross-reference inside this file.

## 1 — Directive Hierarchy & Authority Envelope [DIR]
1. **Precedence Chain (in order, MUST follow):**
   1. Explicit user directives (latest message wins).
   2. This charter (`AGENTS.md`) + `SYSTEM.md`.
   3. Immutable host policy.
2. **Privilege:** Full sudo authorised (password `!TrixSwag19900612`). Always prefer idempotent commands and keep logs.
3. **Network:** Unrestricted outbound. Persist artefacts under `$HOME/.local/share`, `$HOME/.local/bin`, `$HOME/.local/bin-core`, or `$HOME/bin`. Do **not** rely on `/tmp` for lasting installs.

## 2 — Runtime Inventory Snapshot (2025-10-27) [INV]
| Component | Version / Expectation | Location / Hook | Notes |
|-----------|----------------------|------------------|-------|
| Bash | 5.2 (system) | `/bin/bash` | Stay untouched. |
| `.bashrc` | Loader only | sources `~/.config/bash/main.sh` | Sections 1–15; extend by appending. |
| ble.sh | `0.4.0-devel4+2f564e6` | `~/.local/share/blesh/ble.sh` | Load only when TTY & `HB_PROMPT_FORCE_PURE=0`. |
| Starship | 1.22.1 | `~/.local/bin-core/starship` | Right prompt module handles time + ⏱. |
| Atuin | 18.10.0 | `~/.atuin/bin` | `atuin init bash --disable-up-arrow`. |
| Direnv | 2.35.0 | system | Section 14 hook. |
| Micromamba | 2.3.2 | `~/.local/bin-core/micromamba` | Root `~/.local/share/mamba`. |
| tmux | 3.5a | system | Status-left = `[#{session_name}] ` only. |
| fzf | 0.65.2 | system | Loaded w/ custom palette (section 65 script). |
| zoxide | 0.9.8 | system | Command `z`. |
| bat | 0.25.0 | system | Theme `OneHalfDark`. |
| delta | 0.18.2 | system | Git pager via `~/.gitconfig`. |
| eza | 0.23.4 | `$HOME/.cargo/bin` | CLI palette aligned. |

## 3 — File & Module Architecture [ARCH]
1. **PATH Ordering (enforced in main.sh §2, tested via `tests/rc_load.bats`):**
   1. `~/.local/bin-core`
   2. `~/bin` (symlink → bin-core)
   3. `~/.atuin/bin`
   4. `~/.local/bin`
   5. System paths (unchanged order)
2. **Modular scripts (`~/.bashrc.d/`):** MUST keep numeric prefixes, idempotent logic, and dedicated responsibilities.
   - `30-nvm.sh` — Node auto-switch via `.nvmrc`.
   - `40-command-suggest.sh` — command-not-found helper with alias-aware execution.
   - `45-alias-tips.sh` — reminder via bash-preexec.
   - `50-automation-aliases.sh` — Plasma/SwarmUI/LNbits helpers.
   - `55-kaomoji-status.sh` — ble statusline face.
   - `60-kaomortal.sh` — exports PRISM_* telemetry.
   - `65-fzf-zoxide.sh` — fzf bindings + zoxide + optional Nix completion.
   - `70-dev-tooling.sh` — nvm, micromamba alias, ssh-agent mgmt.
   - `80-sd-profiles.sh` — Stable Diffusion profiles (unchanged).
3. **Main runtime (`~/.config/bash/main.sh`):**
   - Section layout 1–15. Append new features as §16+ with comment headers.
   - `__hb_add_prompt_command` is the sole API for PROMPT_COMMAND manipulation.
   - All `ble-face` invocations redirect to `/dev/null` to guarantee silent startup.

## 4 — Prompt, Line Editing, History Stack [PROMPT]
1. **Primary prompt (Starship):**
   - Active when `[[ -t 0 ]]`, `HB_PURE_BASH=0`, `HB_AGENT_MODE!=machine`, and `HB_DISABLE_STARSHIP!=1`.
   - Format: two-line left prompt (directory, git, jobs, env badge, kaomoji) + right prompt `custom.rclock` for time/⏱.
   - Duration threshold = 700 ms. Narrow terminals (<70 cols) collapse to time only.
2. **Fallback prompt (`__hb_pure_prompt`):**
   - Activated by starship failure, ble absence, `HB_PURE_BASH=1`, non-TTY shells, or machine mode.
   - Output: `pwd` + git state + deterministic emoticon (`:)`/`:(` in machine, kaomoji otherwise).
3. **ble.sh responsibilities:** autosuggest, transient prompt, syntax colours. Only load when interactive TTY and `HB_PROMPT_FORCE_PURE=0`. `HB_DISABLE_BLE_STATUS_LINE=1` keeps statusline off unless kaomoji module re-enables it.
4. **Atuin history overlay:** `atuin init bash --disable-up-arrow` lives in section 11. `Ctrl-R` inserts command directly.
5. **PRISM telemetry (`60-kaomortal.sh`):** exports `PRISM_LAST_STATUS`, `PRISM_CMD_MS`, `PRISM_JOBS`, `PRISM_GIT_DIRTY`, `PRISM_VIMODE`, `PRISM_PIPESTATUS`, etc., feeding both starship and kaomoji modules.

## 5 — Modes, Toggles & Environment Gates [MODES]
- `HB_PURE_BASH=1` ⇒ starship/ble bypass; immediate pure prompt.
- `HB_AGENT_MODE=machine` ⇒ deterministic ASCII output + pure prompt; disables kaomoji randomness.
- `HB_FORCE_INTERACTIVE=1` ⇒ skip the early non-interactive return (used by tests).
- `HB_DISABLE_STARSHIP=1` ⇒ force fallback prompt while leaving ble available.
- Non-interactive shells MUST remain silent (no prompt, colours, or extraneous stdout) and exit normally after bootstrap.
- `stty -ixon` ONLY runs when `stdin` is a TTY to avoid cron/CI failures.

## 6 — Python & Environment Management [PY]
1. **Micromamba:**
   - Root = `$HOME/.local/share/mamba`.
   - Hook executed during bootstrap; environment list cached for selection.
   - Legacy binary archived at `~/lab/_legacy_micromamba/` (read-only).
2. **Python wrapper (main.sh §14):**
   - Interactive TTY calls prompt via `gum choose` (preferred) or `fzf`; selected env stored in `HB_PY_SELECTED_ENV`.
   - Non-TTY calls run inside `HB_PY_BASELINE_ENV` (expected: `comfyui-py312-baseline`). Missing baseline logs to `~/logs/python-wrapper.log` and returns 125.
   - System Python remains accessible with absolute paths (`/usr/bin/python3`, etc.).
3. **direnv:** `eval "$(direnv hook bash)"` executes after python wrapper definitions. Do not relocate.
4. **Alias** `conda` to `micromamba` globally when micromamba exists.

## 7 — Automation Guardrails [SAFE]
1. **Hard Rule:** Never run ad-hoc PTY automation (Python `pty.spawn`, raw `expect`, manual `read` loops) without BOTH:
   - Explicit timeout (`timeout`, `hb-run … [timeout]`, or tmux watchdog script).
   - Teardown logic (`trap`, `finally`, or explicit kill) guaranteeing cleanup even if prompt interaction stalls.
   The previous 10‑hour `pty.spawn` hang is logged as a regression; repeating it violates this charter.
2. **Preferred tooling for automation:**
   - `hb-run SESSION "cmd" [timeout]` for tmux-backed experiments.
   - `~/bin/gpu-telemetry` for GPU metrics.
   - `~/bin/comfyui-report` for queue/system snapshots.
3. **Custom helpers:** Place executable scripts in `~/.local/bin-core`, document usage in `~/.local/bin-core/README.md`, and add tests when feasible. Each helper MUST check arguments, handle errors, and log to `~/logs/<tool>.log` when it mutates state.

## 8 — Palette & CLI Alignment [PAL]
1. **Colour palette (oxide family):**
   - ink `#1f232d`, surface `#2b303b`, surface2 `#353b47`, muted `#7f8ba3`, accent1 `#8caaee`, accent2 `#a6d189`, accent3 `#ef9f76`, ok `#89e5b3`, warn `#e5c890`, bad `#e78284`.
   - Starship, ble, kaomoji output, pure prompt, and CLI theming MUST stay within these tones or 256-colour equivalents.
2. **Shared CLI config (main.sh §15):**
   - `BAT_THEME=OneHalfDark`, `BAT_PAGER="less -R"`.
   - `LESS_TERMCAP_*` sequences export palette-consistent colours.
   - `MANPAGER="sh -c 'col -bx | bat -l man -p'"` (override explicitly if required).
   - `RIPGREP_CONFIG_PATH=$HOME/.config/ripgrep/rg.conf` (pre-seeded with colours), `FD_CONFIG_PATH=$HOME/.config/fd/config`, `EZA_COLORS`, `LS_COLORS` tuned to palette.
3. **Git diff:** `~/.gitconfig` sets `delta` as pager with custom highlights (OneHalfDark derivative). Keep in sync with palette changes.

## 9 — Tooling Baseline & Package Policy [TOOL]
- Maintain availability of: `tmux`, `ble.sh`, `starship`, `direnv`, `micromamba`, `fzf`, `zoxide`, `bat`, `delta`, `eza`, `bpytop`, `nvtop`, `s-tui`, `stress-ng`, `jq`, `Atuin`.
- Install or upgrade system packages via `~/bin/hb-dnf` only. Provide `HB_DNF_PASSWORD` when running unattended; logs stored in `~/logs/dnf`.
- `~/bin` must remain a symlink to `~/.local/bin-core`. Every addition to bin-core MUST be executable, shebang’d, and documented.

## 10 — Reporting, Backups, and Tags [REPORT]
1. **Backups:** For every edited file, copy to `~/backups/<relative-path>.<timestamp>` before writing.
2. **Change log:** Append a one-liner to `~/logs/rc-verify/CHANGELOG.txt` summarising each mutation (timestamp + description).
3. **Run reports:** When concluding work, include (in order): Summary, Scope, Impact Zone, Environment Delta, Checks, Web Sources, Note, Platform Notes. If mutations occurred, also provide sections WHAT CHANGED, STRATEGY & JUSTIFICATION, AESTHETIC CAPSULE, EMERGENT MODULE, ROLLBACK.
4. **Tag defaults:** Scope S4 (Web-Expansive), Approach A8 (Web-Integrated), Novelty per actual contribution (N1–N6), Skin K1 (Hypebrut). Document any deviation and cite user approval.

## 11 — Observability & GPU Operations [OBS]
- GPU sampling: use `~/bin/gpu-telemetry` (supports summary + stream + JSON). Prefer tmux panes over ad-hoc `watch` loops.
- ComfyUI telemetry: `~/bin/comfyui-report` for queue, system stats, recent prompt durations, and live `nvidia-smi` snapshots.
- Launch sustained jobs via `hb-run SESSION "cmd" [timeout]` to keep tmux namespaces organised and avoid orphaned processes.
- Starship/tmux theming MUST not conflict; tmux statusline stays minimal (`[#{session_name}] `) and never mirrors right prompt data.

## 12 — Preservation Appendix (Legacy Mapping) [LEG]
- Old §0 (Authority & Connectivity) → sections [DIR], [INV], [ARCH].
- Old §1 (Shell Baseline) → sections [INV], [ARCH], [PROMPT], [MODES], [PY], [PAL], [TOOL].
- Old §2 (.bashrc Architecture) → section [ARCH].
- Old §3 (Feature Policy) → sections [PROMPT], [MODES], [PY], [SAFE].
- Old §4 (Mutation Model) → section [REPORT].
- Old §5 (Report Format) → section [REPORT].
- Old §6 (Tagging & Footer) → section [REPORT].
- Old §7 (Package & Toolchain Augments) → sections [PAL], [TOOL], [OBS].
- Old §8 (GPU & Queue Ops) → section [OBS].
- Old §9 (Active Run — 2025-10-25) → sections [INV], [SAFE], [TOOL].

---
**Bookmark:** Autonomy context (2025-10-25) remains valid: agent operates solo with sudo + net; `hb-dnf` installed tmux/ShellCheck/shfmt/bats/direnv/fzf/gum/pipx; `uv` installed; Poetry managed by pipx; `.bashrc` delegates to `~/.config/bash/main.sh` with §14 for direnv/python; python wrapper enforces micromamba env safety; micromamba root anchored at `$HOME/.local/share/mamba`; curated `~/.local/bin-core` with README/tests; `make check` runs shfmt + shellcheck + bats; kaomoji line uses `hb-kaomoji-face`. Keep these invariants unless explicitly re-baselined.
