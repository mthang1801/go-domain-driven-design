---
name: git-workflow-skill
description: Git workflow, branching strategy, and Conventional Commits guidance for Data Visualizer. Use this skill whenever the user needs to create a branch, prepare a commit, name a branch, write a commit message, sync with `develop`, open a PR/MR, or validate repo workflow rules, even if they only ask loosely about Git.
---

# git-workflow-skill — Git Workflow, Branching & Conventional Commits cho Data Visualizer

## Mục đích

- Đảm bảo mọi agent tuân thủ **Conventional Commits** (feat, fix, chore, refactor, docs, style, test, perf, ci, build, revert, ...)
- Định nghĩa chuẩn **branch naming** theo prefix + kebab-case + ticket/ref nếu có.
- Hướng dẫn checkout/create branch an toàn (không overwrite develop, check clean working tree).
- Tích hợp với jira-skill (nếu có) để lấy task ID từ backlog/progress.md.
- Ngăn chặn commit trực tiếp lên develop → luôn feature/bugfix branch.

## Quy tắc cốt lõi (Mandatory — Security & Consistency)

1. **Không bao giờ commit/push trực tiếp lên develop** — luôn tạo branch mới.
2. **Branch naming convention** (dựa trên Conventional Commits + Angular/GitHub Flow):
    - Format: `<type>/<short-description>` hoặc `<type>/<ticket-id>-<short-description>`
    - Type (prefix) phổ biến:
        - `feature/` : Thêm/tối ưu feature mới (tương ứng commit `feat:`)
        - `bugfix/` : Sửa bug (tương ứng `fix:`)
        - `hotfix/` : Fix khẩn cấp production (tương ứng `fix:` + BREAKING nếu cần)
        - `chore/` : Build, deps, config, docs không ảnh hưởng src/test (tương ứng `chore:`)
        - `refactor/` : Refactor code không thay đổi behavior (tương ứng `refactor:`)
        - `docs/` : Chỉ thay đổi documentation (tương ứng `docs:`)
        - `test/` : Thêm/sửa test (tương ứng `test:`)
        - `style/` : Format, whitespace, missing semi-colon (tương ứng `style:`)
        - `ci/` : CI/CD pipeline, GitHub Actions (tương ứng `ci:`)
    - Short-description: kebab-case, lowercase, ngắn gọn (max 50 ký tự), mô tả rõ ràng.
    - Ví dụ:
        - `feature/table-editor-schema-listing`
        - `bugfix/dashboard-stat-null-value`
        - `chore/update-dependencies-2026`
        - `refactor/inline-style-to-css-modules`
        - `hotfix/security-presigned-url-cors`

3. **Conventional Commits message** (bắt buộc):
    - Format: `<type>[optional scope]: <description>`
        - `<type>`: feat, fix, chore, refactor, docs, style, test, perf, ci, build, revert
        - Scope: optional, ví dụ: `(table-editor)`, `(dashboard)`
        - Description: imperative, lowercase, no period at end.
        - Body: chi tiết nếu cần (why, how).
        - Footer: BREAKING CHANGE: nếu có breaking.
    - Ví dụ:
        - `feat(table-editor): add schema listing dropdown`
        - `fix(dashboard): correct null value in statistics card`
        - `chore(deps): update dependencies to 2026`
        - `refactor(table-editor): extract inline styles to CSS modules`
        - `hotfix(security): add CORS headers to presigned URL endpoint`

4. **Workflow**:
    - Khi bắt đầu task: `git checkout -b <type>/<short-description>` (hoặc `git checkout -b <type>/<ticket-id>-<short-description>` nếu có ticket).
    - Luôn `git pull origin develop` trước khi bắt đầu làm việc để tránh merge conflict.
    - Không commit trực tiếp vào develop.
    - Khi xong task: `git commit -m "<type>: <description>"` (hoặc full format nếu cần).
    - Push: `git push -u origin <branch-name>`.
    - Tạo PR/MR qua UI hoặc CLI (không push trực tiếp).

5. **Branch protection**:
    - develop được protected: chỉ có thể merge qua PR/MR với review.
    - Không force push vào develop.
    - Luôn rebase hoặc merge develop vào feature branch trước khi tạo PR/MR.

## Tích hợp với jira-skill

- Nếu jira-skill đã được load, agent có thể:
    - Lấy ticket ID từ `progress.md` hoặc backlog.
    - Sử dụng ticket ID trong branch name: `feature/<ticket-id>-<short-description>`.
    - Tự động update status khi branch được tạo/merge (nếu jira-skill hỗ trợ).

## Các lệnh mẫu

- Tạo branch mới:

    ```bash
    git checkout -b feature/table-editor-schema-listing
    ```

- Pull latest changes:

    ```bash
    git pull origin develop
    ```

