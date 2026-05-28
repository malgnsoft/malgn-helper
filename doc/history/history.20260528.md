# 작업 이력 — 2026-05-28

## 요약

`malgn-helper-pms`(PMS 애드온) 정의 추가 → 4개 GitHub repo 연결 → Cloudflare Workers/Pages 보일러플레이트 셋업 → Pages 프로젝트 생성 → 다중 계정 대응(account_id 명시)까지 완료. 4개 워크스페이스가 모두 즉시 배포 가능한 상태.

---

## 작업 내역

### 1. `malgn-helper-pms` 정의 추가

- [CLAUDE.md](../../CLAUDE.md): 프로젝트 구성 3개 → 4개로 확장. PMS 애드온 항목 추가
- 데이터 흐름 다이어그램에 **PMS 상담사 화면 → malgn-helper-pms** 진입 경로 추가
- 작업 규칙: `malgn-helper-pms`는 DB·LLM 직접 접근 금지, 반드시 `malgn-helper-api` 경유

### 2. GitHub 연결 (4개 repo)

각 디렉토리에 `git init -b main` + `git remote add origin <URL>`:

| 디렉토리 | 원격 |
| --- | --- |
| `malgn-helper` | https://github.com/malgnsoft/malgn-helper.git |
| `malgn-helper-admin` | https://github.com/malgnsoft/malgn-helper-admin.git |
| `malgn-helper-api` | https://github.com/malgnsoft/malgn-helper-api.git |
| `malgn-helper-pms` | https://github.com/malgnsoft/malgn-helper-pms.git |

### 3. 첫 커밋 + 푸시

- `malgn-helper`: CLAUDE.md + README.md + .gitignore + doc/ (총 11 파일, 2344 줄)
- 나머지 3 repo: README.md + .gitignore

### 4. Cloudflare 보일러플레이트

| Repo | 스택 | 추가 파일 |
| --- | --- | --- |
| `malgn-helper` | Nuxt 3 / Pages | `package.json`, `nuxt.config.ts`, `app.vue` |
| `malgn-helper-admin` | Nuxt 3 / Pages | `package.json`, `nuxt.config.ts`, `app.vue` |
| `malgn-helper-api` | Hono / Workers | `package.json`, `wrangler.jsonc`, `src/index.ts`, `tsconfig.json` |
| `malgn-helper-pms` | Hono / Workers | `package.json`, `wrangler.jsonc`, `src/index.ts`, `tsconfig.json` |

`pnpm install` 4개 repo 모두 완료. README에 개발·배포 명령 추가.

### 5. Cloudflare Pages 프로젝트 생성

- `wrangler pages project create malgn-helper --production-branch main`
- `wrangler pages project create malgn-helper-admin --production-branch main`
- 계정: **Info@malgnsoft.com** (`d2b8c5524b7259214fa302f1fecb4ad6`)
- 배포 URL (첫 deploy 후 활성화):
  - https://malgn-helper.pages.dev/
  - https://malgn-helper-admin.pages.dev/

> Workers 2개(`-api`, `-pms`)는 첫 `wrangler deploy` 시점에 자동 생성.

### 6. 다중 계정 대응 — `account_id` 명시

다중 계정 환경에서 매번 `CLOUDFLARE_ACCOUNT_ID` 환경변수를 지정해야 하던 문제 제거:

- Workers (-api, -pms): `wrangler.jsonc`에 `"account_id"` 추가
- Pages (helper, -admin): `wrangler.toml` 신규 (name + account_id + compatibility_date + pages_build_output_dir)
- Pages 2개의 `package.json` deploy 스크립트 간소화 → `nuxt build && wrangler pages deploy`

---

## 커밋 요약

| Repo | 오늘 커밋 (시간순) |
| --- | --- |
| `malgn-helper` | `1e612b8` 초기 문서 → `d1c7b4a` Nuxt 보일러플레이트 → `065e6ff` Pages config |
| `malgn-helper-admin` | `d92f689` README → `9dfc2c5` Nuxt 보일러플레이트 → `5052765` Pages config |
| `malgn-helper-api` | `1416518` README → `f21e53c` Hono 보일러플레이트 → `8ea04c5` account_id |
| `malgn-helper-pms` | `1dd81d4` README → `5207784` Hono 보일러플레이트 → `4728faf` account_id |

---

## 외부 리소스 변경

| 시스템 | 변경 |
| --- | --- |
| GitHub | 4개 repo에 main 브랜치 생성 + 초기 커밋 푸시 |
| Cloudflare (Info@malgnsoft.com) | Pages 프로젝트 2개 생성 (`malgn-helper`, `malgn-helper-admin`) |

---

## 다음 단계 후보

- [ ] 첫 Workers/Pages 배포 시도 — `pnpm deploy` × 4
- [ ] [wbs.md](../wbs.md) **P1-1.4 Aurora MySQL + Hyperdrive 바인딩** — Aurora 프로비저닝 후 `wrangler.jsonc`에 `HYPERDRIVE` 바인딩 추가
- [ ] **P1-1.6 R2 버킷 생성** — `wrangler r2 bucket create malgn-helper-files` + 바인딩
- [ ] **P1-1.7 OpenSearch 도메인 프로비저닝**
- [ ] **P1-1.8 AI Gateway 설정** + Anthropic API 키 secret 등록 (`wrangler secret put ANTHROPIC_API_KEY`)
- [ ] [doc/roadmap.md](../roadmap.md) **Phase 1 M1** 인프라 Ready 게이트 점검
