# CS 평가 프롬프트 (재사용 템플릿)

> 임의의 프로젝트(고객사)에 대해 동일 양식의 CS·챗봇·고객사 평가 보고서를 AI에게 생성시키기 위한 프롬프트.
> 산출 예시: [`docs/examples/안전보건진흥원.md`](../examples/안전보건진흥원.md)

## 사용법

1. 아래 **§ 프롬프트 본문**을 복사.
2. 상단 `[입력]`의 `{{...}}` 자리에 실제 값을 채움.
3. AI(또는 DB 접근 가능한 에이전트)에게 전달.
4. 산출물은 `docs/examples/{{PROJECT_NAME}}.md`로 저장.

---

# § 프롬프트 본문 (이 아래를 그대로 AI에게 전달)

당신은 **CS 운영 데이터 분석가**입니다.
아래 입력과 평가 프레임을 사용해 단일 프로젝트(고객사)에 대한 종합 평가 보고서를 작성하세요.
산출물은 마크다운이며, 표 위주로 구성합니다. 측정되지 않은 항목은 추측하지 말고 `ㅡ(정보 부족)`으로 표기하세요.

## [입력]

- `PROJECT_ID` = `{{PROJECT_ID}}` (예: `1528`)
- `PROJECT_NAME` = `{{PROJECT_NAME}}` (예: `*안전보건진흥원`)
- `EVAL_DATE` = `{{YYYY-MM-DD}}` (평가 기준일)
- `DB_CONNECTION` = `{{호스트·계정 — 별도 시크릿 채널}}`
- `SCOPE` = `{{선택: 기간/사이트/필터 추가 조건}}`

## [분류 규칙] — 필수 준수

- **`tb_user.email LIKE '%@malgnsoft.com'` → 직원 (staff)**
- **그 외 도메인 → 고객사·협력사 (customer/partner)**
- 이메일이 없거나 NULL이면 별도 검수 (분류 불명)
- **이름·게시판 패턴·작성 빈도로 추정 금지**. 분류는 반드시 이메일 도메인으로 결정.

## [출처 데이터 모델]

`pms` DB의 `tb_post`(게시글) + `tb_post_comment`(댓글) + `tb_post_file`(첨부) + `tb_project`(고객사) + `tb_site`(사이트) + `tb_user`(사용자). 자세한 스키마·정제 정책은 [`docs/LEGACY-DB-INVENTORY.md`](../LEGACY-DB-INVENTORY.md) 참조.

기본 Q&A 후보 필터:

```sql
WHERE p.status = 1
  AND p.comm_cnt >= 1
  AND p.is_task = 0 AND p.is_schedule = 0 AND p.is_poll = 0 AND p.is_notice = 0
  AND p.subject NOT LIKE '테스트%'
  AND CHAR_LENGTH(p.content) >= 20
```

## [필수 데이터 수집 쿼리 — 그대로 실행 가능]

`{{PROJECT_ID}}`만 치환해서 실행. 결과를 평가 프레임에 매핑.

