#!/bin/bash

IDLE_LIMIT_MS=$((30 * 60 * 1000))  # 30 minutes in milliseconds

while true; do
    idle_time=$(xprintidle)
    if [ "$idle_time" -ge "$IDLE_LIMIT_MS" ]; then
        systemctl suspend
    fi
    sleep 60
done

