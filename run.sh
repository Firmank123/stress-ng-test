#!/data/data/com.termux/files/usr/bin/bash

LOG_DIR="/sdcard/kernel_test_logs"
RUNS=3

mkdir -p $LOG_DIR

echo "=== KERNEL BENCHMARK ==="
echo "Runs: $RUNS"
echo ""

TOTAL_MM=0
TOTAL_SCHED=0
TOTAL_PSI=0
TOTAL_EAS=0
VALID=0

for i in $(seq 1 $RUNS); do
    echo "[Run $i/$RUNS]"

    LOG="$LOG_DIR/run_$i.log"

    ./stress-ng.sh | tee "$LOG" | ./log.sh "$i" &
    PID=$!
    wait $PID

    RESULT=$(./parse.sh "$LOG")
    EAS_RESULT=$(./eas_parse.sh "$LOG")

    MODE=$(echo "$RESULT" | grep MODE | cut -d= -f2)

    echo "---- RUN $i DETAIL ----"
    echo "$RESULT"
    echo "$EAS_RESULT"
    echo "--------------------------------"
    echo ""

    if [ "$MODE" = "IDEAL" ]; then
        echo "⚠️ Skip (no memory pressure)"
        continue
    fi

    MM=$(echo "$RESULT" | grep MM_SCORE | cut -d= -f2)
    SCHED=$(echo "$RESULT" | grep SCHED_SCORE | cut -d= -f2)
    PSI=$(echo "$RESULT" | grep PSI_SCORE | cut -d= -f2)
    EAS=$(echo "$EAS_RESULT" | grep EAS_SCORE | cut -d= -f2)

    TOTAL_MM=$((TOTAL_MM + MM))
    TOTAL_SCHED=$((TOTAL_SCHED + SCHED))
    TOTAL_PSI=$((TOTAL_PSI + PSI))
    TOTAL_EAS=$((TOTAL_EAS + EAS))
    VALID=$((VALID + 1))

    echo "Cooling down..."
    sleep 10
    echo ""
done

[ "$VALID" -eq 0 ] && VALID=1

AVG_MM=$((TOTAL_MM / VALID))
AVG_SCHED=$((TOTAL_SCHED / VALID))
AVG_PSI=$((TOTAL_PSI / VALID))
AVG_EAS=$((TOTAL_EAS / VALID))

FINAL=$(((AVG_MM + AVG_SCHED + AVG_PSI + AVG_EAS) / 4))

echo "==== FINAL RESULT ===="
echo "MM Score: $AVG_MM"
echo "Sched Score: $AVG_SCHED"
echo "PSI Score: $AVG_PSI"
echo "EAS Score: $AVG_EAS"
echo ""
echo "🔥 KERNEL SCORE: $FINAL / 100"

if [ "$AVG_MM" -lt "$AVG_SCHED" ]; then
    echo "BOTTLENECK: MEMORY (MM)"
else
    echo "BOTTLENECK: SCHEDULER"
fi
