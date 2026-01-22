package logging

import (
	"bytes"
	"fmt"
	"sync"
	"testing"
	"time"
)

var bufferPool = sync.Pool{
	New: func() interface{} {
		return bytes.NewBuffer(make([]byte, 0, 1024))
	},
}

type Logger struct {
	output chan string
}

func NewLogger() *Logger {
	l := &Logger{
		output: make(chan string, 1000),
	}
	go l.flushLogs()
	return l
}

func (l *Logger) flushLogs() {
	for msg := range l.output {
		fmt.Println(msg)
	}
}

func (l *Logger) Info(format string, args ...any) {
	buf := bufferPool.Get().(*bytes.Buffer)
	buf.Reset()

	buf.WriteString(time.Now().Format("2006-01-02 23:59:59"))
	buf.WriteString(" [INFO] ")
	fmt.Fprintf(buf, format, args...)

	l.output <- buf.String()
	bufferPool.Put(buf)
}

func BenchmarkLoggingWithPool(b *testing.B) {
	logger := NewLogger()
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		logger.Info("User %d logged in from IP %s", i, "192.168.1.1")
	}
}

func BenchmarkLoggingWithoutPool(b *testing.B) {
	for i := 0; i < b.N; i++ {
		msg := fmt.Sprintf("%s [INFO] User %d logged in from IP %s",
			time.Now().Format("2006-01-02 15:04:05"), i, "192.168.1.1")
		fmt.Println(msg)
	}
}
