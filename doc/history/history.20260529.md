# 작업 이력 — 2026-05-29

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
