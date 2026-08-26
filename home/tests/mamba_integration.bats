#!/usr/bin/env bats

setup() {
  export HB_FORCE_INTERACTIVE=1
  export HB_DISABLE_STARSHIP=1
}

@test "micromamba env list works" {
  run bash --noprofile --norc -c '. ~/.bashrc >/dev/null 2>&1; micromamba env list >/dev/null'
  [ "$status" -eq 0 ]
}

@test "micromamba activate surfaces env" {
  run bash --noprofile --norc -c '. ~/.bashrc >/dev/null 2>&1; micromamba activate comfyui-py312-baseline >/dev/null && printf "%s" "$CONDA_DEFAULT_ENV"'
  [ "$status" -eq 0 ]
  [ "$output" = "comfyui-py312-baseline" ]
}

@test "micromamba run executes python" {
  run bash --noprofile --norc -c '. ~/.bashrc >/dev/null 2>&1; micromamba run -n comfyui-py312-baseline python -c "import sys;print(sys.version_info.major)"'
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}
