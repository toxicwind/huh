# Kaomoji status line integration for ble.sh
# shellcheck shell=bash

HB_KAOMOJI_BIN="${HB_KAOMOJI_BIN:-$HOME/.local/bin-core/hb-kaomoji-face}"
__hb_kaomoji_face_applied=0

if [[ ${HB_DISABLE_BLE_STATUS_LINE:-0} == 1 || ${HB_PROMPT_FORCE_PURE:-0} == 1 || ${HB_MACHINE_MODE:-0} == 1 ]]; then
	return 0
fi

__hb_kaomoji_status_line() {
	[[ -x $HB_KAOMOJI_BIN ]] || return
	if ! declare -F bleopt >/dev/null 2>&1; then
		return
	fi
	if ((__hb_kaomoji_face_applied == 0)) && declare -F ble-face >/dev/null 2>&1; then
		ble-face prompt_status_line fg=231,bg=240 2>/dev/null || true
		__hb_kaomoji_face_applied=1
	fi
	local face
	face=$("$HB_KAOMOJI_BIN" 2>/dev/null || printf '(・_・)')
	bleopt prompt_status_line=" $face "
}

if declare -F __hb_add_prompt_command >/dev/null 2>&1; then
	__hb_add_prompt_command __hb_kaomoji_status_line
fi
