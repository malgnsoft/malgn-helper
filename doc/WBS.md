# WBS (Work Breakdown Structure)

> SI 표준 단계(착수/분석 → 설계 → 구현 → 교육·연동 → 테스트 → 이행)를 **Phase별로 독립 적용**.
>
> - **Phase 1**: CS 관리자 + AI 추천 답변 (선행 — 자료/답변 자산을 쌓고 상담사 보조)
> - **Phase 2**: CS 상담 챗봇 (Phase 1 자산을 활용한 고객 직접 응대)
>
> 각 Phase는 자체 착수→이행 사이클을 가진다. Phase 2는 Phase 1의 인프라·자료·표준답변을 재사용하므로 분석·설계 비중이 축소된다.
>
> **마지막 현행화**: 2026-06-01 · 일별 변경은 [doc/history/](history/)에 누적 기록.

---

## 진행률 스냅샷 (2026-06-01 기준)

| Phase / 단계 | 진행률 | 핵심 진행 사항 |
| --- | --- | --- |
| **Phase 1 · 착수/분석** | **95%** | 환경 검토·인프라 활성화·자료 인벤토리·요구사항 정의 모두 완료. 정식 요구사항 정의서만 잔여 |
| **Phase 1 · 설계** | **80%** | hp_* 4테이블 ERD·DDL 완성, OpenAPI 3.1 명세, Q&A 5축+templates 6종 스펙 확정. 검색 인덱스 매핑 미진 |
| **Phase 1 · 구현** | **65%** | API 22+ 엔드포인트, PMS 5페이지 + 폴리시 라운드, LLM 실연동(OpenAI via AI Gateway), Vision 이미지 분석. 자료 인덱싱·하이브리드 검색·관리자 UI 미진 |
| **Phase 1 · 교육·연동** | **35%** | OpenAPI(Scalar) + 배포·이력·분류·MySQL 인덱스 가이드 5종. 정식 상담사 교육·기존 시스템 연동 미진 |
| **Phase 1 · 테스트** | **10%** | UI 호환성·잘못된 캐시·CORS·Q&A 데이터 흐름 등 오류 처리 다수. 정식 단위·통합·UAT 미진 |
| **Phase 1 · 이행** | **30%** | API + PMS 데모 운영 단계 (40+회 deploy.sh 이력, 일별 사용자 검증 진행). 관리자·사용자 챗봇 본 기능 미배포 |

## 누적 완료 자산 (2026-06-01)

### 인프라

- ✅ 4개 GitHub repo 연결·첫 푸시 — `malgn-helper`, `-admin`, `-api`, `-pms`
- ✅ Cloudflare 환경 — Pages 3 (helper·admin·pms) + Workers 1 (api) 모두 운영
- ✅ wrangler 설정 (`wrangler.jsonc` / `wrangler.toml`) + account_id 명시
- ✅ 일괄 배포 스크립트 [`scripts/deploy.sh`](../scripts/deploy.sh) — commit + push + deploy + 이력 자동 기록 (40+회 실행)
- ✅ 일단위 작업 이력 [`doc/history/`](history/) 운영 — 일별 누적 (28일·29일 완료)
- ✅ **Cloudflare Hyperdrive** `pms` (id `aea3...`) — PMS MySQL(5.6.51) 연결 + read cache (1분)
- ✅ **Cloudflare R2** `malgn-helper-files` — WBS 영속화 + 원본 파일 저장소 준비
- ✅ **Cloudflare AI Gateway** `malgn-helper` (Authenticated, compat endpoint) — OpenAI 호출 캐싱·로깅·rate 일원화
- ✅ **시크릿**: `OPENAI_API_KEY`, `AI_GATEWAY_TOKEN`
- ⚪ Aurora MySQL (별도 — 현재는 PMS DB 직접 연결로 대체), OpenSearch (미설치)

### 문서·자산

