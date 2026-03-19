#!/data/data/com.termux/files/usr/bin/bash

LOG_DIR="/sdcard/kernel_test_logs"
STATUS_FILE="$LOG_DIR/status.tmp"
RUNS=3

mkdir -p $LOG_DIR

echo "=== KERNEL BENCHMARK ==="
echo "Runs: $RUNS"
echo ""

TOTAL_MM=0
TOTAL_SCHED=0
TOTAL_PSI=0
VALID_RUNS=0

MIN_MM=100
MAX_MM=0

echo "INIT" > $STATUS_FILE
./log.sh &
LOGGER_PID=$!

for i in $(seq 1 $RUNS); do
    echo "[Run $i/$RUNS]"

    echo "Run $i: PREPARE" > $STATUS_FILE
    sleep 1

    LOG="$LOG_DIR/test_$i.log"

    ./stress-ng.sh > "$LOG"

    kill $LOGGER_PID 2>/dev/null

    echo "Run $i: PARSING" > $STATUS_FILE
    RESULT=$(./parse.sh "$LOG")

    EAS_RESULT=$(./eas_parse.sh "$LOG")

    echo "---- RUN $i DETAIL ----"
    echo "$RESULT"
    echo "--------------------------------"
    echo ""

    MM=$(echo "$RESULT" | grep MM_SCORE | cut -d= -f2)
    SCHED=$(echo "$RESULT" | grep SCHED_SCORE | cut -d= -f2)
    EAS=$(echo "$EAS_RESULT" | grep EAS_SCORE | cut -d= -f2)
    PSI=$(echo "$RESULT" | grep PSI_SCORE | cut -d= -f2)

    MM=${MM:-0}
    SCHED=${SCHED:-0}
    EAS=${EAS:-0}
    PSI=${PSI:-0}

    # skip unstable run
    if [ "$MM" -lt 5 ] && [ "$PSI" -gt 80 ]; then
        echo "⚠️ Skipped unstable run"
    else
        TOTAL_MM=$((TOTAL_MM + MM))
        TOTAL_SCHED=$((TOTAL_SCHED + SCHED))
	TOTAL_EAS=$((TOTAL_EAS + EAS))
        TOTAL_PSI=$((TOTAL_PSI + PSI))
        VALID_RUNS=$((VALID_RUNS + 1))

        [ "$MM" -lt "$MIN_MM" ] && MIN_MM=$MM
        [ "$MM" -gt "$MAX_MM" ] && MAX_MM=$MM
    fi

    echo "Run $i: DONE" > $STATUS_FILE

    # resume logger
    ./log.sh &
    LOGGER_PID=$!

    echo "Cooling down..."
    sleep 10
    echo ""
done

kill $LOGGER_PID 2>/dev/null
rm -f $STATUS_FILE

if [ "$VALID_RUNS" -eq 0 ]; then
    VALID_RUNS=1
fi

AVG_MM=$((TOTAL_MM / VALID_RUNS))
AVG_SCHED=$((TOTAL_SCHED / VALID_RUNS))
AVG_EAS=$((TOTAL_EAS / VALID_RUNS))
AVG_PSI=$((TOTAL_PSI / VALID_RUNS))

FINAL=$(((AVG_MM + AVG_SCHED + AVG_PSI + AVG_EAS) / 4))

echo "==== FINAL RESULT ===="
echo "MM Score: $AVG_MM"
echo "Sched Score: $AVG_SCHED"
echo "EAS Score: $AVG_EAS"
echo "PSI Score: $AVG_PSI"
echo ""
echo "🔥 KERNEL SCORE: $FINAL / 100"

VAR_MM=$((MAX_MM - MIN_MM))

if [ "$VAR_MM" -gt 40 ]; then
    echo "⚠️ RESULT UNSTABLE (variance: $VAR_MM)"
else
    echo "✔️ Result stable (variance: $VAR_MM)"
fi

if [ "$AVG_MM" -lt "$AVG_SCHED" ]; then
    echo "BOTTLENECK: MEMORY (MM)"
else
    echo "BOTTLENECK: SCHEDULER"
fi
