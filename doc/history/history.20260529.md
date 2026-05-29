# 작업 이력 — 2026-05-29

## 종합 (end-of-day)

하루 안에 **스토리보드 수준 PMS 데모 → 진짜 동작하는 LLM 기반 CS 헬퍼 백엔드/관리자**로 도약. 6개 단계 흐름:

1. **WBS 페이지 폴리시·정합성 정리**
   - 인라인 편집(목표일·완료일·상태) + R2 자동 저장(800ms 디바운스)
   - 가중평균 수식 버그 수정 + stage weight 합 100 정규화 (0.2% → 24.2%)
   - PMS 통합 항목(`P1-3-9~13`)이 실구현이 아닌 **사용자단 스토리보드**임을 식별하고 `P1-2-7~11`로 재배치 → 진행률 더 정직해짐

2. **인프라 활성화 (Hyperdrive · R2 · AI Gateway)**
   - Hyperdrive `pms` (id `aea3...`) → PMS MySQL(5.6.51) 연결
   - R2 `malgn-helper-files` 생성 (WBS 영속화)
   - AI Gateway `malgn-helper` (Authenticated 모드, compat endpoint)
   - 시크릿: `OPENAI_API_KEY`, `AI_GATEWAY_TOKEN`

3. **PMS DB 연동 + 첫 실 엔드포인트**
   - DB 탐색용 dev 엔드포인트(`/db/tables` 등) 신설, PMS 27개 테이블 구조 파악
   - `GET /pms/projects` (검색·페이지네이션, 활성 1,653건)
   - `GET /pms/posts/:id` (직원/고객 분류 + **비공개 댓글 본문 마스킹**)
   - `GET /pms/projects/:id/briefing` (DB-only 집계 — 멤버/통계/라벨/알림)
   - PMS의 `BriefingCard` 모킹을 **실 API 호출**로 전환 (P1-2-7 스토리보드 → 실서비스)

4. **헬퍼 전용 DB 스키마 + 캐싱 인프라**
   - `hp_*` 4 테이블 설계·문서화: `hp_briefing` / `hp_qa_eval` / `hp_standard_answer` / `hp_llm_log`
   - 일회용 admin 엔드포인트로 DDL 실행 후 secret·코드 제거
   - `POST /pms/projects/:id/briefing/generate` — `llm_input_hash` 기반 24h 캐시 hit + `hp_llm_log` 감사 기록 + graceful degrade

5. **LLM 실 연동 (OpenAI via AI Gateway)**
   - CLAUDE.md: Claude → OpenAI(`gpt-4o-mini` 기본)로 변경
   - 첫 호출 검증: project 1446 hotTopics 7개 군집화 ("훈련생 오류 15 / 서버 10 / ...")
   - 브리핑 LLM 확장: `oneLiner` + `statusReason` + `urgentCount` + `faq` + `policies`
   - Q&A 평가 카드 전체 LLM 연동: 5축(A~E) score + commentary + **D축 templates 자동 생성** + followups + observation
   - LLM 2회 호출 **병렬화** (`Promise.allSettled`): 7s → 3.5s (50% 단축)

6. **운영·관리자 도구**
   - `/admin/cost` 대시보드 (`hp_llm_log` 일·모델·엔티티 집계 + 최근 100건 추적)
   - `/admin/evals` Q&A 평가 목록 (정렬·필터·점수 색 분기, score_asc로 취약 응대 발굴)
   - `/projects` 프로젝트 목록 (1,653건, 검색·페이지네이션)
   - `/doc` Scalar + OpenAPI 3.1 (수동 스펙, 22개 엔드포인트)
   - 홈에 4개 진입 링크 노출, 헤더 제목 "고객사 목록" → "맑은도우미 데모"
   - Cloudflare Access `/admin/*` `/db/*` 보호 가이드 문서

### 산출 카운트

