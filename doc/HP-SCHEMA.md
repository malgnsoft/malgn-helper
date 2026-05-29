# Malgn Helper — DB 스키마 설계 (`hp_*` 테이블)

PMS DB 안에 **`hp_` 접두사**로 헬퍼 전용 테이블을 둔다. 운영 PMS 테이블(`tb_*`)과 명확히 격리되며, 추후 별도 DB로 마이그레이션할 때도 검색·이전이 쉽다.

> 약어 `hp` = **H**elper **P**roject. 모든 헬퍼 테이블 공통 접두사.

---

## 1. 설계 원칙

1. **PMS 운영 테이블(`tb_*`)에는 외래키 걸지 않는다.** 참조만 하고 검증은 애플리케이션 레벨에서. PMS 스키마 변경에 영향받지 않기 위해.
2. **모든 테이블에 `status TINYINT` (1=활성, -1=삭제)** — soft delete 통일.
3. **시간 컬럼은 `DATETIME` 사용** (`tb_*`은 varchar(14) 레거시. 신규 테이블은 표준형).
4. **LLM 결과는 통째로 JSON 컬럼에**(`LONGTEXT` + JSON serialization). 향후 스키마 진화에 유연.
5. **자주 정렬·조회되는 핵심 값은 별도 컬럼**으로 빼서 인덱스 (예: `hp_qa_eval.overall_score`).
6. **버전 이력 보존** — 같은 프로젝트/게시글의 재생성은 같은 row 갱신이 아니라 **새 row append**. 시계열 분석·되돌리기 가능.

---

## 2. ERD (텍스트)

```
tb_project   tb_post
   │            │
   │ project_id │ post_id
   ▼            ▼
┌─────────────────────┐    ┌─────────────────────┐
│  hp_briefing        │    │  hp_qa_eval         │
│  (프로젝트 브리핑   │    │  (게시글 Q&A 평가   │
│   여러 버전 누적)   │    │   여러 버전 누적)   │
└──────────┬──────────┘    └──────────┬──────────┘
           │                          │
           │  saved_from              │  source_post_id
           ▼                          ▼
        ┌─────────────────────────────────┐
        │  hp_standard_answer             │
        │  (표준 답변 카탈로그            │
        │   — 챗봇 응답 1순위 소스)       │
        └─────────────────────────────────┘

  (모든 LLM 호출은 hp_llm_log로 집계 — entity_type/id로 위 3개 테이블과 느슨 연결)
```

---

## 3. 테이블 상세

### 3-1. `hp_briefing` — 프로젝트 브리핑 카드 캐시

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | INT PK AI | |
| `project_id` | INT NOT NULL | `tb_project.id` (FK 없음) |
| `generated_at` | DATETIME NOT NULL | LLM 생성 시각 |
| `generator` | VARCHAR(20) NOT NULL | `db_only` / `llm` / `hybrid` |
| `llm_model` | VARCHAR(50) NULL | 예: `claude-sonnet-4-6` |
| `llm_input_hash` | CHAR(64) NULL | 동일 입력 캐시 키 (project state SHA-256) |
| `prompt_tokens` | INT NULL | |
| `completion_tokens` | INT NULL | |
| `latency_ms` | INT NULL | |
| `briefing_json` | LONGTEXT NOT NULL | `Briefing` 객체 전체 |
| `status` | TINYINT NOT NULL DEFAULT 1 | 1=활성 / -1=삭제 |
| `created_at` | DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP | |

**인덱스**

- `idx_project_status_gen (project_id, status, generated_at DESC)` — 프로젝트별 최신 N건
- `idx_input_hash (llm_input_hash)` — 캐시 lookup

**캐시 정책**: 같은 `project_id` + 같은 `llm_input_hash`가 24시간 이내면 재사용. 그 외엔 새 LLM 호출.

---

### 3-2. `hp_qa_eval` — 게시글 Q&A 평가 캐시

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | INT PK AI | |
| `post_id` | INT NOT NULL | `tb_post.id` |
| `project_id` | INT NOT NULL | 조회 편의(중복 저장) |
| `generated_at` | DATETIME NOT NULL | |
| `generator` | VARCHAR(20) NOT NULL | |
| `llm_model` | VARCHAR(50) NULL | |
| `llm_input_hash` | CHAR(64) NULL | post + 댓글 본문 해시 |
| `prompt_tokens` | INT NULL | |
| `completion_tokens` | INT NULL | |
| `latency_ms` | INT NULL | |
| `eval_json` | LONGTEXT NOT NULL | `QaEval` 객체 전체 |
| `overall_score` | DECIMAL(3,2) NULL | 정렬·필터용 (예: 4.20) |
| `overall_verdict` | VARCHAR(20) NULL | 표시용 (예: "양호") |
| `status` | TINYINT NOT NULL DEFAULT 1 | |
| `created_at` | DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP | |

**인덱스**

