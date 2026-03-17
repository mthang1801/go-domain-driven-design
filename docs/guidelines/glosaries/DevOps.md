# DevOps — Development + Operations

> **Ngữ cảnh**: Văn hóa + thực hành tích hợp Dev và Ops

---

## ① DEFINE

### Định nghĩa

**DevOps** là sự kết hợp giữa **Development** và **Operations** — bao gồm văn hóa, thực hành, và công cụ nhằm **rút ngắn lifecycle phát triển phần mềm** và **cung cấp tính năng liên tục** với chất lượng cao.

### Các trụ cột DevOps (CALMS)

| Trụ cột | Mô tả |
|---------|-------|
| **C**ulture | Văn hóa cộng tác giữa Dev và Ops |
| **A**utomation | Tự động hóa mọi thứ (CI/CD, IaC, monitoring) |
| **L**ean | Loại bỏ waste, tối ưu flow |
| **M**easurement | Đo lường mọi thứ (DORA metrics) |
| **S**haring | Chia sẻ knowledge, responsibility |

### DORA Metrics (đo lường DevOps)

| Metric | Elite | Low |
|--------|-------|-----|
| **Deployment Frequency** | Multiple/day | Monthly |
| **Lead Time for Changes** | < 1 hour | 1-6 months |
| **Change Failure Rate** | 0-15% | 46-60% |
| **MTTR** | < 1 hour | 1 week+ |

### DevOps Toolchain

| Giai đoạn | Tools |
|-----------|-------|
| **Plan** | Jira, Linear, Notion |
| **Code** | Git, GitHub, GitLab |
| **Build** | Docker, Make, Gradle |
| **Test** | Jest, Go test, Cypress |
| **Release** | GitHub Actions, Jenkins, ArgoCD |
| **Deploy** | Kubernetes, Terraform, Ansible |
| **Operate** | Grafana, Datadog, PagerDuty |
| **Monitor** | Prometheus, Loki, ELK |

---

## ② GRAPH

### DevOps Infinity Loop

```
        Plan → Code → Build → Test
       ↗                           ↘
  Monitor                           Release
       ↖                           ↙
        Operate ← Deploy ← Release
```

### IaC (Infrastructure as Code)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Terraform   │     │   Docker     │     │  Kubernetes  │
│  (Infra)     │────▶│  (Container) │────▶│  (Orchestrate│
│              │     │              │     │   & Scale)   │
│ • VPC        │     │ • Build image│     │ • Deploy pods│
│ • RDS        │     │ • Push to    │     │ • Auto-scale │
│ • EKS        │     │   registry   │     │ • Self-heal  │
└──────────────┘     └──────────────┘     └──────────────┘
```

---

## ③ CODE

### Dockerfile Example

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/bin/server ./cmd/api

FROM alpine:3.19
COPY --from=builder /app/bin/server /usr/local/bin/
EXPOSE 8080
CMD ["server"]
```

### Terraform Example

```hcl
resource "aws_rds_instance" "main" {
  engine         = "postgres"
  engine_version = "16.1"
  instance_class = "db.t3.micro"
  db_name        = "foodapp"
  username       = var.db_username
  password       = var.db_password
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | DevOps = chỉ tools | DevOps là CULTURE trước, tools sau |
| 2 | No monitoring | Dùng Grafana + Prometheus từ ngày 1 |
| 3 | Manual infra | Infrastructure as Code (Terraform) |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| The Phoenix Project | https://itrevolution.com/the-phoenix-project/ |
| Google SRE Book | https://sre.google/sre-book/ |
| DORA Metrics | https://dora.dev/ |
