#!/bin/bash

# Configuration
COMPOSE_FILE="docker-compose.yml"
LOG_FILE="otel_setup.log"
COLLECTOR_HEALTH_URL="http://localhost:13133/"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

trap_handler() {
    local exit_code=$?
    local line_no=$1
    if [ $exit_code -ne 0 ]; then
        log_message "ERROR: Script failed at line $line_no with exit code $exit_code."
        log_message "DEBUG INFO: Check if Docker Desktop is running and WSL can access localhost ports."
        # Log the failed command in debug mode as requested
        log_message "COMMAND FAILED: $(history 1 | sed 's/^[ ]*[0-9]*[ ]*//')"
    fi
}

# Trap errors and report details
trap 'trap_handler $LINENO' ERR

log_message "Starting OTel Infrastructure in Hybrid Mode..."

# Step 1: Start Docker Compose
log_message "Step 1: Running docker-compose up..."
docker-compose -f "$COMPOSE_FILE" up -d

# Step 2: Wait for Collector Health
log_message "Step 2: Waiting for OTel Collector to become healthy on port 13133..."
MAX_RETRIES=12
COUNT=0

until $(curl --output /dev/null --silent --head --fail "$COLLECTOR_HEALTH_URL"); do
    if [ $COUNT -eq $MAX_RETRIES ]; then
        log_message "CRITICAL: OTel Collector failed to reach healthy state after 60 seconds."
        exit 1
    fi
    
    log_message "Collector is starting... (Attempt $((COUNT+1))/$MAX_RETRIES)"
    sleep 5
    ((COUNT++))
done

log_message "SUCCESS: Infrastructure is READY."
log_message "--------------------------------------------------------"
log_message "INSTRUCTIONS FOR INTELLIJ (WINDOWS):"
log_message "1. Set OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318"
log_message "2. Ensure -javaagent points to your local .jar path."
log_message "3. Traces: http://localhost:16686"
log_message "4. Metrics: http://localhost:9090"
log_message "--------------------------------------------------------"
