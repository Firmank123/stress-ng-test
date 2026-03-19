#!/data/data/com.termux/files/usr/bin/bash

LOG="$1"

HAS_PSI=1
grep -q "avg10" "$LOG" || HAS_PSI=0

BEFORE=$(awk '/VMSTAT BEFORE/{f=1;next}/PSI BEFORE/{f=0}f' "$LOG")
AFTER=$(awk '/VMSTAT AFTER/{f=1;next}/PSI AFTER/{f=0}f' "$LOG")

get_val() {
    echo "$2" | grep "^$1 " | awk '{print $2}'
}

delta() {
    B=$(get_val "$1" "$BEFORE")
    A=$(get_val "$1" "$AFTER")
    [ -z "$B" ] && B=0
    [ -z "$A" ] && A=0
    echo $((A - B))
}

PGSCAN=$(( $(delta pgscan_kswapd) + $(delta pgscan_direct) ))
PGSTEAL=$(( $(delta pgsteal_kswapd) + $(delta pgsteal_direct) ))
REFAULT=$(delta workingset_refault)
DIRECT=$(delta pgscan_direct)

EFF=0
[ "$PGSCAN" -gt 0 ] && EFF=$((PGSTEAL * 100 / PGSCAN))

REF=0
[ "$PGSTEAL" -gt 0 ] && REF=$((REFAULT * 100 / PGSTEAL))

if [ "$PGSCAN" -eq 0 ] && [ "$DIRECT" -eq 0 ]; then
    MM_SCORE=60
    MODE="IDEAL"
else
    MM_SCORE=$((EFF - REF))
    MODE="PRESSURE"

    if [ "$DIRECT" -gt 10000 ]; then
        MM_SCORE=$((MM_SCORE - 25))
    elif [ "$DIRECT" -gt 1000 ]; then
        MM_SCORE=$((MM_SCORE - 10))
    fi
fi

[ "$MM_SCORE" -lt 0 ] && MM_SCORE=0
[ "$MM_SCORE" -gt 100 ] && MM_SCORE=100

# PSI
if [ "$HAS_PSI" -eq 1 ]; then
    PSI_MEM=$(grep "some avg10" "$LOG" | tail -n1 | awk '{print $4}' | cut -d= -f2 | cut -d. -f1)
    PSI_CPU=$(grep "cpu" -A1 "$LOG" | grep avg10 | awk '{print $2}' | cut -d= -f2 | cut -d. -f1)
else
    PSI_MEM=0
    PSI_CPU=0
fi

[ -z "$PSI_MEM" ] && PSI_MEM=0
[ -z "$PSI_CPU" ] && PSI_CPU=0

PSI_SCORE=$((100 - PSI_MEM - PSI_CPU))
[ "$PSI_SCORE" -lt 0 ] && PSI_SCORE=0

# SCHED
LOAD=$(awk '/LOADAVG/{getline; print $1}' "$LOG" | cut -d. -f1)
RUNQ=$(awk '/RUNQUEUE/{getline; print $2}' "$LOG")

[ -z "$LOAD" ] && LOAD=0
[ -z "$RUNQ" ] && RUNQ=0

[ "$LOAD" -gt 16 ] && LOAD=16
[ "$RUNQ" -gt 16 ] && RUNQ=16

TOTAL=$((PSI_CPU*2 + RUNQ*2 + LOAD))
[ "$TOTAL" -gt 100 ] && TOTAL=100

SCHED_SCORE=$((100 - TOTAL))
[ "$SCHED_SCORE" -lt 0 ] && SCHED_SCORE=0

echo "MM_SCORE=$MM_SCORE"
echo "SCHED_SCORE=$SCHED_SCORE"
echo "PSI_SCORE=$PSI_SCORE"
echo "MODE=$MODE"

echo ""
echo "==== DETAIL ===="
echo "pgscan: $PGSCAN"
echo "pgsteal: $PGSTEAL"
echo "efficiency: $EFF%"
echo "refault: $REF%"
echo "direct: $DIRECT"
echo "load: $LOAD"
echo "runq: $RUNQ"
echo "psi_cpu: $PSI_CPU"
echo "psi_mem: $PSI_MEM"
echo "mode: $MODE"
