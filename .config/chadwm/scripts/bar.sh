#!/bin/bash

# ^c$var^ = fg color
# ^b$var^ = bg color

interval=0

# load colors
. ~/.config/chadwm/scripts/bar_themes/catppuccin

# cpu() {
#   cpu_val=$(grep -o "^[^ ]*" /proc/loadavg)
#
#   printf "^c$green^ 󰻠 "
#   printf "^c$green^ $cpu_val"
# }
cpu() {
    # Get the 1-minute load average (can be adjusted to 5 or 15 minutes)
    cpu_load=$(awk '{print $1}' /proc/loadavg)

    # Get the number of CPU cores
    cpu_cores=$(nproc)

    # Calculate the CPU load as a percentage
    load_percentage=$(echo "scale=2; $cpu_load * 100 / $cpu_cores" | bc)

    # Define color thresholds (change these as needed)
    if (( $(echo "$load_percentage > 80" | bc -l) )); then
        color=$red  # Red for high CPU usage
    else
        color=$green  # Green for low CPU usage
    fi

    # Output the CPU load with appropriate color
    printf "^c$color^ 󰻠 $load_percentage%%"
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
        status="^c$green^ "
    elif [ "$capacity" -gt 60 ]; then
        status="^c$green^ "
    elif [ "$capacity" -gt 40 ]; then
        status="^c$green^ "
    elif [ "$capacity" -gt 20 ]; then
        status=" "

    else
        status=" "
    fi

    case "$(cat "$battery/status" 2>&1)" in
        Full) status=" " ;;
        Discharging)
            if [ "$capacity" -le 20 ]; then
                status=" $status"
                notify-send -u critical "Battery Low" "Your battery is running low, please plug in your charger."
            fi
            ;;
        Charging) status="^c$green^󰚥 $status" ;;
        "Not charging") status=" " ;;
        Unknown) status="? $status" ;;
        *) exit 1 ;;
    esac

    printf " $status%d%%" "$capacity"
done
}

brightness() {
  current="$(cat /sys/class/backlight/*/brightness)"
  max="$(cat /sys/class/backlight/*/max_brightness)"
  percent="$((100 * current / max))"
  printf "^c$green^   "
  printf "^c$green^%d%%\n" "$percent"
}
volume() {
  vol_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  vol_percent=$(echo "$vol_info" | awk '{printf "%d", $2 * 100}')
  is_muted=$(echo "$vol_info" | grep -q MUTED && echo "yes" || echo "no")

  if [ "$is_muted" = "yes" ]; then
    icon="^c$red^󰝟 "  # Muted icon
  else
    icon="^c$green^"  # Volume icon
  fi

  printf " $icon "
  printf "^c$green^%s%%\n" "$vol_percent"
}
mic() {
    # Get microphone mute state using wpctl
     MIC_STATE=$(wpctl status | grep -q MUTED && echo "yes" || echo "no")

    if [[ $MIC_STATE == "no" ]]; then
        # If mic is muted, display red icon
        printf "^c$green^  "
        
    else
        # If mic is unmuted, display green icon
        printf "^c$red^ 󰍭 "
    fi
}

mem() {
  # Get total memory and used memory
  total_mem=$(free -h | awk '/^Mem/ { print $2 }' | sed s/i//g)
  used_mem=$(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)
  
  # Calculate the percentage of used memory
  used_percent=$(free | awk '/^Mem/ { print int($3/$2 * 100) }')

  # Set color based on memory usage
  if [ "$used_percent" -gt 85 ]; then
    color="^c$red^"  # Red if above 85%
  else
    color="^c$green^"  # Green if below 85%
  fi

  # Print the memory usage with color
  printf "${color} %s/%s" "$used_mem" "$total_mem"
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

  sleep 1 && xsetroot -name "$updates $(battery) $(brightness) $(cpu) $(mem) $(wlan) $(mic) $(volume) $(clock)"
done
