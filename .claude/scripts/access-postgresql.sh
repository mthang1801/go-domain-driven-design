#!/bin/bash
# =============================================================================
# PostgreSQL Access Script
# Project: Data Visualizer
# =============================================================================

PG_HOST="${PG_HOST:-127.0.0.1}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-postgres}"
PG_PASSWORD="${PG_PASSWORD:-admin123}"
PG_DATABASE="${PG_DATABASE:-data_visualizer_test}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  PostgreSQL Access — Data Visualizer Platform"
echo "================================================"

# 1. Health Check
echo -e "\n${YELLOW}[1/2] Port Check...${NC}"
if nc -z "$PG_HOST" "$PG_PORT" 2>/dev/null; then
    echo -e "${GREEN}✓ PostgreSQL is accepting connections at ${PG_HOST}:${PG_PORT}${NC}"
else
    echo -e "${RED}✗ PostgreSQL is NOT reachable at ${PG_HOST}:${PG_PORT}${NC}"
    echo "  Hint: Check if the docker container is running"
fi

# 2. Display Access Info
echo -e "\n${YELLOW}[2/2] Access Information...${NC}"
echo -e "${GREEN}================================================${NC}"
echo "Connection Details:"
echo "  Host:     ${PG_HOST}"
echo "  Port:     ${PG_PORT}"
echo "  Database: ${PG_DATABASE}"
echo "  Username: ${PG_USER}"
echo "  Password: ${PG_PASSWORD}"
echo ""
echo "CLI Command:"
echo "  PGPASSWORD=\"${PG_PASSWORD}\" psql -h ${PG_HOST} -p ${PG_PORT} -U ${PG_USER} -d ${PG_DATABASE}"
echo ""
echo "Connection String (URI):"
echo "  postgresql://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DATABASE}"
echo -e "${GREEN}================================================${NC}"
