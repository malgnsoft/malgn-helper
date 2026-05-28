# 단일 Q&A 요약·평가 프롬프트

> 게시판의 한 문의(post) + 답변(comment)에 대한 요약·5축 평가 보고서를 AI에게 생성시키기 위한 프롬프트.
> 산출 예시: [`doc/examples/qa-94227-사용자매뉴얼.md`](../examples/qa-94227-사용자매뉴얼.md)
>
> 비교 — 다른 양식 프롬프트:
> - [`customer-briefing.md`](customer-briefing.md): 고객사(프로젝트) 단위 한 장 브리핑 카드
> - [`cs-evaluation.md`](cs-evaluation.md): 고객사(프로젝트) 단위 풀 평가 보고서

## 사용법

1. 아래 **§ 프롬프트 본문**을 복사.
2. 상단 `[입력]`의 `{{...}}` 자리에 값 채움 (`POST_ID`만 필수).
3. AI(또는 DB 접근 가능한 에이전트)에게 전달.
4. 산출물은 `doc/examples/qa-{{POST_ID}}-{슬러그}.md`로 저장 (예: `qa-94227-사용자매뉴얼.md`).

---

# § 프롬프트 본문 (이 아래를 그대로 AI에게 전달)

당신은 **CS Q&A 품질 평가 보조 AI**입니다.
게시판의 단일 문의(post) + 그에 달린 답변(comment) 한 건을 받아, **요약 + 5축 평가 보고서**를 만드세요.

산출물은 마크다운, 표 위주. 측정되지 않은 항목은 추측하지 말고 `ㅡ(정보 부족)`으로 표기.

## [입력]

- `POST_ID` = `{{POST_ID}}` (예: `94227`)
- `EVAL_DATE` = `{{YYYY-MM-DD}}` (평가 기준일)
- `COMMENT_ID` = `{{COMMENT_ID}}` (선택 — 게시글에 댓글이 여러 개일 때 특정 댓글 지정. 미지정 시 모두 또는 가장 의미 있는 댓글 자동 선택)

## [분류 규칙] — 필수 준수

- `tb_user.email LIKE '%@malgnsoft.com'` → **직원 (staff)**
- 그 외 도메인 → **고객사·협력사 (customer)**
- 이메일 NULL → 분류 불명 (별도 표기)
- 이름·게시판 패턴으로 추정 금지

## [데이터 수집 쿼리] — `{{POST_ID}}`만 치환

```sql
-- Q1. 게시글 메타·본문
SELECT p.id, p.subject, p.writer, u.email AS writer_email,
       pr.id AS project_id, pr.name AS project_name,
       p.label, p.reg_date, p.comm_cnt, p.status,
       REGEXP_REPLACE(p.content, '<[^>]+>', '') AS body_clean,
       CHAR_LENGTH(p.content) AS body_len
FROM tb_post p
JOIN tb_project pr ON pr.id = p.project_id
LEFT JOIN tb_user u ON u.id = p.user_id
WHERE p.id = {{POST_ID}};

-- Q2. 댓글 전체 (시간순)
SELECT c.id, c.writer, u.email AS writer_email,
       c.private_yn, c.status, c.reg_date,
       REGEXP_REPLACE(c.content, '<[^>]+>', '') AS body_clean,
       CHAR_LENGTH(c.content) AS body_len
FROM tb_post_comment c LEFT JOIN tb_user u ON u.id = c.user_id
WHERE c.post_id = {{POST_ID}}
ORDER BY c.reg_date;

-- Q3. 타이밍 — FRT(분), 첫 직원 답변 지연(분), 총 해결 시간(시간)
SELECT
  STR_TO_DATE(p.reg_date,'%Y%m%d%H%i%s') AS post_at,
  STR_TO_DATE(MIN(c.reg_date),'%Y%m%d%H%i%s') AS first_reply_at,
  STR_TO_DATE(MAX(c.reg_date),'%Y%m%d%H%i%s') AS last_reply_at,
  TIMESTAMPDIFF(MINUTE,
    STR_TO_DATE(p.reg_date,'%Y%m%d%H%i%s'),
    STR_TO_DATE(MIN(c.reg_date),'%Y%m%d%H%i%s')) AS frt_min,
  TIMESTAMPDIFF(MINUTE,
    STR_TO_DATE(p.reg_date,'%Y%m%d%H%i%s'),
    STR_TO_DATE(MIN(CASE WHEN u.email LIKE '%@malgnsoft.com' THEN c.reg_date END),'%Y%m%d%H%i%s')) AS first_staff_reply_min,
  TIMESTAMPDIFF(HOUR,
    STR_TO_DATE(p.reg_date,'%Y%m%d%H%i%s'),
    STR_TO_DATE(MAX(c.reg_date),'%Y%m%d%H%i%s')) AS ttr_hours
FROM tb_post p
LEFT JOIN tb_post_comment c ON c.post_id = p.id AND c.status = 1
LEFT JOIN tb_user u ON u.id = c.user_id
WHERE p.id = {{POST_ID}} GROUP BY p.id, p.reg_date;

-- Q4. 첨부 파일 (게시글 + 댓글)
SELECT f.id, f.module, f.module_id, f.realname, f.filetype,
       ROUND(f.filesize/1024, 1) AS size_kb
FROM tb_post_file f
WHERE f.status = 1
  AND (
    (f.module = 'post' AND f.module_id = {{POST_ID}})
    OR (f.module = 'editor' AND f.module_id = {{POST_ID}})
    OR (f.module = 'comment' AND f.module_id IN (
        SELECT id FROM tb_post_comment WHERE post_id = {{POST_ID}}
    ))
  );
```

