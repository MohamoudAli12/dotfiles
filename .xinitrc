#!/bin/bash

xrdb -merge ~/.Xresources &
#xrandr --output eDP-1 --dpi 192 --scale 1x1
export GDK_SCALE=2
export GDK_DPI_SCALE=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_SCALE_FACTOR=1
export QT_FONT_DPI=192
export ELECTRON_ENABLE_HIGH_DPI_SCALE=1
export ELECTRON_FORCE_DEVICE_SCALE_FACTOR=2

dunst &
# Set idle time to 10 minutes
xset s 600 600
xset dpms 600 600 600
numlockx &
xss-lock ~/myscripts/lock.sh &
~/myscripts/auto_suspend.sh &

~/dotfiles/myscripts/cycle_wall.sh

picom &
~/.config/chadwm/scripts/bar.sh &
while type chadwm >/dev/null; do chadwm && continue || break; done

