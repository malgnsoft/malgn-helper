# 작업 이력 — 2026-06-11


## 배포

### 17:58 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `784a6b3` (신규 커밋: yes)
- 메시지: feat(bots): 챗봇(봇) 관리 — 목록 + 봇별 설정(페르소나·답변범위·학습소스)

- 메뉴 '지식 자산 > 봇 관리' 추가
- /bots 목록(카드·검색·상태필터·활성토글·삭제)
- /bots/[id] 설정폼: 기본정보·캐릭터(말투·성격·시스템프롬프트)·답변범위(서비스·가시성·'모름'정책·에스컬레이션)·학습소스(자료셋·표준답변)·모델
- use-bots 컴포저블(localStorage 영속 데모, 추후 /admin/bots API·hp_bot 연동)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 18:25 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `6936fc4` (신규 커밋: yes)
- 메시지: fix(bots): '봇 관리' 메뉴 권한 제한 해제 — 모든 사용자 사이드바에 노출

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 18:53 — `malgn-helper-admin` → Cloudflare Pages
- 커밋: `844d74f` (신규 커밋: yes)
- 메시지: feat(admin): 목록 공통 필터바(AdminFilterBar/FilterField) + 봇·이미지·Q&A평가 적용

- 라벨형 드롭다운 + 검색어 + 초기화/조회 버튼(이미지 시안 스타일)
- 봇: 구분(서비스)·상태·말투·검색어 / 이미지: 출처·검색어 / Q&A평가: 정렬·빈결과·검색어
- 입력은 조회·Enter로 적용(draft→applied), 초기화 지원

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
