# 작업 이력 — 2026-06-08

## 종합

오늘 4개 흐름 — **관리자단(`malgn-helper-admin`) 기획부터 실 운영 화면·인증까지 일괄 진입**.

### 1. ADMIN-PLAN 기획서 완성 (6 라운드)

[doc/ADMIN-PLAN.md](../ADMIN-PLAN.md) 신설 + 5회 갱신:

- **1차**: IA(12 섹션) + 화면 명세 12종 + Week 1~5 단계별 구현
- **2차**: 3 역할 (`admin`/`developer`/`agent`) 권한 매트릭스 + 동영상 URL 정책 (Whisper 수동 트리거) + 운영 기본값 5건 확정
- **3차**: 표준답변 분류 체계 (`scope` + `topic` + `service_tag` + `tags`) + 이미지 자동 배치 3방식 + AI 초안 = `POST /chat` 재사용 + `/uncovered` 전용 페이지
- **4차**: `lms-private` → `lms-security` 라벨 변경 (민간보안 LMS 도메인 명시)
- **5차**: 사이드바 메뉴 §3-2~3-5 정의 — **5 그룹 × 17 메뉴**, 권한별 가시성, heroicons 아이콘
- **6차**: '미커버 질문' 정의 명확화 — 답변 없는 PMS 게시물(`inquiry-only`)과 구분

### 2. admin 골격 구현 (handoff_noti 디자인 톤 차용)

빈 보일러플레이트 → **256px LNB + 64px TopBar + 17 페이지 stub**.

| 영역 | 파일 |
| --- | --- |
| 의존성 | `@nuxt/ui@3.3.7` · `@tailwindcss/vite@4.3` · `lucide-vue-next` · DM Sans + Pretendard |
| 메뉴 데이터 | `composables/use-admin-menu.ts` — 5 그룹 × 17 메뉴 + 권한·배지 + 검색 |
| 컴포넌트 | `SidebarMenu.vue` · `TopBar.vue` · `PagePlaceholder.vue` |
| 레이아웃 | `layouts/default.vue` · `app.vue` |
| 페이지 | `pages/index.vue` (홈 KPI mockup) + 16개 stub |

초기 `@nuxt/ui` v4 설치 후 Nuxt 3 호환 미충족 발견 → v3.3.7로 다운그레이드.

### 3. 1순위 4 화면 실데이터 구현

PMS의 기존 데이터·컴포넌트를 admin에서 즉시 활용 가능한 4 메뉴 구현:

| 화면 | 데이터 소스 | 핵심 |
| --- | --- | --- |
| `/` 홈 | **신규** `GET /admin/kpi` | 실 KPI 4 카드 (표준답변·이미지·평가·이번 달 비용) + 최근 활동 10건 |
| `/cost` | 기존 `GET /admin/cost` | 7/30/90일 토글 + KPI 4 + 모델별 표 + 일별 추이 + 엔티티 분포 + 최근 호출 50건 |
| `/qa-evals` | 기존 `GET /admin/evals` | 정렬 4종(최신·점수↑·점수↓·지연) + 빈 결과 필터. 행 클릭 → **PMS `/posts/:id/eval` iframe 모달** |
| `/images` | **신규** `GET /image-assets` | 디바운스 검색 + source 필터 + 4:3 그리드 + 상세 모달(원본 + 메타) |

API 신규 2개 — `GET /admin/kpi`, `GET /image-assets(/:id)`.

### 4. tb_user 통합 로그인 (외부 SSO 결정 → tb_user 변경)

처음 외부 SSO 패턴 고려했다가 **PMS의 `tb_user`(`login_id` + `passwd` SHA-256)를 그대로 사용**하는 통합 인증으로 결정.

| 영역 | 변경 |
| --- | --- |
| `wrangler secret` | `JWT_SECRET` 등록 (`openssl rand -hex 32`) |
| CORS | `credentials: true` + `Authorization` 헤더 허용 |
| API 엔드포인트 | `POST /auth/login` · `POST /auth/logout` · `GET /auth/me` |
| 검증 흐름 | `tb_user.passwd === sha256(input)` + 직원 룰(`@malgnsoft.com` OR `company='맑은소프트'`) |
| 세션 | JWT 8h, `Set-Cookie helper_session=...; HttpOnly; Secure; SameSite=None` |
| admin | `composables/use-auth.ts` · `middleware/auth.global.ts` · `pages/login.vue` · 사이드바·TopBar 실 사용자·로그아웃 |
| 역할 매핑 | `level ≥ 9` admin / `≥ 5` developer / 그 외 agent |

PMS는 인증 강제 X (현 흐름 유지).

### 결정/사건

- 외부 사이트 SSO 패턴 검토 후 **tb_user 통합으로 전환** — 인증 책임이 한 곳에 집중되어 일관성·관리성 ↑
- **SHA-256 단독 hash 약점** 인지 — 운영 강화 시 bcrypt/argon2 마이그레이션 (첫 로그인 시 재해시) 권장 (보안 메모)
- handoff_noti_admin 디자인을 admin 톤의 베이스로 차용 — 컴포넌트 룩앤필만, 콘텐츠는 우리 메뉴
- 미커버 질문 = 챗봇 운영 후 자동 수집 (Phase 2). 답변 없는 PMS 게시물(inquiry-only)과 별개임을 명확히

### 검증

- `POST /auth/login {"loginId":"1","password":"wrong"}` → `{"error":"invalid credentials"}` 401 ✅
- `GET /admin/kpi` → `{ standardAnswers: 3, images: 24, evals: 35, avgScore: 3.7, monthCalls: 112 }` 실데이터 ✅

### 다음 작업 후보

- **2순위 마이그레이션** — `hp_topic` + `hp_service` 신설 + `hp_standard_answer` 컬럼 보강 → `/catalog` · `/standard-answers` 정식 활성
- **`hp_account` + `hp_audit_log`** 신설 → admin `/accounts` · `/audit-logs` 동작
- **API 라우트별 `requireAuth/requireRole` 미들웨어 적용** — 현재 인증 검증은 admin 측만, API는 무인증 호출 가능
- **SHA-256 → bcrypt 마이그레이션 계획** (보안 강화)

---

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