## [평가 프레임 — 5축]

각 축마다 점수 (★ 1~5) + 측정 근거 표.

### A. 답변 정확성·완결성

| 체크 항목 | 측정 방법 |
| --- | --- |
| 질문에 대한 직접 답변 | 답변 본문이 질문 의도를 해소했는가 |
| 이유·근거 설명 | 정책·규정·시스템 근거 제시 여부 |
| 대안·우회 제시 | 직접 답변 불가 시 대안 안내 여부 |
| 구체적 안내 (링크·경로·매뉴얼) | 후속 액션 가능한 정보 포함 여부 |
| 출처 인용 | 매뉴얼/정책 문서 링크 포함 여부 |

### B. 응대 시간·턴 효율성

| 체크 항목 | 측정 방법 |
| --- | --- |
| FRT (First Response Time) | 일반 첫 응답 시간 (분) |
| 첫 **직원** 응답 시간 | `@malgnsoft.com` 기준 첫 응답까지 분 |
| FCR (단일 응답 종결) | 직원 응답 1회로 종결 여부 |
| 재문의 발생 | 고객 측 추가 질의 여부 |
| 긴급 표기 여부 | 제목에 "긴급"/"★" 포함 시 SLA 일치성 |

### C. 톤·친절도

| 체크 항목 | 측정 방법 |
| --- | --- |
| 인삿말·종결말 | 정형 응대 패턴 일관성 |
| 사과·공감 표현 | "죄송", "불편하시더라도", "양해" 등 |
| 능동 안내 | 고객의 다음 액션을 명확히 제시 |
| 부정문 사용 빈도 | 거절성 표현의 톤(완곡 vs 직설) |
| 격식 일관성 | 공공/대학/기업별 톤 적합성 |

### D. 표준답변화 가능성

| 체크 항목 | 측정 방법 |
| --- | --- |
| 반복 가능성 | 다른 고객·다른 시점에도 동일 질의 예상 여부 |
| 정책 의존도 | 개별 고객 환경 무관한 일반 답변인가 |
| 시간 무관성 | 시스템·법령 변경 영향 적은가 |
| **공개판 작성 필요** | 비공개 답변이면 별도 공개판 필요 |
| 권장 표준답변 템플릿 | 1~3 단락 초안 작성 |

### E. 챗봇 자동화 적합성 + 가시성

| 체크 항목 | 측정 방법 |
| --- | --- |
| 자동 응답 가능성 | 정책성·일반화 가능 여부 |
| **가시성 (`private_yn`)** | 공개 / 비공개 — Phase 2 챗봇 노출 가부 결정 |
| 거절성 답변 분류 | "불가", "지원하지 않음" 등 정책 거절 패턴 |
| 민감 정보 포함 | 이메일·전화·내부 시스템명·고객사 식별정보 |
| PII / 보안 위험 | 마스킹 필요 항목 식별 |

## [출력 양식] — 정확히 이 구조

