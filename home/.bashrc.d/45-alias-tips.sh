# Alias usage reminders powered by bash-preexec
# shellcheck shell=bash
if [[ -n ${BASH_VERSION:-} && ${BASH_VERSINFO[0]} -ge 4 ]]; then
	declare -gA __hb_alias_tips_map=()
	declare -gA __hb_alias_tips_seen=()
	__hb_alias_tips_last_dump=""

	__hb_alias_tips_rebuild() {
		local dump
		dump=$(alias)
		if [[ $dump == "$__hb_alias_tips_last_dump" ]]; then
			return
		fi
		__hb_alias_tips_last_dump="$dump"
		__hb_alias_tips_map=()
		local line name body
		while IFS='=' read -r line body; do
			[[ -n $line && $line == alias\ * ]] || continue
			name=${line#alias }
			body=${body#\'}
			body=${body%\'}
			__hb_alias_tips_map["$body"]=$name
		done <<<"$dump"
	}

	__hb_alias_tips_preexec() {
		local entered=$1
		[[ -n $entered ]] || return
		__hb_alias_tips_rebuild

		local trimmed=${entered#"${entered%%[!$' \t']*}"}
		for delim in '|' ';' '&'; do
			trimmed=${trimmed%%"$delim"*}
		done
		trimmed=${trimmed%"${trimmed##*[!$' \t']}"}
		[[ -n $trimmed ]] || return

		if [[ -n ${__hb_alias_tips_map[$trimmed]:-} ]]; then
			local alias_name=${__hb_alias_tips_map[$trimmed]}
			if [[ ${__hb_alias_tips_seen[$alias_name]:-} != "$trimmed" ]]; then
				printf "alias tip: use \`%s\` for \`%s\`\n" "$alias_name" "$trimmed" >&2
				__hb_alias_tips_seen[$alias_name]="$trimmed"
			fi
		fi
	}

	if declare -p preexec_functions >/dev/null 2>&1; then
		:
	else
		declare -ga preexec_functions=()
	fi

	__hb_alias_tips_register_preexec() {
		local fn=$1
		local existing
		for existing in "${preexec_functions[@]}"; do
			if [[ $existing == "$fn" ]]; then
				return
			fi
		done
		preexec_functions+=("$fn")
	}

	__hb_alias_tips_register_preexec __hb_alias_tips_preexec
fi
