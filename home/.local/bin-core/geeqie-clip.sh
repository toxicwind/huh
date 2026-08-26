#!/usr/bin/env bash
set -euo pipefail
unset BASH_ENV

file=${1:-}
[[ -n $file ]] || {
	echo "geeqie-clip: usage: geeqie-clip.sh <image>" >&2
	exit 1
}
[[ -f $file ]] || {
	echo "geeqie-clip: missing file: $file" >&2
	exit 2
}
command -v wl-copy >/dev/null 2>&1 || {
	echo "geeqie-clip: wl-copy not found" >&2
	exit 3
}

mime=$(file -b --mime-type -- "$file" 2>/dev/null || echo application/octet-stream)
copy=(wl-copy --paste-once --type "$mime")

icon_default="$HOME/.local/share/icons/hypebrut-copy.png"
if [[ -n ${GEEQIE_CLIP_ICON:-} ]]; then
	GEEQIE_CLIP_ICON_PATH=$GEEQIE_CLIP_ICON
elif [[ -f $icon_default ]]; then
	GEEQIE_CLIP_ICON_PATH=$icon_default
else
	GEEQIE_CLIP_ICON_PATH=""
fi

if command -v timeout >/dev/null 2>&1; then
	timeout 3s "${copy[@]}" <"$file" || {
		echo "geeqie-clip: wl-copy timed out" >&2
		exit 4
	}
else
	"${copy[@]}" <"$file" || {
		echo "geeqie-clip: wl-copy failed" >&2
		exit 4
	}
fi

basename=$(basename -- "$file")
notify() {
	local title=$1
	local body=$2
	local timeout_ms=${GEEQIE_CLIP_NOTIFY_MS:-2200}
	local timeout_s=$(((timeout_ms + 999) / 1000))
	local icon=${GEEQIE_CLIP_ICON_PATH:-}
	if command -v qdbus6 >/dev/null 2>&1; then
		qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications.Notify \
			"Geeqie Clipboard" 0 "${icon}" "$title" "$body" [] {} "$timeout_ms" >/dev/null 2>&1 && return 0
	fi
	if command -v qdbus >/dev/null 2>&1; then
		qdbus org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications.Notify \
			"Geeqie Clipboard" 0 "${icon}" "$title" "$body" [] {} "$timeout_ms" >/dev/null 2>&1 && return 0
	fi
	if command -v kdialog >/dev/null 2>&1; then
		if [[ -n $icon && -f $icon ]]; then
			kdialog --passivepopup "$title: $body" "$timeout_s" --title "Geeqie Clipboard" --icon "$icon" >/dev/null 2>&1 && return 0
		else
			kdialog --passivepopup "$title: $body" "$timeout_s" --title "Geeqie Clipboard" >/dev/null 2>&1 && return 0
		fi
	fi
	return 1
}

notify "Image copied" "$basename" || {
	echo "geeqie-clip: failed to show notification" >&2
	exit 5
}
