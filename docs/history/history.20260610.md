# 작업 이력 — 2026-06-10


## 배포

### 10:18 — `malgn-helper-mng` → Cloudflare Pages
- 커밋: `ee0a8be` (신규 커밋: yes)
- 메시지: refactor: doc 폴더를 docs로 변경 + 참조 일괄 갱신

- doc/ → docs/ (git mv, 28파일)
- content.config.ts·nuxt.config.ts 소스 경로 docs/ 로 수정
- CLAUDE.md·앱 화면 문구·개발자 가이드 self-참조 갱신
- /docs URL 라우트, malgn-helper/doc(타 레포), API /doc 라우트는 보존

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 11:04 — `malgn-helper-mng` → Cloudflare Pages
- 커밋: `a00ccc5` (신규 커밋: yes)
- 메시지: docs: 콘텐츠 문서의 doc/ 표기를 docs/로 정합 (워크스페이스·API 참조는 보존)

- BLUEPRINT·WBS·WBS-TRACKER·examples·prompts·history/README 의 doc/ → docs/
- README 문서 인덱스 링크를 형제경로로 교정해 실제 동작화
- 보존: history 로그(append-only, 워크스페이스 deploy.sh가 쓰는 malgn-helper/doc), CLAUDE 미러, API /doc 라우트

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>

### 11:23 — `malgn-helper-mng` → Cloudflare Pages
- 커밋: `be9165a` (신규 커밋: yes)
- 메시지: docs: malgn-helper/doc → malgn-helper/docs 폴더 변경에 따른 cross-repo 참조 갱신

- wbsData.ts·seed.sql·boardSeed.ts provenance 주석
- CLAUDE.md·DEVELOPER-GUIDE.md·docs/CLAUDE.md(미러)의 워크스페이스 doc/history → docs/history
- dated history 로그는 보존

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
