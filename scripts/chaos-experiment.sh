#!/bin/bash
# Chaos Engineering Experiment Runner
# Usage: ./chaos-experiment.sh [experiment] [duration_seconds]

set -e

EXPERIMENT=${1:-latency}
DURATION=${2:-60}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CHAOS EXPERIMENT RUNNER              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo "Experiment: $EXPERIMENT"
echo "Duration: ${DURATION}s"
echo "Start: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Cleaning up...${NC}"
    case $EXPERIMENT in
        network_delay|packet_loss)
            tc qdisc del dev eth0 root 2>/dev/null || true
            ;;
        disk_fill)
            rm -f /tmp/chaos_fill_* 2>/dev/null || true
            ;;
    esac
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

trap cleanup EXIT

case $EXPERIMENT in
    cpu_stress)
        echo -e "${YELLOW}🔥 Starting CPU stress test...${NC}"
        echo "Consuming 80% CPU for ${DURATION}s"
        if command -v stress &> /dev/null; then
            timeout $DURATION stress --cpu 2 --timeout $DURATION || true
        else
            echo "stress tool not installed, simulating..."
            sleep $DURATION
        fi
        ;;
        
    memory_pressure)
        echo -e "${YELLOW}🔥 Starting memory pressure test...${NC}"
        echo "Allocating 256MB for ${DURATION}s"
        if command -v stress &> /dev/null; then
            timeout $DURATION stress --vm 1 --vm-bytes 256M --timeout $DURATION || true
        else
            echo "stress tool not installed, simulating..."
            sleep $DURATION
        fi
        ;;
        
    network_delay)
        echo -e "${YELLOW}🔥 Adding network latency...${NC}"
        echo "Adding 200ms delay for ${DURATION}s"
        tc qdisc add dev eth0 root netem delay 200ms 2>/dev/null || echo "tc not available"
        sleep $DURATION
        ;;
        
    packet_loss)
        echo -e "${YELLOW}🔥 Introducing packet loss...${NC}"
        echo "10% packet loss for ${DURATION}s"
        tc qdisc add dev eth0 root netem loss 10% 2>/dev/null || echo "tc not available"
        sleep $DURATION
        ;;
        
    disk_fill)
        echo -e "${YELLOW}🔥 Filling disk space...${NC}"
        echo "Creating large temp file for ${DURATION}s"
        dd if=/dev/zero of=/tmp/chaos_fill_test bs=1M count=500 2>/dev/null || true
        sleep $DURATION
        ;;
        
    process_kill)
        echo -e "${YELLOW}🔥 Killing random PHP-FPM worker...${NC}"
        pkill -f "php-fpm: pool" -o 2>/dev/null || echo "No PHP-FPM workers found"
        sleep 5
        ;;
        
    *)
        echo -e "${RED}Unknown experiment: $EXPERIMENT${NC}"
        echo "Available experiments:"
        echo "  - cpu_stress"
        echo "  - memory_pressure"
        echo "  - network_delay"
        echo "  - packet_loss"
        echo "  - disk_fill"
        echo "  - process_kill"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Experiment completed${NC}"
echo "End: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
