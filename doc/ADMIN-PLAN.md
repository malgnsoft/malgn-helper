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
├─ /uncovered                 미커버 질문 큐 ──────────────────────────  (Phase 2 준비, 별도 페이지)
│  └─ /uncovered/:id          상세 + AI 초안 생성 + 표준답변·자료 연결
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

#### 4-3-1. 분류 체계 (Scope · Topic · Service)

표준답변은 **2축 분류** + **태그**로 관리:

| 축 | 값 | 의미 |
| --- | --- | --- |
| **scope** | `common` | 어떤 솔루션이든 동일하게 적용되는 답변 (도메인·SEO·일반 IT 등) |
| | `service` | 특정 솔루션에만 적용되는 답변 (기능·법령·정책 등) |
| **topic** | 슬러그 코드 | 주제 — 검색·필터·자동 추천에 사용 |
| **service_tag** | 솔루션 슬러그 (NULL = scope=common) | 어느 서비스의 답변인지 |
| **tags** | JSON 배열 | 자유 태그 (운영자 큐레이션) |

**기본 topic 카탈로그** (`hp_topic` 테이블로 관리, 운영자가 추가 가능):

| scope | topic 슬러그 | 라벨 | 예시 |
| --- | --- | --- | --- |
| common | `domain` | 도메인 | 도메인 연결·DNS·SSL |
| common | `seo` | SEO | 메타·sitemap·robots.txt |
| common | `it-general` | 일반 IT | 브라우저 캐시·쿠키·HTTPS |
| common | `account` | 계정·로그인 | 비밀번호·OTP·세션 |
| common | `payment` | 결제 일반 | 카드·세금계산서·환불 절차 |
| service | `feature` | 기능 | 알림톡·SMS·게시판·LMS 등 |
| service | `legal` | 법령·약관 | 개인정보·전자상거래·교육법 |
| service | `policy` | 정책 | 사용·요금·약관 정책 |
| service | `pricing` | 요금·계약 | 단가표·계약 조건 |
| service | `integration` | 연동·API | 외부 API·웹훅 |

**기본 service_tag 카탈로그** (`hp_service` 테이블, 운영자가 추가)

맑은소프트 LMS 패밀리 — 같은 LMS라도 도메인 규정·법령·기능 옵션이 달라서 표준답변을 분리해야 함:

| slug | 이름 | 도메인·특수성 |
| --- | --- | --- |
| `lms-general` | 범용 LMS | 일반 학습관리 (베이스 라인) |
| `lms-refund` | 환급 LMS | 고용보험 환급 과정 — 환급법령·증빙·이수율 룰 |
| `lms-public` | 공공 LMS | 공공기관 — 입찰·관급·법정 의무교육·접근성(WCAG) |
| `lms-security` | 민간보안 LMS | 정보보호 의무교육(개인정보보호법·정보통신망법) · ISMS-P 컴플라이언스 · 보안등급별 컨텐츠 분리 · 접근 로그·이수 증명 |
| `lms-hybrid` | 혼합 LMS | 환급+민간 등 복합 — 두 도메인 룰 동시 적용 |
| `lms-global` | 글로벌 LMS | 다국어·다지역 — i18n·결제·세금·시간대·법령 |
| ... | (운영자 추가) | LMS 외 솔루션이 도입되면 추가 |

> 분류 효과: 같은 `topic=legal` 문의여도 환급(고용보험법) vs 공공(전자정부법) vs 글로벌(GDPR)이 전혀 다른 답변. `service_tag` 일치를 우선 매칭하여 정답률 확보.

**매칭 규칙 (챗봇 응답·표준답변 추천)**

1. 사용자 질문 → LLM이 `scope` + `topic` 추론
2. `scope=service`이면 사용자가 사용 중인 서비스(`service_tag`)로 필터
3. `scope=common`이면 service 무관하게 매칭
4. 동점 시 `tags` 매치 수 + `usage_count` 우선순위
5. 매칭 결과 N개를 LLM 컨텍스트에 첨부

#### 4-3-2. 화면

**목록 — `/standard-answers`**

```
[🔍 검색]  [scope: common/service ▾]  [topic ▾]  [service ▾]  [상태 ▾]    [+ 새 표준답변]

#   label              scope    topic        service     사용  업데이트       상태       
84  환급 이수율 기준        service  legal        lms-refund    42회  06-07 14:21   ● 승인됨   
83  비밀번호 변경           common   account      —             12회  06-06 09:10   ◯ 대기     
82  도메인 SSL 갱신         common   domain       —             28회  06-05 11:00   ● 승인됨   
81  공공기관 접근성 인증    service  legal        lms-public     5회  06-05 09:00   ● 승인됨   
80  LMS 수료증 출력         service  feature      lms-general    7회  06-04 17:45   ● 승인됨   
79  다국어 결제 통화        service  pricing      lms-global     3회  06-03 11:00   ◯ 대기     
```