```sql
-- D1. 게시글·댓글·비공개 분포 (이메일 도메인 기반)
SELECT 'posts' kind,
  SUM(u.email LIKE '%@malgnsoft.com') staff,
  SUM(u.email IS NULL OR u.email NOT LIKE '%@malgnsoft.com') customer,
  COUNT(*) total
FROM tb_post p LEFT JOIN tb_user u ON u.id = p.user_id
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1
UNION ALL SELECT 'comments',
  SUM(u.email LIKE '%@malgnsoft.com'),
  SUM(u.email IS NULL OR u.email NOT LIKE '%@malgnsoft.com'),
  COUNT(*)
FROM tb_post_comment c JOIN tb_post p ON p.id = c.post_id LEFT JOIN tb_user u ON u.id = c.user_id
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1 AND c.status = 1
UNION ALL SELECT 'private_comments',
  SUM(c.private_yn='Y' AND u.email LIKE '%@malgnsoft.com'),
  SUM(c.private_yn='Y' AND (u.email IS NULL OR u.email NOT LIKE '%@malgnsoft.com')),
  SUM(c.private_yn='Y')
FROM tb_post_comment c JOIN tb_post p ON p.id = c.post_id LEFT JOIN tb_user u ON u.id = c.user_id
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1 AND c.status = 1;

-- D2. Q&A 후보 / 본문 통계 / 첨부
SELECT COUNT(*) qna_candidates,
  ROUND(AVG(CHAR_LENGTH(p.content))) avg_body_len,
  SUM(p.subject LIKE CONCAT('[', '{{PROJECT_NAME_BARE}}', ']%')) structured_title
FROM tb_post p
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1
  AND p.comm_cnt >= 1 AND p.is_task=0 AND p.is_schedule=0 AND p.is_poll=0 AND p.is_notice=0
  AND p.subject NOT LIKE '테스트%' AND CHAR_LENGTH(p.content) >= 20;

SELECT COUNT(DISTINCT p.id) total,
  COUNT(DISTINCT IF(f.id IS NOT NULL, p.id, NULL)) with_attachment
FROM tb_post p LEFT JOIN tb_post_file f ON f.module='post' AND f.module_id = p.id AND f.status=1
WHERE p.project_id = {{PROJECT_ID}} AND p.status = 1;

-- D3. 응답 시간 (FRT)
SELECT ROUND(AVG(frt)) avg_min,
  SUM(frt <= 60) within_1h, SUM(frt <= 240) within_4h, SUM(frt <= 1440) within_1d, COUNT(*) total
FROM (
  SELECT TIMESTAMPDIFF(MINUTE,
    STR_TO_DATE(p.reg_date,'%Y%m%d%H%i%s'),
    STR_TO_DATE(MIN(c.reg_date),'%Y%m%d%H%i%s')) frt
  FROM tb_post p JOIN tb_post_comment c ON c.post_id=p.id
  WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1
  GROUP BY p.id
) t;

-- D4. FCR (직원 단일 답변 후 종결)
WITH staff_replies AS (
  SELECT c.post_id, COUNT(*) n
  FROM tb_post_comment c JOIN tb_post p ON p.id=c.post_id LEFT JOIN tb_user u ON u.id=c.user_id
  WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1 AND u.email LIKE '%@malgnsoft.com'
  GROUP BY c.post_id
)
SELECT COUNT(*) total, SUM(n=1) single, ROUND(100.0*SUM(n=1)/COUNT(*),1) fcr_pct
FROM staff_replies;

-- D5. 인력 분담 (직원 only)
SELECT u.name, u.email, COUNT(*) replies,
  ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),1) pct,
  SUM(c.private_yn='Y') private_cnt
FROM tb_post_comment c JOIN tb_post p ON p.id=c.post_id LEFT JOIN tb_user u ON u.id=c.user_id
WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1 AND u.email LIKE '%@malgnsoft.com'
GROUP BY u.name, u.email ORDER BY replies DESC;

-- D6. 고객 매너 키워드
SELECT SUM(c.content LIKE '%감사%') thanks,
  SUM(c.content LIKE '%확인%') confirm,
  SUM(c.content LIKE '%부탁%') please,
  SUM(c.content LIKE '%죄송%') apology,
  COUNT(*) customer_comments
FROM tb_post_comment c JOIN tb_post p ON p.id=c.post_id LEFT JOIN tb_user u ON u.id=c.user_id
WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1
  AND (u.email IS NULL OR u.email NOT LIKE '%@malgnsoft.com');

-- D7. 종결 멘트 작성자
WITH last_c AS (
  SELECT c.post_id, u.email, c.content,
    ROW_NUMBER() OVER (PARTITION BY c.post_id ORDER BY c.reg_date DESC) rn
  FROM tb_post_comment c JOIN tb_post p ON p.id=c.post_id LEFT JOIN tb_user u ON u.id=c.user_id
  WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1
)
SELECT IF(email LIKE '%@malgnsoft.com','staff','customer') who, COUNT(*) total,
  SUM(content LIKE '%감사%' OR content LIKE '%확인했%' OR content LIKE '%잘 받았%') closed
FROM last_c WHERE rn=1 GROUP BY 1;

-- D8. 영업시간/주말 응답 (직원)
SELECT SUM(HOUR(STR_TO_DATE(c.reg_date,'%Y%m%d%H%i%s')) BETWEEN 9 AND 18) biz_hours,
  SUM(HOUR(STR_TO_DATE(c.reg_date,'%Y%m%d%H%i%s')) NOT BETWEEN 9 AND 18) off_hours,
  SUM(DAYOFWEEK(STR_TO_DATE(c.reg_date,'%Y%m%d%H%i%s')) IN (1,7)) weekend,
  COUNT(*) total
FROM tb_post_comment c JOIN tb_post p ON p.id=c.post_id LEFT JOIN tb_user u ON u.id=c.user_id
WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1 AND u.email LIKE '%@malgnsoft.com';

-- D9. 주제 키워드 빈도 (제목 기준)
SELECT 'LMS' kw, COUNT(*) cnt FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND subject LIKE '%LMS%'
UNION ALL SELECT '오류', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND subject LIKE '%오류%'
UNION ALL SELECT '문의', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND subject LIKE '%문의%'
UNION ALL SELECT '결제', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND subject LIKE '%결제%'
UNION ALL SELECT '도메인', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND subject LIKE '%도메인%'
UNION ALL SELECT 'SMS·문자', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%SMS%' OR subject LIKE '%문자%' OR subject LIKE '%메일%')
UNION ALL SELECT '회원·계정', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%회원%' OR subject LIKE '%계정%' OR subject LIKE '%로그인%' OR subject LIKE '%비밀번호%')
UNION ALL SELECT '진도·수강', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%진도%' OR subject LIKE '%수강%' OR subject LIKE '%학습%')
UNION ALL SELECT '수료증', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND subject LIKE '%수료%'
UNION ALL SELECT '평가·시험', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%평가%' OR subject LIKE '%시험%' OR subject LIKE '%퀴즈%')
UNION ALL SELECT '콘텐츠·영상', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1 AND (subject LIKE '%WBT%' OR subject LIKE '%콘텐츠%' OR subject LIKE '%컨텐츠%' OR subject LIKE '%영상%')
ORDER BY 2 DESC;

-- D10. 시기별 분포 (월 단위)
SELECT SUBSTRING(reg_date,1,6) ym, COUNT(*) cnt
FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1
GROUP BY ym ORDER BY ym;

-- D11. 본문에 포함된 답변 본문 키워드 (에스컬레이션·거절 시그널)
SELECT
  SUM(c.content LIKE '%개발팀%') dev_handoff,
  SUM(c.content LIKE '%유선%' OR c.content LIKE '%전화%') phone,
  SUM(c.content LIKE '%확인 후%' OR c.content LIKE '%확인하고%') check_back,
  SUM(c.content LIKE '%죄송%') apology,
  SUM(c.content LIKE '%감사%') thanks,
  SUM(c.content LIKE '%개발 어려%' OR c.content LIKE '%지원되지 않%' OR c.content LIKE '%제공되지 않%' OR c.content LIKE '%불가%') rejection,
  COUNT(*) total
FROM tb_post_comment c JOIN tb_post p ON p.id=c.post_id
WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1;

-- D12. PII 의심 패턴
SELECT
  SUM(c.content REGEXP '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+') email_like,
  SUM(c.content REGEXP '010[-]?[0-9]{4}[-]?[0-9]{4}') phone_010,
  SUM(c.content REGEXP '[0-9]{2,3}-[0-9]{3,4}-[0-9]{4}') tel_dash,
  COUNT(*) total
FROM tb_post_comment c JOIN tb_post p ON p.id=c.post_id
WHERE p.project_id={{PROJECT_ID}} AND p.status=1 AND c.status=1;

-- D13. 자동화 적합성 분류 (제목 키워드 기반)
SELECT '위탁·협업 요청' kind, COUNT(*) cnt FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1
  AND (subject LIKE '%모니터링%' OR subject LIKE '%작업%' OR subject LIKE '%세팅%' OR subject LIKE '%확인 요청%' OR subject LIKE '%발송%' OR subject LIKE '%체크%')
UNION ALL SELECT '기능 질의', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1
  AND (subject LIKE '%질의%' OR subject LIKE '%여부%' OR subject LIKE '%가능한지%' OR subject LIKE '%관련 문의%')
UNION ALL SELECT '오류 신고', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1
  AND (subject LIKE '%오류%' OR subject LIKE '%작동%' OR subject LIKE '%안되%' OR subject LIKE '%풀려%')
UNION ALL SELECT '개발 요청', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1
  AND (subject LIKE '%기능개발%' OR subject LIKE '%개발 요청%' OR subject LIKE '%추가 제작%' OR subject LIKE '%반영%')
UNION ALL SELECT '긴급', COUNT(*) FROM tb_post WHERE project_id={{PROJECT_ID}} AND status=1
  AND (subject LIKE '%긴급%' OR subject LIKE '%★%');
```

