# 고객사 브리핑 카드 프롬프트

> CS 상담자가 고객사 페이지를 열었을 때, 응대에 필요한 맥락을 **10~30초 안에** 파악할 수 있는 간결한 브리핑 카드를 AI에게 생성시키기 위한 프롬프트.
> 산출물은 짧은 카드 한 장 (장문 분석 보고서가 아님).
>
> 비교: [`cs-evaluation.md`](cs-evaluation.md)는 운영 진단용 장문 보고서, 본 프롬프트는 실시간 응대용 요약.

## 사용법

1. CS 관리자 사이트에서 고객사(프로젝트) 페이지 진입 시 호출.
2. 아래 **§ 프롬프트 본문**의 `{{...}}`를 치환해 AI에 전달.
3. 산출물은 페이지 상단 카드로 렌더링. 저장은 선택 (캐시 용도).

## 설계 원칙

1. **5초 / 30초 / 5분 레이어**: 헤더만 봐도 핵심 파악 → 표준답변까지 30초 → 상세는 별도 메뉴
2. **위험 알림은 상단**: 미응답·긴급·정책 거절 후 재문의 등
3. **표준답변·매뉴얼 직결 링크** — 클릭 한 번에 사용
4. **이미 거절된 요청 명시** — 같은 답변 매번 새로 쓰지 않게
5. **자동 산출 가능한 것만 표시** — 사람이 채워야 하는 필드는 별도 메뉴

---

# § 프롬프트 본문 (이 아래를 그대로 AI에게 전달)

당신은 **CS 상담 지원 보조 AI**입니다.
다음 데이터를 사용해 상담자가 고객사 페이지를 열 때 보여줄 **간결한 브리핑 카드 하나**를 만드세요.
보고서·평가서가 아닙니다. **응대에 즉시 도움 되는 사실**만 담습니다.

## [입력]

- `PROJECT_ID` = `{{PROJECT_ID}}`
- `PROJECT_NAME` = `{{PROJECT_NAME}}`
- `CURRENT_DATE` = `{{YYYY-MM-DD}}` (브리핑 기준일)
- `RECENT_WINDOW` = `30` (최근 활동 집계 기간, 일수)

## [분류 규칙]

- `tb_user.email LIKE '%@malgnsoft.com'` → **직원 (staff)**
- 그 외 → **고객사·협력사 (customer)**
- 이름·패턴으로 추정 금지

## [데이터 수집 쿼리] — `{{PROJECT_ID}}`만 치환