**상세·편집 — `/standard-answers/:id`**

- 좌측: 메타 (`scope`/`topic`/`service`/`tags`) + 사용 통계 + 출처 역추적
- 우측: HTML 답변 에디터 (Rich text, Tailwind prose preview)
- **하단: 이미지 자동 추천 패널** (다음 §4-3-3 참조)
- 액션: 저장 · 승인 · 반려 · 영구 삭제(`status=-2`, 매우 드물게)

#### 4-3-3. 이미지 자동 배치 (`hp_image_asset` 활용)

**기획 의도**: 표준답변 작성 시 `hp_image_asset`의 캡션·설명으로 적절한 이미지를 자동 매칭·삽입. 운영자가 일일이 src를 찾을 필요 없음.

**3가지 동작 방식**

1. **에디터 사이드 패널 — 추천 이미지 그리드**
   - 현재 입력 중인 답변 본문에서 LLM이 키워드 추출 → `hp_image_asset` 검색 (title·description LIKE 또는 임베딩 유사도)
   - 썸네일 + title 표시
   - 클릭 → 커서 위치에 `<figure><img src=...><figcaption>{title}</figcaption></figure>` 삽입

2. **"AI 자동 삽입" 버튼**
   - LLM이 답변 전체를 읽고 적절한 위치에 자동으로 이미지 + 캡션 삽입
   - 미리보기 → 운영자 승인 → 적용
   - 이미 PMS Q&A 분석에서 D축 templates 생성 시 같은 흐름 동작 중 — 그 로직 재사용

3. **이미지 추출 후 자동 표준답변화** (반대 흐름)
   - `/images/:id` 상세 화면에 "이 이미지를 사용하는 표준답변 만들기" 액션
   - 이미지의 title·description을 시작점으로 LLM이 표준답변 초안 생성
   - 운영자 검토 후 저장

**필요 보강**

- `hp_image_asset`에 임베딩(embedding) 컬럼 추가 또는 OpenSearch 색인 (이미지 의미 검색용)
- 표준답변 ↔ 이미지 다대다 관계 추적: `hp_standard_answer_image` (sa_id, image_id, position) — 어느 표준답변이 어느 이미지를 인용하는지 역추적용

#### 4-3-4. 스키마 보강 (`hp_standard_answer`)

추가 컬럼:
- `scope` ENUM('common', 'service') NOT NULL DEFAULT 'service'
- `topic` VARCHAR(50) NOT NULL — `hp_topic.slug`와 매칭
- `service_tag` VARCHAR(50) NULL — `hp_service.slug`와 매칭 (scope=service일 때만 필수)
- `approval_status` ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending'
- `tags` JSON DEFAULT '[]'
- `approved_by` VARCHAR(100) NULL
- `approved_at` DATETIME NULL

신규 테이블 2종:
- `hp_topic` — slug PK, scope, label, description, sort_order, status
- `hp_service` — slug PK, name, description, sort_order, status
- `hp_standard_answer_image` — sa_id, image_id, position (FK), PRIMARY KEY (sa_id, image_id)

#### 4-3-5. 필요 API (보강)

- `GET /topics` · `POST /topics` · `PATCH /topics/:slug` — 토픽 카탈로그 CRUD
- `GET /services` · `POST /services` · `PATCH /services/:slug` — 서비스 카탈로그 CRUD
- `GET /standard-answers?scope=&topic=&service_tag=&search=` — 필터 보강
- `PATCH /standard-answers/:id/approve` — 승인
- `POST /standard-answers/:id/images` — 이미지 연결
- `POST /standard-answers/:id/suggest-images` — LLM이 이미지 자동 추천 (top N)
- `POST /standard-answers/draft` — 이미지 → 표준답변 초안 생성

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
- 필터 — 일자·만족도·신뢰도

> **참고**: "답변 없는 PMS 게시물"과는 다른 개념. 게시물은 상담사가 직접 PMS에서 답변하고, 미커버 질문은 챗봇 → 자료/표준답변으로 흐름이 다름.

---

### 4-5-1. 미커버 질문 — `/uncovered` *(Phase 2 준비, 별도 전용 페이지)*

