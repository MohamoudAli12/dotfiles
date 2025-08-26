#!/bin/bash

# ^c$var^ = fg color
# ^b$var^ = bg color

interval=0

# load colors
. ~/.config/chadwm/scripts/bar_themes/catppuccin

cpu() {
  cpu_val=$(grep -o "^[^ ]*" /proc/loadavg)

  printf "^c$green^ 󰻠 "
  printf "^c$green^ $cpu_val"
}

pkg_updates() {
  #updates=$({ timeout 20 doas xbps-install -un 2>/dev/null || true; } | wc -l) # void
  updates=$({ timeout 20 checkupdates 2>/dev/null || true; } | sed '/^\s*$/d' | wc -l) # arch
  # updates=$({ timeout 20 aptitude search '~U' 2>/dev/null || true; } | wc -l)  # apt (ubuntu, debian etc)

  if [ "$updates" -eq 0 ]; then
    printf "  ^c$green^    Fully Updated"
  else
    printf "  ^c$red^    $updates"" updates"
  fi
}

battery() {
  # get_capacity="$(cat /sys/class/power_supply/BAT0/capacity)"
  # printf "^c$blue^   $get_capacity"
for battery in /sys/class/power_supply/BAT?*; do
    # If non-first battery, print a space separator.
    [ -n "${capacity+x}" ] && printf " "

    capacity="$(cat "$battery/capacity" 2>&1)"
    if [ "$capacity" -gt 90 ]; then
        status=" "
    elif [ "$capacity" -gt 60 ]; then
        status=" "
    elif [ "$capacity" -gt 40 ]; then
        status=" "
    elif [ "$capacity" -gt 10 ]; then
        status=" "
    else
        status=" "
    fi

    case "$(cat "$battery/status" 2>&1)" in
        Full) status=" " ;;
        Discharging)
            if [ "$capacity" -le 20 ]; then
                status=" $status"
            fi
            ;;
        Charging) status="󰚥 $status" ;;
        "Not charging") status=" " ;;
        Unknown) status="? $status" ;;
        *) exit 1 ;;
    esac

    printf "^c$blue^ $status$capacity%"
done
}

brightness() {
  current="$(cat /sys/class/backlight/*/brightness)"
  max="$(cat /sys/class/backlight/*/max_brightness)"
  percent="$((100 * current / max))"
  printf "^c$red^   "
  printf "^c$red^%d%%\n" "$percent"
}
volume() {
  vol_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  vol_percent=$(echo "$vol_info" | awk '{printf "%d", $2 * 100}')
  is_muted=$(echo "$vol_info" | grep -q MUTED && echo "yes" || echo "no")

  if [ "$is_muted" = "yes" ]; then
    icon="󰝟 "  # Muted icon
  else
    icon=" "  # Volume icon
  fi

  printf "^c$blue^ $icon "
  printf "^c$blue^%s%%\n" "$vol_percent"
}

mem() {
  printf "^c$blue^^b$black^  "
  printf "^c$blue^ $(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)"
}

wlan() {
  case "$(cat /sys/class/net/wl*/operstate 2>/dev/null)" in
  up) printf "^c$green^ 󰤨 ^d^%s" " ^c$green^Connected" ;;
  down) printf "^c$red^ 󰤭 ^d^%s" " ^c$red^Disconnected" ;;
  esac
}

clock() {

  printf "^c$black^ ^b$darkblue^  "
  printf "^c$black^^b$blue^ $(date '+%a %d %b %Y')"
  printf "^c$black^ ^b$darkblue^ 󱑆 "
  printf "^c$black^^b$blue^ $(date '+%H:%M:%S')"
}

while true; do

  [ $interval = 0 ] || [ $(($interval % 120)) = 0 ] && updates=$(pkg_updates)
  interval=$((interval + 1))

  sleep 1 && xsetroot -name "$updates $(battery) $(brightness) $(cpu) $(mem) $(wlan) $(volume) $(clock)"
done
