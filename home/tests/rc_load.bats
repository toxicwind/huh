#!/usr/bin/env bats

setup() {
  export HB_FORCE_INTERACTIVE=1
}

@test "bin-core is first on PATH" {
  export HB_DISABLE_STARSHIP=1
  run bash --noprofile --norc -c '. ~/.bashrc >/dev/null 2>&1; printf "%s" "$PATH"'
  [ "$status" -eq 0 ]
  cleaned=$output
  if [[ $cleaned == /usr/libexec/bats-core:* ]]; then
    cleaned=${cleaned#"/usr/libexec/bats-core:"}
  fi
  first_path=${cleaned%%:*}
  [ "$first_path" = "$HOME/.local/bin-core" ]
  count=$(awk -F: '{n=0; for (i=1; i<=NF; i++) if ($i==ENVIRON["HOME"]"/.local/bin") n++; print n}' <<<"$output")
  [ "$count" -eq 1 ]
}

@test "starship prompt registered once" {
  unset HB_DISABLE_STARSHIP
  run bash --noprofile --norc -c '. ~/.bashrc >/dev/null 2>&1; declare -p PROMPT_COMMAND'
  [ "$status" -eq 0 ]
  occurrences=$(grep -o "__hb_starship_prompt" <<<"$output" | wc -l | tr -d ' ')
  [ "$occurrences" -le 1 ]
}