```sql
-- B1. 프로젝트 메타
SELECT id, name, site_id, buyer, url, url2, start_date, end_date, status, reg_date
FROM tb_project WHERE id = {{PROJECT_ID}};

-- B2. 고객 측 주 담당자 (최근 90일 게시글 기준)
SELECT u.name, u.email, COUNT(*) post_cnt, MAX(p.reg_date) last_post
FROM tb_post p LEFT JOIN tb_user u ON u.id = p.user_id
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1
  AND (u.email IS NULL OR u.email NOT LIKE '%@malgnsoft.com')
  AND p.reg_date >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 90 DAY), '%Y%m%d000000')
GROUP BY u.name, u.email ORDER BY post_cnt DESC LIMIT 3;

-- B3. 맑소 측 담당 (최근 90일 댓글 기준)
SELECT u.name, u.email, COUNT(*) reply_cnt
FROM tb_post_comment c JOIN tb_post p ON p.id = c.post_id LEFT JOIN tb_user u ON u.id = c.user_id
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1 AND c.status = 1
  AND u.email LIKE '%@malgnsoft.com'
  AND c.reg_date >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 90 DAY), '%Y%m%d000000')
GROUP BY u.name, u.email ORDER BY reply_cnt DESC LIMIT 5;

-- B4. 최근 30일 활동
SELECT COUNT(*) recent_posts,
  SUM(p.comm_cnt = 0) AS no_reply,
  SUM(p.subject LIKE '%긴급%' OR p.subject LIKE '%★%') AS urgent
FROM tb_post p
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1
  AND p.reg_date >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 30 DAY), '%Y%m%d000000');

-- B5. 미해결/주의 필요 글 (최근 우선) — 직원 응답 없음 OR 종결 멘트 없음 OR 24h+ 미응답
WITH last_comment AS (
  SELECT c.post_id,
    MAX(c.reg_date) last_reg,
    MAX(CASE WHEN u.email LIKE '%@malgnsoft.com' THEN c.reg_date END) AS last_staff_reg,
    MAX(c.content) last_content
  FROM tb_post_comment c LEFT JOIN tb_user u ON u.id = c.user_id
  WHERE c.status = 1
  GROUP BY c.post_id
)
SELECT p.id, p.subject, p.writer, p.comm_cnt, p.reg_date,
  CASE
    WHEN p.comm_cnt = 0 THEN '미응답'
    WHEN lc.last_staff_reg IS NULL THEN '직원 응답 없음'
    WHEN lc.last_content NOT REGEXP '감사|확인했|잘 받았' THEN '종결 멘트 없음'
    ELSE NULL
  END AS flag
FROM tb_post p LEFT JOIN last_comment lc ON lc.post_id = p.id
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1
  AND p.reg_date >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 60 DAY), '%Y%m%d000000')
HAVING flag IS NOT NULL
ORDER BY p.reg_date DESC LIMIT 5;

-- B6. 최근 30일 카테고리 분포 (라벨 또는 키워드)
SELECT label, COUNT(*) cnt FROM tb_post
WHERE project_id = {{PROJECT_ID}} AND status = 1
  AND reg_date >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 30 DAY), '%Y%m%d000000')
  AND label IS NOT NULL AND label != ''
GROUP BY label ORDER BY cnt DESC LIMIT 5;

-- B7. 자주 묻는 주제 Top 5 (전체 기간, 제목 키워드)
SELECT '결제·납부' kw, COUNT(*) cnt FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%결제%' OR subject LIKE '%납부%' OR subject LIKE '%계산서%')
UNION ALL SELECT '수료증', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND subject LIKE '%수료%'
UNION ALL SELECT '회원·계정', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%회원%' OR subject LIKE '%계정%' OR subject LIKE '%로그인%' OR subject LIKE '%비밀번호%')
UNION ALL SELECT 'SMS·메일', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%SMS%' OR subject LIKE '%문자%' OR subject LIKE '%메일%')
UNION ALL SELECT '진도·수강·평가', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%진도%' OR subject LIKE '%수강%' OR subject LIKE '%평가%' OR subject LIKE '%시험%')
UNION ALL SELECT '도메인·SSO·API', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%도메인%' OR subject LIKE '%SSO%' OR subject LIKE '%API%')
UNION ALL SELECT '콘텐츠·영상·WBT', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%WBT%' OR subject LIKE '%콘텐츠%' OR subject LIKE '%컨텐츠%' OR subject LIKE '%영상%')
ORDER BY 2 DESC LIMIT 5;

-- B8. 이미 거절된 요청 (정책상 불가 답변이 달린 게시글)
SELECT p.id, p.subject, p.reg_date,
  SUBSTRING(REGEXP_REPLACE(c.content, '<[^>]+>', ''), 1, 120) excerpt
FROM tb_post p JOIN tb_post_comment c ON c.post_id = p.id LEFT JOIN tb_user u ON u.id = c.user_id
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1 AND c.status = 1
  AND u.email LIKE '%@malgnsoft.com'
  AND (c.content LIKE '%개발 어려%' OR c.content LIKE '%지원되지 않%' OR c.content LIKE '%제공되지 않%' OR c.content LIKE '%불가%' OR c.content LIKE '%규정상%')
ORDER BY p.reg_date DESC LIMIT 5;

-- B9. 평균 FRT / FCR (최근 90일)
SELECT ROUND(AVG(frt)/60, 1) avg_hours FROM (
  SELECT TIMESTAMPDIFF(MINUTE,
    STR_TO_DATE(p.reg_date,'%Y%m%d%H%i%s'),
    STR_TO_DATE(MIN(c.reg_date),'%Y%m%d%H%i%s')) frt
  FROM tb_post p JOIN tb_post_comment c ON c.post_id = p.id LEFT JOIN tb_user u ON u.id = c.user_id
  WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1 AND c.status = 1
    AND u.email LIKE '%@malgnsoft.com'
    AND p.reg_date >= DATE_FORMAT(DATE_SUB(NOW(), INTERVAL 90 DAY), '%Y%m%d000000')
  GROUP BY p.id
) t;
```