## [평가 프레임 — 8개 섹션 작성]

다음 8개 섹션을 모두 작성하세요. 점수 체계: ★ 1~5, 판정 표시: ✓ 양호 / ⚠ 주의 / ✕ 문제 / ㅡ 정보 부족.

### § 1. 메타 (overview)

다음 정보를 표로 정리:
- Project ID / Name / Site
- 기간 (first_post ~ last_post)
- 전체 게시글 수 / Q&A 후보 수
- 주 문의자 (이메일 도메인 포함)
- 응대자 (직원, 분담 비율)
- 케이스 성격 한 줄 요약

### § 2. 카테고리별 분포

D9·D13 결과로 주요 주제 카테고리와 건수를 표로. 각 카테고리에 대표 문의 예시 1~2개를 함께.

### § 3. 시기별 흐름

D10 결과로 월별 추이 + 시기별 특징(도입 초기 / 운영 중반 / 정착기 등)을 정성 해석.

### § 4. 답변 결과로 본 핵심 시스템 이슈

D11 결과 + 정성 분석. 정책 거절·미지원·개발 불가 답변에서 반복되는 시스템 이슈를 표로:
- 이슈명 / 결과(요약) / 비공개 여부 / 참조 post_id

### § 5. 케이스 특수성

이 프로젝트만의 도메인 특수성(공공/대학/HRD/일반기업 등), 법령·규제, 운영 의존도, 답변 노출 민감성 등 4~6개 항목으로.