- Commit:

    ```bash
    git commit -m "feat(table-editor): add schema listing dropdown"
    ```

- Push:

    ```bash
    git push -u origin feature/table-editor-schema-listing
    ```

- Tạo PR:

    ```bash
    # Qua GitHub UI hoặc dùng gh CLI
    gh pr create --base develop --head feature/table-editor-schema-listing --title "Feature: Table Editor Schema Listing" --body "Add schema listing dropdown to table editor"
    ```

## Checklist trước khi commit/PR

- [ ] Đã tạo branch mới (không commit vào develop).
- [ ] Branch name tuân thủ format: `<type>/<short-description>` hoặc `<type>/<ticket-id>-<short-description>`.
- [ ] Commit message tuân thủ Conventional Commits.
- [ ] Đã `git pull origin develop` trước khi làm việc.
- [ ] Không có merge conflict (hoặc đã rebase/merge develop vào feature branch).
- [ ] Working tree clean (`git status` không có file không mong muốn).
- [ ] Đã chạy test (nếu có) và pass.
- [ ] Đã chạy build (nếu có) và pass.
- [ ] Đã chạy linter (nếu có) và pass.
- [ ] Đã update `progress.md` (nếu cần).

## Khi nào dùng skill này

- Bất cứ khi nào cần tạo branch mới.
- Bất cứ khi nào cần commit code.
- Bất cứ khi nào cần tạo PR/MR.
- Bất cứ khi nào cần đảm bảo commit message tuân thủ Conventional Commits.
- Bất cứ khi nào cần rebase hoặc merge develop vào feature branch.
- Bất cứ khi nào cần kiểm tra working tree hoặc branch status.

## Lưu ý quan trọng

- Luôn ưu tiên tạo branch mới thay vì commit trực tiếp vào develop.
- Luôn sử dụng Conventional Commits cho commit message.
- Luôn sử dụng branch naming convention chuẩn.
- Luôn kiểm tra working tree và branch status trước khi commit.
- Luôn rebase hoặc merge develop vào feature branch trước khi tạo PR/MR.
- Luôn update `progress.md` khi bắt đầu hoặc kết thúc task.

## Ví dụ thực tế

**Scenario 1: Bắt đầu feature mới**

```bash
# 1. Check latest develop
git pull origin develop

# 2. Tạo feature branch
git checkout -b feature/add-table-dependencies

# 3. Làm việc, code, test...
# ...

# 4. Commit
git commit -m "feat(table-editor): add table dependencies feature"

# 5. Push
git push -u origin feature/add-table-dependencies

# 6. Tạo PR qua GitHub UI hoặc gh CLI
```

**Scenario 2: Sửa bug**

```bash
# 1. Check latest develop
git pull origin develop

# 2. Tạo bugfix branch
git checkout -b bugfix/dashboard-stat-null-value

# 3. Sửa bug
# ...

# 4. Commit
git commit -m "fix(dashboard): correct null value in statistics card"

# 5. Push
git push -u origin bugfix/dashboard-stat-null-value

# 6. Tạo PR
```

**Scenario 3: Refactor code**

```bash
# 1. Check latest develop
git pull origin develop

# 2. Tạo refactor branch
git checkout -b refactor/inline-style-to-css-modules

# 3. Refactor code
# ...

# 4. Commit
git commit -m "refactor(table-editor): extract inline styles to CSS modules"

# 5. Push
git push -u origin refactor/inline-style-to-css-modules

# 6. Tạo PR
```

## Tích hợp với jira-skill

Nếu jira-skill đã được load, agent có thể:

**Scenario 4: Tạo branch với ticket ID**

```bash
# Giả sử có ticket JIRA-12345 trong progress.md

# 1. Check latest develop
git pull origin develop

# 2. Tạo branch với ticket ID
git checkout -b feature/JIRA-12345-add-table-dependencies

# 3. Làm việc, code, test...
# ...

# 4. Commit
git commit -m "feat(table-editor): add table dependencies feature [JIRA-12345]"

# 5. Push
git push -u feature/JIRA-12345-add-table-dependencies

# 6. Tạo PR
```

## Tóm tắt

| Hành động   | Lệnh                                         | Khi nào            |
| ----------- | -------------------------------------------- | ------------------ |
| Tạo branch  | `git checkout -b <type>/<short-description>` | Khi bắt đầu task   |
| Pull latest | `git pull origin develop`                    | Trước khi làm việc |
| Commit      | `git commit -m "<type>: <description>"`      | Khi xong task      |
| Push        | `git push -u origin <branch-name>`           | Sau khi commit     |
| Tạo PR      | `gh pr create ...`                           | Khi xong task      |

**Quy tắc vàng**: Không bao giờ commit/push trực tiếp lên develop — luôn tạo branch mới và sử dụng Conventional Commits.