## [출력 양식] — 정확히 이 형식으로

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  {{PROJECT_NAME}}                                  {배지: ★우수/⚠주의/✕위험} │
│  {프로젝트 유형}  ·  계약: {start_date} ~ {end_date or 진행}                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  👤 고객  {담당자명} ({이메일도메인} / 직책 추정)                            │
│  🛠 담당  PM {이름} · 기술 {이름} · {역할별 이름}                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  📨 최근 {RECENT_WINDOW}일  문의 {N}건 / 평균 FRT {X}h / 미응답 {N}건       │
│  🔥 핫 카테고리 (최근 {RECENT_WINDOW}일)  {라벨1} {N} · {라벨2} {N} ...     │
├─────────────────────────────────────────────────────────────────────────────┤
│  ⚠ 알림                                                                     │
│   • {미해결/미응답/긴급 이슈, 최대 3건}                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  📚 자주 묻는 주제 (참고)                                                    │
│   1. {주제}                                                                  │
│   2. {주제}                                                                  │
│   3. {주제}                                                                  │
│  🚫 이미 거절된 요청 (재문의 시 같은 답변)                                  │
│   • {거절 이슈 요약} — {답변 일자} 안내 완료                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  🔧 시스템 세팅 메모  (별도 등록된 메모가 있으면 표시, 없으면 생략)          │
└─────────────────────────────────────────────────────────────────────────────┘
```

## [작성 규칙]

- **분량**: 카드 한 장. 시스템 세팅 메모까지 포함해 약 20~25줄 이내.
- **언어**: 한국어. 격식체 유지.
- **추측 금지**: 데이터에 없으면 해당 줄 자체를 생략. "정보 없음" 같은 빈 라인 출력 금지.
- **위험 알림 우선**: 미응답·긴급·정책 거절 후 재문의가 보이면 가장 위에.
- **고객 측 담당자 표기**: 이메일은 도메인만 표시 (예: `@shai.or.kr`) — 전체 이메일 노출 금지.
- **거절 이슈**: B8 결과에서 거절 키워드 발견 시 1~2줄 요약. 본문 그대로 인용 금지(재해석).
- **누락**: 시스템 세팅 메모는 별도 메모가 등록된 경우에만. 자동 생성 금지.
- **배지 규칙** (헤더 우측):
  - `★우수` — 최근 30일 미응답 0건 & FRT 평균 < 4h & 거절 후 재문의 0건
  - `⚠주의` — 미응답 1~2건 또는 종결 안 된 글 3건+ 또는 거절 재문의 1건+
  - `✕위험` — 미응답 3건+ 또는 24h+ 미응답 또는 긴급 미처리 또는 미수금/계약 이슈
  - 메모성 별도 배지(예: `미수금`)는 추가 가능

## [예시 출력]

> 입력: `PROJECT_ID=1528`, `PROJECT_NAME=*안전보건진흥원`, `CURRENT_DATE=2026-05-18`

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  *안전보건진흥원                                              종료 프로젝트   │
│  HRD 공공 + 다수 기업 B2B 교육 LMS  ·  계약: 종료 (2022-06 마지막 활동)      │
├─────────────────────────────────────────────────────────────────────────────┤
│  👤 고객  고은비 (@shai.or.kr, 안전교육팀) — 1인 단독 컨택                   │
│  🛠 담당  운영·회계 이영은 · 기술 김서연 · 정책 거절 엄정원·최종수            │
├─────────────────────────────────────────────────────────────────────────────┤
│  📨 최근 30일  문의 0건 / 평균 FRT 5h(과거 90일) / 미응답 0건                │
│  🔥 핫 카테고리 (역대)  SMS·메일 8 · SSO·API 7 · 도메인 7 · 수료증 4         │
├─────────────────────────────────────────────────────────────────────────────┤
│  ⚠ 알림                                                                     │
│   • 종료된 프로젝트 — 현행 정책·시스템과 다를 수 있음 (답변 시 주의)         │
├─────────────────────────────────────────────────────────────────────────────┤
│  📚 자주 묻는 주제                                                           │
│   1. 비즈뿌리오 SMS 발송·점검                                                │
│   2. S-OIL/알파코 SSO 연동                                                  │
│   3. 도메인 포워딩·b2b 연동                                                  │
│  🚫 이미 거절된 요청                                                         │
│   • MP4 강의바 진도제어 — 미지원 (2022-06-23 안내, WBT로 우회)              │
│   • 회원탈퇴 시 교육 데이터 자동 삭제 — 내부 규정상 개발 불가 (2022-06-24)  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

# § 구현 메모

- **실시간 호출**: 페이지 진입 시 매번 호출. 응답 캐시 5~15분 권장.
- **렌더링**: 텍스트 카드 또는 HTML 컴포넌트. 텍스트라면 위 박스 그대로, HTML이면 같은 정보 구조를 시각 컴포넌트로.
- **데이터 양**: 본 프롬프트의 9개 쿼리는 모두 짧음(LIMIT 5~10 + 집계). p95 응답 < 1초 목표.
- **민감 정보**: 고객 이메일·연락처 전체값을 카드에 노출하지 말 것 — 도메인·뒷자리만.
- **거절 키워드**: B8의 패턴(`개발 어려`, `지원되지 않`, `제공되지 않`, `불가`, `규정상`)은 운영 결과로 보정 가능. 오탐 시 룰 갱신.

# § 참고

- 장문 평가 프롬프트: [`cs-evaluation.md`](cs-evaluation.md)
- DB 정책: [`legacy-db-inventory.md`](../legacy-db-inventory.md)
- 분류 규칙(메모리): `@malgnsoft.com` → 직원
- 로드맵 위치: [`roadmap.md`](../roadmap.md) **Phase 1 · 1.8 AI 추천 답변** — 본 브리핑은 추천 답변의 진입 컨텍스트로도 사용
