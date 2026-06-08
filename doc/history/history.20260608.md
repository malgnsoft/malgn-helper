# 작업 이력 — 2026-06-08


## 배포

### 16:17 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `b3cfcad` (신규 커밋: yes)
- 메시지: feat(admin): 사이드바 메뉴 구조 + 레이아웃 + 17 페이지 stub (handoff_noti 디자인 톤 적용)

- Nuxt UI v3 + Tailwind v4 + Lucide + DM Sans/Pretendard 도입
- composables/use-admin-menu.ts: 5 그룹 × 17 메뉴 + 권한·배지 정의
- components/admin/SidebarMenu.vue: 256px LNB (브랜드·검색·그룹 접기·뱃지·사용자칩)
- components/admin/TopBar.vue: 64px sticky (breadcrumb·검색·환경 토글·알림·로그아웃)
- layouts/default.vue + app.vue 골격
- pages/index.vue: 홈 KPI 4종 + 최근 활동 mockup
- pages/{16개} stub: AdminPagePlaceholder 컴포넌트로 통일

### 16:42 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `cc7fc47` (신규 커밋: yes)
- 메시지: feat(api): GET /image-assets + GET /admin/kpi — admin 1순위 화면 데이터 소스

### 16:50 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `69db1e8` (신규 커밋: yes)
- 메시지: feat(admin 1순위): 홈 KPI 실데이터 + /cost + /qa-evals(iframe 모달) + /images 그리드

### 17:37 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `cfe84a4` (신규 커밋: yes)
- 메시지: feat(auth): /auth/login·logout·me + JWT(8h httpOnly cookie) — tb_user 통합 인증

### 17:40 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `6f412e5` (신규 커밋: yes)
- 메시지: feat(auth): tb_user 통합 로그인 — /login + auth.global 미들웨어 + JWT httpOnly cookie 세션 (8h)
