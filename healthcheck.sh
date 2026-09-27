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
PORTS=(22 8000)                           # ports to check for listeners

LOG_DIR="./logs"                 # where log files are stored
LOG_RETENTION_DAYS=7             # delete logs older than this
LOG_FILE="$LOG_DIR/healthcheck_$(date +%Y%m%d_%H%M%S).log"

JSON_OUTPUT=false                # --json flag
DISK_THRESHOLD=80                # --threshold flag (percent)

usage() {
    echo "Usage: $0 [--json] [--threshold PERCENT]"
    echo "  --json               Output results as JSON instead of plain text"
    echo "  --threshold PERCENT  Disk usage warning threshold (default: 80)"
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                JSON_OUTPUT=true
                shift
                ;;
            --threshold)
                DISK_THRESHOLD="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# --- Disk check ---
check_disk() {
    echo "=== Disk Usage ==="
    df -h --output=target,pcent -x tmpfs -x devtmpfs | tail -n +2 | while read -r target pcent; do
        pcent_num="${pcent%\%}"
        if [[ "$pcent_num" -ge "$DISK_THRESHOLD" ]]; then
            echo "$target $pcent  WARNING: above ${DISK_THRESHOLD}% threshold"
        else
            echo "$target $pcent"
        fi
    done
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

# --- JSON summary ---
print_json_summary() {
    local services_json ports_json

    services_json=$(for svc in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            printf '{"name":"%s","status":"running"}\n' "$svc"
        else
            printf '{"name":"%s","status":"not_running"}\n' "$svc"
        fi
    done | paste -sd, -)

    ports_json=$(for port in "${PORTS[@]}"; do
        if ss -ltn | grep -q ":$port "; then
            printf '{"port":%s,"status":"listening"}\n' "$port"
        else
            printf '{"port":%s,"status":"not_listening"}\n' "$port"
        fi
    done | paste -sd, -)

    printf '{"timestamp":"%s","services":[%s],"ports":[%s]}\n' \
        "$(date -Iseconds)" "$services_json" "$ports_json"
}

main() {
    parse_args "$@"
    mkdir -p "$LOG_DIR"

    if [[ "$JSON_OUTPUT" == true ]]; then
        print_json_summary | tee "$LOG_FILE"
    else
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
    fi
}

main "$@"