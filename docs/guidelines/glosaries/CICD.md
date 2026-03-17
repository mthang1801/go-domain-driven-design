# CI/CD — Continuous Integration / Continuous Delivery

> **Viết tắt**: CI/CD  
> **Ngữ cảnh**: DevOps practice — tự động hóa build, test, deploy

---

## ① DEFINE

### Định nghĩa

- **CI (Continuous Integration)**: Merge code vào main branch **nhiều lần/ngày**, mỗi lần tự động build + test
- **CD (Continuous Delivery)**: Code luôn ở trạng thái **sẵn sàng deploy** (deploy thủ công)
- **CD (Continuous Deployment)**: Tự động deploy lên production **không cần can thiệp**

### Phân biệt CI vs CD (Delivery) vs CD (Deployment)

| Giai đoạn | CI | CD (Delivery) | CD (Deployment) |
|-----------|----|----|-----|
| **Build** | ✅ Auto | ✅ Auto | ✅ Auto |
| **Unit Test** | ✅ Auto | ✅ Auto | ✅ Auto |
| **Integration Test** | ✅ Auto | ✅ Auto | ✅ Auto |
| **Deploy to Staging** | ❌ | ✅ Auto | ✅ Auto |
| **Deploy to Production** | ❌ | ⚠ Manual approve | ✅ Auto |

### Actors

| Actor | Vai trò |
|-------|---------|
| **Developer** | Push code, trigger CI |
| **CI Server** | Build, test tự động (GitHub Actions, Jenkins) |
| **QA** | Verify staging, approve production deploy |
| **DevOps** | Setup + maintain CI/CD pipeline |

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| Flaky tests | CI fail ngẫu nhiên → dev bỏ qua CI | Quarantine flaky tests, fix ASAP |
| Quá lâu | CI chạy 30+ phút | Parallel tests, cache dependencies |
| Không test đủ | Bug lọt qua CI | Coverage ≥ 80%, integration tests |

---

## ② GRAPH

### CI/CD Pipeline

```
Developer                    CI Server                     Production
    │                            │                             │
    │── git push ───────────────▶│                             │
    │                            │── Build ────────────────── │
    │                            │── Unit Tests ───────────── │
    │                            │── Lint + Static Analysis ── │
    │                            │── Integration Tests ─────── │
    │                            │                             │
    │                            │── Deploy to Staging ───────▶│ (auto)
    │                            │                             │
    │◀── Notify: ✅ or ❌ ───────│                             │
    │                            │                             │
    │   (if CD Delivery)         │                             │
    │── Manual Approve ─────────▶│── Deploy to Prod ──────────▶│
    │                            │                             │
    │   (if CD Deployment)       │                             │
    │                            │── Auto Deploy to Prod ─────▶│
```

---

## ③ CODE

### GitHub Actions Example

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'

      - name: Install dependencies
        run: go mod download

      - name: Run lint
        run: golangci-lint run ./...

      - name: Run tests
        run: go test -race -coverprofile=coverage.out ./...

      - name: Check coverage
        run: |
          coverage=$(go tool cover -func=coverage.out | tail -1 | awk '{print $3}')
          echo "Coverage: $coverage"

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        run: echo "Deploy to K8s..."
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | CI chạy > 15 phút | Parallel tests, cache deps |
| 2 | Flaky tests | Quarantine + fix ngay |
| 3 | No rollback strategy | Blue-green deploy, feature flags |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Continuous Delivery (Jez Humble) | https://continuousdelivery.com/ |
| GitHub Actions Docs | https://docs.github.com/en/actions |
| Martin Fowler — CI | https://martinfowler.com/articles/continuousIntegration.html |
