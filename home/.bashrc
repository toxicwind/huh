# HypeBrut Bash loader (delegates to ~/.config/bash/main.sh)
# shellcheck shell=bash

HB_BASH_MAIN="${HB_BASH_MAIN:-$HOME/.config/bash/main.sh}"
if [[ -r "$HB_BASH_MAIN" ]]; then
	# shellcheck source=/dev/null
	. "$HB_BASH_MAIN"
else
	echo "warning: missing $HB_BASH_MAIN" >&2
fi
