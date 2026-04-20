#!/bin/bash
set -e

SERVER_IP=${1:?"Usage: $0 <server_private_IP>"}
REPEAT=5
DURATION=30

# Use the latest results_* directory
RESULTS_DIR=$(ls -td results_* | head -1)
echo "Using results directory: $RESULTS_DIR"

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

# ============ Bridge Mode ============
log "========== Bridge Mode Test =========="
docker run -d --name client-bridge netbench:latest sleep infinity

run_test "bridge" "tcp" \
    "docker exec client-bridge iperf3 -c $SERVER_IP -t $DURATION -J" "json"

run_test "bridge" "udp" \
    "docker exec client-bridge iperf3 -c $SERVER_IP -u -b 1G -t $DURATION -J" "json"

run_test "bridge" "ping" \
    "docker exec client-bridge ping -c 100 $SERVER_IP" "txt"

run_test "bridge" "tcp_crr" \
    "docker exec client-bridge netperf -H $SERVER_IP -t TCP_CRR -l $DURATION -- -o min_latency,max_latency,mean_latency,transactions" "txt"

run_test "bridge" "tcp_rr" \
    "docker exec client-bridge netperf -H $SERVER_IP -t TCP_RR -l $DURATION -- -o min_latency,max_latency,mean_latency,p99_latency,transactions" "txt"

docker stop client-bridge && docker rm client-bridge

log "========== Bridge Mode Test Completed =========="
log "Results saved in: $RESULTS_DIR/"
