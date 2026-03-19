#!/data/data/com.termux/files/usr/bin/bash

LOG="$1"

get_max() {
    awk "$1" "$LOG" | grep -E '^[0-9]+' | sort -nr | head -n1
}

LOW=$(get_max '/LOW LOAD/{f=1;next}/MID LOAD/{f=0}f')
MID=$(get_max '/MID LOAD/{f=1;next}/HIGH LOAD/{f=0}f')
HIGH=$(get_max '/HIGH LOAD/{f=1}f')

[ -z "$LOW" ] && LOW=0
[ -z "$MID" ] && MID=0
[ -z "$HIGH" ] && HIGH=0

SCORE=100

[ "$LOW" -gt 4 ] && SCORE=$((SCORE - 40))
[ "$MID" -gt 6 ] && SCORE=$((SCORE - 20))
[ "$HIGH" -lt 6 ] && SCORE=$((SCORE - 20))

[ "$SCORE" -lt 0 ] && SCORE=0

echo "EAS_SCORE=$SCORE"
echo ""
echo "==== EAS DETAIL ===="
echo "LOW max cpu: $LOW"
echo "MID max cpu: $MID"
echo "HIGH max cpu: $HIGH"
