#!/bin/bash

# ^c$var^ = fg color
# ^b$var^ = bg color
pink="#f5c2e7" #volume color
muave="#cba6f7" #brightness color
red="#f38ba8"
yellow="#f9e2af" #updates
maroon="#eba0ac"
peach="#fab387" #memory
green="#a6e3a1"
teal="#94e2d5" #wlan connection
sapphire="#74c7ec" #cpu color
lavender="#b4befe" #calendar and time
blue="#96CDFB"
interval=0


# load colors
. ~/.config/chadwm/scripts/bar_themes/catppuccin

cpu() {
    # Get the 1-minute load average (can be adjusted to 5 or 15 minutes)
    cpu_load=$(awk '{print $1}' /proc/loadavg)

    # Get the number of CPU cores
    cpu_cores=$(nproc)

    # Calculate the CPU load as a percentage
    load_percentage=$(echo "scale=2; $cpu_load * 100 / $cpu_cores" | bc)

    # Define color thresholds (change these as needed)
    if (( $(echo "$load_percentage > 80" | bc -l) )); then
        color=$red  # red for high CPU usage
    else
        color=$sapphire  # green for low CPU usage
    fi

    # Output the CPU load with appropriate color
    printf "^c$color^ 󰻠 $load_percentage%% "
}

pkg_updates() {
  #updates=$({ timeout 20 doas xbps-install -un 2>/dev/null || true; } | wc -l) # void
  updates=$({ timeout 20 checkupdates 2>/dev/null || true; } | sed '/^\s*$/d' | wc -l) # arch
  # updates=$({ timeout 20 aptitude search '~U' 2>/dev/null || true; } | wc -l)  # apt (ubuntu, debian etc)

  if [ "$updates" -eq 0 ]; then
    printf "  ^c$yellow^    Fully Updated"
  else
    printf "  ^c$red^    $updates updates"
  fi
}
battery() {
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
        status="^c$green^ "

    else
        status=" "
    fi

    case "$(cat "$battery/status" 2>&1)" in
        Full) status="^c$green^ " ;;
        Discharging)
            if [ "$capacity" -le 20 ]; then
                status="^c$red^ $status"
                notify-send -u critical "Battery Low" "Your battery is running low, please plug in your charger."
            fi
            ;;
        Charging) status="^c$green^󰚥 $status" ;;
        "Not charging") status="^c$red^ " ;;
        Unknown) status="^c$red^? $status" ;;
        *) exit 1 ;;
    esac

    printf " $status "
done
}
brightness() {
  current="$(cat /sys/class/backlight/*/brightness)"
  max="$(cat /sys/class/backlight/*/max_brightness)"
  percent="$((100 * current / max))"
  printf "^c$muave^   "
  printf "^c$muave^%d%% " "$percent"
}
volume() {
  vol_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  vol_percent=$(echo "$vol_info" | awk '{printf "%d", $2 * 100}')
  is_muted=$(echo "$vol_info" | grep -q MUTED && echo "yes" || echo "no")


  # If muted, set the muted icon
  if [ "$is_muted" = "yes" ]; then
    icon="^c$pink^󰝟 "  # Muted icon
  else
    # Select volume icon based on percentage
    if [ "$vol_percent" -ge 80 ]; then
      icon="^c$pink^"  # Full volume
    elif [ "$vol_percent" -ge 40 ]; then
      icon="^c$pink^󰕾"  # Medium-high volume
    elif [ "$vol_percent" -gt 20 ]; then
      icon="^c$pink^󰖀"  # Medium volume
    elif [ "$vol_percent" -gt 0 ]; then
      icon="^c$pink^󰕿"  # Low volume
    else
      icon="^c$pink^󰝟"  # Muted icon (if volume is zero)
    fi
  fi

  # Display the icon without the percentage
  printf " $icon  "
}

