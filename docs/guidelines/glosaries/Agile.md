# Agile — Agile Software Development

> **Ngữ cảnh**: Phương pháp phát triển phần mềm linh hoạt, đối lập với Waterfall

---

## ① DEFINE

### Định nghĩa

**Agile** là tập hợp các **nguyên tắc và giá trị** (Agile Manifesto, 2001) hướng tới phát triển phần mềm **linh hoạt, lặp lại (iterative), và tăng dần (incremental)**. Agile không phải 1 framework cụ thể mà là triết lý bao trùm nhiều frameworks: Scrum, Kanban, XP, SAFe…

### 4 Giá trị cốt lõi (Agile Manifesto)

| Ưu tiên | Hơn là |
|---------|--------|
| **Individuals & interactions** | Processes & tools |
| **Working software** | Comprehensive documentation |
| **Customer collaboration** | Contract negotiation |
| **Responding to change** | Following a plan |

### Phân biệt Agile vs Waterfall

| Tiêu chí | Agile | Waterfall |
|----------|-------|----------|
| **Approach** | Iterative, incremental | Sequential, linear |
| **Requirements** | Thay đổi liên tục | Cố định từ đầu |
| **Delivery** | Mỗi sprint (2-4 tuần) | Cuối dự án (3-12 tháng) |
| **Feedback** | Liên tục | Cuối dự án |
| **Risk** | Phát hiện sớm | Phát hiện muộn |

### Các Framework Agile phổ biến

| Framework | Đặc điểm | Team size |
|-----------|----------|-----------|
| **Scrum** | Sprint, roles (PO, SM, Dev), ceremonies | 5-9 |
| **Kanban** | Flow-based, WIP limits, no sprints | Any |
| **XP** | TDD, pair programming, CI | 5-12 |
| **SAFe** | Scaled Agile cho enterprise | 50-125+ |

---

## ② GRAPH

### Agile vs Waterfall Timeline

```
Waterfall:
  Requirements ──▶ Design ──▶ Code ──▶ Test ──▶ Deploy
  [────── 3 months ──────────────────────────────────]
  Feedback: ────────────────────────────────────── ❌ Cuối

Agile (Scrum):
  Sprint 1    Sprint 2    Sprint 3    Sprint 4
  [R→D→C→T] [R→D→C→T] [R→D→C→T] [R→D→C→T]
  [2 weeks]  [2 weeks]  [2 weeks]  [2 weeks]
  Feedback: ✅         ✅         ✅         ✅
```

### Scrum Framework

```
Product        Sprint        Sprint          Daily         Sprint    Sprint
Backlog ──────▶Planning ────▶Backlog ────────▶Standup ────▶Review ──▶Retro
(PO owns)     (2-4h)       (Dev team)      (15 min)     (Demo)   (Improve)
                                                │
                                    ┌───────────┘
                                    ▼
                              Working Software
                              (Increment)
```

---

## ③ CODE

### User Story Format

```yaml
user_stories:
  - id: US-001
    format: >
      As a [type of user],
      I want [some goal],
      so that [some reason].
    example: >
      As a busy professional,
      I want to re-order my last meal with 1 tap,
      so that I can save time during lunch.
    acceptance_criteria:
      - "Given tôi đã đặt hàng trước đó"
      - "When tôi tap nút 'Đặt lại'"
      - "Then đơn hàng mới được tạo với cùng items"
    story_points: 5
    priority: Must-Have
```

### Sprint Planning (ví dụ)

```yaml
sprint:
  number: 4
  duration: "2 weeks"
  goal: "Hoàn thành Quick Order feature"
  velocity: 21  # story points

  backlog:
    - { id: US-050, points: 8, assignee: "Dev A" }
    - { id: US-051, points: 5, assignee: "Dev B" }
    - { id: US-052, points: 5, assignee: "Dev A" }
    - { id: BUG-12, points: 3, assignee: "Dev C" }
  # Total: 21 points = velocity
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | "Agile = không cần doc" | Agile vẫn cần doc, chỉ ưu tiên working software |
| 2 | Sprint không có goal | Mỗi sprint PHẢI có sprint goal rõ ràng |
| 3 | Quên retrospective | Retro là cơ hội cải tiến — bắt buộc mỗi sprint |
| 4 | Story quá lớn | Tách thành stories ≤ 8 points, hoàn thành trong 1 sprint |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Agile Manifesto | https://agilemanifesto.org/ |
| Scrum Guide | https://scrumguides.org/ |
| Kanban Guide | https://kanban.university/kanban-guide/ |
