# 관리자(`malgn-helper-admin`) 기획서

> 최종 현행화 — 2026-06-08 · **맑은소프트 직원 전용** (협력사 미고려) · 3 역할(관리자·개발자·상담사) · 챗봇 도입 전 필요한 전부 + 설정·계정 포함 MVP

---

## 1. 목적

`malgn-helper-admin`은 CS 챗봇(`malgn-helper`)이 정상 동작하기 위한 **자산 큐레이션과 운영 도구**를 담는다.

- **자료 자산**: 매뉴얼·PDF·동영상 등 챗봇이 답변 근거로 삼을 원본 문서
- **표준답변 자산**: 검증된 한국어 답변(1순위 소스)
- **이미지 자산**: 게시물·답변에서 추출되어 자동 캡션된 화면 자산 (`hp_image_asset`)
- **운영 모니터링**: LLM 비용·Q&A 평가·챗 로그·에스컬레이션
- **설정**: 모델·시스템 프롬프트·캐싱·안전 가드
- **계정·권한**: 운영자/상담사 분리

> 기존 PMS의 `/admin/cost`, `/admin/evals` 페이지는 **유지** — 상담사가 PMS 흐름 안에서 보던 경험을 끊지 않는다. admin은 같은 데이터를 운영자 관점으로 재구성해 제공.

---

## 2. 사용자·역할

**전제** — 맑은소프트 직원 전용. 협력사·고객사는 admin 접근 불가. 식별은 `@malgnsoft.com` 이메일 + 메모리에 등록된 직원 룰(`tb_user.company='맑은소프트'`).

| 역할 | 약자 | 주요 책임 | 핵심 화면 |
| --- | --- | --- | --- |
| **관리자** | `admin` | 시스템 전반 책임, 계정·예산·정책 결정 | 모든 화면 |
| **개발자(기술 지원)** | `developer` | 자료 인덱싱·AI 설정·캐싱·연동·이미지 큐레이션 | 자료·이미지·설정·로그·통계 |
| **상담사** | `agent` | 표준답변 제안·에스컬레이션 처리·챗 로그 검토 | 표준답변·에스컬레이션·챗 로그·이미지 조회 |

### 2-1. 권한 매트릭스

| 액션 | 관리자 | 개발자 | 상담사 |
| --- | :-: | :-: | :-: |
| 자료 업로드·재인덱싱·삭제 | ✅ | ✅ | ❌ |
| 자료 조회 | ✅ | ✅ | ✅ |
| 표준답변 등록·편집 | ✅ | ✅ | ✅ (제안) |
| 표준답변 **승인**·반려·삭제 | ✅ | ✅ | ❌ |
| 이미지 카탈로그 편집·태깅·숨김 | ✅ | ✅ | ❌ (조회만) |
| 챗 로그 열람 | ✅ | ✅ | ✅ |
| 에스컬레이션 처리 | ✅ | ✅ | ✅ |
| AI 설정·안전 가드·캐싱 | ✅ | ✅ | ❌ |
| 외부 연동(Slack·이메일) | ✅ | ✅ | ❌ |
| 계정 초대·역할 변경·비활성 | ✅ | ❌ | ❌ |
| 감사 로그 열람 | ✅ | ✅ (자기 + 시스템) | ❌ (자기 것만) |

> 개발자와 관리자는 운영 책임을 공유한다. 차이는 **계정 관리·예산 정책** 한정.

### 2-2. 역할 결정 흐름

- 가입 시 기본 `agent`
- 관리자가 `developer` 또는 `admin`으로 승격
- 초대 링크에는 역할 미리 지정 가능 (관리자만 발급)

API 측 미들웨어: `requireRole('admin' | 'developer' | 'agent' | { any: [...] })`.

---

## 3. 정보 구조 (IA)

