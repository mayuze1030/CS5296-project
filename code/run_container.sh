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

# ============ Container Mode ============
log "========== Container Mode Test =========="
docker run -d --name client-primary netbench:latest sleep infinity
docker run -d --name client-shared --network container:client-primary netbench:latest sleep infinity

run_test "container" "tcp" \
    "docker exec client-shared iperf3 -c $SERVER_IP -t $DURATION -J" "json"

run_test "container" "udp" \
    "docker exec client-shared iperf3 -c $SERVER_IP -u -b 1G -t $DURATION -J" "json"

run_test "container" "ping" \
    "docker exec client-shared ping -c 100 $SERVER_IP" "txt"

run_test "container" "tcp_crr" \
    "docker exec client-shared netperf -H $SERVER_IP -t TCP_CRR -l $DURATION -- -o min_latency,max_latency,mean_latency,transactions" "txt"

run_test "container" "tcp_rr" \
    "docker exec client-shared netperf -H $SERVER_IP -t TCP_RR -l $DURATION -- -o min_latency,max_latency,mean_latency,p99_latency,transactions" "txt"

docker stop client-shared client-primary && docker rm client-shared client-primary

log "========== Container Mode Test Completed =========="
log "Results saved in: $RESULTS_DIR/"