**기획 의도**: 챗봇이 답을 못 한 질문을 챗 로그에서 따로 모아 **자료·표준답변 보강 작업 큐**로 운영. `/chat-logs`와 분리해 운영자·개발자가 한눈에 누락된 지식 영역을 본다.

**핵심 기능**
- **누적 큐**: 챗봇이 `is_unknown=true` 또는 `confidence < 0.5`로 분기한 질문을 모음
- **자동 클러스터링**: 의미 유사 질문 묶음 (임베딩 cosine ≥ 0.8). 같은 의미면 묶어서 "주 5건" 같은 빈도 표시
- **상태 관리** — `pending`(대기) / `working`(작업 중) / `resolved`(표준답변/자료 추가됨) / `wont_fix`(범위 외)
- **표준답변 등록 트리거** — 큐 항목 클릭 → 답변 초안 작성 모달 (§4-5-2 참조)
- **자료 업로드 트리거** — 큐 항목에 "관련 매뉴얼 추가" 액션 → `/materials/upload`로 미리 채워서 이동
- **필터·정렬** — 빈도 ↓ / 최근 / `scope` 추정 / 상태별

**화면 구조 (목록)**

```
[🔍 검색]  [상태 ▾]  [scope ▾]  [빈도 ▾]                          [정렬: 빈도 ↓]

#   대표 질문                              빈도  마지막 발생      추정 scope/topic   상태       액션
148 알림톡 발신 프로필 등록 어떻게?           12   06-08 09:14    service/feature   ◯ 대기     [답변 작성][자료 추가]
147 SSL 인증서 갱신 절차                       8   06-07 17:00    common/domain     ◯ 대기     [답변 작성]
146 LMS 수강 이력 엑셀 추출                   6   06-07 11:23    service/feature   ● 작업중  
145 결제 영수증 발급                          15   06-06 14:00    common/payment    ✓ 해결됨   [표준답변 #88 보기]
```

**필요 테이블**
- `hp_uncovered_question` — id, sample_question(대표 질문), cluster_id(같은 의미 묶음 키), occurrence_count, last_seen_at, estimated_scope, estimated_topic, estimated_service_tag, status, resolved_by_sa_id(FK to hp_standard_answer), resolved_by_material_id(FK to hp_material), assigned_to, created_at

**필요 API**
- `GET /uncovered` — 목록·필터
- `PATCH /uncovered/:id/assign` — 담당자 지정
- `POST /uncovered/:id/draft-sa` — 미커버 질문을 시드로 표준답변 초안 생성 (§4-5-2)
- `POST /uncovered/:id/resolve` — 표준답변·자료 연결하여 해결 처리

---

### 4-5-2. AI 초안 생성 — 챗봇 응답 로직 그대로 재사용

**기획 결정**: 별도 prompt를 만들지 않는다. **챗봇 응답 파이프라인(`POST /chat`)을 그대로 호출**하여 응답을 받고, 운영자가 검토·편집해 표준답변으로 저장한다.

**진입점**

1. **에스컬레이션 처리 화면** (`/escalations/:id`) — "AI 초안 생성" 버튼
2. **미커버 질문 큐** (`/uncovered/:id`) — "답변 작성" 클릭 시 자동으로 초안 생성
3. **표준답변 신규 등록** (`/standard-answers/new`) — 질문 입력 후 "AI 초안 받기" 옵션

**동작 흐름**

```
운영자: 질문 입력 (또는 미커버 항목 클릭)
   ↓
API: POST /chat (Phase 2 챗봇 응답 API 그대로)
   - 표준답변 매칭 우선 → 하이브리드 검색 → LLM 답변 + 출처 + 신뢰도
   ↓
응답: 답변 본문 + 인용 출처(표준답변 id, 자료 청크 id, 이미지 id)
   ↓
화면: HTML 에디터에 본문 자동 채움 + 우측에 출처 패널
   ↓
운영자: 편집 → scope/topic/service 분류 지정 → 저장
   ↓
승인 후 → 챗봇이 이후 매칭에 사용
```

**장점**

- 별도 prompt 관리 부담 없음 (한 모델·한 prompt 유지)
- 챗봇 응답 품질이 곧 초안 품질 — 챗봇 개선 = 초안 개선
- 출처 인용이 자동으로 따라옴 → 표준답변 저장 시 출처 메타데이터 함께 저장

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

### 5-1. 신규 테이블 (총 11종)