- ✅ 워크스페이스 문서: [CLAUDE.md](../CLAUDE.md) · [README.md](../README.md) · [TECH-STACK.md](TECH-STACK.md) · [ROADMAP.md](ROADMAP.md) · 본 WBS · [LEGACY-DB-INVENTORY.md](LEGACY-DB-INVENTORY.md) · [PROJECT-INQUIRY-ANALYSIS.md](PROJECT-INQUIRY-ANALYSIS.md)
- ✅ **신규**: [HP-SCHEMA.md](HP-SCHEMA.md) (hp_* 4테이블 ERD/DDL) · [WBS-TRACKER.md](WBS-TRACKER.md) (WBS Live Tracker 사양) · [CLOUDFLARE-ACCESS.md](CLOUDFLARE-ACCESS.md) (`/admin/*` 보호 가이드) · [MYSQL-INDEXES.md](MYSQL-INDEXES.md) (4단계 폴백)
- ✅ 재사용 프롬프트 3종 ([prompts/](prompts/)): `cs-evaluation` · `customer-briefing` · `qa-evaluation`
- ✅ 케이스 스터디·예시 3종 ([examples/](examples/))
- ✅ **OpenAPI 3.1 명세** (수동 작성, 22개 엔드포인트) + Scalar API Reference UI (`/doc`)
- ✅ 일별 이력: [history/history.20260528.md](history/history.20260528.md) · [history/history.20260529.md](history/history.20260529.md)

### `malgn-helper-api` (Hono on Workers)

- ✅ 22+ 엔드포인트: `/pms/projects` · `/pms/posts/:id` · `/pms/projects/:id/briefing(/generate)` · `/pms/posts/:id/eval(/generate)` · `/pms/evals/:id` · `/standard-answers` (CRUD) · `/pms/projects/:id/standard-answer-suggestions` · `/admin/cost` · `/admin/evals` · `/healthz` · `/doc`
- ✅ Hyperdrive 경유 PMS DB 연결 + 직원/고객/협력사 분류 + 비공개 댓글 본문 마스킹
- ✅ LLM 실연동: OpenAI `gpt-4o-mini`(default) / `gpt-4o`(이미지 있을 때 자동 업그레이드) via AI Gateway
- ✅ `llm_input_hash` 기반 24h 캐시 + `hp_llm_log` 비용·지연·실패 감사
- ✅ **GPT-4o Vision** — 원본 응답의 이미지 절대URL을 직접 첨부, LLM이 화면 인지 후 캡션 작성
- ✅ 표준답변 컨텍스트 보강 — 같은 프로젝트 최근 5건을 LLM에 전달 (톤·구조 참고)
- ✅ Q&A 평가 prompt: 5축 + D축 templates 6종(짧은/긴/친절/비즈니스/FAQ/단계별), 4파트 구성 강제

### `malgn-helper-pms` (Nuxt 3 / Pages)

- ✅ 브리핑 카드 컴포넌트 + 모달 워크플로 (실 API 연동, mock 제거)
- ✅ Q&A 평가 카드 컴포넌트 + 모달 워크플로
- ✅ 임베드 인터페이스 — `?modal=open` 쿼리, `postMessage` 닫기 신호
- ✅ 표준답변 다중 템플릿 (6종) + "표준답변으로 저장" → API `POST /standard-answers`
- ✅ 페이지: `/projects` (1,653건 검색·페이지네이션) · `/projects/[id]` (브리핑) · `/projects/[id]/posts` · `/posts/[id]` (상세+분석 모달) · `/admin/evals` (Q&A 목록, 행 클릭→모달) · `/admin/cost` (LLM 비용 대시보드) · `/wbs` (WBS Live Tracker)
- ✅ UX 폴리시: 분석 모달은 valid 결과 도착 후 열기 / Q&A 본문 초기 접힘 / 빈 결과 시 "다시 시도" 모달 / 모달 안 삭제 → 서버+메모리 동기화

### `malgn-helper-admin` (Nuxt 3 / Pages)

