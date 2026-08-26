#!/usr/bin/env bash

# Enable interactive correction suggestions for mistyped commands in Bash.

if [[ -n "${BASH_VERSION:-}" ]]; then
	__cmd_suggest_find_match() {
		local query="$1"
		command -v python3 >/dev/null 2>&1 || return 1
		local suggestion
		suggestion=$(
			compgen -A function -A builtin -A command |
				python3 -c '
import sys
from difflib import get_close_matches

query = sys.argv[1]
seen = set()
ordered = []
for line in sys.stdin:
    word = line.strip()
    if not word or word in seen:
        continue
    seen.add(word)
    ordered.append(word)

match = get_close_matches(query, ordered, n=1, cutoff=0.6)
if match:
    print(match[0])
' "$query"
		)
		[[ -n "$suggestion" ]] || return 1
		printf '%s\n' "$suggestion"
	}

	__cmd_suggest_exec() {
		local suggestion=$1
		shift || true
		local k typeinfo
		typeinfo=$(type -t -- "$suggestion" 2>/dev/null || true)
		[[ -n $typeinfo ]] || return 127

		if [[ $typeinfo == alias ]]; then
			local -a qargs=()
			if (($#)); then
				for k in "$@"; do
					qargs+=("$(printf '%q' "$k")")
				done
			fi
			local cmd="$suggestion"
			if ((${#qargs[@]})); then
				cmd+=" ${qargs[*]}"
			fi
			builtin eval -- "$cmd"
			return $?
		else
			"$suggestion" "$@"
			return $?
		fi
	}

	command_not_found_handle() {
		local missing="$1"
		shift || true

		local suggestion typeinfo=""
		suggestion=$(__cmd_suggest_find_match "$missing")
		if [[ -n $suggestion ]]; then
			typeinfo=$(type -t -- "$suggestion" 2>/dev/null || true)
		fi

		if [[ -n "$suggestion" && -n $typeinfo ]]; then
			printf "Do you mean \`%s\` (closest command)? [Yn]? " "$suggestion" >&2
			local reply input_src=/dev/stdin
			if [[ -t 0 && -r /dev/tty ]]; then
				input_src=/dev/tty
			fi
			IFS= read -r reply <"$input_src"
			reply=${reply:-Y}
			if [[ "$reply" =~ ^[Yy]$ ]]; then
				__cmd_suggest_exec "$suggestion" "$@"
				return $?
			fi
		fi

		printf 'bash: %s: command not found\n' "$missing" >&2
		return 127
	}
fi