| 테이블 | 단계 | 비고 |
| --- | --- | --- |
| `hp_material` · `hp_material_chunk` | Phase 1 후반 | 자료 업로드·인덱싱. `kind`=`file`/`url`/`video_url` |
| `hp_topic` | Phase 1 후반 | 표준답변 토픽 카탈로그 (`scope` + `slug` + `label`) |
| `hp_service` | Phase 1 후반 | 솔루션 카탈로그 (`slug` + `name`) |
| `hp_standard_answer_image` | Phase 1 후반 | 표준답변 ↔ 이미지 다대다 (역추적·자동 삽입) |
| `hp_setting` | Phase 1 후반 | 키/값 JSON 설정 |
| `hp_account` · `hp_audit_log` | Phase 1 후반 | 계정·감사 |
| `hp_chat_session` · `hp_chat_message` · `hp_chat_feedback` | **Phase 2** | 챗봇 로그 |
| `hp_escalation` | **Phase 2** | 에스컬레이션 큐 |
| `hp_uncovered_question` | **Phase 2** | 미커버 질문 작업 큐 (클러스터링 포함) |

### 5-2. 기존 테이블 보강

- `hp_standard_answer` — `scope`, `topic`, `service_tag`, `approval_status`, `tags`, `approved_by`, `approved_at` 추가
- `hp_image_asset` — `tags`, `is_curated`, (선택) `embedding` 추가

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
| **자료 보존 무기한** (특별한 일 없는 한) | 2026-06-08 | 사용자 합의 (자산 가치 우선) |
| **표준답변 분류 = scope(`common`/`service`) + topic + service_tag + tags** | 2026-06-08 | 사용자 합의 (도메인·SEO·일반 IT는 공통, 기능·법령은 서비스별) |
| **service_tag 기본 카탈로그 = LMS 패밀리 6종** (`lms-general`/`-refund`/`-public`/`-security`/`-hybrid`/`-global`) | 2026-06-08 | 사용자 합의 — 같은 LMS라도 도메인 룰 달라 표준답변 분리 필요. `lms-security`는 정보보호 의무교육·ISMS-P 컴플라이언스 영역 |
| **AI 초안 생성 = 챗봇 응답 로직(`POST /chat`) 재사용** | 2026-06-08 | 사용자 합의 (별도 prompt 안 만듦) |
| **미커버 질문 = `/uncovered` 별도 전용 페이지** | 2026-06-08 | 사용자 합의 (작업 큐로 운영) |
| **표준답변 작성 시 `hp_image_asset` 자동 추천·삽입** | 2026-06-08 | 사용자 합의 (이미지 캡션·설명 활용) |
| 다크모드 비활성 (CSS body bg 라이트 고정) | 2026-06-08 | PMS와 일관 |

### 운영 정책 기본값 (추가 합의 없을 시 적용)

| 항목 | 기본값 | 근거 |
| --- | --- | --- |
| **미커버 질문(uncovered) 알림 임계값** | **챗봇(Phase 2)이 "모름"으로 분기**하거나 신뢰도 < 0.5로 응답한 질문 중, 같은 의미가 **주 3건** 이상 누적되면 표준답변 후보로 큐 등록 + Slack DM. *답변 없는 게시물(inquiry-only)과는 별개 — 게시물은 이미 PMS에서 상담사가 처리* | 챗봇 지식 베이스의 구멍을 자료·표준답변 보강 신호로 환산 |
| **미커버 알림 채널** | Slack `#cs-helper-ops` 채널 (Webhook 등록 후) — 부재 시 admin 홈의 "후보 알림" 카드만 | 외부 의존 최소화 |
| **상담사 답변 작성 시 AI 초안** | **에스컬레이션 처리 화면**에 "초안 생성" 버튼 (선택). 표준답변 등록 화면에는 없음(이미 LLM이 생성한 6개 변형이 PMS 측에 있음) | 에스컬레이션 = 진짜 새 답변, 표준답변 = 큐레이션 |
| **데이터 보존 — 챗 로그** | 메시지 본문 90일 / 메타(세션·피드백·신뢰도) 1년 / 1년 후 익명화 후 통계 보관 | 개인정보 최소화 + 품질 평가용 보존 |
| **데이터 보존 — 자료** | **특별한 일이 없는 한 무기한 보관** (soft delete + 영구 삭제는 운영자가 명시적으로 트리거). 청크·임베딩은 즉시 OpenSearch에서 제거 | 자산 가치 우선 (사용자 결정 — 챗봇 학습 베이스) |
| **데이터 보존 — 표준답변·이미지** | 무기한 soft delete (수동 영구 삭제만 가능) | 자산 가치 우선 |

---

## 10. 열린 질문 (확정 전)

남아있는 결정 없음 — 모든 항목 §9 기본값으로 확정. 운영 중 조정 시 §9의 "기본값"을 갱신하고 history에 기록.