- ✅ 보일러플레이트 + 첫 배포
- ⚪ 본 기능 미착수 (자료 업로드·표준답변 관리·에스컬레이션 검토)

### `malgn-helper` (사용자 챗봇 / Pages)

- ✅ 보일러플레이트 + 첫 배포
- ⚪ 본 기능 미착수 (챗 UI · RAG 응답)

### DB · 인덱스

- ✅ **hp_* 4테이블** (`hp_briefing` · `hp_qa_eval` · `hp_standard_answer` · `hp_llm_log`) — PMS DB에 공존, DDL 적용 완료
- ✅ MySQL 부하 대책: `tb_post (project_id, status, reg_date)` + `tb_post_comment (post_id, status, reg_date)` 인덱스 추가 → 91초→244ms
- ✅ `hp_qa_eval.overall_verdict` VARCHAR(20) → VARCHAR(100) 마이그레이션 (긴 평 저장)

### 운영 정책

- ✅ 분류 규칙: **직원** = `@malgnsoft.com` OR `tb_user.company='맑은소프트'` / **협력사** = 화이트리스트(플로즈·옐로우윈·온케어·송한나) / 그 외 = 고객 (이름·게시판 패턴 추정 금지 — 메모리 저장)
- ✅ 영업시간 FRT: KST 평일 09–17 + 한국 공휴일 Set 제외
- ✅ 브리핑 statusLabel 5단계(휴면/원활/주의/경고/긴급) + 미응답 임계값·LLM urgent 격상 룰 (LLM이 라벨 직접 결정 금지)
- ✅ 비공개 답변 처리 전략 — Phase 2 챗봇 응답에 직접 인용·출처 노출 금지 (메모리 저장)
- ✅ 첨부파일 처리 전략 (텍스트·이미지·동영상 단계별)
- ✅ 스레드 처리 전략 (단일 도큐먼트 압축 + 화자 라벨)
- ✅ Closing 패턴 가이드 (감사합니다 vs 행동 안내 분기)

---

## 단계별 가중치

| 단계 | 비중 |
| --- | --- |
| 1. 착수/분석 | 10% |
| 2. 설계 | 25% |
| 3. 구현 | 40% |
| 4. 교육 및 연동 | 20% |
| 5. 테스트 | 20% |
| 6. 이행 | 5% |

> 참고 가중치이며 일정 수립 시 Phase별 재산정.

**상태 범례**: ✅ 완료 · 🟢 진행 중 · ⚪ 대기 · ⛔ 보류

---

# Phase 1 — CS 관리자 + AI 추천 답변 (+ PMS 애드온)

## P1-1. 착수/분석 (10%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 1-1 | 요구사항 도출 | 🟢 | 답변 품질·출처 인용·"모름" 정책·표준답변 우선·상담사 채택 플로우 — CLAUDE.md/ROADMAP/HP-SCHEMA에 정의. 실 운영 검증으로 요구사항 추가 발굴 (영업시간 FRT, 직원/협력사/고객 분류, 5단계 statusLabel 등) | 정식 요구사항 정의서 별도 작성 필요 |
| 1-2 | 수행범위 정의 및 확인 | ✅ | Phase 1·2 분리, **4개 repo 정의** (helper / admin / api / **pms 신규**), PMS 애드온 범위 포함 | |
| 1-3 | 개발환경 검토 | ✅ | Cloudflare(Pages·Workers·R2·AI Gateway·Hyperdrive) 활성화 완료. PMS MySQL은 Hyperdrive 경유 연결 검증 완료. OpenSearch는 별도 진행 | wrangler·account_id 표준화 |
| 1-4 | 기본자료 검토 | ✅ | 레거시 PMS DB 인벤토리(1,358 Q&A 후보), 200+ 프로젝트 분포 분석, 비공개·첨부·스레드 처리 전략 수립. **27개 tb_* 테이블 구조 파악 완료** | [LEGACY-DB-INVENTORY.md](LEGACY-DB-INVENTORY.md), [PROJECT-INQUIRY-ANALYSIS.md](PROJECT-INQUIRY-ANALYSIS.md) |

