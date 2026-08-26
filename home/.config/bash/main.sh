# HypeBrut max-level Bash runtime (refit 2025-10-25)
# shellcheck shell=bash

# 1. System defaults -------------------------------------------------------
if [[ -r /etc/bashrc ]]; then
	# shellcheck source=/dev/null
	. /etc/bashrc
fi

# 2. Deterministic PATH hygiene --------------------------------------------
__hb_prepend_path() {
	local dir=$1
	[[ -n $dir && -d $dir ]] || return
	case ":$PATH:" in
	*:"$dir":*) ;;
	*) PATH="$dir:${PATH}" ;;
	esac
}

__hb_force_path_front() {
	local dir=$1
	[[ -n $dir && -d $dir ]] || return
	local scoped=":$PATH:"
	scoped=${scoped//:$dir:/:}
	scoped=${scoped#:}
	scoped=${scoped%:}
	if [[ -n $scoped ]]; then
		PATH="$dir:$scoped"
	else
		PATH="$dir"
	fi
}

HB_BIN_CORE="$HOME/.local/bin-core"
HB_ATUIN_BIN="$HOME/.atuin/bin"
__hb_prepend_path "$HOME/.local/bin"
if [[ -f "$HB_ATUIN_BIN/env" ]]; then
	# shellcheck source=/dev/null
	. "$HB_ATUIN_BIN/env"
fi
__hb_prepend_path "$HB_ATUIN_BIN"
__hb_prepend_path "$HOME/bin"
__hb_prepend_path "$HB_BIN_CORE"

__hb_force_path_front "$HOME/.local/bin"
__hb_force_path_front "$HB_ATUIN_BIN"
__hb_force_path_front "$HOME/bin"
__hb_force_path_front "$HB_BIN_CORE"

export PATH
unset -f __hb_prepend_path __hb_force_path_front

: "${STARSHIP_SESSION_KEY:=hb-$(date +%s%N)}"
export STARSHIP_SESSION_KEY

if command -v micromamba >/dev/null 2>&1; then
	export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-$HOME/.local/share/mamba}"
	__hb_mamba_exe_path="$(command -v micromamba)"
	export MAMBA_EXE="$__hb_mamba_exe_path"
	__hb_mamba_hook_output="$($MAMBA_EXE shell hook --shell=bash 2>/dev/null || true)"
	if [[ -n $__hb_mamba_hook_output ]]; then
		eval "$__hb_mamba_hook_output"
	fi
fi
unset __hb_mamba_hook_output
unset __hb_mamba_exe_path

if command -v micromamba >/dev/null 2>&1 && micromamba env list 2>/dev/null | grep -q 'comfyui-py312-baseline'; then
	export HB_PY_BASELINE_ENV="comfyui-py312-baseline"
else
	export HB_PY_BASELINE_ENV=""
fi
export HB_BIN_CORE HB_ATUIN_BIN

# 2a. Session + mode toggles ------------------------------------------------
: "${HB_PURE_BASH:=0}"
HB_MACHINE_MODE=0
if [[ ${HB_AGENT_MODE:-} == machine ]]; then
	HB_MACHINE_MODE=1
fi
if [[ -t 0 && -t 1 ]]; then
	HB_INTERACTIVE_TTY=1
else
	HB_INTERACTIVE_TTY=0
fi
export HB_MACHINE_MODE HB_INTERACTIVE_TTY HB_PURE_BASH

__hb_force_pure_prompt=0
if ((HB_MACHINE_MODE)); then
	__hb_force_pure_prompt=1
fi
if ((HB_INTERACTIVE_TTY == 0)); then
	__hb_force_pure_prompt=1
fi

HB_BLE_RUNTIME="${HB_BLE_RUNTIME:-$HOME/.local/share/blesh/ble.sh}"
if [[ ! -f $HB_BLE_RUNTIME ]]; then
	__hb_force_pure_prompt=1
fi
export HB_BLE_RUNTIME

# 3. Non-interactive shells bail early ------------------------------------
if [[ -z ${HB_FORCE_INTERACTIVE:-} ]]; then
	case "$-" in
	*i*) ;;
	*) return ;;
	esac
