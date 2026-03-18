#!/data/data/com.termux/files/usr/bin/bash

OUT="/sdcard/kernel_test_logs/kernel_test_$(date +%Y%m%d_%H%M%S).log"

mkdir -p /sdcard/kernel_test_logs

echo "=== KERNEL TEST START ===" | tee $OUT
echo ""

# =========================
# BASELINE
# =========================
echo "==== VMSTAT BEFORE ====" | tee -a $OUT
cat /proc/vmstat | tee -a $OUT

echo "" | tee -a $OUT

sleep 3

# =========================
# STRESS TEST
# =========================
echo "==== STRESS TEST ====" | tee -a $OUT

./stress-ng --cpu 8 --vm 4 --vm-bytes 70% --timeout 30s --metrics-brief 2>&1 | tee -a $OUT

echo "" | tee -a $OUT

# =========================
# AFTER
# =========================
echo "==== VMSTAT AFTER ====" | tee -a $OUT
cat /proc/vmstat | tee -a $OUT

echo "" | tee -a $OUT

echo "==== MEMINFO ====" | tee -a $OUT
cat /proc/meminfo | tee -a $OUT

echo ""
echo "Saved to: $OUT"
