#!/usr/bin/env bash
# sd profile + fan aliases
alias sd-rush='gpu-profile apply sd-rush && hb-fan-target 88 && gpu-clocks lock'
alias sd-flow='gpu-profile apply sd-flow && hb-fan-target 78 && gpu-clocks lock'
alias sd-hush='gpu-profile apply sd-hush && hb-fan-target 70 && gpu-clocks reset'
alias sd-auto='sd-profile-suite --manage-clocks --apply'
alias fan-lock='hb-fan-target'
alias fan-auto='sudo -n DISPLAY=${DISPLAY:-:0} XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority} nvidia-settings -a [gpu:0]/GPUFanControlState=0'