| 항목 | 수 |
| --- | ---: |
| 신규 API 엔드포인트 | 22개 |
| 신규 PMS 페이지 | 5개 (`/projects` `/admin/cost` `/admin/evals` `/admin/cost` `/doc`은 API 측) |
| 신규 DB 테이블 (PMS DB) | 4개 (`hp_*`) |
| 신규 인프라 | R2 버킷 1 / Hyperdrive 1 / AI Gateway 1 |
| 신규 문서 | `WBS-TRACKER.md` / `HP-SCHEMA.md` / `CLOUDFLARE-ACCESS.md` |
| 메모리 추가 | 2건 (스토리보드 식별 / Hyperdrive 캐싱 stale) |
| 배포 (정식 deploy.sh) | 약 35회 (말미 기준) |

### 첫 LLM 호출 결과 (project 1446)

| 항목 | 값 |
| --- | --- |
| hotTopics | 훈련생 오류 15 / 서버·접속 10 / 강의·콘텐츠 10 / 수료증 8 / 문서 6 / 결제 5 / 기타 4 |
| statusReason (LLM) | "긴급 문의가 다수 발생" |
| urgent | 0 (DB) → **6** (LLM 추정) |
| faq (자동 추출) | 학습시간 오류 / SSL 갱신 / 강의 오류메세지 / 모바일 영상 / 과제 재제출 불가 |
| policies (직원 응답 패턴) | 강의 수강 환경 안내 / SSL 인증서 관리 |
| 비용 | $0.0012 (≈ ₩1.6) / brief 1회 |
| 캐시 hit 시 비용 | $0 |

### 결정/사건

- **D1 DB 거부 → R2 + JSON 영속화** (어제 결정 유지)
- **PMS 운영 DB에 `hp_*` 접두사로 헬퍼 테이블 공존** (별도 DB 분리는 추후 시나리오 문서화)
- **LLM 공급자 Claude → OpenAI** (사용자 키 제공 따라)
- **AI Gateway Authenticated 모드** (cf-aig-authorization 토큰)
- **사용자단 스토리보드 vs 실서비스 구분** 룰 명문화 (메모리)
- **OpenAI 키 채팅 노출** 사용자가 재발급 보류 — 그대로 사용 결정

### 알려진 잔여 이슈

- ~~`hp_qa_eval.overall_verdict` VARCHAR(20)~~ → **VARCHAR(100) 마이그레이션 완료** (eod 추가 작업, 검증: "문의에 대한 답변이 부족하여 개선이 필요합니다." 26자 정상 저장)
- Hyperdrive read 캐싱으로 write 후 GET이 stale 보일 수 있음 (메모리 기록, 임팩트 작음)
- `/admin/*` `/db/*` 무인증 — 가이드(`doc/CLOUDFLARE-ACCESS.md`)대로 적용 권장
- `/db/*` 탐색 엔드포인트는 안정화 후 제거 예정 (OpenAPI에 명시)

### 미리보기 링크

- 홈: https://malgn-helper-pms.pages.dev/
- 프로젝트 목록: https://malgn-helper-pms.pages.dev/projects
- 프로젝트 브리핑 (LLM): https://malgn-helper-pms.pages.dev/projects/1446
- Q&A 평가 목록: https://malgn-helper-pms.pages.dev/admin/evals
- LLM 비용 대시보드: https://malgn-helper-pms.pages.dev/admin/cost
- WBS Tracker: https://malgn-helper-pms.pages.dev/wbs
- API 문서: https://malgn-helper-api.malgnsoft.workers.dev/doc

---

## 요약

[WBS.md](../WBS.md) 현행화. 어제(2026-05-28) 누적된 19개 작업 단위와 4개 repo의 진행 상태를 반영해 전 단계 진행률·상태·신규 카테고리(PMS 애드온)를 추가.

---

## 작업 내역

### 1. WBS 전면 현행화

기존 WBS는 작업 항목만 나열한 상태였음. 다음을 추가·갱신:

