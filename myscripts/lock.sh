#!/bin/bash
image="$HOME/dotfiles/lockscreen/grid_lock.png"
if [ -f "$image" ]; then
  i3lock -i "$image" -n -e
else
  i3lock -n -e
fi