### § 6. AI 챗봇 적합성 평가 (5축)

각 축마다 체크 항목 표를 작성. 측정값 + 판정(✓/⚠/✕/ㅡ).

**A. 답변 품질**: 정확도 · 현재 유효성(신선도) · 완결성(종결 멘트) · 일관성 · 출처·근거 인용
**B. 운영 지표**: FRT 평균·분포(1h/4h/1d) · TTR · 재문의 패턴 · 긴급 처리 일관성
**C. 응대 패턴**: 답변자 분포(이메일 기반) · 셀프 보완 · 에스컬레이션 시그널 · 응답 톤 정형성 · 반복 답변 가능성
**D. 정책·규제·민감 정보**: 거절·미지원 답변 비율 · 비공개 댓글 비율 · 비공개에만 답 있는 글 · PII 의심 패턴 · 고객사 식별정보 · 법령 종속 답변 · 비공개 작성자 패턴
**E. 자동화 적합성**: D13의 5분류(위탁·협업 / 기능 질의 / 오류 신고 / 개발 요청 / 긴급) 비중 → **추정 자동 응답 가능 비중(%)**

**§6 종합 판정**: 5개 차원에 대한 ✓/⚠/✕ 판정 + 권장 후속 조치 5~7개.

### § 7. 순수 CS 운영 품질 평가 (챗봇 분리)

5축 × ★ 1~5 점수.

**A. 응답 신속성**: FRT 평균 · 1h/4h/1d 비율 · 영업시간 응답률 · 주말 응답 · 긴급 SLA 일관성
**B. 해결 품질**: FCR(D4) · 평균 댓글 수 · 종결 시그널(D7) · 사과 사용 · 장기 미해결 · 반복 주제(D9)
**C. 인력 운영**: 응답 인력 수(D5) · 주 응답자 집중도 · 역할 분담 패턴(공개/비공개·테마별) · 백업 운영 · 야간 커버 · 표준답변·KMS 여부
**D. 프로세스 성숙도**: 티켓 시스템 · 표준답변/FAQ · 카테고리·태그 · 우선순위 분기 · 공개/비공개 분리 · 지식 베이스 검색 · 에스컬레이션 경로 · 개발 환류 추적
**E. 고객 경험**: 만족 시그널 · 사과 빈도 · 응답 톤 일관성 · 고객-담당자 관계 · 고객 측 능동성 · 긴급 대응 실패 사례 · 거절 답변 노출 통제

