#!/bin/bash

WALL_DIR="$HOME/dotfiles/wall"

# Find and sort images
mapfile -d '' -t WALLS < <(find "$WALL_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) -print0 | sort -z)
TOTAL=${#WALLS[@]}

if [[ $TOTAL -eq 0 ]]; then
  notify-send "No wallpapers found in $WALL_DIR" -t 2000
  exit 1
fi

# File to track current wallpaper index
INDEX_FILE="$HOME/.cache/current_wall_index"

# Load index or start from 0
if [[ -f "$INDEX_FILE" ]]; then
  INDEX=$(<"$INDEX_FILE")
else
  INDEX=0
fi

# Ensure valid index
if (( INDEX < 0 || INDEX >= TOTAL )); then
  INDEX=0
fi

# Get next wallpaper and update index
WALL="${WALLS[$INDEX]}"
NEXT_INDEX=$(( (INDEX + 1) % TOTAL ))
echo "$NEXT_INDEX" > "$INDEX_FILE"

# Set wallpaper
feh --bg-fill "$WALL"

