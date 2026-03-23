#!/bin/bash
# =============================================================================
# Metabase Access Script
# Project: Data Visualizer — Metabase Component
# URL: http://localhost:3100
# =============================================================================

METABASE_URL="${METABASE_URL:-http://localhost:3100}"
METABASE_USERNAME="${METABASE_USERNAME:-supabase}"
METABASE_PASSWORD="${METABASE_PASSWORD:-admin123}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Metabase Access — Data Visualizer Platform"
echo "================================================"

# 1. Health Check
echo -e "\n${YELLOW}[1/3] Health Check...${NC}"
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${METABASE_URL}/api/health" 2>/dev/null)
if [ "$HEALTH" = "200" ]; then
    echo -e "${GREEN}✓ Metabase is running at ${METABASE_URL}${NC}"
else
    echo -e "${RED}✗ Metabase is NOT reachable at ${METABASE_URL} (HTTP: ${HEALTH})${NC}"
    exit 1
fi

# 2. Login & Get Session
echo -e "\n${YELLOW}[2/3] Authenticating...${NC}"
SESSION_RESPONSE=$(curl -s -X POST "${METABASE_URL}/api/session" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${METABASE_USERNAME}\",\"password\":\"${METABASE_PASSWORD}\"}" 2>/dev/null)

SESSION_TOKEN=$(echo "$SESSION_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$SESSION_TOKEN" ]; then
    echo -e "${GREEN}✓ Authenticated successfully${NC}"
    echo "  Session Token: ${SESSION_TOKEN}"
else
    echo -e "${RED}✗ Authentication failed${NC}"
    echo "  Response: ${SESSION_RESPONSE}"
    exit 1
fi

# 3. List Databases
echo -e "\n${YELLOW}[3/3] Listing Databases...${NC}"
DATABASES=$(curl -s "${METABASE_URL}/api/database" \
    -H "X-Metabase-Session: ${SESSION_TOKEN}" 2>/dev/null)

echo "$DATABASES" | grep -o '"name":"[^"]*"' | while read -r line; do
    DB_NAME=$(echo "$line" | cut -d'"' -f4)
    echo -e "  ${GREEN}📊 ${DB_NAME}${NC}"
done

echo -e "\n${GREEN}================================================${NC}"
echo "Key URLs:"
echo "  Home:       ${METABASE_URL}"
echo "  Databases:  ${METABASE_URL}/browse/databases"
echo "  New Query:  ${METABASE_URL}/question#new"
echo "  Admin:      ${METABASE_URL}/admin"
echo "  API Docs:   ${METABASE_URL}/api/docs"
echo -e "${GREEN}================================================${NC}"
