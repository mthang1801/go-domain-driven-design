#!/bin/bash
# =============================================================================
# Supabase Access Script
# Project: Data Visualizer — Supabase Component
# URL: http://localhost:8000
# =============================================================================

SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"
SUPABASE_API_URL="${SUPABASE_API_URL:-http://localhost:8000}"
SUPABASE_EMAIL="${SUPABASE_EMAIL:-mthang1801@gmail.com}"
SUPABASE_PASSWORD="${SUPABASE_PASSWORD:-Aa@123456}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Supabase Access — Data Visualizer Platform"
echo "================================================"

# 1. Health Check
echo -e "\n${YELLOW}[1/3] Health Check...${NC}"
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_URL}" 2>/dev/null)
if [ "$HEALTH" = "200" ] || [ "$HEALTH" = "302" ]; then
    echo -e "${GREEN}✓ Supabase Studio is running at ${SUPABASE_URL}${NC}"
else
    echo -e "${RED}✗ Supabase Studio is NOT reachable at ${SUPABASE_URL} (HTTP: ${HEALTH})${NC}"
    exit 1
fi

# 2. Check API health (Kong gateway)
echo -e "\n${YELLOW}[2/3] API Gateway Check...${NC}"
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${SUPABASE_API_URL}/rest/v1/" 2>/dev/null)
if [ "$API_HEALTH" = "200" ] || [ "$API_HEALTH" = "401" ]; then
    echo -e "${GREEN}✓ Supabase API Gateway is responding${NC}"
else
    echo -e "${YELLOW}⚠ API Gateway returned HTTP ${API_HEALTH}${NC}"
fi

# 3. Display Access Info
echo -e "\n${YELLOW}[3/3] Access Information...${NC}"
echo -e "${GREEN}================================================${NC}"
echo "Key URLs:"
echo "  Dashboard:     ${SUPABASE_URL}/project/default"
echo "  Table Editor:  ${SUPABASE_URL}/project/default/editor"
echo "  SQL Editor:    ${SUPABASE_URL}/project/default/sql/new"
echo "  Database:      ${SUPABASE_URL}/project/default/database/tables"
echo "  Auth:          ${SUPABASE_URL}/project/default/auth/users"
echo "  Storage:       ${SUPABASE_URL}/project/default/storage/buckets"
echo "  Edge Funcs:    ${SUPABASE_URL}/project/default/functions"
echo "  Realtime:      ${SUPABASE_URL}/project/default/realtime/inspector"
echo "  Logs:          ${SUPABASE_URL}/project/default/logs/explorer"
echo "  Settings:      ${SUPABASE_URL}/project/default/settings/general"
echo ""
echo "Credentials:"
echo "  Email:    ${SUPABASE_EMAIL}"
echo "  Password: ${SUPABASE_PASSWORD}"
echo -e "${GREEN}================================================${NC}"
