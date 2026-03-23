#!/bin/bash
# =============================================================================
# MongoDB Access Script
# Project: Data Visualizer
# =============================================================================

MONGO_HOST="${MONGO_HOST:-127.0.0.1}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-root}"
MONGO_PASSWORD="${MONGO_PASSWORD:-admin123}"
MONGO_DATABASE="${MONGO_DATABASE:-data_visualizer}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  MongoDB Access — Data Visualizer Platform"
echo "================================================"

# 1. Health Check
echo -e "\n${YELLOW}[1/2] Port Check...${NC}"
if nc -z "$MONGO_HOST" "$MONGO_PORT" 2>/dev/null; then
    echo -e "${GREEN}✓ MongoDB is accepting connections at ${MONGO_HOST}:${MONGO_PORT}${NC}"
else
    echo -e "${RED}✗ MongoDB is NOT reachable at ${MONGO_HOST}:${MONGO_PORT}${NC}"
    echo "  Hint: Check if the docker container is running"
fi

# 2. Display Access Info
echo -e "\n${YELLOW}[2/2] Access Information...${NC}"
echo -e "${GREEN}================================================${NC}"
echo "Connection Details:"
echo "  Host:     ${MONGO_HOST}"
echo "  Port:     ${MONGO_PORT}"
echo "  Database: ${MONGO_DATABASE}"
echo "  Username: ${MONGO_USER}"
echo "  Password: ${MONGO_PASSWORD}"
echo ""
echo "CLI Command:"
echo "  mongosh \"mongodb://${MONGO_HOST}:${MONGO_PORT}/${MONGO_DATABASE}?authSource=admin\""
echo ""
echo "Connection String (URI):"
echo "  mongodb://${MONGO_HOST}:${MONGO_PORT}/${MONGO_DATABASE}?authSource=admin"
echo -e "${GREEN}================================================${NC}"