**상단 신규 섹션**:
- **진행률 스냅샷** — 6개 단계별 % + 핵심 진행 사항
- **누적 완료 자산** — 인프라 / 문서·자산 / `malgn-helper-pms` 데모 / 운영 정책 4개 카테고리로 정리
- **상태 범례** (✅ 완료 · 🟢 진행 중 · ⚪ 대기 · ⛔ 보류)

**기존 표 갱신**:
- 모든 작업 항목에 **상태 컬럼** 추가
- **산출물 컬럼**에 실제 생성된 파일·경로 명시
- **비고 컬럼** 신설 — 미진 사유·후속 작업 안내

**P1-3 구현에 신규 카테고리 추가**:
- **PMS 애드온 (`malgn-helper-pms`)** — 3-9 ~ 3-15 (총 7개 항목)
  - 3-9 브리핑 카드 컴포넌트 통합 ✅
  - 3-10 Q&A 평가 카드 컴포넌트 통합 ✅
  - 3-11 워크플로 페이지 ✅
  - 3-12 임베드 인터페이스 ✅
  - 3-13 표준답변 다중 템플릿 + 저장 ✅
  - 3-14 실제 API 연동 ⚪
  - 3-15 Q&A 평가 워크플로 페이지 ⚪

**횡단 운영 도구 섹션 신규**:
- 일괄 배포 스크립트 / 일단위 이력 / 다중 계정 Cloudflare / Pages 배포 표준 / 작성자 분류 규칙 — 모두 ✅

**다음 단계 우선순위 제안 (6건)**:
1. P1-3-1 DB 구축
2. P1-2-4 데이터 설계
3. P1-3-6 API 개발 (1차)
4. P1-3-14 PMS ↔ API 실연동
5. P1-2-6 AI 프로토타입
6. P1-3-15 Q&A 평가 워크플로 페이지

### 2. 진행률 현황 산정

각 단계별로 어제까지 누적된 작업을 환산:

| Phase 1 단계 | 진행률 |
| --- | --- |
| 착수/분석 | 70% (요구사항만 미완) |
| 설계 | 40% (데이터 설계·AI PoC 미진) |
| 구현 | 25% (보일러플레이트+PMS 데모만, API·DB·관리자 본격 미진) |
| 교육·연동 | 10% (배포 스크립트·이력 시스템) |
| 테스트 | 0% |
| 이행 | 5% (보일러플레이트 첫 배포만) |

> M1 인프라 Ready 게이트 직전. 다음 6개 작업 완료 시 M2(자료 수집) 진입.

### 2. malgn-helper-pms에 `/wbs` 진행 현황 페이지 신규

WBS.md 내용을 시각화한 페이지. 메인 페이지(`/`)에서 우상단 링크로 진입.

**섹션 구성**:
- 헤더 — WBS 배지 + 마지막 현행화 일자
- **가중평균 진행률** 큰 숫자 + 게이지 바 (Phase 1 6단계 가중 계산)
- **단계별 진행률** 6개 카드 (각 단계 ID·이름·비중·진행률·요약 + 게이지)
- **누적 완료 자산** 4 카드 (인프라/문서/PMS 데모/운영 정책 + 진행률·항목 리스트)
- **Phase 1 작업 상세** — 6개 접기/펴기 details 블록 (진행 중인 단계는 기본 펼침)
  - 각 작업 항목 한 줄: ID · 제목 · 비고 · 상태 배지(✅/🟢/⚪/⛔)
- **다음 단계 우선순위 6건** 카드
- **Phase 2** placeholder (모두 대기)
- 푸터에 WBS.md / history/ 원본 링크

**디자인 토큰**:
- 상태 배지: emerald(done) · amber(in_progress) · neutral(pending) · rose(blocked)
- 게이지 색상: 70%+ emerald · 30%+ amber · 0%+ neutral
- 카드: rounded-lg border-neutral-200 bg-white p-4 (브리핑/QA 카드와 일관)

**데이터**: 현재 WBS.md를 미러링한 TypeScript 인라인. 추후 빌드 타임 마크다운 파싱으로 자동화 검토.

