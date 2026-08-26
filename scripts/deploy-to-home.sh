#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MANIFEST="$ROOT/manifest.txt"
BACKUP_ROOT=${DOTFILES_BACKUP_DIR:-$HOME/.local/share/dotfiles-backups}
STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$STAMP"
LOG(){ printf '[deploy] %s\n' "$*"; }
ERR(){ printf '[deploy][error] %s\n' "$*" >&2; }
trim(){ local str=$1; str=${str#"${str%%[![:space:]]*}"}; str=${str%"${str##*[![:space:]]}"}; printf '%s' "$str"; }
mkdir -p "$BACKUP_DIR"

LOG "backups -> $BACKUP_DIR"

if [[ ! -f $MANIFEST ]]; then
  ERR "manifest not found: $MANIFEST"
  exit 1
fi

while IFS= read -r raw; do
  [[ -z $raw || ${raw:0:1} == '#' ]] && continue
  if [[ $raw == *'->'* ]]; then
    src_rel=$(trim "${raw%%->*}")
    repo_rel=$(trim "${raw#*->}")
  else
    src_rel=$(trim "$raw")
    repo_rel="home/$src_rel"
  fi
  [[ -n $src_rel ]] || continue
  [[ -n $repo_rel ]] || repo_rel="home/$src_rel"
  repo_path="$ROOT/$repo_rel"
  if [[ ! -f $repo_path ]]; then
    ERR "missing repo file: $repo_path"
    continue
  fi
  if [[ $repo_rel != home/* ]]; then
    LOG "skip deploy $repo_rel (non-home mapping)"
    continue
  fi
  rel=${repo_rel#home/}
  dest="$HOME/$rel"
  mkdir -p "$(dirname "$dest")"
  if [[ -f $dest ]]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    cp "$dest" "$BACKUP_DIR/$rel"
    LOG "backup $rel"
  fi
  install -m 644 "$repo_path" "$dest"
  LOG "deployed $rel"
done < "$MANIFEST"

LOG "done"
