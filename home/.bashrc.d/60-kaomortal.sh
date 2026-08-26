# Kaomortal context export hooks for Bash
# shellcheck shell=bash

# Ensure defaults
export PRISM_VIMODE=${PRISM_VIMODE:-INSERT}
export PRISM_GIT_DIRTY=${PRISM_GIT_DIRTY:-0}
export PRISM_JOBS=${PRISM_JOBS:-0}
export PRISM_LAST_STATUS=${PRISM_LAST_STATUS:-0}
export PRISM_CMD_MS=${PRISM_CMD_MS:-0}
PRISM_SSH=$([[ -n ${SSH_CONNECTION:-} ]] && echo 1 || echo 0)
export PRISM_SSH
export PRISM_IS_ROOT=$((${EUID:-$(id -u)} == 0 ? 1 : 0))
PRISM_MAMBA_HOOK=$([[ -n ${MAMBA_EXE:-} ]] && echo 1 || echo 0)
export PRISM_MAMBA_HOOK

prism__epoch_ns() {
	local er=${EPOCHREALTIME:-} sec frac
	if [[ -n $er ]]; then
		if [[ $er == *.* ]]; then
			sec=${er%%.*}
			frac=${er#*.}
		else
			sec=$er
			frac=0
		fi
		frac=${frac//[^0-9]/}
		while [[ ${#frac} -lt 6 ]]; do
			frac="${frac}0"
		done
		frac=${frac:0:6}
		REPLY="${sec}${frac}000"
		return
	fi

	if command -v date >/dev/null 2>&1; then
		REPLY=$(date +%s%N 2>/dev/null || date +%s000000000)
	else
		REPLY=0
	fi
}

# Capture start time using portable EPOCHREALTIME-derived helper
prism_preexec() {
	prism__epoch_ns
	PRISM_CMD_START_NS=$REPLY
}

prism_precmd() {
	local last_status=$?
	export PRISM_LAST_STATUS=$last_status

	local jobs_count
	jobs_count=$(jobs -p 2>/dev/null | wc -l | tr -d ' ')
	export PRISM_JOBS=${jobs_count:-0}

	if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		if git status --porcelain -uno --ignore-submodules=dirty 2>/dev/null | head -n1 | grep -q .; then
			export PRISM_GIT_DIRTY=1
		else
			export PRISM_GIT_DIRTY=0
		fi
	else
		export PRISM_GIT_DIRTY=0
	fi

	if [[ -n ${PRISM_CMD_START_NS:-} ]]; then
		prism__epoch_ns
		local now_ns=$REPLY
		local diff_ns=$((now_ns - PRISM_CMD_START_NS))
		if ((diff_ns < 0)); then diff_ns=0; fi
		export PRISM_CMD_MS=$((diff_ns / 1000000))
	else
		export PRISM_CMD_MS=0
	fi

	PRISM_SSH=$([[ -n ${SSH_CONNECTION:-} ]] && echo 1 || echo 0)
	export PRISM_SSH
	export PRISM_IS_ROOT=$((${EUID:-$(id -u)} == 0 ? 1 : 0))
	PRISM_MAMBA_HOOK=$([[ -n ${MAMBA_EXE:-} ]] && echo 1 || echo 0)
	export PRISM_MAMBA_HOOK
	local pipestatus_value=0
	if [[ -n ${PIPESTATUS[*]:-} ]]; then
		local ps
		for ps in "${PIPESTATUS[@]}"; do
			if ((ps != 0)); then
				pipestatus_value=1
				break
			fi
		done
	fi
	export PRISM_PIPESTATUS=$pipestatus_value
}

# Register with bash-preexec if available; otherwise attach to traps
if declare -p preexec_functions >/dev/null 2>&1; then
	if ! [[ " ${preexec_functions[*]} " == *" prism_preexec "* ]]; then
		preexec_functions+=(prism_preexec)
	fi
else
	declare -ga preexec_functions=(prism_preexec)
fi

if declare -p precmd_functions >/dev/null 2>&1; then
	if ! [[ " ${precmd_functions[*]} " == *" prism_precmd "* ]]; then
		precmd_functions+=(prism_precmd)
	fi
else
	declare -ga precmd_functions=(prism_precmd)
fi

# Fallback: ensure PROMPT_COMMAND triggers even if bash-preexec not active
if ! [[ ${PROMPT_COMMAND:-} == *prism_precmd* ]]; then
	if declare -F __hb_add_prompt_command >/dev/null 2>&1; then
		__hb_add_prompt_command prism_precmd prepend
	else
		PROMPT_COMMAND=${PROMPT_COMMAND:+prism_precmd; $PROMPT_COMMAND}
	fi
fi