배포 URL: https://malgn-helper-pms.pages.dev/wbs

### 3. WBS 데이터 저장소를 JSON 정적 파일로 결정

**경위**: WBS 영속화를 위해 D1 DB를 한 차례 시도(생성·바인딩·CRUD 엔드포인트·CORS까지 구현 완료) 했으나, 사용자 결정으로 **정적 JSON 공유 방식으로 전환**.

**최종 채택**: `malgn-helper-pms/public/wbs.json`

- 파일 1개. 편집 후 `./scripts/deploy.sh malgn-helper-pms ...` 한 번이면 배포·공유 완료
- 공개 URL `https://malgn-helper-pms.pages.dev/wbs.json` 으로 다른 시스템에서도 fetch 가능 (CORS 별도 설정 불요)
- DB·런타임 의존 없음 → 장애 영향 0

**롤백 / 정리**:
- `malgn-helper-api/wrangler.jsonc`에서 `d1_databases` 바인딩 제거
- `src/index.ts`를 원래 형태(hello + healthz)로 환원
- `migrations/` 폴더 삭제
- D1 DB 자체는 Cloudflare에 잔존 (`malgn-helper-wbs`, `558d397e-…`) — 사용 안함. 추후 `wrangler d1 delete malgn-helper-wbs` 가능

**JSON 스키마**:

```jsonc
{
  "_meta": { "lastUpdated": "2026-05-29", "project": "...", "source": "...", "editGuide": "..." },
  "phase1": {
    "stages": [
      {
        "id": "P1-1", "name": "...", "weight": 10, "progress": 70, "summary": "...",
        "tasks": [
          { "id": "P1-1-1", "taskNo": "1-1", "title": "...",
            "status": "done|in_progress|pending|blocked",
            "note": "...", "targetDate": "YYYY-MM-DD", "completionDate": "YYYY-MM-DD" }
        ]
      }
    ]
  }
}
```

### 4. /wbs 페이지에 목표일·완료일 컬럼 추가

페이지 본문의 작업 상세를 표 구조로 변경:

| ID | 작업 | 목표일 | 완료일 | 상태 |
| --- | --- | --- | --- | --- |

- **목표일** — 미설정 시 `—`, **지난 미완료는 빨강 강조** (`text-rose-600 font-semibold`)
- **완료일** — 완료된 경우 emerald, 그 외 `—`
- `useFetch('/wbs.json')` 로 동기 로드, 로딩·에러 상태 표시
- 헤더·푸터에 `/wbs.json` 링크 노출 (외부 시스템 임베드 가이드)

## 배포

### 08:34 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `b803162` (신규 커밋: yes)
- 메시지: feat: /wbs 진행 현황 페이지 + 인덱스 링크

### 08:40 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `f29e575` (신규 커밋: yes)
- 메시지: feat: D1(malgn-helper-wbs) 바인딩 + /wbs CRUD 엔드포인트 + CORS

### 08:46 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `d177b29` (신규 커밋: yes)
- 메시지: revert: D1 제거 (WBS는 JSON 정적 파일로 전환)

### 08:46 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `5eda3a4` (신규 커밋: yes)
- 메시지: feat: WBS를 정적 JSON(/wbs.json)으로 전환 + 목표일·완료일 컬럼 추가

### 08:51 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `a8bd1cb` (신규 커밋: yes)
- 메시지: fix: /wbs 페이지의 wbs.json fetch를 client-only로 (SSR 404 회피)

### 08:58 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `81031f3` (신규 커밋: yes)
- 메시지: feat: WBS 산출물 URL 컬럼·인라인 편집·JSON 복사 (localStorage 임시 저장)

### 09:05 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `c75d600` (신규 커밋: yes)
- 메시지: redesign(/wbs): Editorial Blueprint — Instrument Serif 이탤릭 + JetBrains Mono + 따뜻한 크림지 + 안전 오렌지 액센트 + 플로팅 편집바

