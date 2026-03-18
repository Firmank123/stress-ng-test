#!/data/data/com.termux/files/usr/bin/bash

LOG_FILE="$1"

if [ -z "$LOG_FILE" ]; then
    echo "Usage: ./parse.sh <log_file>"
    exit 1
fi

echo "=== ANALYZE KERNEL TEST ==="
echo "File: $LOG_FILE"
echo ""

# =========================
# 🔥 SCHED (CPU)
# =========================
echo "==== SCHED (CPU) ===="

BOGO=$(grep "stress-ng: metrc:" "$LOG_FILE" | grep "cpu" | tail -n 1 | awk '{for(i=NF;i>0;i--) if ($i ~ /^[0-9.]+$/) {print $i; break}}')

if ! echo "$BOGO" | grep -qE '^[0-9]+(\.[0-9]+)?$'; then
    BOGO="FAILED"
fi

echo "Bogo ops/s: $BOGO"
echo ""

# =========================
# 🔥 EXTRACT VMSTAT BLOCKS
# =========================
BEFORE=$(awk '/==== VMSTAT BEFORE ====/{flag=1;next}/==== STRESS TEST ====/{flag=0}flag' "$LOG_FILE")
AFTER=$(awk '/==== VMSTAT AFTER ====/{flag=1;next}/==== MEMINFO ====/{flag=0}flag' "$LOG_FILE")

# fallback (old log)
if [ -z "$BEFORE" ] || [ -z "$AFTER" ]; then
    echo "⚠️ No BEFORE/AFTER found → fallback to snapshot mode"
    VMSTAT=$(awk '/==== VMSTAT ====/{flag=1;next}/==== MEMINFO ====/{flag=0}flag' "$LOG_FILE")
    BEFORE="$VMSTAT"
    AFTER="$VMSTAT"
fi

get_val() {
    KEY="$1"
    BLOCK="$2"
    echo "$BLOCK" | grep "^$KEY " | awk '{print $2}'
}

delta() {
    KEY="$1"
    B=$(get_val "$KEY" "$BEFORE")
    A=$(get_val "$KEY" "$AFTER")

    [ -z "$B" ] && B=0
    [ -z "$A" ] && A=0

    echo $((A - B))
}

# =========================
# 🔥 MM (DELTA)
# =========================
echo "==== MEMORY (DELTA) ===="

PGSCAN=$(delta pgscan_kswapd)
PGSCAN_DIRECT=$(delta pgscan_direct)
PGSTEAL=$(delta pgsteal_kswapd)
PGSTEAL_DIRECT=$(delta pgsteal_direct)

TOTAL_SCAN=$((PGSCAN + PGSCAN_DIRECT))
TOTAL_STEAL=$((PGSTEAL + PGSTEAL_DIRECT))

REFAULT=$(delta workingset_refault)
ACTIVATE=$(delta workingset_activate)

echo "pgscan: $TOTAL_SCAN"
echo "pgsteal: $TOTAL_STEAL"
echo "refault: $REFAULT"
echo "activate: $ACTIVATE"
echo ""

# =========================
# 🔥 METRICS
# =========================
echo "==== METRICS ===="

if [ "$TOTAL_SCAN" -gt 0 ]; then
    EFF=$((TOTAL_STEAL * 100 / TOTAL_SCAN))
else
    EFF=0
fi

if [ "$TOTAL_STEAL" -gt 0 ]; then
    REFAULT_RATE=$((REFAULT * 100 / TOTAL_STEAL))
else
    REFAULT_RATE=0
fi

if [ "$REFAULT" -gt 0 ]; then
    ACT_RATE=$((ACTIVATE * 100 / REFAULT))
else
    ACT_RATE=0
fi

echo "Efficiency: $EFF%"
echo "Refault rate: $REFAULT_RATE%"
echo "Activation success: $ACT_RATE%"
echo ""

# =========================
# 🔥 VERDICT
# =========================
echo "==== VERDICT ===="

if [ "$EFF" -gt 80 ]; then
    MM="GOOD"
elif [ "$EFF" -gt 60 ]; then
    MM="OK"
else
    MM="BAD"
fi

if [ "$REFAULT_RATE" -lt 15 ]; then
    RF="EXCELLENT"
elif [ "$REFAULT_RATE" -lt 30 ]; then
    RF="GOOD"
elif [ "$REFAULT_RATE" -lt 60 ]; then
    RF="OK"
else
    RF="BAD"
fi

echo "MM: $MM ($EFF%)"
echo "Refault: $RF ($REFAULT_RATE%)"
echo ""

# =========================
# 🔥 BEHAVIOR ANALYSIS
# =========================
echo "==== BEHAVIOR ===="

if [ "$TOTAL_SCAN" -eq 0 ]; then
    echo "No reclaim activity detected"
else
    if [ "$REFAULT_RATE" -gt 40 ]; then
        echo "⚠️ Reclaim terlalu agresif"
    elif [ "$REFAULT_RATE" -lt 15 ]; then
        echo "✔️ Reclaim sangat stabil"
    fi
fi

if [ "$ACT_RATE" -lt 10 ]; then
    echo "⚠️ Workingset activation rendah (normal di banyak kernel)"
elif [ "$ACT_RATE" -gt 50 ]; then
    echo "✔️ Workingset tracking bagus"
fi

echo ""
echo "=== DONE ==="
