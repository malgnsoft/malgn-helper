# 작업 이력 — 2026-06-01

## 문서 현행화

5/29 종일 진행된 다음 작업이 [WBS.md](../WBS.md)에 미반영 상태로 누적되어 일괄 현행화:

- 인프라 활성화 (Hyperdrive `pms` · R2 `malgn-helper-files` · AI Gateway `malgn-helper` Authenticated)
- API 22+ 엔드포인트 (PMS 조회·브리핑·Q&A 평가·표준답변 CRUD·`/admin/cost`·`/admin/evals`·`/doc` OpenAPI)
- hp_* 4테이블 적용 (`hp_briefing` · `hp_qa_eval` · `hp_standard_answer` · `hp_llm_log`)
- LLM 실연동 (OpenAI `gpt-4o-mini` / `gpt-4o` via AI Gateway, 24h `llm_input_hash` 캐시, `hp_llm_log` 감사)
- PMS 신규 페이지 5종 + UX 폴리시 라운드 (분석 모달 valid 결과 후 표시·Q&A 본문 초기 접힘·빈 결과 "다시 시도"·followups 빈 섹션 제거)
- LLM 품질 라운드 (GPT-4o Vision 이미지 분석 + 캡션 배치 · 표준답변 컨텍스트 첨부 · 4파트 답변 강제)
- 운영 정책 메모리 5건 (직원·협력사 분류 / 브리핑 statusLabel 5단계 / Hyperdrive read 캐시 stale / PMS 스토리보드 식별 / md 파일 doc/ 배치)
- MySQL 부하 대책 (`tb_post`·`tb_post_comment` 인덱스 추가 → 91s→244ms)
- `hp_qa_eval.overall_verdict` VARCHAR(20)→VARCHAR(100) 마이그레이션

### [WBS.md](../WBS.md) 갱신

| 항목 | Before | After |
| --- | ---: | ---: |
| 진행률 — 착수/분석 | 70% | **95%** |
| 진행률 — 설계 | 40% | **80%** |
| 진행률 — 구현 | 25% | **65%** |
| 진행률 — 교육·연동 | 10% | **35%** |
| 진행률 — 테스트 | 0% | **10%** |
| 진행률 — 이행 | 5% | **30%** |
| 마지막 현행화 | 2026-05-29 | **2026-06-01** |

표 안 모든 ID 산출물·비고 컬럼 갱신. P1-3-14·3-15 ✅ 전환. P1-3-16(UX 폴리시)·P1-3-17(LLM 품질) 신규 항목 추가.

"다음 단계 우선순위" 섹션을 M2(자료 수집 + 검색) 진입 기준으로 재작성:
1. OpenSearch 도메인 + 인덱스 매핑 (k-NN 1536d + BM25)
2. `malgn-helper-admin` 자료 업로드 MVP (R2 → 청크 → 임베딩 → 색인)
3. `/chat` 응답 파이프라인 (표준답변 우선 → 하이브리드 검색 → LLM + 출처 + "모름" 가드)
4. `malgn-helper` 사용자 챗봇 UI
5. 관리자 추가 화면 (표준답변 승인 · 상담 로그 · 에스컬레이션 큐)
6. OpenSearch 매핑·R2 키 규칙 문서화 (P1-2-4 잔여)
7. PMS UX 잔여 (`/admin/evals` LLM 행 즉시 모달 등)

### [HP-SCHEMA.md](../HP-SCHEMA.md) 갱신

- `hp_qa_eval.overall_verdict` 컬럼 정의·DDL 모두 `VARCHAR(20)` → `VARCHAR(100)` 반영 + 마이그레이션 일자(2026-05-29) 명시

## 사용자 보고

이력 확인 후 **다음 작업 추천** 제시:
- (권장) OpenSearch + 자료 업로드 MVP 묶음 진행으로 챗봇 응답 파이프라인 데이터 채우기
- 또는 사용자 챗봇 UI / 관리자 화면 / PMS UX 폴리시 잔여 중 택일
