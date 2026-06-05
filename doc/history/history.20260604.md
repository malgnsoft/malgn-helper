# 작업 이력 — 2026-06-04

> 6/3 작업 없음 — 6/2 다음 작업 재개.

## 종합

PMS 분석 모달 UX와 임베드 인터페이스, Vision 이미지 URL 안정화 4개 흐름 진행:

1. **임베드 모드 신호 정리** — `/projects/[id]` 페이지에 `isEmbedded` 도입(`?embed=1`). 임베드 시 PMS 내부 nav("📋 게시글 목록 →", breadcrumb) 숨김. `?modal=open`(모달 자동 오픈)과 시그널 분리해서 혼동 제거.

2. **"최근 활동" 풀 타임스탬프** — `slice(0,7)`(YYYY-MM)에서 `slice(0,19).replace('T',' ')`로 확장 (KST 기준 `YYYY-MM-DD HH:mm:ss`).

3. **QaEvalCard 인-모달 상태 전환** — 외부 로딩/에러 Teleport 2개 제거. 모달이 클릭 즉시 열리고 같은 모달 안에서 `로딩(✨ 펄스) → 분석 결과 / 에러(다시 시도)`로 자연 전환. 프로젝트 브리핑 모달과 동일 UX. props에 `loading?`·`error?` 추가, `qa` nullable, `retry` emit 신설. 모달 임베드 전용 페이지 `/posts/[id]/eval`도 같은 패턴으로 통일.

4. **Vision 이미지 URL 절대화 확장** — 원본 PMS 본문의 이미지 src가 `../data/1/...` 같은 상대 경로일 때 OpenAI Vision이 `invalid_image_url` 400. `toAbsolute`(API 측)와 `fixPmsHtml`(PMS 측) 모두 `/data/·../data/·./data/·data/` 등 모든 상대경로를 `https://ppm.malgn.co.kr/data/...`로 변환하도록 확장.

### 결정/사건

- `?embed=1` = PMS 임베드 시그널(내부 nav 숨김) / `?modal=open` = 모달 자동 오픈 — 두 시그널 의도 분리
- QaEvalCard는 모달이 항상 열리는 동안 내부 상태(loading/error/result) 분기. UX 안정성이 별도 모달 전환보다 자연스러움
- `admin` repo nuxt.config의 colorMode 항목도 PMS와 일관성 위해 제거(13903cc)

### 다음 작업 후보

- 안내글 평가(`/pms/posts/:id/announce-eval/generate`) PMS UI 통합 — 작성자 staff 분기 + 모달 재활용
- OpenSearch 셋업 + 자료 업로드 MVP (M2 진입)
- `/admin/evals`에서 LLM 행 클릭 시 모달 즉시 열기

---

## 배포

### 16:33 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `074504b` (신규 커밋: yes)
- 메시지: feat(projects): 임베드 모드(?embed=1 또는 ?modal=open) — 게시글 목록 버튼·breadcrumb 숨김

### 16:35 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `f743545` (신규 커밋: yes)
- 메시지: feat(projects): 최근 활동 표시를 yyyy-MM에서 yyyy-MM-dd HH:mm:ss로 확장

### 16:49 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `2c9aca3` (신규 커밋: yes)
- 메시지: feat(QaEvalCard): 모달이 클릭 즉시 열리고 안에서 loading→결과/에러 상태 전환 (프로젝트 분석과 동일 UX)

### 17:06 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `7dad92b` (신규 커밋: yes)
- 메시지: fix(projects): isEmbedded는 ?embed=1만 — modal=open과 분리 + 새 청크 hash로 캐시 갱신

### 17:22 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `9c14a01` (신규 커밋: yes)
- 메시지: refactor(posts/eval): 인-모달 loading/error 패턴으로 통일 (적용 URL 변경 없음)

### 17:32 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `3dd0abf` (신규 커밋: yes)
- 메시지: fix(vision): Vision 이미지 URL 변환에 ../data/ ./data/ data/ 등 상대경로 모두 절대화

### 17:32 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `8d51e8b` (신규 커밋: yes)
- 메시지: fix(fixPmsHtml): ../data/ ./data/ 등 상대경로 자산도 PMS 도메인으로 절대화
