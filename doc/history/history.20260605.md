# 작업 이력 — 2026-06-05

## 종합

오늘 5개 흐름 진행 — 답변 없는 문의 추천 답변 모드, PMS UI 폴리시 다회, **hp_image_asset 신설(Vision 자동 캡션)**:

1. **답변 없는 문의 → inquiry-only 모드** — `QA_INQUIRY_ONLY_SYSTEM_PROMPT` 신설. resp 없으면 5축 평가 생략하고 D축 1개에 추천 답변 6개(짧은/긴/친절/비즈니스/FAQ/단계별)만 wrap. 모호한 문의면 commentary에 "추가 확인 필요 정보" 명시.

2. **PMS UI 폴리시 라운드** (10회 배포)
   - 임베드 시그널 `modal=open` 다시 포함 → 모달 진입 시 게시글 목록 버튼/breadcrumb 숨김
   - 빈 상태 카드: `tb_post` 코드 라벨 제거, "1.5초 시뮬레이션" 안내 제거. "약 30초~1분 소요" 안내만 남김
   - 메타 일시 표시: ISO → `yyyy.MM.dd HH:mm:ss` 한 줄, MetaTile 폰트 18→14px
   - PersonBlock: UTooltip 안 텍스트가 안 보이던 이슈 fix (title 속성으로 대체), 이름·뱃지·이메일을 한 줄로 (좁으면 wrap)
   - 추천 답변 가독성: 문단 간격 `my-3`, line-height 1.8, 폰트 13px, 패딩 py-4

3. **hp_image_asset 신설 + 자동 Vision 캡션** (오늘의 핵심)
   - 5번째 hp_* 테이블. `src_path` UNIQUE(prefix 191 — MySQL 5.6 utf8mb4 767 byte 한도 대응)로 한 이미지는 한 번만 분석
   - `analyzeAndStoreImage()`: 캐시 hit이면 usage_count++, 없으면 GPT-4o Vision으로 `title` + `description` 생성 → INSERT
   - eval/generate에서 본문(`inquiry`) + 응답(`reply`) HTML의 `/data/*` 이미지 추출 → 병렬 분석·저장 (최대 16장)
   - HP-SCHEMA.md 3-5 섹션 + DDL 추가
   - `/admin/migrate/hp_image_asset?confirm=yes` 일회용 엔드포인트로 마이그레이션 완료
   - 검증: post 149694의 이미지 9장이 정확한 한국어 캡션으로 저장 (예: "메시지관리 메뉴 화면", "발신프로필 정보 화면", "알림톡 템플릿 수정 화면")

4. **표준답변 저장 흐름 정리** — 사용자 질의에 따라 전 경로 (QaEvalCard `save-template` emit → `POST /standard-answers` → `hp_standard_answer` INSERT) 문서화. axisLetter는 모두 `'D'`로 고정.

### 결정/사건

- AI Gateway는 `malgn-helper2` + Provider OpenAI 키 + Authorization+cf-aig-authorization 헤더 조합으로 안정 운영
- hp_image_asset의 `src_path`는 VARCHAR(500)이지만 UNIQUE 인덱스는 prefix 191자만 — utf8mb4 4byte × 191 = 764 byte ≤ 767 한도
- inquiry-only 응답의 axes는 D축 1개만 들어가지만 UI는 그대로 정상 동작 (5축 평가 섹션은 D축 카드 1개 + 추천 답변 섹션은 별도 분리되어 표시)
- `/admin/migrate/hp_image_asset` 엔드포인트는 일회용 — 후속 정리 시 코드에서 제거 권장

### 다음 작업 후보

- 안내글 평가(`/pms/posts/:id/announce-eval/generate`) PMS UI 통합 — 코드만 들어가 있음
- `hp_image_asset`을 표준답변·챗봇 컨텍스트로 활용 (이미지 설명을 텍스트로 인용)
- 관리자 화면에 이미지 카탈로그 (검색·태그 큐레이션)
- OpenSearch 셋업 + 자료 업로드 MVP (M2 진입)
- inquiry-only 응답에 axes가 D축만 들어갈 때 UI에서 5축 평가 섹션 숨기는 분기

---

## 배포

### 11:09 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `2b0689d` (신규 커밋: yes)
- 메시지: feat(eval): 답변이 없는 문의는 inquiry-only 모드로 추천 답변 6개만 생성

### 11:16 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `a3d0f43` (신규 커밋: yes)
- 메시지: fix(projects): modal=open도 임베드 시그널에 다시 포함 — 모달 진입 시 게시글 목록 버튼 숨김

### 11:17 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `9205573` (신규 커밋: yes)
- 메시지: chore(ui): 빈 상태 카드 문구 정리 — tb_post 코드 라벨·1.5초 시뮬레이션 안내 제거

### 11:19 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `20c17f3` (신규 커밋: yes)
- 메시지: chore(ui): 빈 상태 카드에 생성 소요 시간 안내 복원 (약 30초~1분)

### 11:34 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `795bdc3` (신규 커밋: yes)
- 메시지: feat(QaEvalCard): 문의·응답 일시를 yyyy.MM.dd HH:mm:ss 형식으로 표시

### 11:37 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `11f92a0` (신규 커밋: yes)
- 메시지: chore(QaEvalCard): 문의·응답 메타타일에 날짜+시간 한 줄로 합쳐 표시

### 11:39 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `a47445a` (신규 커밋: yes)
- 메시지: fix(QaEvalCard): PersonBlock에서 UTooltip 제거 → 이름이 안 보이던 이슈 fix (title 속성으로 툴팁 대체)

### 11:40 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `0446352` (신규 커밋: yes)
- 메시지: chore(ui): MetaTile value 폰트 18px→14px — 한 줄 일시 표시 시 줄바꿈 방지

### 11:44 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `b17be67` (신규 커밋: yes)
- 메시지: chore(QaEvalCard): PersonBlock의 이름·뱃지·이메일을 한 줄로 표시 (좁으면 wrap)

### 11:47 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `ecd7955` (신규 커밋: yes)
- 메시지: chore(QaEvalCard): 추천 답변 가독성 — 문단 간격(my-3) + 줄간격(1.8) + 폰트 13px 적용

### 12:01 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `b3ce7e1` (신규 커밋: yes)
- 메시지: feat(image-asset): hp_image_asset 신설 + Vision으로 PMS 자산 이미지 자동 캡션·설명 추출·저장

### 18:52 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `137dc9c` (신규 커밋: yes)
- 메시지: fix(hp_image_asset): UNIQUE 인덱스 prefix 255→191 (MySQL 5.6 utf8mb4 키 길이 767 byte 제한)
