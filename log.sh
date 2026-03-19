#!/data/data/com.termux/files/usr/bin/bash

STATUS_FILE="/sdcard/kernel_test_logs/status.tmp"

echo "=== LIVE RUN STATUS ==="

LAST=""

while true; do
    if [ -f "$STATUS_FILE" ]; then
        CUR=$(cat "$STATUS_FILE")

        if [ "$CUR" != "$LAST" ]; then
            echo "[$(date +%H:%M:%S)] $CUR"
            LAST="$CUR"
        fi
    fi

    sleep 0.5
done