mic() {
    # Get microphone mute state using wpctl
     MIC_STATE=$(wpctl status | grep -q MUTED && echo "yes" || echo "no")

    if [[ $MIC_STATE == "no" ]]; then
        # If mic is muted, display red icon
        printf "^c$green^  "
        
    else
        # If mic is unmuted, display green icon
        printf "^c$maroon^ 󰍭 "
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
    color="^c$red^"  # red if above 85%
  else
    color="^c$peach^"  # green if below 85%
  fi

  # Print the memory usage with color
  printf "${color}  %s/%s " "$used_mem" "$total_mem"
}

wlan() {
  local operstate signal strength icon color

  operstate=$(cat /sys/class/net/wl*/operstate 2>/dev/null)
  current_connected=$(iwctl station wlan0 show | grep "Connected network" | sed 's/^[[:space:]]*Connected network[[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [[ "$operstate" == "up" ]]; then
    signal=$(awk '/wl/ { print int($3 * 100 / 70) }' /proc/net/wireless 2>/dev/null)

    # Map signal strength to icons
    if (( signal >= 75 )); then
      icon="󰤨 "  # Strong
      color="$teal"
    elif (( signal >= 50 )); then
      icon="󰤥"  # Medium
      color="$teal"
    elif (( signal >= 25 )); then
      icon="󰤢"  # Weak
      color="$teal"
    else
      icon="󰤟"  # Very weak
      color="$teal"
    fi

    printf "^c%s^ %s   %s " "$color" "$icon" "$current_connected"
  else
    printf "^c$red^ 󰤭 "
  fi
}

#bluetooth functions
power_on() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        return 0
    else
        return 1
    fi
}
device_paired() {
    device_info=$(bluetoothctl info "$1")
    if echo "$device_info" | grep -q "Paired: yes"; then
        echo "Paired: yes"
        return 0
    else
        echo "Paired: no"
        return 1
    fi
}
device_connected() {
    device_info=$(bluetoothctl info "$1")
    if echo "$device_info" | grep -q "Connected: yes"; then
        return 0
    else
        return 1
    fi
}
bluetooth() {
    if power_on; then
        printf "^c$darkblue^ "

        paired_devices_cmd="devices Paired"
        # Check if an outdated version of bluetoothctl is used to preserve backwards compatibility
        if (( $(echo "$(bluetoothctl version | cut -d ' ' -f 2) < 5.65" | bc -l) )); then
            paired_devices_cmd="paired-devices"
        fi

        mapfile -t connected_devices < <(bluetoothctl devices Connected | grep Device | cut -d ' ' -f 2)
        connected_devices_count=${#connected_devices[@]}
        printf " %s" "$connected_devices_count"
        # mapfile -t paired_devices < <(bluetoothctl $paired_devices_cmd | grep Device | cut -d ' ' -f 2)
        # counter=0
        # for device in "${paired_devices[@]}"; do
        #     if device_connected "$device"; then
        #         device_alias=$(bluetoothctl info "$device" | grep "Alias" | cut -d ' ' -f 2-)
        #
        #         if [ $counter -gt 0 ]; then
        #             printf ", %d" "$device_alias"
        #         else
        #             printf " %d" "$device_alias"
        #         fi
        #
        #         ((counter++))
        #     fi
        # done
        printf "\n"
    else
        echo "^c$darkblue^󰂲 "
    fi
}
clock() {

  printf "^c$lavender^  "
  printf "^c$lavender^ $(date '+%a %d %b ')"
  printf "^c$blue^ 󱑆 "
  printf "^c$blue^ $(date '+%H:%M')"
}

while true; do

  [ $interval = 0 ] || [ $(($interval % 120)) = 0 ] && updates=$(pkg_updates)
  interval=$((interval + 1))

  sleep 1 && xsetroot -name " $(brightness) $(cpu) $(mem) $(wlan) $(bluetooth) $(mic) $(volume) $(battery) $(clock)"
done
