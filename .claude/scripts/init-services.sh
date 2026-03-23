#!/bin/bash
# Script để khởi tạo backend và frontend service

echo "🚀 Starting backend service..."
# Run backend in the background
pnpm start &
BACKEND_PID=$!

echo "🚀 Starting frontend service..."
# Run frontend in the background
if [ -d "frontend" ]; then
  cd frontend
  pnpm dev &
  FRONTEND_PID=$!
  cd ..
else
  echo "⚠️ Frontend directory not found!"
fi

echo "✅ Services started in background."
echo "Backend PID: $BACKEND_PID"
if [ -n "$FRONTEND_PID" ]; then
  echo "Frontend PID: $FRONTEND_PID"
fi
