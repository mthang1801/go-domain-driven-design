#!/bin/bash

echo "🧪 Testing Go Tutorial Project..."

# Test build
echo "🔨 Testing build..."
go build -o tmp/test-main main.go
if [ $? -eq 0 ]; then
    echo "✅ Build thành công!"
else
    echo "❌ Build thất bại!"
    exit 1
fi

# Test run
echo "🏃 Testing run..."
./tmp/test-main
if [ $? -eq 0 ]; then
    echo "✅ Run thành công!"
else
    echo "❌ Run thất bại!"
    exit 1
fi

# Clean up
rm -f tmp/test-main
echo "🧹 Cleaned up test files"

echo "🎉 Tất cả tests đều thành công!"

