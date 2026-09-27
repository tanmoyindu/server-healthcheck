#!/usr/bin/env bash
#############################
# Author: Tanmoy
# Date: 26/09/2026
# Project: server-healthcheck
#############################

set -e            # exit on any command failure
set -u             # exit on undefined variable
set -o pipefail    # catch failures in piped commands

# --- Configuration ---
SERVICES=("NetworkManager" "firewalld")   # systemd services to check
PORTS=(22 8000)                  # ports to check for listeners

LOG_DIR="./logs"                 # where log files are stored
LOG_RETENTION_DAYS=7             # delete logs older than this
LOG_FILE="$LOG_DIR/healthcheck_$(date +%Y%m%d_%H%M%S).log"

# --- Disk check ---
check_disk() {
    echo "=== Disk Usage ==="
    df -h --output=target,pcent -x tmpfs -x devtmpfs | tail -n +2
    echo
}

# --- Memory check ---
check_memory() {
    echo "=== Memory Usage ==="
    free -h
    echo
}

# --- Service check ---
check_services() {
    echo "=== Service Status ==="
    for svc in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            echo "$svc: RUNNING"
        else
            echo "$svc: NOT RUNNING"
        fi
    done
    echo
}

# --- Port check ---
check_ports() {
    echo "=== Port Status ==="
    for port in "${PORTS[@]}"; do
        if ss -ltn | grep -q ":$port "; then
            echo "port $port: LISTENING"
        else
            echo "port $port: NOT LISTENING"
        fi
    done
    echo
}

# --- Cleanup old logs ---
cleanup_logs() {
    echo "=== Log Cleanup ==="
    local deleted
    deleted=$(find "$LOG_DIR" -name "healthcheck_*.log" -mtime +"$LOG_RETENTION_DAYS" -print -delete | wc -l)
    echo "Deleted $deleted log(s) older than $LOG_RETENTION_DAYS days"
    echo
}

main() {
    mkdir -p "$LOG_DIR"
    {
        echo "Health check started: $(date)"
        echo
        check_disk
        check_memory
        check_services
        check_ports
        cleanup_logs
        echo "Health check finished: $(date)"
    } | tee "$LOG_FILE"
}

main