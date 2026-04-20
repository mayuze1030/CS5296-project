#!/bin/bash
set -e

SERVER_IP=${1:?"Usage: $0 <server_private_IP>"}
REPEAT=5
DURATION=30
RESULTS_DIR="results_20260417_075004"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

run_test() {
    local mode=$1
    local test_type=$2
    local cmd=$3
    local output_ext=$4

    for i in $(seq 1 $REPEAT); do
        local outfile="$RESULTS_DIR/${mode}_${test_type}_run${i}.${output_ext}"
        if [ -s "$outfile" ]; then
            log "[$mode] $test_type - Run $i/$REPEAT already exists, skipping"
            continue
        fi
        log "[$mode] $test_type - Run $i/$REPEAT"
        eval "$cmd" > "$outfile" 2>&1 || true
        sleep 5
    done
}

log "========== Host Mode Test =========="
sudo docker rm -f client-host 2>/dev/null || true
sudo docker run -d --name client-host --network host netbench:latest sleep infinity

run_test "host" "tcp" \
    "sudo docker exec client-host iperf3 -c $SERVER_IP -t $DURATION -J" "json"
run_test "host" "udp" \
    "sudo docker exec client-host iperf3 -c $SERVER_IP -u -b 1G -t $DURATION -J" "json"
run_test "host" "ping" \
    "sudo docker exec client-host ping -c 100 $SERVER_IP" "txt"
run_test "host" "tcp_crr" \
    "sudo docker exec client-host netperf -H $SERVER_IP -t TCP_CRR -l $DURATION -- -o min_latency,max_latency,mean_latency,transactions" "txt"
run_test "host" "tcp_rr" \
    "sudo docker exec client-host netperf -H $SERVER_IP -t TCP_RR -l $DURATION -- -o min_latency,max_latency,mean_latency,p99_latency,transactions" "txt"

sudo docker stop client-host && sudo docker rm client-host
log "========== Host Mode Test Completed =========="
ls -la $RESULTS_DIR/host_*