```
malgn-helper-admin.pages.dev
├─ /                          홈 · 전체 KPI 대시보드 · 최근 활동
├─ /login                     로그인 (구글 OAuth 또는 자체)
│
├─ /materials                 자료 ───────────────────────────────────
│  ├─ /materials              목록 (검색·필터·인덱싱 상태)
│  ├─ /materials/upload       업로드 (드래그앤드롭 + 메타 입력)
│  └─ /materials/:id          상세 (원본 다운로드·재인덱싱·삭제)
│
├─ /standard-answers          표준답변 ─────────────────────────────────
│  ├─ /standard-answers       목록 (검색·태그·사용량·승인 상태)
│  ├─ /standard-answers/:id   상세·편집 (질문 패턴 / 답변 HTML / 사용량)
│  └─ /standard-answers/suggestions  자동 추출 후보 (LLM이 제안)
│
├─ /images                    이미지 카탈로그 ─────────────────────────
│  ├─ /images                 목록 (썸네일 그리드, title·description 검색)
│  └─ /images/:id             상세 (메타·사용 게시물 역추적·태그·숨김)
│
├─ /chat-logs                 챗봇 응답 로그 ──────────────────────────  (Phase 2 준비)
│  ├─ /chat-logs              세션 목록 (사용자·시각·답변 수·만족도)
│  └─ /chat-logs/:sessionId   세션 상세 (메시지 흐름·인용 출처·피드백)
│
├─ /escalations               에스컬레이션 큐 ────────────────────────  (Phase 2 준비)
│  ├─ /escalations            대기 큐 (질문·신뢰도·우선순위)
│  └─ /escalations/:id        처리 (상담사 답변 작성·표준답변 등록)
│
├─ /qa-evals                  Q&A 평가 (PMS와 병행) ──────────────────
│  ├─ /qa-evals               목록 (= PMS /admin/evals 동일)
│  └─ /qa-evals/:id           상세 (= QaEvalCard 모달)
│
├─ /cost                      LLM 비용 (PMS와 병행) ──────────────────
│  └─ /cost                   대시보드 (= PMS /admin/cost 동일)
│
├─ /settings                  설정 ─────────────────────────────────────
│  ├─ /settings/ai            AI 설정 (모델·온도·맥스토큰·시스템 프롬프트)
│  ├─ /settings/safety        안전 가드 (PII·금칙어·"모름" 임계값)
│  ├─ /settings/cache         캐싱 (TTL·invalidation 규칙)
│  └─ /settings/integrations  외부 연동 (Slack·이메일·티켓)
│
└─ /accounts                  계정·권한 ───────────────────────────────
   ├─ /accounts               사용자 목록
   └─ /accounts/:id           역할·활성/비활성·감사 로그
```

### 3-1. 글로벌 레이아웃

- **좌측 사이드바**: 8개 섹션(자료·표준답변·이미지·챗로그·에스컬레이션·평가·비용·설정·계정)
- **상단바**: 검색 입력 / 환경 토글(개발/운영) / 사용자 메뉴
- **본문**: 좌측 패널 240px + 본문, 모바일은 hamburger
- **디자인 톤**: PMS와 일관 (Tailwind v4 + Pretendard + Notion-clean 라이트 모드 고정)

---

## 4. 화면 명세

### 4-1. 홈 — `/`

**목적**: 운영 상태 한눈에. 상담사는 자기 작업, 운영자는 시스템 전체.

**KPI 카드 (운영자)**
- 자료 총 N건 · 인덱싱 완료 X% · 미처리 N건
- 표준답변 N건 · 승인 대기 N건 · 이번 주 신규 N건
- 챗봇 응답 N건 (Phase 2) · 평균 신뢰도 X%
- 에스컬레이션 N건 대기 · 평균 처리 시간 X시간
- 이번 달 LLM 비용 $X.XX · 예산 대비 X%

**KPI 카드 (상담사)**
- 내가 등록한 표준답변 N건
- 내가 처리한 에스컬레이션 N건
- 최근 7일 평가 점수 평균

**최근 활동 피드** — 시간순 (자료 업로드·표준답변 추가·평가 등록·에스컬레이션 해결)

