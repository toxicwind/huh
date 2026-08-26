#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MANIFEST="$ROOT/manifest.txt"
LOG(){ printf '[update] %s\n' "$*"; }
ERR(){ printf '[update][error] %s\n' "$*" >&2; }
trim(){ local str=$1; str=${str#"${str%%[![:space:]]*}"}; str=${str%"${str##*[![:space:]]}"}; printf '%s' "$str"; }

if [[ ! -f $MANIFEST ]]; then
  ERR "manifest not found: $MANIFEST"
  exit 1
fi

while IFS= read -r raw; do
  [[ -z $raw || ${raw:0:1} == '#' ]] && continue
  if [[ $raw == *'->'* ]]; then
    src_rel=$(trim "${raw%%->*}")
    dest_rel=$(trim "${raw#*->}")
  else
    src_rel=$(trim "$raw")
    dest_rel=""
  fi
  [[ -n $src_rel ]] || continue
  src="$HOME/$src_rel"
  if [[ -n $dest_rel ]]; then
    dest="$ROOT/$dest_rel"
  else
    dest="$ROOT/home/$src_rel"
  fi
  if [[ -f $src ]]; then
    mkdir -p "$(dirname "$dest")"
    rsync -a "$src" "$dest"
    LOG "synced $src_rel -> ${dest#$ROOT/}"
  else
    ERR "missing source: $src"
  fi
done < "$MANIFEST"
