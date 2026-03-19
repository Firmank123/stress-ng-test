#!/data/data/com.termux/files/usr/bin/bash

echo "=== CLEAN STATE ==="
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null

# preload memory biar konsisten
echo "=== PRELOAD MEMORY ==="
dd if=/dev/zero of=/dev/null bs=1M count=512 &
PRELOAD_PID=$!
sleep 2

echo "=== VMSTAT BEFORE ==="
cat /proc/vmstat

echo "=== PSI BEFORE ==="
cat /proc/pressure/memory 2>/dev/null
cat /proc/pressure/cpu 2>/dev/null

sleep 1

echo "=== STRESS ==="
./stress-ng \
    --cpu 8 \
    --vm 4 \
    --vm-bytes 80% \
    --vm-keep \
    --timeout 30s \
    --metrics-brief

kill $PRELOAD_PID 2>/dev/null

echo "=== VMSTAT AFTER ==="
cat /proc/vmstat

echo "=== PSI AFTER ==="
cat /proc/pressure/memory 2>/dev/null
cat /proc/pressure/cpu 2>/dev/null

echo "=== LOADAVG ==="
cat /proc/loadavg

echo "=== RUNQUEUE ==="
cat /proc/stat | grep procs_running
