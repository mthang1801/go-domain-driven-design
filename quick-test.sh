#!/bin/bash

echo "🔧 Quick test for new project structure..."

# Test 1: Check if cmd/api/main.go exists
if [ -f "./cmd/api/main.go" ]; then
    echo "✅ cmd/api/main.go exists"
else
    echo "❌ cmd/api/main.go not found"
    exit 1
fi

# Test 2: Try to build
echo "📦 Testing build..."
if go build -buildvcs=false -o tmp/test-main ./cmd/api 2>/dev/null; then
    echo "✅ Build successful!"
    rm -f tmp/test-main
else
    echo "❌ Build failed!"
    echo "Trying to see what's wrong..."
    go build -buildvcs=false -o tmp/test-main ./cmd/api
fi

# Test 3: Try to run
echo "🏃 Testing run..."
if go run ./cmd/api 2>/dev/null; then
    echo "✅ Run successful!"
else
    echo "❌ Run failed!"
    echo "Trying to see what's wrong..."
    go run ./cmd/api
fi

echo "🎉 Quick test completed!"
