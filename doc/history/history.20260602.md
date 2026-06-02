# 작업 이력 — 2026-06-02


## 배포

### 13:54 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `c7670ba` (신규 커밋: yes)
- 메시지: feat(wbs): 다크 모드여도 항상 라이트 톤 — useColorMode override

### 14:05 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `77395c7` (신규 커밋: yes)
- 메시지: fix(ui): colorMode를 글로벌 light 고정 — nuxt.config + wbs.vue 페이지별 override 제거

### 14:12 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `c754924` (신규 커밋: yes)
- 메시지: chore: 다크모드 비활성 — colorMode light 글로벌 (모듈 추가 시 자동 발효)

### 14:13 — `malgn-helper` → Cloudflare Pages
- 커밋: `8ed0965` (신규 커밋: yes)
- 메시지: chore: 다크모드 비활성 — colorMode light 글로벌 (모듈 추가 시 자동 발효)

### 14:22 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `acb8940` (신규 커밋: yes)
- 메시지: fix(ui): localStorage 옛 dark 값 무시 — plugin으로 light 강제

### 14:27 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `2d273db` (신규 커밋: yes)
- 메시지: fix(ui): colorMode 제거 + body background-color: #ffffff 강제 (다크 모드 무관)

### 15:59 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `1e1eb28` (신규 커밋: yes)
- 메시지: feat(QaEvalCard): '추천 문의 답변' 별도 섹션으로 분리 — Q&A 본문 다음에 배치

### 17:58 — `malgn-helper-api` → Cloudflare Workers
- 커밋: `bab7867` (신규 커밋: yes)
- 메시지: feat(eval): announce-eval 엔드포인트 신설 + LLM 모델·게이트웨이 정비

- /pms/posts/:id/announce-eval/generate (직원 작성 안내글 평가, 3축 + 3개 추천)
- llm.ts: Workers AI binding 호출 함수(callWorkersAi) 추가
- AI Gateway malgn-helper2로 전환 (이전 malgn-helper는 결제 정책 변경으로 차단)
- LLM_MODEL: openai/gpt-4.1-mini (Vision 포함)
- Smart Placement + AI binding 활성