**종합 점수표** (5축 + 전체 평균)
**강점 vs 개선점** (개선 우선순위 5~7개)
**본 케이스 → 전사 시사점** (다른 프로젝트로 일반화 가능 패턴)

### § 8. 고객사 평가 (협업 행태)

5축 × ★ 1~5 점수.

**A. 문의 품질**: 제목 구조화 비율(D2) · 카테고리 라벨링 · 본문 길이(D2) · 컨텍스트 첨부(D2) · 재현 정보 명시
**B. 컨택 일관성**: 주 담당자 단독/복수 · 협업자·백업 유무 · 다중 채널(유선) 사용 · 응대 시간대 · 후속 응답 속도
**C. 요청 합리성**: D13 분류의 위탁·협업 비중 · 단순 질의 비중 · 오류 신고 정상 비율 · 개발 요청 무리도 · 긴급 표기 남용 · 법령/근거 인용
**D. 협업 태도**: 종결 멘트 작성률(고객) · 매너 키워드(D6: 감사/확인/부탁/죄송) · 회신 방향성 · 정책 거절 수용도 · 후속 정보 능동 제공
**E. 운영 성숙도**: 기술 용어 정확도 · 자체 분류 운영 · FAQ 인지 · 동일 주제 반복 · 의사결정 일관성 · 도입 단계 · 장기 미종결 처리

**종합 점수표** (5축 + 전체 평균)
**강점 vs 잠재 우려**
**제공자 vs 고객사 매트릭스** (5축 점수 비교 + 관계 진단 한 문단)
**후속 활용** (신규 고객사 온보딩 가이드 · 위탁 비중 비교 · 고객사 SLA 자가진단 등)

## [출력 형식 규칙]

- **언어**: 한국어
- **포맷**: 마크다운, 표 위주
- **점수**: ★ 1~5
- **판정 기호**: ✓ 양호 · ⚠ 주의 · ✕ 문제 · ㅡ 정보 부족
- **추측 금지**: 데이터로 측정·관찰되지 않은 항목은 반드시 `ㅡ`로 표기.
- **분류 기준 명시**: §1 메타에 "분류 규칙: 이메일 도메인 `@malgnsoft.com` 기준" 한 줄 포함.
- **Cross-link**: 결과 문서 하단에 [`LEGACY-DB-INVENTORY.md`](../LEGACY-DB-INVENTORY.md), [`PROJECT-INQUIRY-ANALYSIS.md`](../PROJECT-INQUIRY-ANALYSIS.md), [`ROADMAP.md`](../ROADMAP.md) 링크.
- **저장 경로**: `docs/examples/{{PROJECT_NAME}}.md`. (`*` 같은 접두 기호는 안전한 파일명으로 치환 가능)
- **추출 쿼리 섹션은 포함하지 않음** — 본 프롬프트의 [필수 데이터 수집 쿼리] 절을 재사용.

## [품질 체크리스트] — 보고서 제출 전 확인

- [ ] 메타에 이메일 도메인 분류 기준 명시
- [ ] 모든 수치는 측정값 (가정·추정 금지)
- [ ] §6·§7·§8 각각의 종합 점수표 포함
- [ ] §8 끝의 제공자 vs 고객사 매트릭스 포함
- [ ] 정보 부족 항목은 `ㅡ`로 명시
- [ ] 점수 산정 근거가 표 안에 들어 있음
- [ ] 강점/개선점/후속 조치 모두 포함

---

# § 참고

- 예시 산출물: [`docs/examples/안전보건진흥원.md`](../examples/안전보건진흥원.md) — 본 프롬프트로 만들 결과의 모범 형태
- DB 정책·정제 룰: [`docs/LEGACY-DB-INVENTORY.md`](../LEGACY-DB-INVENTORY.md)
- 전체 업체 분포·필터 룰: [`docs/PROJECT-INQUIRY-ANALYSIS.md`](../PROJECT-INQUIRY-ANALYSIS.md)
- 분류 규칙 메모리 근거: 사용자 정책 (`@malgnsoft.com` → 직원)
