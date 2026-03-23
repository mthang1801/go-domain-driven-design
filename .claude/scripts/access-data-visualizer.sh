#!/bin/bash
# =============================================================================
# Data Visualizer Access Script
# Project: Data Visualizer — Main Application
# Frontend: Next.js (http://localhost:3100)
# Backend: NestJS
# =============================================================================

FRONTEND_URL="${FRONTEND_URL:-http://localhost:3100}"
BACKEND_URL="${BACKEND_URL:-http://localhost:3000}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Data Visualizer — Platform Access"
echo "================================================"

# 1. Frontend Check
echo -e "\n${YELLOW}[1/2] Frontend (Next.js) Check...${NC}"
FE_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${FRONTEND_URL}" 2>/dev/null)
if [ "$FE_HEALTH" = "200" ] || [ "$FE_HEALTH" = "302" ]; then
    echo -e "${GREEN}✓ Frontend is running at ${FRONTEND_URL}${NC}"
else
    echo -e "${RED}✗ Frontend is NOT reachable at ${FRONTEND_URL} (HTTP: ${FE_HEALTH})${NC}"
    echo "  Try: cd frontend && pnpm start"
fi

# 2. Backend Check
echo -e "\n${YELLOW}[2/2] Backend (NestJS) Check...${NC}"
BE_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}" 2>/dev/null)
if [ "$BE_HEALTH" = "200" ] || [ "$BE_HEALTH" = "302" ] || [ "$BE_HEALTH" = "404" ]; then
    echo -e "${GREEN}✓ Backend is running at ${BACKEND_URL}${NC}"
else
    echo -e "${RED}✗ Backend is NOT reachable at ${BACKEND_URL} (HTTP: ${BE_HEALTH})${NC}"
    echo "  Try: pnpm start:dev"
fi

echo -e "\n${GREEN}================================================${NC}"
echo "Project Structure:"
echo "  Frontend:  frontend/ (Next.js)"
echo "  Backend:   src/ (NestJS)"
echo "  Docs:      docs/"
echo "  Modules:   docs/modules/"
echo "  Config:    config/"
echo ""
echo "Companion services:"
echo "  Metabase:  http://localhost:3100"
echo "  Supabase:  http://localhost:8000/project/default"
echo ""
echo "Run all checks:"
echo "  bash .claude/scripts/access-metabase.sh"
echo "  bash .claude/scripts/access-supabase.sh"
echo "  bash .claude/scripts/access-data-visualizer.sh"
echo -e "${GREEN}================================================${NC}"
