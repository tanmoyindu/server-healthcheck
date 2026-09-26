#!/usr/bin/env bash
#############################
# Author: Tanmoy
# Date: 26/09/2026
# Project: server-healthcheck
#############################

set -e            # exit on any command failure
set -u             # exit on undefined variable
set -o pipefail    # catch failures in piped commands

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

main() {
    echo "Health check started: $(date)"
    echo
    check_disk
    check_memory
    echo "Health check finished: $(date)"
}

main