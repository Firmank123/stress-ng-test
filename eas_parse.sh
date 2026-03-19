#!/data/data/com.termux/files/usr/bin/bash

LOG="$1"

extract_max_cpu() {
    awk "$1" "$LOG" | grep stress-ng | awk '{print $1}' | sort -nr | head -n1
}

LOW_BIG=$(extract_max_cpu '/LOW LOAD/{flag=1;next}/MID LOAD/{flag=0}flag')
MID_BIG=$(extract_max_cpu '/MID LOAD/{flag=1;next}/HIGH LOAD/{flag=0}flag')
HIGH_BIG=$(extract_max_cpu '/HIGH LOAD/{flag=1}flag')

# default
[ -z "$LOW_BIG" ] && LOW_BIG=0
[ -z "$MID_BIG" ] && MID_BIG=0
[ -z "$HIGH_BIG" ] && HIGH_BIG=0

# safety numeric check
LOW_BIG=$(echo "$LOW_BIG" | tr -dc '0-9')
MID_BIG=$(echo "$MID_BIG" | tr -dc '0-9')
HIGH_BIG=$(echo "$HIGH_BIG" | tr -dc '0-9')

[ -z "$LOW_BIG" ] && LOW_BIG=0
[ -z "$MID_BIG" ] && MID_BIG=0
[ -z "$HIGH_BIG" ] && HIGH_BIG=0

SCORE=100

if [ "$LOW_BIG" -gt 4 ]; then
    SCORE=$((SCORE - 40))
fi

if [ "$MID_BIG" -gt 6 ]; then
    SCORE=$((SCORE - 20))
fi

if [ "$HIGH_BIG" -lt 6 ]; then
    SCORE=$((SCORE - 20))
fi

[ "$SCORE" -lt 0 ] && SCORE=0

echo "EAS_SCORE=$SCORE"

echo ""
echo "==== EAS DETAIL ===="
echo "LOW max cpu: $LOW_BIG"
echo "MID max cpu: $MID_BIG"
echo "HIGH max cpu: $HIGH_BIG"

if [ "$SCORE" -gt 80 ]; then
    echo "✔️ Proper EAS behavior"
elif [ "$SCORE" -gt 50 ]; then
    echo "⚠️ Slight performance bias"
else
    echo "❌ Not energy aware"
fi
