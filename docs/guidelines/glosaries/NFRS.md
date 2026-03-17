# NFRS — Non-Functional Requirements Specification

> **Viết tắt**: NFRS · **Hay gọi**: Quality Attributes, System Qualities  
> **Ngữ cảnh**: Bổ sung cho FRS — mô tả hệ thống làm **TỐT thế nào**, không phải làm **gì**

---

## ① DEFINE

### Định nghĩa

**NFRS (Non-Functional Requirements Specification)** là tài liệu đặc tả các **ràng buộc chất lượng** mà hệ thống phải đáp ứng: hiệu suất, bảo mật, khả dụng, khả năng mở rộng, bảo trì… NFRS trả lời câu hỏi **"Hệ thống phải làm TỐT đến mức nào?"**.

### Các nhóm NFR chính (ISO 25010)

| Nhóm | Ví dụ cụ thể |
|------|-------------|
| **Performance** | API response ≤ 2s (p95), throughput ≥ 1000 rps |
| **Scalability** | Chịu tải 10K → 100K users mà không cần redesign |
| **Availability** | Uptime ≥ 99.9% (downtime ≤ 8.76h/năm) |
| **Security** | Mã hóa AES-256, OWASP Top 10 compliance |
| **Usability** | Task completion ≤ 3 clicks, mobile-first responsive |
| **Maintainability** | Code coverage ≥ 80%, deploy time ≤ 15 phút |
| **Reliability** | MTBF ≥ 720h, MTTR ≤ 1h |
| **Portability** | Chạy trên Linux/macOS/Windows, Docker-ready |

### Phân biệt FR vs NFR

| | Functional (FR) | Non-Functional (NFR) |
|--|-----------------|---------------------|
| **Câu hỏi** | Hệ thống làm **gì**? | Làm **tốt** thế nào? |
| **Ví dụ** | "User đăng nhập bằng email" | "Login API ≤ 2s, 99.9% uptime" |
| **Test** | Pass/Fail — đúng chức năng không? | Benchmark — đạt threshold không? |
| **Nếu thiếu** | Hệ thống thiếu tính năng | Hệ thống chậm, crash, bị hack |

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| Quên NFR cho đến production | Hệ thống chậm, crash dưới load | Viết NFR song song với FR |
| NFR không đo lường được | "Phải nhanh" — không verify được | Dùng số liệu: "p95 ≤ 2000ms" |
| NFR quá lý tưởng | "99.999% uptime" — tốn kém không cần thiết | Cân đối cost vs requirement |

---

## ② GRAPH

### Mô hình NFR — ISO 25010

```
                    ┌───────────────────────┐
                    │   System Quality      │
                    │   (Non-Functional)     │
                    └───────────┬───────────┘
                                │
    ┌───────┬───────┬───────┬───┴───┬───────┬───────┬───────┐
    ▼       ▼       ▼       ▼       ▼       ▼       ▼       ▼
┌───────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐
│Perfor-││Scala-││Avail-││Secu- ││Usab- ││Main- ││Relia-││Port- │
│mance  ││bility││bility││rity  ││ility ││tain- ││bility││abi-  │
│       ││      ││      ││      ││      ││abi-  ││      ││lity  │
│       ││      ││      ││      ││      ││lity  ││      ││      │
└───┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘└──┬───┘
    │       │       │       │       │       │       │       │
  Latency  Hori-  Uptime   Auth   Mobile  Deploy  MTBF   Docker
  Through- zontal  SLA     Encrypt  A11y   CI/CD   MTTR   Cross-
  put      Verti-  Failov  OWASP          Testab-        platform
           cal     er                      ility
```

### NFR Tradeoff Matrix

```
                High Performance
                      ▲
                      │
                      │
    High Security ◄───┼───► High Usability
                      │
                      │
                      ▼
               Low Cost / Simplicity

    ⚠ Không thể tối ưu TẤT CẢ cùng lúc — phải prioritize!
    Ví dụ: Security cao → thêm 2FA → Usability giảm (thêm bước)
```

---

## ③ CODE

### Ví dụ: NFRS dạng Structured

```yaml
non_functional_requirements:

  performance:
    - id: NFR-P01
      description: "API response time ≤ 2000ms (p95) với 10.000 concurrent users"
      metric: "p95 latency"
      threshold: "≤ 2000ms"
      measurement: "Load test bằng k6/JMeter mỗi sprint"

    - id: NFR-P02
      description: "Database query ≤ 500ms cho 95% queries"
      metric: "p95 query time"
      threshold: "≤ 500ms"
      measurement: "pg_stat_statements monitoring"

  availability:
    - id: NFR-A01
      description: "System uptime ≥ 99.9%"
      metric: "Monthly uptime percentage"
      threshold: "≥ 99.9% (downtime ≤ 43 phút/tháng)"
      measurement: "UptimeRobot / Datadog monitoring"

  security:
    - id: NFR-S01
      description: "Tất cả API endpoints PHẢI dùng HTTPS (TLS 1.2+)"
      compliance: "OWASP Top 10"

    - id: NFR-S02
      description: "Password PHẢI hash bằng bcrypt (cost ≥ 12)"
      compliance: "NIST SP 800-63B"

    - id: NFR-S03
      description: "JWT token hết hạn sau 15 phút, refresh token 7 ngày"

  scalability:
    - id: NFR-SC01
      description: "Hệ thống PHẢI scale horizontal từ 1 → 10 instances"
      method: "Kubernetes HPA, stateless services"

  maintainability:
    - id: NFR-M01
      description: "Code coverage ≥ 80%"
      measurement: "SonarQube / Codecov"

    - id: NFR-M02
      description: "Deployment time ≤ 15 phút (zero-downtime)"
      method: "Blue-green deployment / Rolling update"
```

### SLA Tiers phổ biến

```yaml
# Service Level Agreement — Uptime tiers
sla_tiers:
  "99%":     { downtime_per_year: "3.65 ngày",   note: "Startup / internal tools" }
  "99.9%":   { downtime_per_year: "8.76 giờ",    note: "Business apps" }
  "99.95%":  { downtime_per_year: "4.38 giờ",    note: "E-commerce" }
  "99.99%":  { downtime_per_year: "52.56 phút",  note: "Financial / healthcare" }
  "99.999%": { downtime_per_year: "5.26 phút",   note: "Critical infrastructure" }
```

---

## ④ PITFALLS

| # | Lỗi | Ví dụ | Fix |
|---|------|-------|-----|
| 1 | **NFR không đo lường** | "Hệ thống phải nhanh" | "p95 ≤ 2000ms với 10K users" |
| 2 | **Quên NFR đến khi production** | Dev chỉ code features | Viết NFR cùng lúc FRS |
| 3 | **Overspec** | "99.999% uptime" cho app nội bộ | Chọn SLA phù hợp business value |
| 4 | **Không test NFR** | Chỉ test functional | Load test, security scan mỗi sprint |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| ISO/IEC 25010:2011 (Quality Model) | https://www.iso.org/standard/35733.html |
| OWASP Top 10 | https://owasp.org/www-project-top-ten/ |
| Google SRE Book | https://sre.google/sre-book/table-of-contents/ |