### 09:13 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `42a259f` (신규 커밋: yes)
- 메시지: redesign(/wbs): Terminal/IDE — GitHub Dark Dimmed + JetBrains Mono + 탭바·라인거터·상태바

### 09:18 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `21b172c` (신규 커밋: yes)
- 메시지: redesign(/wbs): Soft SaaS (Notion/Linear 풍) — 라이트 + Pretendard + 부드러운 모서리·여백

### 09:21 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `5460422` (신규 커밋: yes)
- 메시지: tweak(/wbs): 전체 폰트 사이즈 +1px (가독성)

### 09:24 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `e704617` (신규 커밋: yes)
- 메시지: tweak(/wbs): 전체 폰트 -1px (이전 +1 환원)

### 09:29 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `8f64bed` (신규 커밋: yes)
- 메시지: tweak(/wbs): 목표일·완료일 input[type=date] 편집 + 컬럼 너비 키움 + 상태 nowrap + URL -1px

### 09:46 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `25de7c4` (신규 커밋: yes)
- 메시지: feat: /wbs GET·PUT (R2 자동저장) + CORS

### 09:50 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `3ce38a9` (신규 커밋: yes)
- 메시지: feat(/wbs): API(R2) 자동저장 — 800ms debounce + 저장 상태 표시 + status 인라인 select

### 10:09 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `ce94486` (신규 커밋: yes)
- 메시지: fix(/wbs): 가중평균 수식 보정 + stage weight 합 100 정규화 (0.2% → 24.2%)

### 10:19 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `e341642` (신규 커밋: yes)
- 메시지: chore(/wbs): PMS 스토리보드 5건을 P1-2(설계) 하위로 재배치 (id·taskNo 압축)

### 10:37 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `acac93e` (신규 커밋: yes)
- 메시지: feat: Hyperdrive(pms) 바인딩 + GET /db/ping (mysql2)

