# QA — Quality Assurance

> **Viết tắt**: QA · **Phân biệt**: QA ≠ QC ≠ Testing  
> **Ngữ cảnh**: Đảm bảo chất lượng phần mềm xuyên suốt SDLC

---

## ① DEFINE

### Định nghĩa

**QA (Quality Assurance)** là quy trình **đảm bảo chất lượng** xuyên suốt vòng đời phần mềm — tập trung vào **quy trình** để **ngăn ngừa** lỗi, không chỉ tìm lỗi.

### Phân biệt QA vs QC vs Testing

| | QA | QC | Testing |
|--|----|----|---------|
| **Focus** | Quy trình (process) | Sản phẩm (product) | Phát hiện lỗi |
| **Khi nào** | Xuyên suốt SDLC | Sau khi code | Giai đoạn test |
| **Mục tiêu** | Ngăn ngừa lỗi | Phát hiện lỗi | Tìm bugs |
| **Ví dụ** | Code review, CI/CD | UAT, regression test | Run test cases |
| **Proactive** | ✅ | ❌ Reactive | ❌ Reactive |

### Các loại Testing

| Level | Tên | Ai test | Tìm gì |
|-------|-----|---------|---------|
| 1 | **Unit Test (UT)** | Developer | Logic đúng ở mức function |
| 2 | **Integration Test (IT)** | Developer/QA | Modules giao tiếp đúng |
| 3 | **System Test (ST)** | QA | Hệ thống end-to-end đúng |
| 4 | **UAT** | User/PO | Đáp ứng business requirement |

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| QA chỉ ở cuối | Bug phát hiện muộn — fix đắt | Shift-left: QA từ requirements |
| Không có test automation | Regression test mỗi release mất days | Automate 80% test cases |
| Thiếu test environment | Test trên production → rủi ro | Staging environment giống production |

---

## ② GRAPH

### Testing Pyramid

```
              ╱╲
             ╱  ╲
            ╱ E2E╲           ← Ít nhất, chậm nhất, đắt nhất
           ╱ Tests ╲
          ╱──────────╲
         ╱Integration ╲      ← Vừa phải
        ╱    Tests      ╲
       ╱──────────────────╲
      ╱    Unit Tests      ╲  ← Nhiều nhất, nhanh nhất, rẻ nhất
     ╱______________________╲

  Tỷ lệ lý tưởng: 70% Unit / 20% Integration / 10% E2E
```

### Shift-Left Testing

```
Traditional:    Requirements → Design → Code → TEST → Deploy
                                                 ↑
                                            QA ở đây (muộn)

Shift-Left:     Requirements → Design → Code → Deploy
                     ↑            ↑        ↑       ↑
                    QA           QA       QA      QA
                 (review)    (review)  (test)  (monitor)
```

---

## ③ CODE

### Go Test Example

```go
// Unit Test
func TestCalculateTotal(t *testing.T) {
    items := []OrderItem{
        {Price: 50000, Quantity: 2},
        {Price: 30000, Quantity: 1},
    }
    total := CalculateTotal(items)
    assert.Equal(t, 130000, total)
}

// Table-Driven Test (Go idiom)
func TestCalculateDiscount(t *testing.T) {
    tests := []struct {
        name     string
        total    int
        expected int
    }{
        {"no discount", 50000, 50000},
        {"10% discount", 200000, 180000},
        {"20% discount", 500000, 400000},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := CalculateDiscount(tt.total)
            assert.Equal(t, tt.expected, result)
        })
    }
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | QA = chỉ manual testing | Automate ≥ 80% test cases |
| 2 | No test data management | Seed data + factory pattern |
| 3 | QA chỉ cuối sprint | Shift-left — QA từ requirements |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| ISTQB Foundation Level | https://www.istqb.org/ |
| Go Testing | https://go.dev/doc/tutorial/add-a-test |
| Test Pyramid (Martin Fowler) | https://martinfowler.com/bliki/TestPyramid.html |
