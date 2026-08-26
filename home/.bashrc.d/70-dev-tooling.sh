# Development tooling helpers (managed by Codex)
# shellcheck shell=bash

# micromamba convenience alias is provided globally
if command -v micromamba >/dev/null 2>&1; then
	alias conda='micromamba'
fi

# Automatically load per-directory Node versions via .nvmrc when available
if [ -n "$NVM_DIR" ] && [ -s "$NVM_DIR/nvm.sh" ]; then
	load_nvmrc() {
		if [ -f .nvmrc ]; then
			nvm use --silent >/dev/null 2>&1 || nvm install
		elif [ "$(nvm current)" != "default" ]; then
			nvm use default >/dev/null 2>&1
		fi
	}
	export -fn load_nvmrc 2>/dev/null || true
	if declare -F __hb_add_prompt_command >/dev/null 2>&1; then
		__hb_add_prompt_command load_nvmrc
	else
		declare -a __hb_pc_fallback=()
		if declare -p PROMPT_COMMAND >/dev/null 2>&1; then
			if [[ $(declare -p PROMPT_COMMAND) == "declare -a"* ]]; then
				__hb_pc_fallback=("${PROMPT_COMMAND[@]}")
			elif [[ -n ${PROMPT_COMMAND:-} ]]; then
				__hb_pc_fallback=("$PROMPT_COMMAND")
			fi
		elif [[ -n ${PROMPT_COMMAND:-} ]]; then
			__hb_pc_fallback=("$PROMPT_COMMAND")
		fi
		declare __hb_entry __hb_found=0
		for __hb_entry in "${__hb_pc_fallback[@]}"; do
			if [[ $__hb_entry == load_nvmrc ]]; then
				__hb_found=1
				break
			fi
		done
		if ((__hb_found == 0)); then
			__hb_pc_fallback+=("load_nvmrc")
			PROMPT_COMMAND=("${__hb_pc_fallback[@]}")
		fi
	fi
fi

# Ensure ssh-agent is running and loads the GitHub key when the shell is interactive.
if [ -z "${CODEX_SSH_AGENT_DISABLED:-}" ] && command -v ssh-agent >/dev/null 2>&1; then
	case "$-" in
	*i*) _codex_manage_ssh_agent=1 ;;
	*) _codex_manage_ssh_agent=0 ;;
	esac

	if [ "$_codex_manage_ssh_agent" -eq 1 ]; then
		if [ -n "$SSH_AUTH_SOCK" ]; then
			if [ ! -S "$SSH_AUTH_SOCK" ] || [ ! -O "$SSH_AUTH_SOCK" ] || [ ! -r "$SSH_AUTH_SOCK" ] || [ ! -w "$SSH_AUTH_SOCK" ]; then
				unset SSH_AUTH_SOCK SSH_AGENT_PID
			elif command -v ssh-add >/dev/null 2>&1; then
				if ! ssh-add -l >/dev/null 2>&1; then
					_codex_ssh_add_status=$?
					if [ "$_codex_ssh_add_status" -eq 2 ]; then
						unset SSH_AUTH_SOCK SSH_AGENT_PID
					fi
				fi
			fi
		fi

		if [ -z "$SSH_AUTH_SOCK" ]; then
			if ssh_agent_info="$(ssh-agent -s 2>/dev/null)" && [ -n "$ssh_agent_info" ]; then
				eval "$ssh_agent_info"
			else
				export CODEX_SSH_AGENT_DISABLED=1
			fi
		fi

		if [ -z "${CODEX_SSH_AGENT_DISABLED:-}" ] && [ -n "$SSH_AUTH_SOCK" ] &&
			command -v ssh-add >/dev/null 2>&1 && [ -f "$HOME/.ssh/id_ed25519" ]; then
			if ! ssh-add -l >/dev/null 2>&1; then
				_codex_ssh_add_status=$?
				if [ "$_codex_ssh_add_status" -eq 1 ]; then
					ssh-add "$HOME/.ssh/id_ed25519" >/dev/null 2>&1 || true
				elif [ "$_codex_ssh_add_status" -eq 2 ]; then
					export CODEX_SSH_AGENT_DISABLED=1
				fi
			fi
		fi
	fi
	unset _codex_manage_ssh_agent _codex_ssh_add_status
fi
