# 08 - UI/UX Standards & Frontend Integration

> **Priority:** High | **Complexity:** Medium
> **Estimated Time:** 3 days

## Summary | Tóm tắt

**EN:** Setup a dedicated React/Next.js frontend relying on `vercel-react-best-practices` as the primary UI. Alternatively, structure Typesafe Frontend Server-Side Rendering (SSR) functionality using Handlebars (`.hbs`), embedded within the NestJS backend using the `BaseAssetsModule` pattern if backend tight coupling is needed (`server-side-render` skill).

**VI:** Coi React/Next.js làm frontend chính thức. Nhưng nếu cần, có thể xây dựng tính năng SSR (Server-Side Rendering) thông qua Handlebars (`.hbs`), nhúng hoàn toàn vào NestJS thông qua pattern `BaseAssetsModule` (`server-side-render`). API vẫn tách bạch rõ ràng độc lập.

---

## Proposed Changes | Các thay đổi đề xuất

### 8.1 SSR Module Setup

**File:** `src/presentation/portal/data-builder/data-builder-assets.module.ts`

**EN:**

- Import and extend `BaseAssetsModule` defined in `libs/src/common/modules/assets-base`.
- Set configuration via `getConfig()` including `moduleName: 'data-builder'` and a `publicPath`.
- The main `app.module.ts` initializes this via `BaseAssetsModule.setupAssets(app)`.

**VI:**

- Gọi và kế thừa `.claude/skills/server-side-render` SDK (`BaseAssetsModule`).
- Thiết lập biến `getConfig()` tương ứng: `moduleName: 'data-builder'` và `publicPath`.
- Đảm bảo class `main.ts` kích hoạt cấu hình `BaseAssetsModule.setupAssets()`.

### 8.2 Client Assets Configuration & Design System

**Files:** `public/` (Backend SSR) & Next.js/React App (Frontend)

**EN:**

- **Backend Assets**: Client assets for backend rendering must be placed in the root `public/` directory.
- **Frontend Architecture (The 7 Modules Layout)**: Adhere to `.claude/skills/vercel-react-best-practices`. The main workspace layout must emulate Supabase Studio UX via a **3-column Contextual Sidebar System**: (1) Primary Nav Sidebar (Icons), (2) Secondary Context Sidebar (Lists/Search), and (3) Main Workspace Area with floating AI Agent panels.
- **Design System Metrics**:
    - **Font**: Google Font `Lato, sans-serif` globally.
    - **Colors**: Primary Brand `#509EE3` (Picton Blue), Surface Background `#071722` (Dark) / `#FFFFFF` (Light), Main Background `#050E15` (Dark) / `#F9F9FA` (Light).
    - **Borders & Spacing**: Elements consistently use `8px` border radius (`6px` for buttons) and large paddings (e.g. `24px` for Data Cards) adhering to the negative-space principles discovered in `.claude/skills/ui-ux`.
    - **Eliminate Waterfalls**: Strongly utilize `React.Suspense` for Data Cards arrays rather than centralized loading spinners.

**VI:**

- **Backend Assets (SSR)**: Toàn bộ static assets của NestJS backend phục vụ SSR phải được đặt trong thư mục `public/` ở thư mục gốc của project.
- **Frontend Architecture**: Cấu trúc UI của frontend phải tuân thủ nghiêm ngặt theo `.claude/skills/vercel-react-best-practices` với React/Next.js.
- **Hệ thống Design System**:
    - **Phông chữ**: `Lato, sans-serif` toàn cục.
    - **Màu sắc**: Màu Brand Primary `#509EE3` (Picton Blue), Nền thẻ Surface `#071722` (Dark) / `#FFFFFF` (Light), Nền Body `#050E15` (Dark) / `#F9F9FA` (Light).
    - **Kích thước**: Bo góc thẻ `8px` (nút bấm `6px`), Padding thẻ cực kì thoáng (`24px` cho Data Cards) dựa theo lý thuyết khoảng không gian âm từ `.claude/skills/ui-ux`.

### 8.3 SSR Controller

**File:** `src/presentation/portal/data-builder/controllers/data-builder-ssr.controller.ts`

**EN:**

- Extend `AssetsBaseController` to utilize `buildEditorViewData`.
- Create a GET endpoint decorated with `@Render('data-builder')` to push server configuration into the global client `window` variables.

**VI:**

- Kế thừa `AssetsBaseController`.
- Cài đặt GET Route trang trí với `@Render('data-builder')` để push các biến cấu hình từ NestJS vào global `window` object giúp JS front-end dễ truy cập.

## Verification | Xác minh

- Users accessing the Data Visualizer path see the Handlebars compiled HTML with dynamically injected internal endpoints.
- Tailwind classes bind accurately to DOM rendered on initial navigation.
