
#!/bin/bash
set -e

SERVER_IP=${1:?"Usage: $0 <server_private_IP>"}
REPEAT=5
DURATION=30
RESULTS_DIR="results_$(date +%Y%m%d_%H%M%S)"
mkdir -p $RESULTS_DIR

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

# ============ Host Mode ============
log "========== Host Mode Test =========="
docker run -d --name client-host --network host netbench:latest sleep infinity

run_test "host" "tcp" \
    "docker exec client-host iperf3 -c $SERVER_IP -t $DURATION -J" "json"

run_test "host" "udp" \
    "docker exec client-host iperf3 -c $SERVER_IP -u -b 1G -t $DURATION -J" "json"

run_test "host" "ping" \
    "docker exec client-host ping -c 100 $SERVER_IP" "txt"

run_test "host" "tcp_crr" \
    "docker exec client-host netperf -H $SERVER_IP -t TCP_CRR -l $DURATION -- -o min_latency,max_latency,mean_latency,transactions" "txt"

run_test "host" "tcp_rr" \
    "docker exec client-host netperf -H $SERVER_IP -t TCP_RR -l $DURATION -- -o min_latency,max_latency,mean_latency,p99_latency,transactions" "txt"

docker stop client-host && docker rm client-host

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

log "========== All Tests Completed =========="
log "Results saved in: $RESULTS_DIR/"
ls -la $RESULTS_DIR/