```
┌────────────────────────────────────────────────────────┐
│  📊 시스템 현황                       [상담사 모드 보기 ↗]│
├──────────────┬──────────────┬──────────────┬───────────│
│ 자료         │ 표준답변      │ 이번 달 비용  │ 에스컬레이션│
│ 142건        │ 87건         │ $12.45       │ 3건 대기   │
│ 인덱싱 96%   │ 승인대기 4    │ 예산 25%     │ 평균 2h 처리│
└──────────────┴──────────────┴──────────────┴───────────┘
┌────────────────────────────────────────────────────────┐
│  📜 최근 활동                                            │
│  ─ 09:14  표준답변 #88 등록 — "알림톡 비용 안내" (장지혜)  │
│  ─ 09:02  자료 인덱싱 완료 — manual-v2.3.pdf (32 청크)    │
│  ─ 08:51  에스컬레이션 해결 — "비밀번호 변경" (김현희)     │
└────────────────────────────────────────────────────────┘
```

---

### 4-2. 자료 관리 — `/materials`

**자산 종류 2가지**

| 종류 | 설명 | 인덱싱 |
| --- | --- | --- |
| **파일 자산** (`file`) | PDF·MD·HTML·DOCX 직접 업로드 → R2 저장 | 텍스트 추출 → 청크 → 임베딩 → OpenSearch |
| **URL 자산** (`url`) | 외부/사내 페이지·**동영상 URL** 등록만 | URL 페이지는 크롤링 후 텍스트 청크화. 동영상은 메타(제목·설명·태그)만 인덱싱하고, **필요시 Whisper로 자막 추출 트리거**(별도 액션) |

**핵심 기능**
- 파일 드래그앤드롭 또는 **URL 입력 폼** (제목·설명·태그)
- 자동 인덱싱 — `pending` → `processing` → `indexed` / `failed`
- 재인덱싱(`reindex`) · 삭제(soft delete)
- 동영상 URL 자산은 **"자막 추출(Whisper)" 액션 버튼** — 누르면 비동기 Whisper 호출 후 텍스트 청크에 합산. 기본 비활성, 필요할 때만
- 검색은 메타·본문 LIKE(MVP), 추후 OpenSearch full-text

**목록 표 컬럼**: 제목 · 종류(파일/URL) · 형식 · 인덱싱 상태 · 청크 수 · 업로더 · 등록일 · 액션
**상세 페이지**: 메타데이터, 원본(파일은 다운로드/URL은 새 탭), 청크 미리보기(처음 5개), "재인덱싱"·"자막 추출"(동영상만)·"삭제"·"태그 편집" 액션

**필요 테이블 (신규)**
- `hp_material` — id, title, **kind** (`file`/`url`/`video_url`), file_path(R2 key, file·video일 때만), source_url(url·video_url일 때만), mime, size, description, tags(JSON), uploader_id, project_id(NULL = 전사), indexing_status(pending/processing/indexed/failed), chunk_count, indexed_at, transcript_status(`none`/`pending`/`done`/`failed`, video_url 전용), status(1/-1), created_at
- `hp_material_chunk` — id, material_id, chunk_idx, body(TEXT), token_count, embedding(LONGBLOB or OpenSearch only), source(`body`/`transcript`), created_at

**필요 API (신규)**
- `POST /materials/file` (multipart) — 파일 업로드 + 인덱싱 시작
- `POST /materials/url` (JSON) — URL/동영상 URL 등록
- `GET /materials` — 목록·필터 (kind, indexing_status, search)
- `GET /materials/:id` — 상세 (청크 포함)
- `POST /materials/:id/reindex` — 재인덱싱
- `POST /materials/:id/transcribe` — Whisper 자막 추출 (video_url만)
- `DELETE /materials/:id` — soft delete

**의존**
- OpenSearch 셋업 (Phase 1 후반)
- Whisper API 키 (선택, 동영상 자막 필요할 때)

---

### 4-3. 표준답변 관리 — `/standard-answers`

**핵심 기능 (PMS는 저장만, admin은 완전 관리)**
- 목록 — 검색(question·answer LIKE 또는 FULLTEXT)·태그·프로젝트 필터·사용량 정렬
- 상세·편집 — `label`/`question`/`answer`/`tags`/`project_id` 수정
- 승인 워크플로 — `pending` → `approved` (운영자만), 챗봇은 `approved`만 사용
- 사용 통계 — `usage_count` · `last_used_at` 차트
- 출처 역추적 — `source_post_id` 클릭 → PMS 게시물 모달
- 자동 추출 후보 — `/standard-answers/suggestions`에서 LLM이 제안한 N건 검토