## P1-2. 설계 (25%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 2-1 | 전체 진행 일정 (WBS) | ✅ | 본 문서 + 진행률 스냅샷 + WBS Live Tracker (`/wbs`) | 일별 [history/](history/) 누적, `/wbs` 인라인 편집 + R2 자동 저장 |
| 2-2 | 시스템 아키텍처 설계 | ✅ | CLAUDE.md 데이터 흐름, [TECH-STACK.md](TECH-STACK.md), 4 repo 책임 분리, [HP-SCHEMA.md](HP-SCHEMA.md) hp_* ERD, [CLOUDFLARE-ACCESS.md](CLOUDFLARE-ACCESS.md) 권한 모델 | 상세 시퀀스 다이어그램은 P2 진입 시 보강 |
| 2-3 | 화면명세서 작성 | 🟢 | PMS 카드 2종 (브리핑·Q&A 평가) + 페이지 7종 (`/projects` `/posts` `/admin/evals` `/admin/cost` `/wbs` 등) 실구현 명세 | 관리자(`malgn-helper-admin`) 본격 화면 명세 미진 |
| 2-4 | 데이터 설계 | ✅ | **hp_* 4테이블 ERD/DDL** ([HP-SCHEMA.md](HP-SCHEMA.md)) — `hp_briefing` · `hp_qa_eval` · `hp_standard_answer` · `hp_llm_log`. 인덱스·캐시 키·llm_input_hash 전략 포함 | OpenSearch 인덱스 매핑·R2 키 규칙은 Phase 1 후반·Phase 2 진입 시 |
| 2-5 | 디자인 시안 | 🟢 | 브리핑·Q&A 평가 카드(Notion-clean) + PMS 페이지 디자인(Tailwind v4 + Soft SaaS 톤) | 관리자·사용자 챗봇 화면 시안 미진 |
| 2-6 | AI 프로토타입 서비스 구현 | ✅ | **실 LLM 호출 운영 중** — `/pms/projects/:id/briefing/generate` · `/pms/posts/:id/eval/generate` 24h 캐시 + Vision + 표준답변 컨텍스트 | 챗봇용 RAG(검색→인용→"모름" 가드)는 Phase 1 후반 신설 예정 |

## P1-3. 구현 (40%)

### DB

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-1 | DB 구축 | 🟢 | **Hyperdrive `pms` 바인딩** + **hp_* 4테이블 적용** (`hp_briefing` · `hp_qa_eval` · `hp_standard_answer` · `hp_llm_log`). `overall_verdict` VARCHAR(100) 마이그레이션, MySQL 인덱스 추가 | Aurora 별도 인스턴스는 미진(현재는 PMS DB 공존 운영) |

### 디자인 / 퍼블리싱

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-2 | Front 디자인 | 🟢 | PMS 카드 2종 + 페이지 7종(`/projects` `/posts` `/admin/*` `/wbs`) 디자인 통합 | 관리자(`malgn-helper-admin`)·사용자 챗봇 본격 화면 미진 |
| 3-3 | Front 퍼블리싱 | 🟢 | Nuxt 3 컴포넌트: `BriefingCard.vue` · `QaEvalCard.vue` · `QaAxisCard.vue` · `QaScoreSummary.vue` 외 보조 컴포넌트 + 7개 페이지 라우트 | |
| 3-4 | 디자인/퍼블리싱 검수 | 🟢 | Tailwind v4 + Nuxt UI v3 호환성 이슈 다회차 수정, `fixPmsHtml`로 `/data/` 자산 도메인 prefix 처리, prose dark/light 정합 | 추가 회귀 검증 필요 |

