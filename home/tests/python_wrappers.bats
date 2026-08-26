#!/usr/bin/env bats

setup() {
  export HB_FORCE_INTERACTIVE=1
  export HB_DISABLE_STARSHIP=1
}

@test "python wrapper honors selected env in TTY mode" {
  export HB_PY_SELECTED_ENV=comfyui-py312-baseline
  run bash --noprofile --norc -c '. ~/.bashrc >/dev/null 2>&1; python -c "import sys; print(sys.prefix)"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"comfyui-py312-baseline"* ]]
}

@test "python wrapper routes non-tty to baseline" {
  unset HB_PY_SELECTED_ENV
  run bash --noprofile --norc -c '. ~/.bashrc >/dev/null 2>&1; python -c "import sys; print(sys.prefix)"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"comfyui-py312-baseline"* ]]
}
