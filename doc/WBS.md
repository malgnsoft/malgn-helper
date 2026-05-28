# WBS (Work Breakdown Structure)

> SI 표준 단계(착수/분석 → 설계 → 구현 → 교육·연동 → 테스트 → 이행)를 **Phase별로 독립 적용**.
>
> - **Phase 1**: CS 관리자 + AI 추천 답변 (선행 — 자료/답변 자산을 쌓고 상담사 보조)
> - **Phase 2**: CS 상담 챗봇 (Phase 1 자산을 활용한 고객 직접 응대)
>
> 각 Phase는 자체 착수→이행 사이클을 가진다. Phase 2는 Phase 1의 인프라·자료·표준답변을 재사용하므로 분석·설계 비중이 축소된다.
>
> **마지막 현행화**: 2026-05-29 · 일별 변경은 [doc/history/](history/)에 누적 기록.

---

## 진행률 스냅샷 (2026-05-29 기준)

| Phase / 단계 | 진행률 | 핵심 진행 사항 |
| --- | --- | --- |
| **Phase 1 · 착수/분석** | **70%** | 환경 검토 완료, 자료 인벤토리 완료, 요구사항 일부 정의 |
| **Phase 1 · 설계** | **40%** | WBS · 아키텍처 문서 · PMS 디자인 시안 2종 통합, 데이터 모델 미진 |
| **Phase 1 · 구현** | **25%** | 4개 repo 보일러플레이트 + 배포 완료, PMS 애드온 데모 완성, API 본 로직·DB 미진 |
| **Phase 1 · 교육·연동** | **10%** | 배포 자동화·이력 시스템 셋업. 정식 운영 가이드·연동 미진 |
| **Phase 1 · 테스트** | **0%** | 미시작 |
| **Phase 1 · 이행** | **5%** | 4개 repo 보일러플레이트 첫 배포 완료. Phase 1 본 기능 미배포 |

## 누적 완료 자산 (2026-05-29)

### 인프라

- ✅ 4개 GitHub repo 연결·첫 푸시 — `malgn-helper`, `-admin`, `-api`, `-pms`
- ✅ Cloudflare 환경 — Pages 3 (helper·admin·pms) + Workers 1 (api) 모두 첫 배포
- ✅ wrangler 설정 (`wrangler.jsonc` / `wrangler.toml`) + account_id 명시
- ✅ 일괄 배포 스크립트 [`scripts/deploy.sh`](../scripts/deploy.sh) — commit + push + deploy + 이력 자동 기록
- ✅ 일단위 작업 이력 [`doc/history/`](history/) 운영 시작
- ⚪ Aurora MySQL + Hyperdrive · OpenSearch · R2 · AI Gateway (미설치)

### 문서·자산

- ✅ 워크스페이스 문서: [CLAUDE.md](../CLAUDE.md) · [README.md](../README.md) · [TECH-STACK.md](TECH-STACK.md) · [ROADMAP.md](ROADMAP.md) · 본 WBS · [LEGACY-DB-INVENTORY.md](LEGACY-DB-INVENTORY.md) · [PROJECT-INQUIRY-ANALYSIS.md](PROJECT-INQUIRY-ANALYSIS.md)
- ✅ 재사용 프롬프트 3종 ([prompts/](prompts/)): `cs-evaluation` · `customer-briefing` · `qa-evaluation`
- ✅ 케이스 스터디·예시 3종 ([examples/](examples/)): 안전보건진흥원(풀평가) · 현대엔지비(브리핑 카드) · qa-94227-사용자매뉴얼(Q&A 평가)
- ✅ 일별 이력: [history/history.20260528.md](history/history.20260528.md) (어제 19개 작업) + [history/history.20260529.md](history/history.20260529.md) (오늘 WBS 현행화)

### `malgn-helper-pms` 데모 (PMS 애드온)