**기존 자산 활용**
- `hp_standard_answer` 그대로 (스키마 확장만)
- 신규 컬럼: `approval_status` (`pending`/`approved`/`rejected`), `tags` (JSON), `approved_by`, `approved_at`

**필요 API (보강)**
- `PATCH /standard-answers/:id/approve` — 승인
- `PATCH /standard-answers/:id/reject` — 반려
- `GET /standard-answers/suggestions` — `/pms/projects/:id/standard-answer-suggestions` 재활용

**화면 구조 (목록)**
```
[🔍 검색]  [태그 ▾]  [프로젝트 ▾]  [상태 ▾]    [+ 새 표준답변]

#  label              question                  사용  업데이트       상태       액션
84 알림톡 비용         알림톡 추가 비용은?         42회  06-07 14:21   ● 승인됨   [편집]
83 비밀번호 변경       비밀번호를 잊었어요         12회  06-06 09:10   ◯ 대기     [승인]
…
```

---

### 4-4. 이미지 카탈로그 — `/images`

**핵심 기능**
- `hp_image_asset` 전체 시각화 — 썸네일 그리드
- 검색 — `title` · `description` LIKE
- 필터 — `source` (inquiry/reply) · 프로젝트 · 사용 횟수
- 상세 — 메타 · `first_seen_post_id` 역추적 · 태그 편집 · 숨김(`status=-1`)
- 챗봇 컨텍스트 활용 미리보기 — "이 이미지 설명이 답변에 인용될 때 모습"

**필요 컬럼 보강**
- `tags` (JSON) — 운영자가 큐레이션
- `is_curated` (TINYINT) — 운영자가 검토 완료 표시

**필요 API (신규)**
- `GET /image-assets` — 목록·검색·페이지네이션
- `GET /image-assets/:id` — 상세
- `PATCH /image-assets/:id` — title·description·tags 편집
- `DELETE /image-assets/:id` — soft hide

---

### 4-5. 챗봇 응답 로그 — `/chat-logs` *(Phase 2 준비)*

**핵심 기능**
- 세션 단위 목록 — 사용자·시작 시각·메시지 수·평균 신뢰도·만족도(👍/👎)
- 세션 상세 — 메시지 흐름 (질문·답변·인용 출처·신뢰도) + 사용자 피드백 + 처리 시간
- 필터 — 일자·만족도·신뢰도·"모름" 분기 여부
- 추출 — 미커버 질문 → 표준답변 후보 자동 제안

**필요 테이블 (신규, Phase 2)**
- `hp_chat_session` — id, user_id(익명 hash 가능), started_at, ended_at, message_count, status
- `hp_chat_message` — id, session_id, role(user/assistant), content, citations(JSON, hp_standard_answer.id 또는 hp_material_chunk.id), confidence, latency_ms, model, created_at
- `hp_chat_feedback` — session_id, message_id, rating(1/-1), comment, created_at

**필요 API (신규, Phase 2)**
- `POST /chat` — 응답 생성 (스트리밍)
- `GET /chat-sessions` — 목록
- `GET /chat-sessions/:id` — 상세
- `POST /chat-feedback` — 피드백

---

### 4-6. 에스컬레이션 큐 — `/escalations` *(Phase 2 준비)*

**핵심 기능**
- 챗봇이 "모름" 또는 신뢰도 임계값 미만으로 분기한 질문 큐
- 대기·진행·완료 탭
- 상담사 답변 작성 → 사용자 알림 + 표준답변 등록 옵션
- 우선순위 (사용자 만족도·VIP·신뢰도·반복 횟수)

**필요 테이블 (신규)**
- `hp_escalation` — id, session_id, message_id, question, status(pending/in_progress/resolved), assigned_to, priority, created_at, resolved_at, resolution

---

### 4-7. Q&A 평가 / LLM 비용 — `/qa-evals` · `/cost`

