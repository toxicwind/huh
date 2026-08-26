# bin-core

Curated helper executables live here. `~/.bashrc` ensures this directory is the first
entry on `PATH`, provides a symlink at `~/bin`, and keeps legacy `~/.local/bin` later
for compatibility with package managers.

Rules of the road:
- only checked-in or documented helpers (gpu suite, reto stack, micromamba launcher, etc.).
- scripts must use `/usr/bin/env <lang>` shebangs and be executable.
- no ad-hoc pip installs; prefer `pipx`, `uvx`, or micromamba env shims.
- if an external tool requires a fixed absolute path, leave a one-line shim here pointing
  to the canonical target.