### API (`malgn-helper-api`)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-5 | 워커 및 프레임워크 설치 | ✅ | Hono on Workers + 운영 (https://malgn-helper-api.malgnsoft.workers.dev) + Hyperdrive·R2·AI Gateway 바인딩 활성 | |
| 3-6 | API 개발 | 🟢 | **22+ 엔드포인트** — `/pms/projects` 목록·상세·브리핑(generate)·게시글·Q&A 평가(generate)·평가 CRUD/삭제·`/standard-answers` CRUD·표준답변 추천·`/admin/cost`·`/admin/evals` · OpenAPI(`/doc`). 캐시·감사·Vision·문서 컨텍스트 모두 연동 | 자료 인덱싱·하이브리드 검색·챗봇 응답 파이프라인 미진 |

### Admin (`malgn-helper-admin`)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-7 | AI 설정 페이지 | ⚪ | Nuxt 3 보일러플레이트만, 첫 배포 (https://malgn-helper-admin.pages.dev/) | 자료/표준답변/모델 설정 화면 미진 |
| 3-8 | AI 시연 페이지 개발 | ⚪ | — | 문의→추천답변→채택 플로우 미진. 현재는 PMS 측 분석 모달이 유사 역할 수행 |

### PMS 애드온 (`malgn-helper-pms`)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-9 | 브리핑 카드 컴포넌트 통합 | ✅ | `BriefingCard.vue` + types/data/composables + 모달 워크플로 | |
| 3-10 | Q&A 평가 카드 컴포넌트 통합 | ✅ | `QaEvalCard.vue` + `QaAxisCard.vue` + `QaScoreSummary.vue` + 표준답변 6종 (짧은/긴/친절/비즈니스/FAQ/단계별) | |
| 3-11 | 워크플로 페이지 | ✅ | `/projects/[id]` 빈 상태 → AI 생성 → 모달. 서버 히스토리 fetch (localStorage v1 자동 정리) | |
| 3-12 | 임베드 인터페이스 | ✅ | `?modal=open` 쿼리, `window.open`·iframe 호환, `postMessage` 닫기 신호 | |
| 3-13 | 표준답변 다중 템플릿 + 저장 | ✅ | D축 templates 6개 LLM 자동 생성 → "표준답변으로 저장" → `POST /standard-answers` 영속화 | |
| 3-14 | 실제 API 연동 | ✅ | 브리핑·Q&A 평가·표준답변·삭제·검색 모두 `malgn-helper-api` 호출로 전환. mock 제거 | |
| 3-15 | Q&A 평가 카드 워크플로 페이지 | ✅ | `/admin/evals` 목록(정렬·필터·점수 색 분기) + 행 클릭 → `QaEvalCard` 모달. 빈 결과 행은 기본 숨김(`?includeEmpty=1`) + `/posts/:id` 상세 안 "AI 문의 답변 분석" 모달 | LLM 행만 모달 즉시 열기 폴리시 추가 검토 중 |
| 3-16 | UX 폴리시 라운드 | ✅ | **분석 모달은 valid 결과 도착 후만 표시** (빈 0점 모달 노출 fix) · Q&A 본문 초기 접힘 · 빈 결과 → "다시 시도" 모달 · 모달 안 🗑 삭제 → 서버+메모리 동기화 · followups 빈 섹션 완전 제거 (schema·prompt·UI·clipboard 4곳) | |
| 3-17 | LLM 품질 라운드 | ✅ | **GPT-4o Vision** 이미지 직접 분석 + 캡션 배치 · 표준답변 컨텍스트 (같은 프로젝트 최근 5건) · 4파트 답변 강제(인사/공감/핵심/보조/마무리) · maxTokens 6000→8000 | |

