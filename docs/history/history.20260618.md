# 작업 이력 — 2026-06-18

## 요약
표준답변(Q&A) 큐레이션 UX 고도화(위지위그·분류 편집·미리보기) + **안내글(hp_announce) 별도 트랙 신설** + **PMS 문의 수집(harvest) 파이프라인** + 추천답변 6스타일 재정의 + 인증 오류 한국어화. admin·api 다수 배포.

## 1. 표준답변 상세·편집 고도화 (admin + api)
- 상세 패널: 측면 슬라이드오버 → **가운데 모달(1120px, AdminModal 2xl)**.
- 질문·답변에 **TinyMCE 위지위그**(`AdminRichEditor`, TinyMCE7 CDN, `@tinymce/tinymce-vue`) 도입.
- **분류(scope/토픽/서비스/태그) 편집 활성화** — 기존 항목도 수정. `PATCH /standard-answers/:id`가 분류 수용 + question/answer 자산 절대화.
- 'scope' → **'분류'** 라벨, 옵션 공통/서비스 한글화. 목록에 **토픽·서비스 컬럼** 추가.
- 목록 질문 미리보기: 태그 노출 → 평문화 → **서식 렌더(줄바꿈 유지·이미지 숨김)** 로 정착.
- 토픽 필터 버그픽스: service 답변에도 **공통 토픽 함께 표시**.

## 2. 추천 답변 6스타일 재정의 (api)
- 길이·톤·형식 혼재 → **용도 중심 6종**: 기본 / 요약 / 상세 / 단계별 가이드 / 공감·사과 톤 / 격식·공식 톤 (Q&A 평가 D축 프롬프트).

## 3. 안내글(hp_announce) 별도 트랙 신설 (api + admin)
- 005 마이그레이션: **hp_announce 테이블** + hp_service 7서비스 재시드(applied).
- API: `/announces` CRUD + 승인 전이(SA_TRANSITIONS 재사용) + 분류·이미지 절대화. 004 봇 슬러그 정본화.
- admin: 메뉴 분리(**Q&A 표준답변 / 안내글**), `/announces` 실데이터 연동.

## 4. PMS 문의 수집(harvest) 파이프라인 (api + admin)
- API: `POST /pms/harvest/scan`(미리보기) · `/commit`(선택 등록 → qa=hp_standard_answer / announce=hp_announce, developer↑).
- 일회용 `/admin/migrate/harvest-curate`: LLM 가치평가로 draft 큐레이션(적용 후 라우트 제거).
- admin: `/harvest` 화면(scan→검토→commit) + 메뉴.

## 5. 인증 오류 메시지 한국어화 (api)
- invalid credentials / unauthorized / forbidden / 세션 만료 등 → 한국어. (서비스 토큰·내부 분석 라우트는 유지)

## 6. UI 정리 (admin)
- 목록 필터바 **초기화 버튼 제거**(전 페이지 공통).
- 미연동 목업 페이지에 **'목업' 배지**(analytics·chat-logs·escalations·uncovered).

## 7. 기획·정책 문서 (mng docs)
- 토픽 정본 **24종**, 안내글 별도 테이블·메뉴 분리 정합.
- PMS 문의 → 표준답변 **수집 절차 7단계** 정본.
- Phase 2 챗봇 **PII·비공개 노출 가드** 정책.

## 다음 단계
- 카탈로그(토픽·서비스) 데이터 정리 — 서비스성 토픽 정돈.
- `materials`(학습 자료) 백엔드(R2/OpenSearch) 연동.
- 표준답변/봇 필드 검증 메시지 한국어화(잔여), 일회용 `/db/*` 등 정리.

## 배포

### 09:54 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `eaaf2ce` (신규 커밋: yes)
- 메시지: chore(admin): 목록 필터바에서 초기화 버튼 제거 (전 페이지 공통)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 10:29 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `7b516e1` (신규 커밋: yes)
- 메시지: feat(admin): 목업(미연동) 페이지에 '목업' 배지 — analytics·chat-logs·escalations·uncovered

- AdminPageHeader에 mock prop 추가(제목 옆 앰버 '목업' 배지)
- MOCK_ 하드코딩(Phase 2 데이터) 5개 페이지에 적용

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 12:53 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `82e8c9b` (신규 커밋: yes)
- 메시지: feat(standard-answers): 상세를 가운데 모달(1120px)로 전환 + 답변 TinyMCE 위지위그

- AdminModal에 2xl(1120px) 사이즈 추가, 표준답변 상세를 SlideOver→중앙 모달
- AdminRichEditor(TinyMCE7 CDN, 클라이언트 전용) 신규 — 답변 필드에 적용
- @tinymce/tinymce-vue 의존성 + SSR transpile

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 15:31 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `362176b` (신규 커밋: yes)
- 메시지: feat(qa-eval): 추천 답변 6스타일 용도 중심 재정의 — 기본/요약/상세/단계별 가이드/공감·사과/격식·공식

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 16:41 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `8143e27` (신규 커밋: yes)
- 메시지: feat(standard-answers): PATCH가 분류(scope/topic/service/tags) 수정 수용 + question/answer 자산 절대화

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 16:41 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `2a3bd86` (신규 커밋: yes)
- 메시지: feat(standard-answers): 분류(scope/서비스/토픽/태그) 편집 활성화 + 'scope'→'분류' 라벨 + 목록에 토픽·서비스 컬럼

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 17:22 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `2657056` (신규 커밋: yes)
- 메시지: fix(auth): 로그인·세션·권한 오류 메시지 한국어화 (invalid credentials 등)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 18:09 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `f368835` (신규 커밋: yes)
- 메시지: feat(announces): hp_announce CRUD + 전이 + 수집 헬퍼 + 004 봇 슬러그 정본화

- POST/GET/GET:id/PATCH:id/DELETE:id/PATCH:id/transition /announces (hp_announce, 005 적용 완료)
- SA 와 동형: 분류(scope/topic_id/service_id/tags)·승인 워크플로(SA_TRANSITIONS 재사용)·이미지 절대화
- 조회 응답 body→answer 매핑(admin SA UI 재사용), question NULL 허용, title/body 필수
- classify.ts: groupNameToServiceSlug(7서비스 매핑)·isAnnounceCandidate(staff 첫글) export
- migrations/004_bots.sql 시드 슬러그 lms-general/lms-public-security → general/public 정본화
- openapi: /announces 경로·announces 태그 문서화

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>

### 19:33 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `e6970ba` (신규 커밋: yes)
- 메시지: feat(harvest): POST /pms/harvest/commit — 선택 후보를 draft 등록 (qa→hp_standard_answer / announce→hp_announce, requireAuth+developer↑)

### 19:33 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `d0668e2` (신규 커밋: yes)
- 메시지: feat(harvest): PMS 문의 수집 미리보기 — scan→검토→commit (/harvest + 메뉴)

### 20:07 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `3b23c0c` (신규 커밋: yes)
- 메시지: fix(standard-answers): 목록 미리보기에서 HTML 태그 제거(평문 표시)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 20:16 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `08cd46c` (신규 커밋: yes)
- 메시지: feat(standard-answers): 질문도 TinyMCE 위지위그로 — HTML 태그 렌더 표시

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 20:36 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `e16e200` (신규 커밋: yes)
- 메시지: fix(standard-answers): 서비스 답변 편집·필터에서 공통 토픽도 함께 표시 (토픽 필터 버그)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 20:44 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `f970f90` (신규 커밋: yes)
- 메시지: fix(standard-answers): 목록 질문 미리보기를 평문화 대신 서식 렌더(줄바꿈 유지·이미지 숨김)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
