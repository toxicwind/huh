#!/usr/bin/env bats

BIN_CORE="$HOME/.local/bin-core"

@test "bin-core helpers are executable and discoverable" {
  for file in "$BIN_CORE"/*; do
    [[ -f "$file" ]] || continue
    case "$file" in
      *.md) continue ;;
    esac
    run test -x "$file"
    [ "$status" -eq 0 ]
    head_bytes=$(head -c 2 "$file")
    if [[ "$head_bytes" = "#!" ]]; then
      true
    else
      filetype=$(file -b "$file")
      [[ "$filetype" == ELF* ]] || [[ "$filetype" == *"script"* ]]
    fi
    run command -v "$(basename "$file")"
    [ "$status" -eq 0 ]
  done
}
