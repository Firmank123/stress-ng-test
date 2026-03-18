#!/data/data/com.termux/files/usr/bin/bash

LOG_DIR="/sdcard/kernel_test_logs"

echo "=== AUTO KERNEL TEST ==="
echo ""

# =========================
# RUN STRESS TEST
# =========================
echo "[1/3] Running stress test..."
./stress-ng.sh

# =========================
# GET LATEST LOG
# =========================
echo ""
echo "[2/3] Fetching latest log..."

LATEST_LOG=$(ls -t $LOG_DIR/kernel_test_*.log 2>/dev/null | head -n 1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ No log file found!"
    exit 1
fi

echo "Latest log: $LATEST_LOG"

# =========================
# PARSE RESULT
# =========================
echo ""
echo "[3/3] Parsing result..."
echo ""

./parse.sh "$LATEST_LOG"

echo ""
echo "=== DONE ==="