fi

# 4. Shell behaviour knobs -------------------------------------------------
shopt -s histappend
shopt -s checkwinsize
shopt -s extglob
shopt -s globstar
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE='ls:ll:ls -a:bg:fg:history:exit'
PROMPT_DIRTRIM=3
if [[ -t 0 ]]; then
	stty -ixon >/dev/null 2>&1 || true
fi

# 5. Prompt command management --------------------------------------------
__hb_add_prompt_command() {
	local fn=$1
	local mode=${2:-append}
	[[ -n $fn ]] || return 1

	local -a __hb_pc=()
	if declare -p PROMPT_COMMAND &>/dev/null; then
		if [[ $(declare -p PROMPT_COMMAND) == "declare -a"* ]]; then
			__hb_pc=("${PROMPT_COMMAND[@]}")
		elif [[ -n ${PROMPT_COMMAND:-} ]]; then
			__hb_pc=("$PROMPT_COMMAND")
		fi
	fi

	local existing
	for existing in "${__hb_pc[@]}"; do
		[[ $existing == "$fn" ]] && return 0
	done

	if [[ $mode == prepend ]]; then
		__hb_pc=("$fn" "${__hb_pc[@]}")
	else
		__hb_pc+=("$fn")
	fi

	if ((${#__hb_pc[@]})); then
		PROMPT_COMMAND=("${__hb_pc[@]}")
	else
		unset PROMPT_COMMAND
	fi
}

__hb_remove_function_from_array() {
	local array_name=$1 target=$2
	[[ -n $array_name && -n $target ]] || return 0
	if declare -p "$array_name" &>/dev/null && [[ $(declare -p "$array_name") == "declare -a"* ]]; then
		local -n __hb_array_ref="$array_name"
		local __hb_entry
		local -a __hb_new=()
		for __hb_entry in "${__hb_array_ref[@]}"; do
			[[ $__hb_entry == "$target" ]] || __hb_new+=("$__hb_entry")
		done
		__hb_array_ref=("${__hb_new[@]}")
	fi
}

__hb_disable_starship_prompt() {
	__hb_remove_function_from_array precmd_functions starship_precmd
	__hb_remove_function_from_array preexec_functions starship_preexec
	unset -f starship_precmd 2>/dev/null || true
	unset -f starship_preexec 2>/dev/null || true
	local -a __hb_pc=()
	if declare -p PROMPT_COMMAND &>/dev/null; then
		if [[ $(declare -p PROMPT_COMMAND) == "declare -a"* ]]; then
			__hb_pc=("${PROMPT_COMMAND[@]}")
		elif [[ -n ${PROMPT_COMMAND:-} ]]; then
			__hb_pc=("$PROMPT_COMMAND")
		fi
	fi
	if ((${#__hb_pc[@]})); then
		local __hb_entry
		local -a __hb_filtered=()
		for __hb_entry in "${__hb_pc[@]}"; do
			[[ $__hb_entry == *starship_precmd* ]] || __hb_filtered+=("$__hb_entry")
		done
		if ((${#__hb_filtered[@]})); then
			PROMPT_COMMAND=("${__hb_filtered[@]}")
		else
			unset PROMPT_COMMAND
		fi
	fi
}

__hb_disable_starship_prompt

# 6. Git status helpers ----------------------------------------------------
if [[ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]]; then
	# shellcheck source=/dev/null
	. /usr/share/git-core/contrib/completion/git-prompt.sh
fi
if [[ -f /usr/share/git-core/contrib/completion/git-completion.bash ]]; then
	# shellcheck source=/dev/null
	. /usr/share/git-core/contrib/completion/git-completion.bash
fi
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUPSTREAM=auto
export GIT_PS1_SHOWCOLORHINTS=1

# 7. Bash completion baseline ----------------------------------------------
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
	# shellcheck source=/dev/null
	. /usr/share/bash-completion/bash_completion
fi

# 8. Cargo env for Rust toolchains -----------------------------------------
if [[ -f "$HOME/.cargo/env" ]]; then
	# shellcheck source=/dev/null
	. "$HOME/.cargo/env"
fi

# 9. Preexec / prompts ------------------------------------------------------
if [[ -f "$HOME/.local/share/bash-preexec/bash-preexec.sh" ]]; then
	# shellcheck source=/dev/null
	. "$HOME/.local/share/bash-preexec/bash-preexec.sh"
fi

# 10. Prompt orchestration (starship or fallback) --------------------------
__hb_use_starship=0
if command -v starship >/dev/null 2>&1 && [[ ${HB_DISABLE_STARSHIP:-0} != 1 ]] && ((HB_INTERACTIVE_TTY == 1)); then
	__hb_use_starship=1
fi

if ((!__hb_use_starship)); then
	__hb_force_pure_prompt=1
fi
if [[ ${HB_PURE_BASH:-0} == 1 ]]; then
	__hb_force_pure_prompt=1
fi

__hb_activate_pure_prompt_runtime() {
	__hb_force_pure_prompt=1
	export HB_PROMPT_FORCE_PURE=1
	__hb_disable_starship_prompt
	if [[ ${__hb_pure_prompt_hooked:-0} == 1 ]]; then
		__hb_pure_prompt
		return
	fi
	__hb_add_prompt_command __hb_pure_prompt prepend
	__hb_pure_prompt
	__hb_pure_prompt_hooked=1
}

__hb_starship_prompt() {
	local last_status=$?
	if [[ ${HB_AGENT_MODE:-} == machine ]] && ((HB_MACHINE_MODE == 0)); then
		HB_MACHINE_MODE=1
		export HB_MACHINE_MODE
		__hb_force_pure_prompt=1
	fi
	if ((!__hb_use_starship)) || [[ ${HB_PURE_BASH:-0} == 1 ]] || ((__hb_force_pure_prompt)); then
		__hb_activate_pure_prompt_runtime
		return
	fi
	local prompt
	# shellcheck disable=SC2097,SC2098
	if ! prompt=$(STARSHIP_SHELL=bash \
		STARSHIP_SHELL_VERSION="${BASH_VERSION}" \
		STARSHIP_SESSION_KEY="$STARSHIP_SESSION_KEY" \
		STARSHIP_CMD_DURATION_MS="${PRISM_CMD_MS:-0}" \
		STARSHIP_JOBS="${PRISM_JOBS:-0}" \
		STARSHIP_STATUS="${PRISM_LAST_STATUS:-$last_status}" \
		STARSHIP_PIPE_STATUS="${PRISM_PIPESTATUS:-0}" \
		PRISM_LAST_STATUS="${PRISM_LAST_STATUS:-$last_status}" \
		PRISM_JOBS="${PRISM_JOBS:-0}" \
		PRISM_CMD_MS="${PRISM_CMD_MS:-0}" \
		PRISM_PIPESTATUS="${PRISM_PIPESTATUS:-0}" \
		starship prompt 2>/dev/null); then
		__hb_activate_pure_prompt_runtime
		return
	fi
	if [[ -z $prompt ]]; then
		__hb_activate_pure_prompt_runtime
		return
	fi
	PS1="$prompt"
}

__hb_pure_prompt() {
	local exit_code=${__bp_last_ret_value:-$?}
	local face_ok="(＾_＾)"
	local face_warn="(・_・;)"
	local face_fail="(×_×)"
	local face="$face_ok"
	if ((exit_code != 0)); then
		face=$face_fail
	elif ((${PRISM_GIT_DIRTY:-0})); then
		face=$face_warn
	fi
	if ((HB_MACHINE_MODE)) || [[ ${HB_AGENT_MODE:-} == machine ]]; then
		if ((exit_code == 0)); then
			face=":)"
		else
			face=":("
		fi
	fi

	local git_segment=""
	if declare -F __git_ps1 >/dev/null 2>&1; then
		git_segment=$(__git_ps1 ' ‹%s›')
	fi

	local dir_color='\[\e[38;5;110m\]'
	local git_color='\[\e[38;5;146m\]'
	local face_color='\[\e[38;5;117m\]'
	if ((HB_MACHINE_MODE)); then
		dir_color=''
		git_color=''
		face_color=''
	fi

	PS1="${dir_color}\w${git_color}${git_segment}\[\e[0m\] ${face_color}${face}\[\e[0m\] "
}

if ((__hb_force_pure_prompt == 0)); then
	export HB_DISABLE_BLE_STATUS_LINE=1
	export HB_PROMPT_FORCE_PURE=0
	__hb_add_prompt_command __hb_starship_prompt prepend
else
	unset HB_DISABLE_BLE_STATUS_LINE
	__hb_activate_pure_prompt_runtime
fi

# 11. History overlay (Atuin) ----------------------------------------------
if command -v atuin >/dev/null 2>&1; then
	eval "$(atuin init bash --disable-up-arrow)"
fi

# 12. Modular shell snippets ------------------------------------------------
if [[ -d "$HOME/.bashrc.d" ]]; then
	while IFS= read -r -d '' rc; do
		# shellcheck source=/dev/null
		. "$rc"
	done < <(find "$HOME/.bashrc.d" -maxdepth 1 -type f -name '*.sh' -print0 | sort -z)
	unset rc
fi

# 13. ble.sh line editor ----------------------------------------------------
if [[ ${HB_PROMPT_FORCE_PURE:-0} != 1 && -t 0 && -f "$HB_BLE_RUNTIME" ]]; then
	# shellcheck source=/dev/null
	. "$HB_BLE_RUNTIME" --noattach
	if declare -F bleopt >/dev/null 2>&1; then
		bleopt exec_restore_pipestatus=1
		bleopt prompt_status_line='' 2>/dev/null || true
		bleopt prompt_rps1='' 2>/dev/null || true
		bleopt prompt_ps1_transient='same-dir:trim' 2>/dev/null || true
	fi
	if declare -F ble-attach >/dev/null 2>&1; then
		ble-attach
	fi
	if declare -F ble-face >/dev/null 2>&1; then
		ble-face prompt_line fg=252 >/dev/null 2>&1 || true
		ble-face syntax_default fg=252 >/dev/null 2>&1 || true
		ble-face syntax_command fg=110 >/dev/null 2>&1 || true
		ble-face syntax_quotation fg=180 >/dev/null 2>&1 || true
		ble-face syntax_escape fg=214 >/dev/null 2>&1 || true
		ble-face syntax_error fg=197,bold >/dev/null 2>&1 || true
		ble-face command_builtin fg=110 >/dev/null 2>&1 || true
		ble-face command_alias fg=146 >/dev/null 2>&1 || true
		ble-face command_file fg=152 >/dev/null 2>&1 || true
	fi
fi

# 14. Direnv + Python safeguarding -----------------------------------------
__hb_python_env_cache=()
__hb_python_env_menu() {
	local raw
	raw=$(micromamba env list --json 2>/dev/null) || return 1
	mapfile -t __hb_python_env_cache < <(
		HB_MAMBA_ENV_JSON="$raw" python3 - <<'PY'
import json, os
home = os.path.expanduser('~')
data = json.loads(os.environ['HB_MAMBA_ENV_JSON'])
for env in data.get('envs', []):
    if env == os.path.join(home, '.local', 'share', 'mamba'):
        print('base:' + env)
    elif env.startswith(os.path.join(home, '.local', 'share', 'mamba', 'envs') + os.sep):
        print(env.rsplit('/', 1)[-1] + ':' + env)
    else:
        print(env + ':' + env)
PY
	)
}

__hb_select_python_env() {
	[[ ${#__hb_python_env_cache[@]} -gt 0 ]] || __hb_python_env_menu || return 1
	local choice
	local display=()
	local line idx=0
	for line in "${__hb_python_env_cache[@]}"; do
		local name=${line%%:*}
		local path=${line#*:}
		display[idx]="$name :: $path"
		((idx++))
	done
	if command -v gum >/dev/null 2>&1; then
		choice=$(printf '%s\n' "${display[@]}" | gum choose --header "Select micromamba env for python") || return 1
	elif command -v fzf >/dev/null 2>&1; then
		choice=$(printf '%s\n' "${display[@]}" | fzf --prompt="micromamba env> " --height=40%) || return 1
	else
		PS3="micromamba env #? "
		select choice in "${display[@]}"; do
			[[ -n $choice ]] && break
		done || return 1
	fi
	local selected=${choice%% ::*}
	HB_PY_SELECTED_ENV="$selected"
	export HB_PY_SELECTED_ENV
}

__hb_log_python_event() {
	mkdir -p "$HOME/logs"
	printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >>"$HOME/logs/python-wrapper.log"
}

__hb_python_dispatch() {
	local bin=$1
	shift
	local baseline=${HB_PY_BASELINE_ENV:-}
	local is_tty=0
	if [[ -t 0 && -t 1 ]]; then
		is_tty=1
	fi
	if ((is_tty)); then
		if [[ -z ${HB_PY_SELECTED_ENV:-} ]]; then
			__hb_select_python_env || {
				echo "python wrapper: selection aborted" >&2
				return 125
			}
		fi
		micromamba run -n "$HB_PY_SELECTED_ENV" "$bin" "$@"
	else
		if [[ -n $baseline ]]; then
			micromamba run -n "$baseline" "$bin" "$@"
		else
			__hb_log_python_event "no-baseline:$bin $*"
			echo "python wrapper: no baseline env configured" >&2
			return 125
		fi
	fi
}

python() { __hb_python_dispatch python "$@"; }
pip() { __hb_python_dispatch pip "$@"; }

if command -v direnv >/dev/null 2>&1; then
	eval "$(direnv hook bash)"
fi

# 15. Toolchain harmony palette --------------------------------------------
if [[ ${HB_TOOLCHAIN_PALETTE_APPLIED:-0} != 1 ]]; then
	export HB_TOOLCHAIN_PALETTE_APPLIED=1
	export BAT_THEME="${BAT_THEME:-OneHalfDark}"
	export BAT_PAGER="less -R"
	export LESS=${LESS:--R}
	export LESS_TERMCAP_mb=$'\e[38;5;208m'
	export LESS_TERMCAP_md=$'\e[38;5;110m'
	export LESS_TERMCAP_me=$'\e[0m'
	export LESS_TERMCAP_se=$'\e[0m'
	export LESS_TERMCAP_so=$'\e[48;5;240m\e[38;5;252m'
	export LESS_TERMCAP_ue=$'\e[0m'
	export LESS_TERMCAP_us=$'\e[38;5;146m'
	export MANPAGER="${MANPAGER:-sh -c 'col -bx | bat -l man -p'}"
	export RIPGREP_CONFIG_PATH="${RIPGREP_CONFIG_PATH:-$HOME/.config/ripgrep/rg.conf}"
	export FD_CONFIG_PATH="${FD_CONFIG_PATH:-$HOME/.config/fd/config}"
	export LS_COLORS="${LS_COLORS:-di=38;5;110:ln=38;5;146:ex=38;5;117:*.md=38;5;146:*.sh=38;5;180}"
	export EZA_COLORS="${EZA_COLORS:-da=38;5;110:gm=38;5;180:tr=38;5;146:ex=1;38;5;117:ln=38;5;146}"
fi

# 16. History synchronization ----------------------------------------------
__hb_history_sync() {
	((HB_INTERACTIVE_TTY == 1)) || return 0
	builtin history -a
	builtin history -n
}

if [[ $- == *i* ]] && ((HB_INTERACTIVE_TTY == 1)) && declare -F __hb_add_prompt_command >/dev/null 2>&1; then
	builtin history -n
	__hb_add_prompt_command __hb_history_sync
fi
