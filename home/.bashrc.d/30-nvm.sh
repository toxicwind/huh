# Node Version Manager integration
# shellcheck shell=bash
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
	# shellcheck source=/dev/null
	. "$NVM_DIR/nvm.sh"
fi
if [ -s "$NVM_DIR/bash_completion" ]; then
	# shellcheck source=/dev/null
	. "$NVM_DIR/bash_completion"
fi
