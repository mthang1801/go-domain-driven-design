#!/bin/bash
# =============================================================================
# MySQL Access Script
# Project: Data Visualizer
# =============================================================================

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-admin123}"
MYSQL_DATABASE="${MYSQL_DATABASE:-data_visualizer}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  MySQL Access — Data Visualizer Platform"
echo "================================================"

# 1. Health Check
echo -e "\n${YELLOW}[1/2] Port Check...${NC}"
if nc -z "$MYSQL_HOST" "$MYSQL_PORT" 2>/dev/null; then
    echo -e "${GREEN}✓ MySQL is accepting connections at ${MYSQL_HOST}:${MYSQL_PORT}${NC}"
else
    echo -e "${RED}✗ MySQL is NOT reachable at ${MYSQL_HOST}:${MYSQL_PORT}${NC}"
    echo "  Hint: Check if the docker container is running"
fi

# 2. Display Access Info
echo -e "\n${YELLOW}[2/2] Access Information...${NC}"
echo -e "${GREEN}================================================${NC}"
echo "Connection Details:"
echo "  Host:     ${MYSQL_HOST}"
echo "  Port:     ${MYSQL_PORT}"
echo "  Database: ${MYSQL_DATABASE}"
echo "  Username: ${MYSQL_USER}"
echo "  Password: ${MYSQL_PASSWORD}"
echo ""
echo "CLI Command:"
echo "  mysql -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}"
echo ""
echo "Connection String (URI):"
echo "  mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"
echo -e "${GREEN}================================================${NC}"