- ✅ 브리핑 카드 컴포넌트 통합 ([design_handoff_briefing_card](https://github.com/malgnsoft/malgn-helper-pms) 적용)
- ✅ Q&A 평가 카드 컴포넌트 통합 ([design_handoff_qa_eval_card](https://github.com/malgnsoft/malgn-helper-pms) 적용)
- ✅ 워크플로 페이지 — 빈 상태 → AI 생성 → 히스토리 셀렉트박스
- ✅ 임베드 인터페이스 — `?modal=open` 쿼리, `postMessage('malgn-helper:briefing:close')` / `:qa-eval:close`
- ✅ 외부 임베드 스니펫 (URL · `window.open` · iframe + 백드랍) — 메인 페이지에 복사 가능 형태로
- ✅ 표준답변 다중 템플릿 (6종 스타일) + "표준답변으로 저장" 버튼 → localStorage 영속화
- ⚪ 실제 `malgn-helper-api` 연동 (현재 mock data + localStorage)

### 운영 정책

- ✅ 분류 규칙: 직원 vs 고객 = `@malgnsoft.com` 도메인 (메모리 저장)
- ✅ 비공개 답변 처리 전략 ([LEGACY-DB-INVENTORY.md](LEGACY-DB-INVENTORY.md) §6)
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
| 1-1 | 요구사항 도출 | 🟢 | 답변 품질·출처 인용·"모름" 정책·표준답변 우선·상담사 채택 플로우 — CLAUDE.md/ROADMAP에 정의 | 정식 요구사항 정의서 별도 작성 필요 |
| 1-2 | 수행범위 정의 및 확인 | ✅ | Phase 1·2 분리, **4개 repo 정의** (helper / admin / api / **pms 신규**), PMS 애드온 범위 포함 | |
| 1-3 | 개발환경 검토 | ✅ | Cloudflare(Pages·Workers·R2·AI Gateway) 검토·셋업 완료. Aurora/OpenSearch는 별도 진행 | wrangler·account_id 표준화까지 완료 |
| 1-4 | 기본자료 검토 | ✅ | 레거시 PMS DB 인벤토리(1,358 Q&A 후보), 200+ 프로젝트 분포 분석, 비공개·첨부·스레드 처리 전략 수립 | [LEGACY-DB-INVENTORY.md](LEGACY-DB-INVENTORY.md), [PROJECT-INQUIRY-ANALYSIS.md](PROJECT-INQUIRY-ANALYSIS.md) |

## P1-2. 설계 (25%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 2-1 | 전체 진행 일정 (WBS) | ✅ | 본 문서 + 진행률 스냅샷 | 일별 [history/](history/) 누적 |
| 2-2 | 시스템 아키텍처 설계 | 🟢 | CLAUDE.md 데이터 흐름, TECH-STACK.md, 4 repo 책임 분리 | 상세 컴포넌트 명세·시퀀스 다이어그램 미진 |
| 2-3 | 화면명세서 작성 | 🟢 | **PMS 카드 2종** (브리핑·Q&A 평가) 핸드오프 시안 통합 | malgn-helper-admin 본격 화면 명세 미진 |
| 2-4 | 데이터 설계 | ⚪ | — | Aurora ERD, OpenSearch 인덱스 매핑, R2 키 규칙 — 본격 시작 필요 |
| 2-5 | 디자인 시안 | 🟢 | 브리핑 카드·Q&A 평가 카드 (Notion-clean A안) — 컴포넌트 단위 시안 적용 완료 | 관리자 화면 시안 미진 |
| 2-6 | AI 프로토타입 서비스 구현 | ⚪ | — | 실제 검색 + Claude 호출 PoC 미진 (PMS 데모는 mock data) |

## P1-3. 구현 (40%)

### DB

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-1 | DB 구축 | ⚪ | — | Aurora 인스턴스, Hyperdrive 바인딩, Phase 1 스키마 마이그레이션 |

### 디자인 / 퍼블리싱

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-2 | Front 디자인 | 🟢 | PMS 카드 2종 통합 완료. 관리자 본격 화면 미진 | |
| 3-3 | Front 퍼블리싱 | 🟢 | Nuxt 3 컴포넌트로 마크업 — `components/BriefingCard.vue`, `QaEvalCard.vue` + 보조 컴포넌트 | |
| 3-4 | 디자인/퍼블리싱 검수 | 🟢 | Tailwind v4 + Nuxt UI v3 호환성 이슈 수정 (color gray→neutral, ring·subtle 변형 등) | 추가 회귀 검증 필요 |

### API (`malgn-helper-api`)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-5 | 워커 및 프레임워크 설치 | ✅ | Hono on Workers 부트스트랩 + 첫 배포 (https://malgn-helper-api.malgnsoft.workers.dev) | Hyperdrive·R2·AI Gateway 바인딩은 stub 주석 |
| 3-6 | API 개발 | ⚪ | `/` + `/healthz`만 존재 | 자료 CRUD·인덱싱·하이브리드 검색·추천답변 파이프라인 등 본격 미진 |

### Admin (`malgn-helper-admin`)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-7 | AI 설정 페이지 | ⚪ | Nuxt 3 보일러플레이트만, 첫 배포 (https://malgn-helper-admin.pages.dev/) | 자료/표준답변/모델 설정 화면 미진 |
| 3-8 | AI 시연 페이지 개발 | ⚪ | — | 문의→추천답변→채택 플로우 미진 |

### PMS 애드온 (`malgn-helper-pms`) — 신규 카테고리

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 3-9 | 브리핑 카드 컴포넌트 통합 | ✅ | `BriefingCard.vue` + types/data/composables + 메인 모달 작동 | Teleport로 모달 전환 (Nuxt UI v3 호환) |
| 3-10 | Q&A 평가 카드 컴포넌트 통합 | ✅ | `QaEvalCard.vue` + `QaAxisCard.vue` + `QaScoreSummary.vue` | 5축 평가 + 표준답변 6종 |
| 3-11 | 워크플로 페이지 | ✅ | `/projects/[id]` 빈 상태 → AI 생성 → 히스토리 셀렉트박스 → 모달 | useBriefingHistory 컴포저블 + localStorage |
| 3-12 | 임베드 인터페이스 | ✅ | `?modal=open` 쿼리, `window.open`·iframe 호환, `postMessage` 닫기 신호 | 메인 페이지에 복사 가능 스니펫 노출 |
| 3-13 | 표준답변 다중 템플릿 + 저장 | ✅ | 6종 스타일(정보 안내·대체 자료·간결 거절·친절 공감·상세 안내·공식 격식) + "표준답변으로 저장" 버튼 | 현재 localStorage 누적. API 연동 미진 |
| 3-14 | 실제 API 연동 | ⚪ | — | `malgn-helper-api`의 브리핑/평가/저장 엔드포인트 구현 후 mock 제거 |
| 3-15 | Q&A 평가 카드 워크플로 페이지 | ⚪ | — | 브리핑 카드의 워크플로 패턴을 Q&A 평가에도 적용 (현재 모달 단독) |

## P1-4. 교육 및 연동 (20%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 4-1 | 개발자 가이드 작성 | 🟢 | CLAUDE.md 배포 절차, deploy.sh 사용법, history 시스템 메모리, 분류 규칙 메모리 | 정식 운영 가이드(자료/표준답변/인덱싱) 미진 |
| 4-2 | 개발자 교육 | ⚪ | — | 상담사 사용 교육 미진 |
| 4-3 | 서비스 연동 | ⚪ | — | 기존 CS 시스템/SSO 연동 미진 |

## P1-5. 테스트 (20%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 5-1 | 베타 오픈(테스트 서버) | ⚪ | — | 데모는 동작하지만 본격 베타 미진 |
| 5-2 | 단위 테스트 | ⚪ | — | API·검색·파이프라인 단위 테스트 |
| 5-3 | 통합 테스트 | ⚪ | — | 자료 업로드→인덱싱→검색→추천→채택 E2E |
| 5-4 | 오류 수정작업 | 🟢 | UI 호환성 이슈 13건 수정 (history §10·15·16·color·badge·star 등) | 본 기능 결함 처리는 미진 |
| 5-5 | 최종 테스트 | ⚪ | — | UAT + 답변 품질 평가 |

## P1-6. 이행 (5%)

| ID | 작업 | 상태 | 산출물 | 비고 |
| --- | --- | --- | --- | --- |
| 6-1 | 배포 | 🟢 | 4개 repo 모두 첫 배포 완료 (https://malgn-helper-api.malgnsoft.workers.dev / https://malgn-helper-{pms,admin,_}.pages.dev) | Phase 1 본 기능 배포는 본격 진행 후 |
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

1. **P1-3-1 DB 구축** — Aurora MySQL + Hyperdrive 바인딩 → 데이터 모델 본격 시작
2. **P1-2-4 데이터 설계** — ERD · OpenSearch 인덱스 매핑 · R2 키 규칙 확정
3. **P1-3-6 API 개발 (1차)** — 자료 CRUD + 인덱싱 트리거 + 하이브리드 검색 엔드포인트
4. **P1-3-14 PMS 애드온 ↔ API 실연동** — 현재 localStorage mock을 진짜 API로 교체 (추천 답변 / 표준답변 저장 / 평가 데이터)
5. **P1-2-6 AI 프로토타입** — 실 데이터로 검색→Claude 호출→인용 응답 PoC
6. **P1-3-15 Q&A 평가 카드 워크플로 페이지** — 브리핑 카드 워크플로 패턴을 Q&A에도 적용

> M1 인프라 Ready(P1-1·P1-2·P1-3 핵심) 게이트 진입 직전. 다음 2~3주 내 위 6개를 완료하면 M2(자료 수집) 단계로 이행 가능.