- `idx_post_status_gen (post_id, status, generated_at DESC)`
- `idx_project_score (project_id, overall_score DESC)` — 프로젝트별 우수/취약 응대 정렬
- `idx_input_hash (llm_input_hash)`

---

### 3-3. `hp_standard_answer` — 표준 답변 카탈로그

QaEval 카드에서 "표준답변으로 저장" 액션 → 이 테이블에 누적. **챗봇 응답의 1순위 소스**.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | INT PK AI | |
| `label` | VARCHAR(100) NOT NULL | 카드/탭 헤더 |
| `question` | TEXT NOT NULL | 다루는 질문 패턴 |
| `answer` | TEXT NOT NULL | 답변 본문 |
| `project_id` | INT NULL | NULL = 전사 공통, 값 있으면 해당 프로젝트 전용 |
| `source_post_id` | INT NULL | 출처 게시글 |
| `source_axis` | VARCHAR(10) NULL | QaEval 축 (A/B/C/D/E) |
| `created_by` | VARCHAR(100) NULL | 저장한 직원 이메일 (인증 도입 후) |
| `usage_count` | INT NOT NULL DEFAULT 0 | 챗봇이 사용한 횟수 |
| `last_used_at` | DATETIME NULL | |
| `status` | TINYINT NOT NULL DEFAULT 1 | |
| `created_at` | DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | |

**인덱스**

- `idx_project_status (project_id, status)`
- `idx_usage (status, usage_count DESC)` — 인기 답변 순회
- `idx_source_post (source_post_id)` — 출처 역추적
- `FULLTEXT idx_qa (question, answer)` — InnoDB FULLTEXT (MySQL 5.6.4+ 지원)

---

### 3-4. `hp_llm_log` — LLM 호출 감사 로그

비용·지연·실패 추적. 전 엔티티 공통.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | BIGINT PK AI | |
| `route` | VARCHAR(100) NOT NULL | 호출 라우트 (예: `POST /pms/projects/:id/briefing/generate`) |
| `entity_type` | VARCHAR(30) NOT NULL | `briefing` / `qa_eval` / `chat` 등 |
| `entity_id` | INT NULL | 위 3개 테이블의 id (생성 후 채움) |
| `model` | VARCHAR(50) NOT NULL | |
| `prompt_tokens` | INT NULL | |
| `completion_tokens` | INT NULL | |
| `latency_ms` | INT NULL | |
| `cost_usd` | DECIMAL(10,6) NULL | |
| `cache_hit` | TINYINT NOT NULL DEFAULT 0 | 1 = `llm_input_hash` 매치로 LLM 미호출 |
| `error` | TEXT NULL | 실패 시 메시지 |
| `request_at` | DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP | |

**인덱스**

- `idx_entity (entity_type, entity_id, request_at)`
- `idx_request_at (request_at)` — 일별 비용 집계

---

## 4. DDL (한 파일로 일괄 실행)

```sql
-- malgn-helper-api/migrations/001_init_hp_tables.sql
-- 실행 위치: PMS DB (pms)
-- 안전: 기존 tb_* 테이블에 영향 없음. CREATE TABLE IF NOT EXISTS 사용.

CREATE TABLE IF NOT EXISTS hp_briefing (
  id                INT NOT NULL AUTO_INCREMENT,
  project_id        INT NOT NULL,
  generated_at      DATETIME NOT NULL,
  generator         VARCHAR(20) NOT NULL,
  llm_model         VARCHAR(50) NULL,
  llm_input_hash    CHAR(64) NULL,
  prompt_tokens     INT NULL,
  completion_tokens INT NULL,
  latency_ms        INT NULL,
  briefing_json     LONGTEXT NOT NULL,
  status            TINYINT NOT NULL DEFAULT 1,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_project_status_gen (project_id, status, generated_at),
  KEY idx_input_hash (llm_input_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS hp_qa_eval (
  id                INT NOT NULL AUTO_INCREMENT,
  post_id           INT NOT NULL,
  project_id        INT NOT NULL,
  generated_at      DATETIME NOT NULL,
  generator         VARCHAR(20) NOT NULL,
  llm_model         VARCHAR(50) NULL,
  llm_input_hash    CHAR(64) NULL,
  prompt_tokens     INT NULL,
  completion_tokens INT NULL,
  latency_ms        INT NULL,
  eval_json         LONGTEXT NOT NULL,
  overall_score     DECIMAL(3,2) NULL,
  overall_verdict   VARCHAR(20) NULL,
  status            TINYINT NOT NULL DEFAULT 1,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_post_status_gen (post_id, status, generated_at),
  KEY idx_project_score (project_id, overall_score),
  KEY idx_input_hash (llm_input_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS hp_standard_answer (
  id              INT NOT NULL AUTO_INCREMENT,
  label           VARCHAR(100) NOT NULL,
  question        TEXT NOT NULL,
  answer          TEXT NOT NULL,
  project_id      INT NULL,
  source_post_id  INT NULL,
  source_axis     VARCHAR(10) NULL,
  created_by      VARCHAR(100) NULL,
  usage_count     INT NOT NULL DEFAULT 0,
  last_used_at    DATETIME NULL,
  status          TINYINT NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_project_status (project_id, status),
  KEY idx_usage (status, usage_count),
  KEY idx_source_post (source_post_id),
  FULLTEXT KEY idx_qa (question, answer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS hp_llm_log (
  id                BIGINT NOT NULL AUTO_INCREMENT,
  route             VARCHAR(100) NOT NULL,
  entity_type       VARCHAR(30) NOT NULL,
  entity_id         INT NULL,
  model             VARCHAR(50) NOT NULL,
  prompt_tokens     INT NULL,
  completion_tokens INT NULL,
  latency_ms        INT NULL,
  cost_usd          DECIMAL(10,6) NULL,
  cache_hit         TINYINT NOT NULL DEFAULT 0,
  error             TEXT NULL,
  request_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_entity (entity_type, entity_id, request_at),
  KEY idx_request_at (request_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 5. 사용 흐름

### 5-1. 브리핑 카드 생성

```
화면: [AI 요약 카드 생성하기] 클릭
    │
    ▼
