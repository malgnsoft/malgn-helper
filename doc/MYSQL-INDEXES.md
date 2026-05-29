# PMS DB 인덱스 추천 (브리핑 카드 쿼리 부하 절감)

브리핑 카드 생성 시 MySQL 부하 원인은 두 가지:

1. ~~`email LIKE '%@malgnsoft.com'`~~ → **이미 코드에서 `staff user_id IN (...)` 으로 교체** (별도 작업 불요)
2. 큰 프로젝트(post 수천 건)에서 `tb_post` 스캔 — **복합 인덱스 추가 필요**

`hp_*` 헬퍼 테이블 인덱스는 이미 `001_init_hp_tables.sql`에 정의돼 있으니 여기서는 **`tb_post` / `tb_post_comment` 운영 테이블** 만 다룹니다.

---

## 추천 인덱스

### 1. tb_post — 최우선

```sql
ALTER TABLE tb_post ADD INDEX idx_project_status_regdate (project_id, status, reg_date);
```

**효과**: 다음 6개 쿼리가 모두 인덱스 한 번으로 결정됨
- `COUNT(*) WHERE project_id=? AND status=1` (누적·180일 통계)
- `MIN/MAX(reg_date) WHERE project_id=? AND status=1` (빠른 quick check)
- `SELECT subject ... ORDER BY reg_date DESC LIMIT 100` (제목 군집화)
- `WHERE project_id=? AND status=1 AND reg_date >= ?` (180일 cutoff)
- `WHERE project_id=? AND status=1 AND p.user_id NOT IN (...)` (미응답·고객 메시지)
- `WHERE project_id=? AND label IS NOT NULL GROUP BY label` (라벨 분포)

**비용**: 추가 디스크 < 1% (PMS tb_post 행 사이즈 작음). 쓰기 부하 무시 가능.

### 2. tb_post_comment

```sql
ALTER TABLE tb_post_comment ADD INDEX idx_postid_status_regdate (post_id, status, reg_date);
ALTER TABLE tb_post_comment ADD INDEX idx_postid_userid_status (post_id, user_id, status);
```

**효과**:
- `NOT EXISTS (SELECT 1 FROM tb_post_comment WHERE post_id = p.id AND status = 1 AND user_id IN (...))` (미응답 판정)
- `MIN(reg_date) WHERE post_id = ? AND user_id IN (...)` (FRT 첫 응답 시각)
- 가장 비싼 NOT EXISTS 상관 서브쿼리가 인덱스 한 번으로 끝남

**비용**: 댓글 테이블이 크면 디스크 사용 약간 증가 (1~2%). 그래도 NOT EXISTS 풀스캔 대비 압도적 이득.

---

## 적용 절차 (운영팀 검토)

1. **백업 또는 dry run** — 운영 PMS에 적용 전 테스트 서버에서 EXPLAIN 비교
2. **온라인 ALTER**: MySQL 5.6에서 InnoDB는 `ALGORITHM=INPLACE` 지원
   ```sql
   ALTER TABLE tb_post
     ADD INDEX idx_project_status_regdate (project_id, status, reg_date),
     ALGORITHM=INPLACE, LOCK=NONE;
   ```
   - 쓰기 차단 없이 추가됨 (행 수 많으면 시간 걸림)
3. **검증**: 적용 후 첫 브리핑 카드 호출이 5~10배 빨라지면 OK

---

## EXPLAIN 비교 (참고)

### Before
```
SELECT COUNT(*) FROM tb_post p
JOIN tb_user pu ON pu.id = p.user_id
WHERE p.project_id = 1528 AND p.status = 1 AND p.reg_date >= '20251130000000'
  AND pu.email NOT LIKE '%@malgnsoft.com'
  AND NOT EXISTS (SELECT 1 FROM tb_post_comment c JOIN tb_user cu ...)
```
- `tb_post` Using where, rows = N (project_id 인덱스만 활용)
- `tb_post_comment` ALL (풀스캔, 매 row마다)
- `tb_user` Using where (email LIKE 풀스캔)

### After (코드 변경 + 인덱스 추가)
```
SELECT COUNT(*) FROM tb_post p
WHERE p.project_id = 1528 AND p.status = 1 AND p.reg_date >= '20251130000000'
  AND p.user_id NOT IN (1, 2, 3, ...)
  AND NOT EXISTS (SELECT 1 FROM tb_post_comment c
                   WHERE c.post_id = p.id AND c.status = 1 AND c.user_id IN (1, 2, ...))
```
- `tb_post` Using index for group-by, range 한정
- `tb_post_comment` Using index, ref (post_id) — 인덱스 lookup만
- `tb_user` 안 봄 (LIKE 제거됨)

---

## 코드 측에서 한 일

1. **staff user_id를 한 번에 가져와 캐시** — 모든 후속 쿼리에서 `IN`/`NOT IN`으로 사용
2. **캐시 키를 quick check 2개로 변경** — `MAX(tb_post.reg_date)` + `MAX(tb_post_comment.reg_date)`로 데이터 변동 감지. 같으면 13개 SQL 안 침
3. **24시간 hp_briefing 캐시 적중률 상승** — 데이터 안 바뀌면 매번 캐시 그대로 반환

---

## 적용 후 기대 효과

| 지표 | 적용 전 | 적용 후 |
| --- | --- | --- |
| 캐시 hit 시 SQL 쿼리 수 | 13~14 | **2** (quick check만) |
| 캐시 miss 시 SQL 쿼리 수 | 13~14 | 13~14 (동일하나 각 쿼리가 빨라짐) |
| 가장 비싼 unanswered 쿼리 지연 | 수백 ms ~ 수 초 | 수십 ms |
| `email LIKE` 풀스캔 | 매 호출마다 N회 | **0회** (`IN` 사용) |
