#!/bin/bash
set -e

SERVER_IP=${1:?"Usage: $0 <server_private_IP>"}
REPEAT=5
DURATION=30
RESULTS_DIR="results_$(date +%Y%m%d_%H%M%S)"

# If results_* directory already exists, use the latest one
if ls results_* 1> /dev/null 2>&1; then
    RESULTS_DIR=$(ls -td results_* | head -1)
    echo "Using existing results directory: $RESULTS_DIR"
else
    mkdir -p $RESULTS_DIR
    echo "Creating new results directory: $RESULTS_DIR"
fi

log() { echo "[$(date '+%H:%M:%S')] $1"; }

run_test() {
    local mode=$1
    local test_type=$2
    local cmd=$3
    local output_ext=$4

    for i in $(seq 1 $REPEAT); do
        log "[$mode] $test_type - Run $i/$REPEAT"
        eval "$cmd" > "$RESULTS_DIR/${mode}_${test_type}_run${i}.${output_ext}"
        sleep 5
    done
}

# ============ Native Host Test ============
log "========== Native Host Network Test =========="

run_test "native" "tcp" \
    "iperf3 -c $SERVER_IP -t $DURATION -J" "json"

run_test "native" "udp" \
    "iperf3 -c $SERVER_IP -u -b 1G -t $DURATION -J" "json"

run_test "native" "ping" \
    "ping -c 100 $SERVER_IP" "txt"

run_test "native" "tcp_crr" \
    "netperf -H $SERVER_IP -t TCP_CRR -l $DURATION -- -o min_latency,max_latency,mean_latency,transactions" "txt"

run_test "native" "tcp_rr" \
    "netperf -H $SERVER_IP -t TCP_RR -l $DURATION -- -o min_latency,max_latency,mean_latency,p99_latency,transactions" "txt"

log "========== Native Mode Test Completed =========="
log "Results saved in: $RESULTS_DIR/"