API: POST /pms/projects/:id/briefing/generate
    │
    ├─ 1. DB 집계 → input 객체 구성 (현재 GET /briefing 로직 재사용)
    ├─ 2. input SHA-256 = input_hash
    ├─ 3. hp_briefing에 input_hash 매치 + 24h 이내 활성 row 있나?
    │      ├─ YES → 그 row 반환 (cache_hit=1, hp_llm_log 기록)
    │      └─ NO  → LLM 호출
    │              ├─ Claude → hotTopics/faq/policies/oneLine 요약 생성
    │              ├─ DB 집계 + LLM 결과 병합한 briefing_json 저장 (status=1)
    │              └─ hp_llm_log 기록 (cache_hit=0, 토큰·지연·비용)
    └─ 4. 응답: { briefing }
```

### 5-2. Q&A 평가 생성

```
화면: 게시글 상세에서 [평가 카드 생성]
    │
    ▼
API: POST /pms/posts/:id/eval/generate
    │
    ├─ 1. tb_post + tb_post_comment + tb_user로 input 구성
    ├─ 2. input_hash 계산
    ├─ 3. hp_qa_eval 캐시 lookup (post_id + input_hash)
    │      └─ HIT 또는 MISS → LLM 호출 후 새 row append
    └─ 4. overall_score를 별도 컬럼으로 추출 저장
```

### 5-3. 표준답변 저장 (사용자 액션)

```
QaEval 카드의 "이 템플릿을 표준답변으로 저장" 버튼
    │
    ▼
API: POST /standard-answers
  body: { label, question, answer, projectId?, sourcePostId, sourceAxis }
    │
    └─ hp_standard_answer INSERT (status=1, usage_count=0)
```

### 5-4. 표준답변 검색 (챗봇 응답 1순위)

```
챗봇 질의 → API: GET /standard-answers/match?q=...
    │
    ├─ FULLTEXT MATCH (question, answer) AGAINST (?)
    ├─ 같은 project_id 우선, 그 다음 NULL(전사 공통)
    ├─ usage_count 증가 + last_used_at 업데이트
    └─ 챗봇 응답 컴포저로 전달
```

---

## 6. 향후 분리 시나리오

PMS 운영팀과 분리 협의가 필요해지면:

1. 새 Aurora MySQL DB(`malgn_helper`) 구축
2. Hyperdrive에 새 connection string 등록 (`HYPERDRIVE_HELPER` 바인딩 추가)
3. `mysqldump --tables hp_*` → 새 DB 로드
4. API 코드에서 `hp_*` 쿼리만 새 바인딩으로 전환
5. PMS DB의 `hp_*` 테이블은 1주일 보존 후 DROP

테이블 접두사를 일관되게 둔 이유 = **이 단계를 단순화하기 위함**.

---

## 7. 보안·운영 메모

| 항목 | 방침 |
| --- | --- |
| 비공개 댓글 본문(`tb_post_comment.private_yn='Y'`) | `hp_qa_eval.eval_json`에 절대 저장 금지. LLM 입력 단계에서 필터링 |
| 직원/고객 분류 | `@malgnsoft.com` 매칭 결과만 저장. PII는 추가 저장 안 함 |
| `created_by` | 인증 도입 전까지는 NULL. 도입 후엔 직원 이메일 필수 |
| 비용 추적 | `hp_llm_log.cost_usd`를 일별 GROUP BY로 대시보드 (별도 페이지) |
| 캐시 무효화 | 화면의 "새 카드 생성" 버튼 = `?force=1` 쿼리로 캐시 우회 |
| 백업 | PMS DB 전체 백업에 포함 (별도 백업 불필요 — 분리 전까지) |