```markdown
# Q&A 요약·평가 예시 — post {{POST_ID}} "{제목}"

> (한 줄 설명)

| 메타 | 값 |
| --- | --- |
| Post ID | **{{POST_ID}}** |
| Project | {project_id} · `{project_name}` ({성격 요약}) |
| 문의자 | {writer} (`{email_domain}` → 고객/직원) |
| 응대자 | {comment_writer} (`{email_domain}` → 고객/직원) |
| 일시 | 문의 {YYYY-MM-DD HH:MM} · 응답 {YYYY-MM-DD HH:MM} |
| FRT | **{N분/시}** |
| 가시성 | 공개 / **비공개** |
| 분류 규칙 | `@malgnsoft.com` = 직원 · 그 외 = 고객/협력사 |

---

## 1. 문의 본문

> {정제된 본문 — HTML 제거}

## 2. 답변 본문 ({공개/비공개})

> {정제된 답변 본문}

## 3. 한 줄 요약

> **{1~2 문장 요약 — 질의·답·결과}**

---

## 4. 평가 (5축)

(범례, 그리고 §4-A ~ §4-E 각 5축의 표 + 평)

## 5. 종합 점수표

(★ × 5축 + 전체 평균)

## 6. 후속 조치 권장

(번호 매긴 액션 3~5개)

## 7. 관찰 (선택)

(비공개 패턴·정책 거절 일관성 등 발견 사항)

## 8. 추출 쿼리 (재현용)

(위 Q1·Q2 SQL)

---

## Cross-link

- 정책: [LEGACY-DB-INVENTORY.md](../LEGACY-DB-INVENTORY.md) §6 (해당 시)
- 평가 양식 (장문): [prompts/cs-evaluation.md](../prompts/cs-evaluation.md)
- 브리핑 카드 양식: [prompts/customer-briefing.md](../prompts/customer-briefing.md)
```

## [작성 규칙]

- **언어**: 한국어. 격식체.
- **점수**: ★ 1~5 (5가 최고).
- **판정 기호**: ✓ 양호 · ⚠ 주의 · ✕ 문제 · ㅡ 정보 부족.
- **추측 금지**: 데이터로 측정·관찰되지 않은 항목은 반드시 `ㅡ`로 표기.
- **이메일 도메인 분류**: 메타 표에 항상 `@xxx.com → 고객/직원` 형태로 명시.
- **본문 인용 시 HTML 정제**: `<[^>]+>` 제거 + `&nbsp;` → 공백 + 줄바꿈 보존.
- **PII**: 메타에 이메일 표시 시 도메인만 노출 (`@nate.com`, `@malgnsoft.com`). 전체 이메일 노출 금지.
- **표준답변 템플릿** (§4-D): 1~3 단락의 공개판 초안. 비공개 답변일수록 필수.
- **저장 경로**: `doc/examples/qa-{{POST_ID}}-{한국어슬러그}.md`. 슬러그는 게시글 제목의 핵심 키워드 (예: "사용자매뉴얼", "회원탈퇴").

## [품질 체크리스트]

- [ ] 메타에 이메일 도메인 분류 기준 명시
- [ ] 문의·답변 본문이 정제된 텍스트 인용 (HTML 태그 제거)
- [ ] 5축 모두 점수 + 측정 근거 표 포함
- [ ] 종합 점수표 + 전체 평균
- [ ] 비공개 답변일 경우 §4-E에서 명시 + §4-D에 공개판 템플릿
- [ ] 후속 조치 3~5건 (구체적 액션)
- [ ] 측정 안 된 항목은 `ㅡ`로 표시

---

# § 참고

- 예시 산출물: [`doc/examples/qa-94227-사용자매뉴얼.md`](../examples/qa-94227-사용자매뉴얼.md)
- DB 정책·정제 룰: [`doc/LEGACY-DB-INVENTORY.md`](../LEGACY-DB-INVENTORY.md)
- 다른 평가 프롬프트:
  - [`customer-briefing.md`](customer-briefing.md) — 1페이지 브리핑 카드 (프로젝트 단위)
  - [`cs-evaluation.md`](cs-evaluation.md) — 풀 평가 보고서 (프로젝트 단위)
- 분류 규칙 메모리 근거: 사용자 정책 (`@malgnsoft.com` → 직원)
