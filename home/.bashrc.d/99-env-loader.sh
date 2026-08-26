# .env loader - extends paths, never overwrites
# shellcheck shell=bash

ENV_FILE="${ENV_FILE:-/mnt/agents/.env}"
if [[ -r "$ENV_FILE" ]]; then
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^# ]] && continue
        [[ -z "$key" ]] && continue
        export "$key=$value"
    done < "$ENV_FILE"
fi

# Extend LD_LIBRARY_PATH safely
if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
    export LD_LIBRARY_PATH="/mnt/agents/dot/lib:/mnt/agents/lib:${LD_LIBRARY_PATH}"
else
    export LD_LIBRARY_PATH="/mnt/agents/dot/lib:/mnt/agents/lib"
fi

# Extend PATH safely
__hb_prepend_path() {
    local dir=$1
    [[ -n $dir && -d $dir ]] || return
    case ":$PATH:" in
    *:"$dir":*) ;;
    *) PATH="$dir:${PATH}" ;;
    esac
}
__hb_prepend_path "/mnt/agents/bin"
__hb_prepend_path "/mnt/agents/dot/bin"
unset -f __hb_prepend_path
