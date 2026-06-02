# 작업 이력 — 2026-06-02

## 종합

다음 5가지 흐름이 하루에 진행:

1. **WBS 페이지 다크모드 → 라이트 톤 강제** — wbs.vue 단독 useColorMode override → nuxt.config 글로벌 colorMode → plugin으로 localStorage 덮어쓰기 → 최종적으로 `main.css`의 `body { background-color: #ffffff }`로 일원화 (관련 colorMode 코드는 모두 제거). 다른 3개 repo(`admin`·`helper`·`pms`)도 nuxt.config 정리·일관성 적용.

2. **QaEvalCard 구조 개편** — "추천 문의 답변"을 D축(표준화 가능성) 안에서 빼내 **Q&A 본문 다음 별도 섹션**으로 배치. templates 6개 표시·복사·표준답변 저장 동작 모두 유지. QaAxisCard에서 templates 렌더링·관련 import 제거.

3. **안내글 평가 엔드포인트 신설** — `POST /pms/posts/:id/announce-eval/generate`. 작성자가 직원(staff)일 때만 동작, 3축(톤·자세 / 명확성 / 완전성) + 3개 변형 추천(짧은 / 명료한 / 자세한). 캐싱·hp_qa_eval 저장·hp_llm_log 감사 모두 동일 구조 재활용. **PMS UI 통합은 보류** (코드만 들어가 있음).

4. **AI Gateway·LLM 정비 (큰 변화)** — Cloudflare AI Gateway 결제 정책 변경 + 한국 region IP block 정책이 겹쳐 OpenAI 호출 경로가 다수 차단됨. 6가지 경로 검증 후 최종 안정 구성으로 안착:
   - 새 게이트웨이 `malgn-helper2` (Authentication disabled, BYOK Provider 키 등록)
   - 모델 `openai/gpt-4.1-mini` (Vision 포함)
   - 헤더 원래 방식 — `Authorization`(OpenAI 키) + `cf-aig-authorization`(Gateway 토큰)
   - Smart Placement + AI binding 활성 (유지)
   - callOpenAiJson 경로 복귀 (callWorkersAi는 코드에 유지하되 미사용)
   - 검증: post 149694 평점 **4.4–4.8**, oneLiner 자연스러움, D templates 6개 정상

5. **5/29 작업 → 문서 현행화** — WBS.md 전면 갱신(진행률 6단계 모두 상향, 누적 자산 갱신, 다음 우선순위 M2 진입 기준 재작성), HP-SCHEMA.md `overall_verdict` VARCHAR(100) 마이그레이션 반영, history.20260601.md 작성. R2의 `wbs.json`도 PUT으로 갱신해 `/wbs` 라이브 트래커 동기화.

### 시도된 OpenAI 호출 경로 (트러블슈팅 기록)

| # | 경로 | 결과 |
| --- | --- | --- |
| 1 | AI Gateway compat (`malgn-helper`) + BYOK | region 차단 |
| 2 | AI Gateway compat + Cloudflare credit | compat에 미적용 |
| 3 | Worker → OpenAI 직접 | region 차단 (Workers IP block) |
| 4 | 위 + Smart Placement | 학습 안 됨, 동일 차단 |
| 5 | Workers AI binding `@cf/openai/...` | `5007 No such model` |
| 6 | Workers AI binding `openai/gpt-4.1-mini` + Provider 키 | `2021 Payment error` (partner 결제 정책) |
| **7** | **AI Gateway compat (`malgn-helper2`) + Authorization + cf-aig-authorization** | **정상 동작** ✅ |

### 결정/사건

- `malgn-helper` 게이트웨이는 결제 정책상 더 이상 사용 불가 → `malgn-helper2` 신규 게이트웨이로 전환 (사용자가 직접 생성)
- AI Gateway에 OpenAI Provider 키 **재등록** (이전에 BYOK region 차단 우려로 삭제했던 키 다시 등록)
- AI Gateway $10 크레딧 충전 (단 partner 모델 호출에는 적용되지 않음 — Cloudflare 자체 모델 전용)
- Llama 3.3 70B로의 fallback 가능성 검증 완료 (평점 4.0, 한국어 OK) — 비상시 옵션으로 유지
- 안내글 평가 기능은 코드 들어감, UI 통합은 별도 작업 (PMS의 `pages/posts/[id]/index.vue` 작성자 staff 분기 + 모달 재활용)

### 다음 작업 후보

- 안내글 평가 UI 통합 (`작성자 staff → "AI 안내글 분석" 버튼 + 모달`)
- OpenSearch 셋업 + 자료 업로드 MVP (M2 진입)
- `/admin/evals`에서 LLM 행 클릭 시 모달 즉시 열기

---

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

### 18:12 — `malgn-helper-pms` → Cloudflare Pages
- 커밋: `1e1eb28` (신규 커밋: no)
- 메시지: chore: 청크 hash 갱신 — '추천 문의 답변' 섹션 분리 변경이 브라우저 캐시로 안 보이는 사례 대응