PMS의 `/admin/evals`, `/admin/cost`와 동일 데이터·UI. 동일 컴포넌트(`QaEvalCard` 등) 재사용. 운영자가 PMS를 안 켜고도 모니터링 가능.

추후 admin 전용 부가 기능:
- 평가 기준선(score < 3) 알림
- 비용 예산 알림 (월 한도 임박 시 Slack)

---

### 4-8. AI 설정 — `/settings/ai`

**관리 항목**
- 기본 모델 (`gpt-4.1-mini` · 다른 모델 선택)
- Vision 모델 (이미지 있을 때 자동 업그레이드 여부)
- 시스템 프롬프트 — 챗봇 (`PHASE2_CHAT_SYSTEM_PROMPT`) · 평가 · 추천답변 별도 편집
- `temperature` · `max_tokens` · `timeout`
- LLM 캐싱 TTL (`llm_input_hash` 24h 등)

**저장 위치**: 신규 `hp_setting` (key/value JSON) 또는 단순 KV 바인딩

**Diff 미리보기** — 변경 적용 전 영향 받을 엔드포인트 명시

---

### 4-9. 안전 가드 — `/settings/safety`

- "모름" 분기 임계값 (confidence < X)
- PII 마스킹 패턴 (이메일·전화·계좌 등 정규식 목록)
- 금칙어 사전 (정치·종교·욕설)
- 응답 길이 제한·언어 제한

---

### 4-10. 캐싱 — `/settings/cache`

- `hp_briefing`·`hp_qa_eval` 캐시 TTL
- `hp_standard_answer` 자주 묻는 답변 in-memory 캐시 크기
- 캐시 무효화 트리거 (자료 업로드 시 등)
- 수동 캐시 비우기 액션

---

### 4-11. 외부 연동 — `/settings/integrations`

- **Slack** — 에스컬레이션·비용 임계 알림 (Webhook URL 등록)
- **이메일** — SendGrid·SMTP (선택)
- **티켓 시스템** — Jira·Zendesk·기존 CS (Phase 2 후반)
- **SSO** — Google OAuth (Phase 1 후반)

---

### 4-12. 계정·권한 — `/accounts`

**핵심 기능**
- 사용자 목록 — 이메일 · 역할(admin/agent) · 마지막 로그인 · 활성 여부
- 초대 — 이메일 invite + 역할 지정 (운영자만)
- 역할 변경 · 비활성화
- 감사 로그 — 각 계정의 액션 시간순 (자료 업로드, 표준답변 승인 등)

**필요 테이블 (신규)**
- `hp_account` — id, email, name, role(admin/agent), status, last_login_at, created_at
- `hp_audit_log` — id, account_id, action(material.upload, sa.approve 등), entity_type, entity_id, payload(JSON), created_at

**인증 방식**: Cloudflare Access SSO 또는 자체 비밀번호 + JWT. 1차는 Cloudflare Access(이미 가이드 있음).

---

## 5. 데이터·API 종합 추가 사항

### 5-1. 신규 테이블 (4종)

| 테이블 | 단계 | 비고 |
| --- | --- | --- |
| `hp_material` · `hp_material_chunk` | Phase 1 후반 | 자료 업로드·인덱싱 |
| `hp_setting` | Phase 1 후반 | 키/값 JSON 설정 |
| `hp_account` · `hp_audit_log` | Phase 1 후반 | 계정·감사 |
| `hp_chat_session` · `hp_chat_message` · `hp_chat_feedback` | **Phase 2** | 챗봇 로그 |
| `hp_escalation` | **Phase 2** | 에스컬레이션 큐 |

### 5-2. 기존 테이블 보강

- `hp_standard_answer` — `approval_status`, `tags`, `approved_by`, `approved_at` 추가
- `hp_image_asset` — `tags`, `is_curated` 추가

### 5-3. 신규 API 그룹

| 경로 | 목적 |
| --- | --- |
| `/materials` (CRUD + `/reindex`) | 자료 관리 |
| `/image-assets` (CRUD) | 이미지 카탈로그 |
| `/standard-answers/:id/approve` · `/reject` | 승인 워크플로 |
| `/settings/*` | AI·안전·캐싱 설정 |
| `/accounts` (CRUD + invite) | 계정 |
| `/audit-logs` | 감사 로그 조회 |

