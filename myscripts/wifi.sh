#!/usr/bin/env bash

# Replace with your actual wireless interface (check via: iwctl device list)
INTERFACE="wlan0"

# Ensure iwd is running
if ! systemctl is-active --quiet iwd; then
    notify-send "Wi-Fi" "Starting iwd..."
    sudo systemctl start iwd
    sleep 1
fi

# Scan for networks
notify-send "Wi-Fi" "Scanning for Wi-Fi networks..."
iwctl station "$INTERFACE" scan
sleep 2

wifi_list=$(iwctl station "$INTERFACE" get-networks | \
    sed -r 's/\x1B\[[0-9;]*[mK]//g' | \
    awk 'NR > 4 {
        sub(/^[^[:alnum:]]*[[:space:]]*/, "", $0)
        match($0, /^(.*[^[:space:]])[[:space:]]+(psk|open|wep)[[:space:]]+/, a)
        if (a[1] != "") print a[1]
    }' | sort -u)
# Get current connected network
current_connected=$(iwctl station "$INTERFACE" show | grep "Connected network" | sed 's/^[[:space:]]*Connected network[[:space:]]*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Let user select SSID using rofi
chosen_network=$(echo "$wifi_list" | rofi -dmenu -i -p "Select Wi-Fi: ")

# Exit if nothing selected
if [[ -z "$chosen_network" ]]; then
    exit 0
fi

# If already connected to selected network, exit
if [[ "$chosen_network" == "$current_connected" ]]; then
    notify-send "Wi-Fi" "Already connected to \"$chosen_network\"."
    exit 0
fi
# Check if network is known
known_networks=$(iwctl known-networks list | \
    sed -r 's/\x1B\[[0-9;]*[mK]//g' | \
    awk 'NR > 4 {
        sub(/^[^[:alnum:]]*[[:space:]]*/, "", $0)
        match($0, /^(.*[^[:space:]])[[:space:]]+(psk|open|wep)[[:space:]]+/, a)
        if (a[1] != "") print a[1]
    }' | sort -u)

# If the network is known, connect directly
if echo "$known_networks" | grep -Fxq "$chosen_network"; then
    notify-send "Wi-Fi" "Connecting to saved network: $chosen_network"
    iwctl station "$INTERFACE" connect "$chosen_network"
else
    # If not known, check if it's secure and prompt for a password if necessary
    security_info=$(iwctl station "$INTERFACE" get-networks | grep -F "$chosen_network")
    if echo "$security_info" | grep -qE "psk|wep"; then
        # Prompt for password
        wifi_password=$(rofi -dmenu -password -p "Password for $chosen_network: ")

        if [[ -z "$wifi_password" ]]; then
            notify-send "Wi-Fi" "No password entered. Cancelling."
            exit 1
        fi
# iwctl --passphrase=PASSPHRASE station DEVICE connect SSID
        # Connect with password using iwctl
        iwctl --passphrase="$wifi_password" station "$INTERFACE" connect "$chosen_network" 
    else
        # Open network, no password needed
        iwctl station "$INTERFACE" connect "$chosen_network"
    fi
fi

# Wait and verify connection
sleep 2
new_connection=$(iwctl station "$INTERFACE" show | grep "Connected network" | sed 's/^[[:space:]]*Connected network[[:space:]]*//;s/[[:space:]]*$//')

if [[ "$new_connection" == "$chosen_network" ]]; then
    notify-send "Wi-Fi" "Connected to $chosen_network"
else
    notify-send "Wi-Fi" "Failed to connect to $chosen_network"
fi
