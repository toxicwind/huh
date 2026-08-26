# Custom automation aliases
# shellcheck shell=bash
: "${PUSH_TO_TALK_BIN:=$HOME/wayland-push-to-talk-fix/push-to-talk}"
: "${SWARMUI_ROOT:=$HOME/sd/SwarmUI}"
: "${LNBITS_HOME:=$HOME/tor-browser/work/lnbits-poetry}"
: "${PGP_TOOL_ROOT:=$HOME/tor-browser/work/pgp_tool}"
: "${PGP_ENV_PREFIX:=$HOME/tor-browser/work/env}"

ptt() {
	"$PUSH_TO_TALK_BIN" -k KEY_LEFTALT -n Alt_L /dev/input/by-id/usb-8BitDo_8BitDo_Retro_Keyboard-if01-event-kbd &
}
comfyui_launch() {
	"$HOME/bin/comfyui-launch" "$@"
}
swarmui_launch() {
	(
		ENV_NAME=${ENV_NAME:-comfyui-py312}
		MAMBA_BIN=${MAMBA_BIN:-$HOME/.local/bin/micromamba}
		cd "$SWARMUI_ROOT" && ./launch-linux.sh "$@"
	)
}
lnbits_start() { bash "$LNBITS_HOME/bin/start" "$@"; }
lnbits_stop() { bash "$LNBITS_HOME/bin/stop" "$@"; }
lnbits_status() { bash "$LNBITS_HOME/bin/status" "$@"; }
pgp_orchestrate() {
	micromamba run -p "$PGP_ENV_PREFIX" bash -lc "cd \"$PGP_TOOL_ROOT\" && python pgp.py"
}
alias pgp-orchestrate='pgp_orchestrate'
alias comfyui-launch='comfyui_launch'
alias swarmui-launch='swarmui_launch'
alias lnbits-start='lnbits_start'
alias lnbits-stop='lnbits_stop'
alias lnbits-status='lnbits_status'

# Plasma desktop helpers
plasma_restart() {
	printf 'Restarting Plasma shell via systemd user service...\n' >&2
	if systemctl --user restart plasma-plasmashell.service >/dev/null 2>&1; then
		return 0
	fi

	local quit_cmd=
	for candidate in kquitapp6 kquitapp5 kquitapp; do
		if command -v "$candidate" >/dev/null 2>&1; then
			quit_cmd=$candidate
			break
		fi
	done
	if [ -n "$quit_cmd" ]; then
		"$quit_cmd" plasmashell >/dev/null 2>&1 || true
	else
		killall plasmashell >/dev/null 2>&1 || true
	fi

	local start_cmd=
	for candidate in kstart6 kstart5 kstart; do
		if command -v "$candidate" >/dev/null 2>&1; then
			start_cmd=$candidate
			break
		fi
	done
	if [ -n "$start_cmd" ]; then
		"$start_cmd" plasmashell >/dev/null 2>&1 &
		if command -v disown >/dev/null 2>&1; then
			disown
		fi
		return 0
	fi

	printf 'plasma_restart: unable to locate kstart binary; plasmashell may need manual restart.\n' >&2
	return 1
}
alias plasmar='plasma_restart'
alias plasma-restart='plasma_restart'
