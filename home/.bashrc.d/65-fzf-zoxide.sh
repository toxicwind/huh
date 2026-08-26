# fzf, zoxide, and Nix integration layer
# shellcheck shell=bash

if [[ $- != *i* ]]; then
	return 0
fi

# fzf key bindings + completion
if command -v fzf >/dev/null 2>&1; then
	for dir in /usr/share/fzf /usr/share/doc/fzf/examples "$HOME/.local/share/fzf" "$HOME/.fzf"; do
		if [[ -f "$dir/key-bindings.bash" ]]; then
			# shellcheck source=/dev/null
			. "$dir/key-bindings.bash"
			break
		fi
	done
	for dir in /usr/share/fzf /usr/share/doc/fzf/examples "$HOME/.local/share/fzf" "$HOME/.fzf"; do
		if [[ -f "$dir/completion.bash" ]]; then
			# shellcheck source=/dev/null
			. "$dir/completion.bash"
			break
		fi
	done
	oxide_palette='bg+:#3a404f,bg:#2b303b,spinner:#a6d189,hl:#e5c890,fg:#c6d0f5,header:#81c8be,info:#8caaee,pointer:#ef9f76,marker:#e78284,fg+:#e5e9ff,prompt:#a6d189,hl+:#ef9f76'
	if [[ -n ${FZF_DEFAULT_OPTS:-} ]]; then
		export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --height=40% --layout=reverse --border=rounded --color=$oxide_palette"
	else
		export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded --color=$oxide_palette"
	fi
fi
unset oxide_palette

# zoxide smart cd
if command -v zoxide >/dev/null 2>&1; then
	# shellcheck disable=SC1090
	eval "$(zoxide init bash --cmd z)"
fi

# Optional Nix completions (conditional load)
_hb_nix_completion_files=(
	"$HOME/.nix-profile/share/bash-completion/completions/nix"
	"/nix/var/nix/profiles/default/etc/bash_completion.d/nix"
	"/etc/bash_completion.d/nix"
)
for comp in "${_hb_nix_completion_files[@]}"; do
	if [[ -f $comp ]]; then
		# shellcheck source=/dev/null
		. "$comp"
		break
	fi
done
unset _hb_nix_completion_files comp
