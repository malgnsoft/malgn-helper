# Malgn Helper — 고객상담 AI 챗봇

NotebookLM 수준의 사내 솔루션 전문 고객상담 AI 챗봇.
자사 솔루션 사용 방법·안내를 자동화하여 상담 비용을 절감하고 24/7 응답 채널을 확보한다.

## 프로젝트 구성

이 워크스페이스는 역할별로 5개의 독립 디렉토리로 분리되어 있다 (제품 4 + 관리 허브 1).

- `malgn-helper/` — **사용자 프론트엔드** (고객이 챗봇과 대화하는 화면). Nuxt 3 / Cloudflare Pages.
- `malgn-helper-admin/` — **관리자 프론트엔드** (자료 업로드, 표준 답변 관리, 상담 로그/에스컬레이션 검토).
- `malgn-helper-api/` — **API 서버** (Hono on Cloudflare Workers). 검색·LLM·DB 접근을 모두 담당.
- `malgn-helper-pms/` — **PMS 애드온** (맑은프로젝트게시판 PMS에 탑재되는 상담사 도우미). PMS 내부에서 동작하며 `malgn-helper-api`를 호출해 **고객 문의 답변 추천** + **고객 문의 분석/브리핑**을 PMS 상담사에게 제공.
- `malgn-helper-mng/` — **프로젝트 관리 허브** (대시보드·현황판·WBS·문서·작업 이력). 제품 코드가 아닌 이 프로젝트의 운영·조망용. Nuxt 3 / Cloudflare Pages + D1.

## 핵심 요구사항

- **NotebookLM 수준의 답변 품질**: 업로드된 자료에 근거한 정확한 답변 + 출처 인용
- **정확성·일관성 우선**: 같은 질문에 매번 같은 답변, 잘못된 안내 방지
- **표준 답변 우선 사용**: 회사가 검증한 답변이 있으면 그것을 사용
- **"모르면 모른다"**: 추측 금지. 모호하면 상담사에게 에스컬레이션
- **데이터 소스**: 매뉴얼 문서, 동영상, 기존 Q&A DB
- **한국어 컨텐츠 비중 높음**

## 인프라 제약

- 프론트엔드/백엔드는 **Cloudflare** (Pages + Workers)
- RDB는 **Aurora MySQL**, **Hyperdrive**로 연결
- 검색 인프라는 외부 **AWS OpenSearch Service** (k-NN + BM25 하이브리드)
- 원본 파일 저장소는 **Cloudflare R2**
- 인덱싱은 **MVP에서 동기 처리**. 동영상/대용량 자료가 늘어나면 **Cloudflare Queues + Indexer Worker**로 2단계 도입.
- LLM 호출은 **Cloudflare AI Gateway** → **OpenAI** (기본 `gpt-4o-mini`, 고품질 작업은 `gpt-4o`)
  - Gateway 이름: `malgn-helper`
  - Worker 환경변수: `AI_GATEWAY_URL` (vars), `OPENAI_API_KEY` (secret)

## 데이터 흐름

```
사용자 브라우저       관리자 브라우저       PMS 상담사 화면
      │                  │                      │
      ▼                  ▼                      ▼
malgn-helper      malgn-helper-admin       malgn-helper-pms
(Nuxt 3 / Pages)  (Nuxt 3 / Pages)         (Nuxt 3 / Pages, PMS 임베드)
      │                  │                      │
      └──────────────────┼──────────────────────┘
                         ▼
                  malgn-helper-api
                  (Hono / Workers)
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   Hyperdrive       OpenSearch           R2
      │             (k-NN+BM25)       (원본파일)
      ▼
 Aurora MySQL

                         ▼
                  AI Gateway → OpenAI

  ※ 향후 동영상/대용량 자료 도입 시:
    Queue → Indexer Worker 비동기 파이프라인 추가
```

## 작업 시 유의사항

- 답변 생성 로직은 **출처 인용이 누락되지 않도록** 보장한다.
- 검색은 하이브리드(벡터 + BM25)를 전제로 한다. 한쪽만 쓰는 변경은 의도와 영향 범위를 명확히.
- "표준 답변" 매칭이 검색·생성 파이프라인보다 우선한다.
- LLM이 자신 없을 때는 답변을 짜내지 말고 에스컬레이션 경로로 빠진다.
- DB 접근은 Worker → Hyperdrive 경유. 직접 연결 코드 금지.
- 모든 LLM 호출은 AI Gateway를 통과시켜 캐싱·로깅·rate limit을 적용한다.
- `malgn-helper-pms`는 PMS 시스템 내부에서 동작하지만 **DB·LLM 직접 접근 금지** — 반드시 `malgn-helper-api`를 통해 호출한다 (인증/권한·로깅 일원화).

## 배포 절차

서브프로젝트(`malgn-helper` / `-admin` / `-api` / `-pms`) 배포 시 **커밋 → 푸시 → Cloudflare deploy → 이력 기록**을 일괄 처리한다.

### 일괄 스크립트 (권장)

워크스페이스 루트(`malgn-helper`)에서:

```bash
./scripts/deploy.sh <repo-name> "<commit message>"
```

- `<repo-name>`: `malgn-helper` | `malgn-helper-admin` | `malgn-helper-api` | `malgn-helper-pms` | `malgn-helper-mng`
- 스크립트가 자동 실행하는 4단계:
  1. `git add -A && git commit -m "<message>"` (변경 없으면 commit skip)
  2. `git push`
  3. 해당 repo에서 `pnpm deploy` — `wrangler.toml` 존재 여부로 Pages/Workers 자동 분기
  4. `doc/history/history.{yyyyMMdd}.md`의 `## 배포` 섹션에 항목 append (파일 없으면 생성)

### 수동 절차 (스크립트 미사용 시)

```bash
cd ~/Projects/<repo>
git add . && git commit -m "<message>"
git push
pnpm deploy
# doc/history/history.{yyyyMMdd}.md에 배포 항목 직접 추가
```

### 규칙

- 변경된 repo만 배포. 전체 일괄 배포 금지.
- Secret 변경은 별도 — `wrangler secret put <KEY>` 후 deploy.
- 배포 실패 시 history에 실패 사유 함께 기록.
- 이력 파일은 누적 — 같은 날 추가 배포는 기존 파일에 항목만 추가.
- **account_id 주입 방식**:
  - Workers (`wrangler.jsonc`)는 `account_id` 필드를 지원 → 파일에 명시.
  - Pages (`wrangler.toml`)는 `account_id` 필드 **미지원** → `scripts/deploy.sh`에서 `CLOUDFLARE_ACCOUNT_ID` 환경변수로 주입.
  - 수동 배포 시 Pages는 `CLOUDFLARE_ACCOUNT_ID=... pnpm run deploy` 형태로 실행 필요.
- **`pnpm deploy` 대신 `pnpm run deploy`** — `deploy`는 pnpm 예약어라 충돌. 항상 `run`을 명시.
- **Nuxt Cloudflare Pages 출력 디렉토리는 `dist/`** — `wrangler.toml`의 `pages_build_output_dir`도 `dist`로 설정.
