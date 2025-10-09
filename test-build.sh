#!/bin/bash

# test-build.sh - Script test build và format code

set -e

echo "🔧 Testing Go build and format system..."

# Test 1: Build với go build
echo "📦 Test 1: Building with go build..."
if go build -buildvcs=false -o tmp/test-main ./cmd/api; then
    echo "✅ Build successful!"
    rm -f tmp/test-main
else
    echo "❌ Build failed!"
    exit 1
fi

# Test 2: Format với gofmt
echo "🎨 Test 2: Testing gofmt..."
if gofmt -s -d ./cmd/api/main.go | grep -q .; then
    echo "⚠️  Code needs formatting"
    gofmt -s -w ./cmd/api/main.go
    echo "✅ Code formatted with gofmt"
else
    echo "✅ Code is already formatted"
fi

# Test 3: Test goimports (nếu có)
echo "📝 Test 3: Testing goimports..."
if command -v goimports >/dev/null 2>&1; then
    if goimports -d ./cmd/api/main.go | grep -q .; then
        echo "⚠️  Imports need organizing"
        goimports -w ./cmd/api/main.go
        echo "✅ Imports organized with goimports"
    else
        echo "✅ Imports are already organized"
    fi
else
    echo "⚠️  goimports not installed, skipping test"
fi

# Test 4: Test golangci-lint (nếu có)
echo "🔍 Test 4: Testing golangci-lint..."
if command -v golangci-lint >/dev/null 2>&1; then
    if golangci-lint run; then
        echo "✅ Linter passed!"
    else
        echo "⚠️  Linter found issues"
    fi
else
    echo "⚠️  golangci-lint not installed, skipping test"
fi

echo "🎉 All tests completed!"
