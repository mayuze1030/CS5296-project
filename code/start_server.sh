#!/bin/bash
set -e
log() { echo "[$(date '+%H:%M:%S')] $1"; }

MODE=${1:?"Usage: $0 <native|bridge|host|container>"}

# Stop any leftover services
pkill iperf3 2>/dev/null || true
pkill netserver 2>/dev/null || true
docker rm -f server-bridge server-host server-primary server-shared 2>/dev/null || true

case $MODE in
    native)
        log "Starting native host services..."
        iperf3 -s -D
        netserver
        ;;
    bridge)
        log "Starting Bridge mode services..."
        docker run -d --name server-bridge \
            -p 5201:5201 -p 12865:12865 \
            netbench:latest sleep infinity
        docker exec server-bridge iperf3 -s -D
        docker exec server-bridge netserver
        ;;
    host)
        log "Starting Host mode services..."
        docker run -d --name server-host \
            --network host \
            netbench:latest sleep infinity
        docker exec server-host iperf3 -s -D
        docker exec server-host netserver
        ;;
    container)
        log "Starting Container mode services..."
        docker run -d --name server-primary \
            -p 5201:5201 -p 12865:12865 \
            netbench:latest sleep infinity
        docker run -d --name server-shared \
            --network container:server-primary \
            netbench:latest sleep infinity
        docker exec server-primary iperf3 -s -D
        docker exec server-primary netserver
        ;;
    *)
        echo "Unknown mode: $MODE"
        exit 1
        ;;
esac

log "$MODE mode services started"