## P1-4. 교육 및 연동 (20%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 4-1 | 개발자 가이드 작성 | 🟢 | CLAUDE.md 배포 절차·LLM 모델·secret 규칙, deploy.sh 사용법, history 시스템 메모리, 분류·표준답변·캐싱 메모리, **OpenAPI(Scalar)** 22 엔드포인트, [MYSQL-INDEXES.md](MYSQL-INDEXES.md) 4단계 폴백, [CLOUDFLARE-ACCESS.md](CLOUDFLARE-ACCESS.md) | 자료 인덱싱·표준답변 큐레이션 가이드 미진 |
| 4-2 | 개발자 교육 | ⚪ | — | 상담사 사용 교육 미진 |
| 4-3 | 서비스 연동 | ⚪ | — | 기존 CS 시스템/SSO 연동 미진. PMS DB는 Hyperdrive 경유 직접 연결로 확보 |

## P1-5. 테스트 (20%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 5-1 | 베타 오픈(테스트 서버) | 🟢 | PMS·API 운영 단계 진입 — 사용자가 실 게시물(149694 등)로 일별 검증 중 | 정식 베타 사용자 범위·SLA 미진 |
| 5-2 | 단위 테스트 | ⚪ | — | API·LLM·캐시 키 단위 테스트 |
| 5-3 | 통합 테스트 | ⚪ | — | 자료 업로드→인덱싱→검색→추천→채택 E2E |
| 5-4 | 오류 수정작업 | 🟢 | UI 호환성·CORS DELETE/PATCH·Hyperdrive stale read·members 쿼리 91s→244ms·잘못된 빈 캐시·인덱스 LOCK=NONE 미지원·HTML escape 처리 등 다회차 | 본 기능 결함 처리 진행 중 |
| 5-5 | 최종 테스트 | ⚪ | — | UAT + 답변 품질 평가 |

## P1-6. 이행 (5%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 6-1 | 배포 | 🟢 | 4개 repo 운영 (https://malgn-helper-api.malgnsoft.workers.dev / https://malgn-helper-{pms,admin,_}.pages.dev). API·PMS는 40+회 deploy.sh 이력으로 사실상 일일 배포 | 관리자·사용자 챗봇 본 기능 배포는 본격 진행 후 |
| 6-2 | 완료 보고 및 공유 | ⚪ | — | Phase 2 입력자료 정리 포함 |

---

# Phase 2 — CS 상담 챗봇

> Phase 1의 인프라·자료·표준답변을 그대로 재사용하므로 새 인프라 셋업은 없다.
> 신규 작업은 사용자 챗 UX, 챗 세션, 스트리밍·신뢰도 가드, 에스컬레이션, 운영 확장에 집중된다.

(Phase 1 완료 후 본격 진행. 현재는 모두 ⚪ 대기.)

## P2-1. 착수/분석 (10%)

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 1-1 | 요구사항 도출 | ⚪ | 사용자 챗 UX, 익명/세션 정책, 에스컬레이션 SLA, 안전 가드(PII·금칙어·환각) |
| 1-2 | 수행범위 정의 및 확인 | ⚪ | Phase 2 범위 합의서 (P1 자산 재사용 명시, 동영상/Queue 도입 여부 결정) |
| 1-3 | 개발환경 검토 | ⚪ | P1 환경의 챗봇 트래픽 대응 점검, AI Gateway 캐싱·rate 정책 재점검 |
| 1-4 | 기본자료 검토 | ⚪ | P1 운영 중 쌓인 자료·표준답변·미커버 질문 분석. 추가 도입 자료(동영상 등) 식별 |

## P2-2. 설계 (25%)

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 2-1 | 전체 진행 일정 (WBS) | ⚪ | Phase 2 일정표 |
| 2-2 | 시스템 아키텍처 설계 | ⚪ | 확장 아키텍처(챗 세션·스트리밍·에스컬레이션, Queue/Indexer Worker 도입 여부 결정) |
| 2-3 | 화면명세서 작성 | ⚪ | 사용자 챗봇 화면 명세 + 관리자 추가 화면(챗 로그·에스컬레이션 큐·미커버 질문) |
| 2-4 | 데이터 설계 | ⚪ | chat_sessions·chat_messages·escalation_tickets·feedback 스키마 추가, 챗 로그 인덱스 |
| 2-5 | 디자인 시안 | ⚪ | 사용자 챗봇 시안(모바일 포함), 관리자 추가 화면 시안 |
| 2-6 | AI 프로토타입 서비스 구현 | ⚪ | 챗 PoC: 스트리밍 응답 + 출처 카드 + "모름" 분기 + 에스컬레이션 흐름 검증 |

