package utils

import (
	"fmt"
	"strings"
)

// GreetUser chào người dùng
func GreetUser(name string) string {
	return fmt.Sprintf("👋 Xin chào, %s! Chào mừng bạn đến với Go Tutorial!", strings.Title(name))
}

// AddNumbers cộng hai số
func AddNumbers(a, b int) int {
	return a + b
}

// GetCurrentTime trả về thời gian hiện tại dưới dạng string
func GetCurrentTime() string {
	return "Thời gian hiện tại: " + getTimeString()
}

func getTimeString() string {
	return "2024-01-01 12:00:00" // Placeholder
}
