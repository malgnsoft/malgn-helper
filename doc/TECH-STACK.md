# 기술 스택

> 고객상담 AI 챗봇 (Malgn Helper) 기술 스택 정의 문서.
> 변경 시 본 문서와 [CLAUDE.md](../CLAUDE.md)를 함께 갱신한다.

---

## 1. 전체 개요

| 레이어 | 기술 | 비고 |
| --- | --- | --- |
| 사용자 프론트엔드 | Nuxt 3 | Cloudflare Pages |
| 관리자 프론트엔드 | Nuxt 3 | Cloudflare Pages |
| API 서버 | Hono | Cloudflare Workers |
| RDB | Aurora MySQL | Hyperdrive 경유 |
| 검색 | AWS OpenSearch Service | k-NN(벡터) + BM25 하이브리드 |
| 객체 스토리지 | Cloudflare R2 | 원본 파일(매뉴얼·동영상 등) |
| LLM | Claude | Cloudflare AI Gateway 경유 |
| 인덱싱 | 동기 처리(MVP) → Cloudflare Queues(추후) | 2단계 도입 |

---

## 2. 프론트엔드

### 2.1 사용자 (`malgn-helper`)

- **프레임워크**: Nuxt 3
- **배포**: Cloudflare Pages
- **주요 화면**: 챗봇 대화 UI, 출처 인용 표시, 에스컬레이션 요청
- **인증**: 필요 시 추가 (게스트 허용 여부는 운영 정책으로 결정)

### 2.2 관리자 (`malgn-helper-admin`)

- **프레임워크**: Nuxt 3
- **배포**: Cloudflare Pages
- **주요 기능**:
  - 자료(매뉴얼·동영상·Q&A) 업로드 및 메타데이터 관리
  - 표준 답변 등록·검토
  - 상담 로그 열람 / 에스컬레이션 큐 처리
  - 인덱싱 상태 모니터링

---

## 3. API 서버 (`malgn-helper-api`)

- **프레임워크**: Hono
- **런타임**: Cloudflare Workers
- **주요 책임**:
  - 챗 요청 처리 (검색 → 컨텍스트 구성 → LLM 호출 → 응답)
  - 표준 답변 우선 매칭 로직
  - 자료 업로드 → R2 저장 → 인덱싱 트리거
  - 관리자 CRUD 엔드포인트
- **DB 접근**: Hyperdrive 바인딩만 사용. 직접 커넥션 금지.
- **외부 호출**: AI Gateway, OpenSearch는 fetch 기반 클라이언트.

---

## 4. 데이터 저장소

### 4.1 Aurora MySQL (via Hyperdrive)

- **용도**: 사용자, 대화 세션, 메시지, 표준 답변, 자료 메타데이터, 에스컬레이션 티켓.
- **접근 방식**: Cloudflare Hyperdrive 바인딩으로 Worker에서 풀링 + 캐싱.
- **마이그레이션**: 도구 미정 (Drizzle / Prisma / 직접 SQL 중 결정 필요).

### 4.2 Cloudflare R2

- **용도**: 업로드된 원본 파일(PDF, 동영상, 첨부 이미지).
- **참조**: DB에는 R2 키만 저장. 다운로드는 서명 URL로 발급.

### 4.3 AWS OpenSearch Service

- **용도**: 청크 단위 본문/임베딩 인덱싱, 하이브리드 검색.
- **검색 전략**:
  - **BM25**: 키워드 기반 정확 매칭
  - **k-NN (벡터)**: 의미 기반 유사도
  - 두 결과를 가중치로 결합(RRF 또는 직접 스코어 합산) — 구체 가중치는 운영 중 튜닝.
- **인덱스 설계**: `documents`(원본), `chunks`(청크+벡터), `standard_answers`(표준 답변).

---

## 5. AI / LLM

- **모델**: Claude (기본 `claude-opus-4-7` 또는 비용 균형이 필요할 때 `claude-sonnet-4-6`).
- **호출 경로**: Cloudflare AI Gateway → Anthropic API.
- **AI Gateway 사용 이유**:
  - 캐싱(동일 프롬프트 응답 재사용)
  - 로깅·분석
  - rate limit / 비용 제어
  - 실패 시 폴백 전략 적용
- **프롬프트 캐싱**: 시스템 프롬프트 + 표준 답변 카탈로그 등 고정 컨텍스트에 적극 적용.

### 5.1 답변 파이프라인

```
질의
 ├─ (1) 표준 답변 매칭 → hit 시 즉시 반환
 ├─ (2) 하이브리드 검색 (BM25 + k-NN) → top-k 청크 추출
 ├─ (3) Claude에 컨텍스트 + 인용 지시와 함께 전달
 └─ (4) 응답 신뢰도 부족 시 "모름 + 상담사 연결" 반환
```

---

## 6. 인덱싱 파이프라인

### MVP (현재 단계)

- 관리자 업로드 → API가 동기로 텍스트 추출 → 청킹 → 임베딩 → OpenSearch upsert.
- 텍스트 위주 자료 전제. Worker CPU 제한 내 처리 가능한 크기만 허용.

### 2단계 (동영상/대용량 도입 시)

- 업로드 후 Cloudflare Queue에 인덱싱 작업 enqueue.
- 별도 **Indexer Worker**가 consumer로 동작:
  - 동영상 → 트랜스크립트 추출
  - 대용량 PDF → 분할 처리, 재시도, 진행률 기록
- 관리자 화면에서 인덱싱 상태(pending/processing/done/failed) 표시.

---

## 7. 인프라 / 배포

- **호스팅**: Cloudflare (Pages + Workers + R2 + Hyperdrive + AI Gateway)
- **외부 서비스**:
  - Aurora MySQL (AWS)
  - OpenSearch Service (AWS)
  - Anthropic API (AI Gateway 경유)
- **환경 분리**: dev / staging / prod — Cloudflare 환경별 바인딩과 시크릿으로 분리.
- **시크릿 관리**: Cloudflare Workers 시크릿 / Pages 환경변수.

---

## 8. 미결 사항 (TBD)

- ORM/마이그레이션 도구 선정
- 임베딩 모델 (Anthropic 자체 / OpenAI / 한국어 특화 오픈모델) 결정
- 인증 방식 (사용자/관리자 각각)
- 관측: 로깅·메트릭·알람 스택 (Cloudflare Logs / 외부 APM)
- 에스컬레이션 채널 (이메일 / Slack / 자체 티켓 시스템)