## P2-3. 구현 (40%)

### DB

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 3-1 | DB 구축 | ⚪ | Phase 2 추가 스키마 마이그레이션(챗 세션/메시지/에스컬레이션/피드백) |

### 디자인 / 퍼블리싱

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 3-2 | Front 디자인 | ⚪ | 사용자 챗봇 디자인 + 관리자 추가 화면 디자인 |
| 3-3 | Front 퍼블리싱 | ⚪ | Nuxt 컴포넌트/페이지(`malgn-helper` + admin 추가) |
| 3-4 | 디자인/퍼블리싱 검수 | ⚪ | 검수 보고 |

### API

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 3-5 | 워커 및 프레임워크 설치 | ⚪ | P1 워커 재사용 + 스트리밍 응답 인프라, 필요 시 Queue/Indexer Worker 추가 |
| 3-6 | API 개발 | ⚪ | 챗 세션/메시지 API, 스트리밍 답변, 신뢰도 가드, 에스컬레이션 API, 피드백, 챗 로그 검색 |

### Admin (`malgn-helper-admin`)

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 3-7 | AI 설정 페이지 | ⚪ | 챗봇 운영 설정(시스템 프롬프트·캐싱·안전 가드), 미커버 질문 → 표준답변 후보 자동 추천 |
| 3-8 | AI 시연 페이지 개발 | ⚪ | 챗 로그 열람·검색, 에스컬레이션 큐 처리, 응답 품질 샘플링 리뷰 |

### Front (`malgn-helper`)

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 3-9 | 사용자단 AI 챗봇 연동 | ⚪ | 챗 UI(스트리밍·마크다운·출처 카드) + 세션 유지 + 에스컬레이션 버튼 + 모바일 반응형 |

## P2-4. 교육 및 연동 (20%)

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 4-1 | 개발자 가이드 작성 | ⚪ | 챗봇 운영 가이드(프롬프트·캐싱·안전 가드·에스컬레이션) 추가 |
| 4-2 | 개발자 교육 | ⚪ | 상담사 교육(에스컬레이션 처리, 챗 로그 리뷰) |
| 4-3 | 서비스 연동 | ⚪ | 에스컬레이션 채널 연동(Slack/이메일/티켓 시스템), 사이트 임베드(필요 시) |

## P2-5. 테스트 (20%)

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 5-1 | 베타 오픈(테스트 서버) | ⚪ | 스테이징 챗봇 오픈, 제한 고객 베타 |
| 5-2 | 단위 테스트 | ⚪ | 챗 API/스트리밍/가드 단위 테스트 |
| 5-3 | 통합 테스트 | ⚪ | 챗 E2E(질문→검색→답변→인용→평가→에스컬레이션) |
| 5-4 | 오류 수정작업 | ⚪ | 결함 처리 이력 |
| 5-5 | 최종 테스트 | ⚪ | UAT + 환각 가드 검증, "모름" 분기 검증, PII/금칙어 검증, 부하 테스트 |

## P2-6. 이행 (5%)

| ID | 작업 | 상태 | 산출물 |
| --- | --- | --- | --- |
| 6-1 | 배포 | ⚪ | 프로덕션 배포(사용자 챗봇), 트래픽·비용 모니터링 강화 |
| 6-2 | 완료 보고 및 공유 | ⚪ | Phase 2 완료 보고서, 운영 인수인계, 운영 KPI(응답 시간·정답률·에스컬레이션율) 정의 |

---

## Phase 간 의존 관계 / 재사용

