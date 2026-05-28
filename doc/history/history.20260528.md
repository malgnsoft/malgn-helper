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
| `malgn-helper-pms` | Nuxt 3 / Pages | `package.json`, `nuxt.config.ts`, `app.vue`, `wrangler.toml` (재구성 — §9 참조) |

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

- [ ] 첫 Workers/Pages 배포 시도 — `./scripts/deploy.sh <repo> "<msg>"`
- [ ] [WBS.md](../WBS.md) **P1-1.4 Aurora MySQL + Hyperdrive 바인딩** — Aurora 프로비저닝 후 `wrangler.jsonc`에 `HYPERDRIVE` 바인딩 추가
- [ ] **P1-1.6 R2 버킷 생성** — `wrangler r2 bucket create malgn-helper-files` + 바인딩
- [ ] **P1-1.7 OpenSearch 도메인 프로비저닝**
- [ ] **P1-1.8 AI Gateway 설정** + Anthropic API 키 secret 등록 (`wrangler secret put ANTHROPIC_API_KEY`)
- [ ] [doc/ROADMAP.md](../ROADMAP.md) **Phase 1 M1** 인프라 Ready 게이트 점검

---

## 추가 작업 (이력 시스템·배포 자동화)

### 7. 일단위 작업 이력 도입

- [doc/history/history.20260528.md](history.20260528.md) (본 파일) 신규 — 오늘 작업 6건 정리
- 메모리에 규칙 저장: `doc/history/history.yyyyMMdd.md`에 매일 누적 기록 (덮어쓰기 X)
- [CLAUDE.md](../../CLAUDE.md) 직접 변경은 없음. 메모리·MEMORY.md 인덱스 갱신

### 8. 배포 일괄 처리 스크립트

- [scripts/deploy.sh](../../scripts/deploy.sh) 신규 — 4단계 일괄 처리:
  1. `git commit -m <msg>` (변경 없으면 skip)
  2. `git push`
  3. `pnpm deploy` (Workers/Pages 자동 분기 — `wrangler.toml` 존재 여부로)
  4. `doc/history/history.{yyyyMMdd}.md`의 `## 배포` 섹션에 항목 append
- 사용법: `./scripts/deploy.sh <repo> "<commit message>"`
- [CLAUDE.md](../../CLAUDE.md)에 `## 배포 절차` 섹션 추가 — 일괄 스크립트 사용법 + 수동 절차 + 규칙
- 배포 실패·secret 변경·`account_id` 규칙 모두 문서화

### 9. `malgn-helper-pms` 스택 전환 — Workers → Pages

사용자 결정 변경에 따라 PMS 애드온 스택을 Hono Workers에서 Nuxt 3 / Pages로 전환.

- 제거: `src/index.ts`, `wrangler.jsonc`, `tsconfig.json` (Hono Worker 보일러플레이트)
- 추가: `nuxt.config.ts`, `app.vue`, `wrangler.toml` (Pages config, account_id 포함)
- `package.json` 의존성 교체: `hono` → `nuxt`. deploy 스크립트 `wrangler pages deploy`로 변경
- `README.md` 스택 섹션 갱신 (Hono on Workers → Nuxt 3 / Pages, iframe·위젯 임베드 명시)
- Cloudflare Pages 프로젝트 생성: `wrangler pages project create malgn-helper-pms` → https://malgn-helper-pms.pages.dev/
- [CLAUDE.md](../../CLAUDE.md) 데이터 흐름 다이어그램에서 pms 라벨을 `(Nuxt 3 / Pages, PMS 임베드)`로 명시
- 본 history 파일 §4 표의 pms 행 갱신 (Workers → Pages)

### 10. 첫 Cloudflare 배포 + 배포 환경 이슈 수정

4개 repo 전체를 Cloudflare에 최초 배포. 진행 중 세 가지 이슈 발견·수정.

**발견된 이슈**

| # | 증상 | 원인 |
| --- | --- | --- |
| 1 | `ERR_PNPM_CANNOT_DEPLOY  A deploy is only possible from inside a workspace` | `pnpm deploy`는 pnpm 워크스페이스 예약어. 스크립트 호출은 `pnpm run deploy`여야 함 |
| 2 | `Configuration file for Pages projects does not support "account_id"` | Pages용 `wrangler.toml`은 `account_id` 필드 미지원 (Workers만 지원) |
| 3 | Nuxt 빌드 산출물이 `dist/`인데 `wrangler.toml`은 `.output/public`로 설정 | Nuxt 3 cloudflare-pages preset의 실제 출력은 `dist/` |

**수정 사항**

- `scripts/deploy.sh`: `pnpm deploy` → `pnpm run deploy` 로 변경. Pages용으로 `CLOUDFLARE_ACCOUNT_ID` env 변수 export 추가
- `malgn-helper` / `-admin` / `-pms`의 `wrangler.toml`: `account_id` 제거 + `pages_build_output_dir = "dist"`
- [CLAUDE.md](../../CLAUDE.md) `## 배포 절차`의 account_id 안내 갱신 (Workers와 Pages 차이, `pnpm run deploy` 명시, 출력 디렉토리 `dist/` 명시)

**배포 결과**

| Repo | Production URL | 커밋 |
| --- | --- | --- |
| `malgn-helper-api` | https://malgn-helper-api.malgnsoft.workers.dev | `8ea04c5` |
| `malgn-helper-pms` | https://malgn-helper-pms.pages.dev/ | `676724d` |
| `malgn-helper` | https://malgn-helper.pages.dev/ | `cf1e931` |
| `malgn-helper-admin` | https://malgn-helper-admin.pages.dev/ | `a613e64` |

`scripts/deploy.sh`가 4건 모두 자동 처리 (commit-skip 또는 fix 커밋 → push → build·deploy → 이력 append).

### 11. 브리핑 카드 예시 저장

- [doc/examples/현대엔지비.md](../examples/현대엔지비.md) 신규 — `# 현대엔지비 LMS` 프로젝트 브리핑 카드 예시
- 같은 폴더의 [안전보건진흥원.md](../examples/안전보건진흥원.md)는 풀 평가(케이스 스터디), 본 파일은 [customer-briefing.md](../prompts/customer-briefing.md) 프롬프트로 만든 짧은 카드 — 두 양식 비교 가능
- 안전보건진흥원과의 비교표 포함 → 양극단 케이스 한눈에 확인 가능

## 배포

### 11:39 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `8ea04c5` (신규 커밋: no)
- 메시지: chore: Cloudflare 최초 배포

### 11:41 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `676724d` (신규 커밋: yes)
- 메시지: chore: Cloudflare 최초 배포

### 11:41 — `malgn-helper` → Cloudflare Pages
- 커밋: `cf1e931` (신규 커밋: yes)
- 메시지: chore: Cloudflare 최초 배포

### 11:42 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `a613e64` (신규 커밋: yes)
- 메시지: chore: Cloudflare 최초 배포