### 10:45 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `36ef602` (신규 커밋: yes)
- 메시지: feat: PMS 연동 GET /pms/posts/:id — 직원/고객 분류 + 비공개 댓글 마스킹 + 탐색용 /db/* 엔드포인트

### 10:52 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `eadcbd2` (신규 커밋: yes)
- 메시지: feat: BriefingCard 실 API 연동 — generateBriefing()이 /pms/projects/:id/briefing 호출 (P1-2-7 스토리보드 → 실서비스)

### 10:53 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `615204f` (신규 커밋: yes)
- 메시지: feat: GET /pms/projects/:id/briefing — 멤버/통계/라벨/알림 집계 (LLM 영역 제외)

### 10:59 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `04f41d0` (신규 커밋: yes)
- 메시지: feat: /projects 프로젝트 목록 페이지 (검색·페이지네이션·최근활동)

### 11:00 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `e8f5d31` (신규 커밋: yes)
- 메시지: feat: GET /pms/projects?q=&limit=&offset= 목록 + 검색 + 카운트

### 11:04 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `778453c` (신규 커밋: yes)
- 메시지: fix(/pms/projects): id > 0 조건 추가 (시스템/임시 row 제외)

### 11:15 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `d28a282` (신규 커밋: yes)
- 메시지: feat: /doc API 문서 페이지 (Scalar + OpenAPI 3.1)

### 11:31 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `d7ce674` (신규 커밋: no)
- 메시지: chore: migrate-hp-tables 일회용 엔드포인트 제거 (4테이블 생성 완료)

### 11:37 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `e1d8d20` (신규 커밋: yes)
- 메시지: feat: BriefingCard generateBriefing()을 POST .../generate로 전환 (서버 id 사용)

### 11:38 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `4bab4d2` (신규 커밋: yes)
- 메시지: feat: POST /briefing/generate + 캐시·로깅 (hp_briefing, hp_llm_log) + 목록/단건/삭제 + OpenAPI 갱신

### 11:44 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `b724b9f` (신규 커밋: yes)
- 메시지: feat: QaEvalCard 저장 버튼을 POST /standard-answers로 실연동 (localStorage → hp_standard_answer)

### 11:44 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `5ee2608` (신규 커밋: yes)
- 메시지: feat: /standard-answers CRUD + /use + OpenAPI (hp_standard_answer)

### 11:55 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `d0b91e8` (신규 커밋: yes)
- 메시지: feat: OpenAI 연동 인프라 — AI Gateway + LLM hotTopics + hp_llm_log 비용·토큰

### 12:03 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `ea13e0d` (신규 커밋: yes)
- 메시지: fix(llm): cost 계산이 model prefix(openai/...)를 인식하도록 base 추출 + Gateway 토큰 헤더 지원

### 12:14 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `d8a0197` (신규 커밋: yes)
- 메시지: feat(QaEvalCard): 실 API 연동 — POST /pms/posts/:id/eval/generate

### 12:14 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `2368b29` (신규 커밋: yes)
- 메시지: feat: Q&A 평가 카드 LLM 연동 (5축 + templates + hp_qa_eval) + OpenAPI 4건 추가

### 12:18 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `e191511` (신규 커밋: yes)
- 메시지: feat: 브리핑 LLM 확장 — oneLiner/statusReason/urgent/faq/policies 채우기

### 12:31 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `78d4873` (신규 커밋: yes)
- 메시지: feat: /admin/cost LLM 비용·호출 대시보드 페이지

### 12:31 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `60b6f30` (신규 커밋: yes)
- 메시지: feat: GET /admin/cost — hp_llm_log 일·모델·엔티티 집계 + OpenAPI

### 12:41 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `281ba35` (신규 커밋: yes)
- 메시지: feat: 홈에 /admin/cost · /projects · /wbs 진입 링크 노출

### 12:41 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `845515f` (신규 커밋: yes)
- 메시지: perf: briefing LLM 2회 호출 병렬화 (Promise.allSettled) — 7s→3.5s

### 12:46 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `b023aab` (신규 커밋: yes)
- 메시지: feat: /admin/evals Q&A 평가 목록·정렬·필터 + 홈 링크 추가

### 12:46 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `68c9bd6` (신규 커밋: yes)
- 메시지: feat: GET /admin/evals (정렬·필터·post/project JOIN) + OpenAPI

### 12:49 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `014c513` (신규 커밋: yes)
- 메시지: tweak(home): 제목 '고객사 목록' → '맑은도우미 데모'

### 12:54 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `614dff7` (신규 커밋: yes)
- 메시지: chore(hp_qa_eval): overall_verdict VARCHAR(20→100) + trim 완화 + admin 엔드포인트 정리

### 13:01 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `bbf380d` (신규 커밋: yes)
- 메시지: feat: /admin/suggestions 표준답변 후보 자동 추출 페이지 + evals/홈 링크

### 13:01 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `c4342d1` (신규 커밋: yes)
- 메시지: feat: POST /pms/projects/:id/standard-answer-suggestions — LLM 패턴 추출 + OpenAPI

### 13:11 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `a7de0f3` (신규 커밋: yes)
- 메시지: feat: AppHeader 공통 컴포넌트로 5개 페이지 상단 디자인 통일 + 현재 라우트 강조

### 13:21 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `ad807cd` (신규 커밋: yes)
- 메시지: feat: 5개 admin 페이지 본문 톤을 메인·브리핑·QnA 카드와 통일 (UContainer/h1 text-3xl/표 thead bg-neutral-50 uppercase tracking-wider/카드 hover primary-500/링 칩)

### 13:25 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `870fa16` (신규 커밋: yes)
- 메시지: feat(/pms/projects): site_id=1 기본 필터 (?siteId=all로 우회 가능) + OpenAPI

### 13:35 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `ed0e208` (신규 커밋: yes)
- 메시지: feat(/projects): 그룹 컬럼 추가 (tb_project_group 매칭)

### 13:35 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `0a0ef9a` (신규 커밋: yes)
- 메시지: feat(/pms/projects): tb_project_group JOIN으로 groupName 반환 + OpenAPI

### 13:41 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `7712afb` (신규 커밋: yes)
- 메시지: feat: /projects 그룹 셀렉트 + /admin/evals 그룹 인라인 칩

### 13:41 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `71771f8` (신규 커밋: yes)
- 메시지: feat: GET /pms/groups + /pms/projects ?groupId + /admin/evals groupName JOIN

### 13:45 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `d7b8edc` (신규 커밋: yes)
- 메시지: fix(BriefingCard): 담당자/보조 이름 표시 — UTooltip 제거하고 일반 span+title

### 14:09 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `8b60916` (신규 커밋: yes)
- 메시지: fix(BriefingCard): 고객 primary/others도 UTooltip 제거하여 이름 표시

### 14:09 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `81b422f` (신규 커밋: yes)
- 메시지: feat(briefing): 180일 cutoff — 사람·FRT·미응답·긴급·알림은 180일 / 누적·핫카테고리·FAQ·정책은 전체. statusLabel '휴면' 추가. extras LLM input에 RECENT_180 분리

### 14:17 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `0874622` (신규 커밋: yes)
- 메시지: tweak(BriefingCard): 평균 FRT hint를 영업시간 안내로 (avgFRTNote)

### 14:17 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `e8a7500` (신규 커밋: yes)
- 메시지: feat(FRT): 영업시간(KST 평일 9~17, 공휴일 제외) 기준 계산

### 14:22 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `ce0aaec` (신규 커밋: yes)
- 메시지: tweak(BriefingCard): FRT hint를 avgFRTGrade로 (매우 빠름/빠른 편/보통/느린 편/응답 지연)

### 14:22 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `afe3cbf` (신규 커밋: yes)
- 메시지: feat(briefing): avgFRTGrade 동적 등급 — 영업시간 분 기준 5단계

### 14:25 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `a0237f1` (신규 커밋: yes)
- 메시지: fix(timezone): PMS DB가 KST 기준 — mysql2 timezone='+09:00' + toIso에 +09:00 명시

### 14:37 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `d5d5b59` (신규 커밋: yes)
- 메시지: feat(BriefingCard): 응대 통계 5칸으로(최근 180일 추가) + customer.primary name fallback 강화

### 14:37 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `c7946dc` (신규 커밋: yes)
- 메시지: feat(briefing): stats.recent 180일 문의수 + customer 이름 fallback(email 로컬파트)

### 14:45 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `d5d5b59` (신규 커밋: no)
- 메시지: chore: BriefingCard 캐시 무효화 (협력사 분류 적용)

### 14:45 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `f56abe5` (신규 커밋: yes)
- 메시지: feat: 협력사 분류 (PARTNER_WHITELIST=['플로즈']) — customer.primary 후순위, partners 배열 신설

### 14:47 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `6459da6` (신규 커밋: yes)
- 메시지: tweak(/projects/[id]): 미니 통계 5칸으로 + 최근 180일 추가

### 15:35 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `e62f2e5` (신규 커밋: yes)
- 메시지: feat(BriefingCard): 고객 응대 톤·태도 박스 추가 (customer.persona)

### 15:35 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `520c200` (신규 커밋: yes)
- 메시지: feat(briefing): customerPersona LLM 추출 — 고객 메시지(180일, 비공개·직원·협력사 제외) 30건 분석

### 15:50 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `978f358` (신규 커밋: yes)
- 메시지: feat(briefing): statusLabel 5단계 enum + 미응답 임계값 룰 고정. LLM은 statusLabel·statusReason 출력 금지. urgentCount≥5만 긴급 격상

### 16:07 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `43f6582` (신규 커밋: yes)
- 메시지: feat(BriefingCard): 협력사 영역 + 상담사 톤·태도 + 직함 trim + 라벨 변경

### 16:07 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `246b27c` (신규 커밋: yes)
- 메시지: feat(briefing): partners 분리 + staffPersona LLM 추출

### 17:00 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `19a34e5` (신규 커밋: yes)
- 메시지: fix(/projects/[id]): 헤더 메타를 API 단건 호출로 로드 (이름·발주처·그룹·마지막활동·상태)

### 17:00 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `0cfe132` (신규 커밋: yes)
- 메시지: feat: GET /pms/projects/:id 단건 메타 엔드포인트

### 17:05 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `5fd1550` (신규 커밋: yes)
- 메시지: fix(BriefingHistory): localStorage → 서버 fetch — 모든 브라우저에서 동일 데이터

### 17:20 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `4ea9760` (신규 커밋: yes)
- 메시지: perf(briefing): MySQL 부하 큰 폭 감소 — quick-check 캐시 + email LIKE → user_id IN

### 17:48 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `f77e24b` (신규 커밋: yes)
- 메시지: perf(briefing): members 쿼리 분리로 92s → 244ms (380배 단축, force=1 총 130s→10s) + timings 응답 노출

### 17:52 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `c0fddd8` (신규 커밋: yes)
- 메시지: fix(briefing): persona 없는 옛 캐시는 자동 폐기 후 재생성 + LLM 프롬프트에 persona 누락 금지 명시

### 17:57 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `4bdc3eb` (신규 커밋: yes)
- 메시지: feat(classify): 직원 룰에 tb_user.company='맑은소프트' 추가 (이메일 + 회사명 OR)

### 17:59 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `69256bb` (신규 커밋: yes)
- 메시지: fix(cors): allowMethods에 DELETE/PATCH 추가 (브리핑·평가 삭제 실패 fix)

### 18:05 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `25bcd37` (신규 커밋: yes)
- 메시지: tweak(BriefingCard): 협력사를 고객 영역 하단으로 + 두 persona를 사람 grid 밖 좌우 나란히

### 18:10 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `64f8340` (신규 커밋: yes)
- 메시지: fix(BriefingHistory): v1 localStorage 자동 정리 (옛 캐시 잔존 → 삭제한 카드가 새로고침 시 다시 표시되던 문제)

### 18:12 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `43dd327` (신규 커밋: yes)
- 메시지: tweak(BriefingCard): 헤더 제목 옆 statusLabel 칩 제거

### 18:16 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `268daca` (신규 커밋: yes)
- 메시지: feat(classify): PARTNER_WHITELIST에 '옐로우윈' 추가

### 18:19 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `4eab3f4` (신규 커밋: yes)
- 메시지: feat(classify): PARTNER_WHITELIST에 오케어/송한나 추가

### 18:20 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `77969bf` (신규 커밋: yes)
- 메시지: fix(classify): '오케어' → '온케어' 오타 수정

### 18:30 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `ab42ce6` (신규 커밋: yes)
- 메시지: feat: /projects/:id/posts 게시글 목록 페이지 + 진입 링크

### 18:31 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `5bffb41` (신규 커밋: yes)
- 메시지: feat: GET /pms/projects/:id/posts (검색·필터·페이지네이션 + 작성자 분류) + OpenAPI

### 18:34 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `75b3e8e` (신규 커밋: yes)
- 메시지: fix(BriefingCard): '새 카드 생성' 버튼이 force=true로 호출 (캐시 hit 우회)

### 18:35 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `2a4e75b` (신규 커밋: yes)
- 메시지: fix(routing): pages/projects/[id].vue → [id]/index.vue (게시글 페이지로 이동 안 되던 문제)

### 19:38 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `9e123e8` (신규 커밋: yes)
- 메시지: feat: /posts/:id 게시물 상세 페이지 + 게시글 목록 행 클릭은 상세로 (평가는 별도)

### 19:43 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `465d635` (신규 커밋: yes)
- 메시지: fix(posts): /data/ 절대경로 이미지·링크에 ppm.malgn.co.kr 도메인 prefix