OpenAPI(`/doc`)에 모두 추가.

---

## 6. 권한·인증

### 6-1. 인증

**Cloudflare Access SSO** ([CLOUDFLARE-ACCESS.md](CLOUDFLARE-ACCESS.md) 가이드 적용)
- admin 도메인 전체 보호 — 외부 접근 차단
- 이메일 도메인 화이트리스트 = **`@malgnsoft.com`** 만 (협력사·고객사 차단)
- 세션 토큰을 API가 검증 (`cf-access-jwt-assertion` 헤더)
- 외부 운영자 초대 케이스가 없으므로 자체 비밀번호 로직 불필요

### 6-2. 권한 가드

API 측 미들웨어:

```ts
type Role = 'admin' | 'developer' | 'agent';

function requireRole(...allowed: Role[]) {
  return async (c, next) => {
    const user = c.get('user'); // CF Access JWT에서 추출 (email, role)
    if (!user) return c.json({ error: 'unauthorized' }, 401);
    if (!user.email.endsWith('@malgnsoft.com')) return c.json({ error: 'forbidden' }, 403);
    if (!allowed.includes(user.role)) return c.json({ error: 'forbidden' }, 403);
    await next();
  };
}
```

라우트 별 적용 예:

| 라우트 | 가드 |
| --- | --- |
| `POST /materials/*` · `DELETE /materials/:id` | `requireRole('admin', 'developer')` |
| `GET /materials` · `GET /materials/:id` | `requireRole('admin', 'developer', 'agent')` |
| `POST /standard-answers` | `requireRole('admin', 'developer', 'agent')` |
| `PATCH /standard-answers/:id/approve` | `requireRole('admin', 'developer')` |
| `PATCH /image-assets/:id` · `DELETE /image-assets/:id` | `requireRole('admin', 'developer')` |
| `POST /settings/*` | `requireRole('admin', 'developer')` |
| `POST /accounts/*` · `PATCH /accounts/:id/role` | `requireRole('admin')` |
| `GET /audit-logs` | `requireRole('admin', 'developer')` |

---

## 7. 단계별 구현 우선순위 (5주 기준)

> 각 주차는 누적. 이전 주차 산출물 위에 추가.

### Week 1 — 골격 + 인증

- 글로벌 레이아웃(사이드바·상단바·로그인 페이지)
- Cloudflare Access SSO 적용 + JWT 검증 미들웨어
- `/` 홈 (KPI 카드 mockup, 실제 데이터는 다음 주차)
- 신규 테이블 5종 DDL (`hp_material`·`hp_material_chunk`·`hp_setting`·`hp_account`·`hp_audit_log`)
- `hp_standard_answer` · `hp_image_asset` 컬럼 보강

**산출물 검증**: 로그인 후 빈 홈 진입, 사이드바·역할 분기 동작

### Week 2 — 표준답변 + 이미지 카탈로그

- `/standard-answers` 목록·상세·편집·승인 워크플로
- `/standard-answers/suggestions` (자동 추출 후보 검토)
- `/images` 그리드·검색·태그·숨김
- API: `/standard-answers/:id/approve|reject` · `/image-assets` CRUD

**검증**: 운영자가 PMS에서 저장한 표준답변을 admin에서 승인, 챗봇이 `approved`만 사용하는지 확인

### Week 3 — 자료 업로드 + 인덱싱

- `/materials` 업로드·목록·재인덱싱·삭제
- API: `/materials` CRUD + R2 업로드 + 청크 + 임베딩 + OpenSearch 색인 (동기 MVP)
- 인덱싱 상태 폴링 UI

**검증**: 매뉴얼 PDF 1건 업로드 → 청크 N개 색인 완료 → `/images` 자동 채워짐

### Week 4 — 설정 + 통합 모니터링

- `/settings/ai` · `/settings/safety` · `/settings/cache` · `/settings/integrations`
- `/qa-evals` · `/cost` (PMS와 동일 데이터, admin 톤으로 재구성)
- 홈 KPI 카드 실제 데이터 연동
- 자동 추출 후보(`hp_standard_answer/suggestions`) 알림 → Slack 연동