| Phase 2 항목 | 재사용/의존하는 Phase 1 산출물 |
| --- | --- |
| P2-1-4 기본자료 검토 | P1 운영 중 쌓인 자료·표준답변·미커버 질문 |
| P2-2-2 아키텍처 | P1 아키텍처(인프라·검색·추천 파이프라인) |
| P2-2-4 데이터 설계 | P1 ERD에 챗/에스컬레이션만 추가 |
| P2-3-1 DB | P1 Aurora·Hyperdrive 그대로 사용 |
| P2-3-5 워커 | P1 Hono 워커·바인딩 재사용 |
| P2-3-6 API | P1 추천답변 파이프라인을 챗봇용으로 확장 |
| P2-3-9 챗봇 | P1 표준답변·하이브리드 검색·AI Gateway 그대로 호출 |
| P2-5-5 최종 테스트 | P1 답변 품질 평가 방법론 재사용 |

---

## 횡단(Cross-cutting) 운영 도구 — 이번 사이클에서 추가

Phase별 작업과 별도로 진행되는 운영 도구. 모두 ✅ 완료.

| 항목 | 산출물 | 위치 |
| --- | --- | --- |
| 일괄 배포 스크립트 | `commit + push + deploy + history append` 4단계 일괄 처리 | [scripts/deploy.sh](../scripts/deploy.sh) |
| 일단위 작업 이력 | `history.yyyyMMdd.md` 누적 기록 (덮어쓰기 X) | [doc/history/](history/) |
| 다중 계정 Cloudflare | `account_id`를 wrangler 설정에 명시 — env 변수 불필요 | 각 repo의 `wrangler.jsonc` / `wrangler.toml` |
| Pages 배포 표준 | Nuxt 3 `cloudflare-pages` preset, 출력 디렉토리 `dist/`, deploy 스크립트 `pnpm run deploy` | [CLAUDE.md](../CLAUDE.md) 배포 절차 |
| 작성자 분류 규칙 | `@malgnsoft.com` = 직원 / 그 외 = 고객·협력사 (이름·패턴 추정 금지) | 메모리 + 모든 분석 문서에 적용 |

---

## 다음 단계 우선순위 (제안)

> M1(인프라 Ready) **통과**. 현재 M2(자료 수집 + 검색) 진입 직전.

1. **OpenSearch 도메인 셋업 + 인덱스 매핑** — k-NN(`text-embedding-3-small` 1536d) + BM25 하이브리드. 청크 단위 doc 구조 (parent_id·source·chunk_idx·embedding·body·title 등). Phase 1 후반 검색 백엔드.
2. **`malgn-helper-admin` 자료 업로드 MVP** — R2 업로드 → 텍스트 추출(PDF·MD·HTML) → 청크 → 임베딩 → OpenSearch 색인. 동기 처리(MVP), Queue는 동영상 도입 시.
3. **챗봇 응답 파이프라인 (`/chat`)** — 표준답변 매칭 우선 → 하이브리드 검색 → LLM 답변 + 출처 인용 + 신뢰도 가드("모름" 분기 → 에스컬레이션). PMS 측 Q&A 분석에서 검증된 prompt·캐시·감사 인프라 재사용.
4. **`malgn-helper` 사용자 챗봇 UI** — NotebookLM 스타일 본문+출처 패널, 스트리밍 응답, 모바일 반응형.
5. **관리자 추가 화면** — 표준답변 관리(승인 워크플로) · 상담 로그 검토 · 에스컬레이션 큐.
6. **OpenSearch 인덱스 매핑 + R2 키 규칙 문서화** — P1-2-4 잔여 산출물.
7. **(병행) PMS UX 잔여 폴리시** — `/admin/evals` LLM 행 모달 즉시 열기 · 정렬·필터 추가.

위 1~4가 완료되면 **Phase 1 본 기능 베타** 가능. 5는 Phase 1·2 공통 자산. 6은 설계 잔여.
