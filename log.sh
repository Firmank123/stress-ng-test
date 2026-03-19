#!/data/data/com.termux/files/usr/bin/bash

RUN_ID="$1"

while IFS= read -r line || [ -n "$line" ]; do

    case "$line" in

        *"CLEAN STATE"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: CLEAN STATE"
        ;;

        *"PRELOAD MEMORY"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: PRELOAD"
        ;;

        *"VMSTAT BEFORE"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: VMSTAT BEFORE"
        ;;

        *"PSI BEFORE"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: PSI BEFORE"
        ;;

        *"STRESS"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: STRESS RUNNING"
        ;;

        *"VMSTAT AFTER"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: VMSTAT AFTER"
        ;;

        *"PSI AFTER"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: PSI AFTER"
        ;;

        *"LOADAVG"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: LOADAVG"
        ;;

        *"RUNQUEUE"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: RUNQUEUE"
        ;;

        *"EAS TEST"*)
            echo "[`date +%H:%M:%S`] Run $RUN_ID: EAS TEST"
        ;;

    esac

done