**검증**: 시스템 프롬프트 편집 후 챗봇·평가 호출 결과 변화 반영, 비용 임계 알림 동작

### Week 5 — 계정·권한·감사 + Phase 2 준비

- `/accounts` CRUD · 역할·초대
- `/audit-logs` 감사 로그
- `/chat-logs` · `/escalations` 페이지 골격 (Phase 2 챗봇 데이터 도착 전까지는 mockup)
- 모든 액션 감사 로그 기록 (`hp_audit_log` INSERT)

**검증**: 운영자가 상담사 초대 → 상담사 가입 → 역할 가드 동작, 감사 로그 누적

---

## 8. 다음 단계 (이 기획서 승인 후)

1. **신규 테이블 5종 DDL 작성** + `/admin/migrate/*` 일회용 엔드포인트 (`hp_image_asset` 패턴 재활용)
2. **Cloudflare Access 셋업** + admin 도메인 보호 적용
3. **Week 1 골격 구현 시작** — 사이드바·로그인·홈
4. **OpenSearch 도메인 발주·셋업** (자료 인덱싱 의존)
5. **WBS 갱신** — 본 기획의 5주차를 P1-3 / P1-4 산하 task로 분해

---

## 9. 결정 사항 기록

| 결정 | 일자 | 근거 |
| --- | --- | --- |
| 사용자 = **맑은소프트 직원 전용** (협력사·고객사 차단) | 2026-06-08 | 사용자 합의 |
| 역할 3개 — 관리자(`admin`) · 개발자(`developer`) · 상담사(`agent`) | 2026-06-08 | 사용자 합의 |
| PMS `/admin/*` 페이지와 admin은 병행 | 2026-06-08 | 상담사 PMS 흐름 유지 |
| MVP = 챗봇 도입 전 필요한 전부 + 설정 + 계정 | 2026-06-08 | 사용자 합의 |
| 인증은 Cloudflare Access SSO (`@malgnsoft.com` 도메인 한정) | 2026-06-08 | 직원 전용 + 기존 가이드 |
| **동영상 자료는 URL 등록만**, Whisper 자막은 필요할 때 수동 트리거 | 2026-06-08 | 사용자 합의 |
| 다크모드 비활성 (CSS body bg 라이트 고정) | 2026-06-08 | PMS와 일관 |

### 운영 정책 기본값 (추가 합의 없을 시 적용)

| 항목 | 기본값 | 근거 |
| --- | --- | --- |
| **미커버 질문 알림 임계값** | 같은 표현 **주 3건** 이상 누적되면 자동 표준답변 후보로 큐에 등록 + Slack DM(개발자·관리자) | 빈도 낮은 한 번 질문은 노이즈, 3회는 패턴 |
| **미커버 알림 채널** | Slack `#cs-helper-ops` 채널 (Webhook 등록 후) — 부재 시 admin 홈의 "후보 알림" 카드만 | 외부 의존 최소화 |
| **상담사 답변 작성 시 AI 초안** | **에스컬레이션 처리 화면**에 "초안 생성" 버튼 (선택). 표준답변 등록 화면에는 없음(이미 LLM이 생성한 6개 변형이 PMS 측에 있음) | 에스컬레이션 = 진짜 새 답변, 표준답변 = 큐레이션 |
| **데이터 보존 — 챗 로그** | 메시지 본문 90일 / 메타(세션·피드백·신뢰도) 1년 / 1년 후 익명화 후 통계 보관 | 개인정보 최소화 + 품질 평가용 보존 |
| **데이터 보존 — 자료** | soft delete 후 90일 R2 hold, 그 후 영구 삭제. 청크는 즉시 OpenSearch에서 제거 | 실수 복구 + 비용 |
| **데이터 보존 — 표준답변·이미지** | 무기한 soft delete (수동 영구 삭제만 가능) | 자산 가치 우선 |

---

## 10. 열린 질문 (확정 전)

남아있는 결정 없음 — 모든 항목 §9 기본값으로 확정. 운영 중 조정 시 §9의 "기본값"을 갱신하고 history에 기록.
