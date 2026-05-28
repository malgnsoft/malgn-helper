# malgn-helper

NotebookLM 수준의 사내 솔루션 전문 고객상담 AI 챗봇 — **사용자 프론트엔드**.

워크스페이스 진입점. 전체 시스템은 4개 저장소로 구성된다.

| 저장소 | 역할 |
| --- | --- |
| [malgn-helper](https://github.com/malgnsoft/malgn-helper) (이 저장소) | 사용자 챗봇 프론트엔드 — Nuxt 3 / Cloudflare Pages |
| [malgn-helper-admin](https://github.com/malgnsoft/malgn-helper-admin) | 관리자 프론트엔드 (자료·표준답변·상담 로그) |
| [malgn-helper-api](https://github.com/malgnsoft/malgn-helper-api) | API 서버 — Hono on Cloudflare Workers |
| [malgn-helper-pms](https://github.com/malgnsoft/malgn-helper-pms) | PMS 애드온 — 상담사용 추천 답변·문의 분석 도우미 |

## 핵심 문서

- [CLAUDE.md](CLAUDE.md) — 시스템 개요·인프라·작업 규칙
- [doc/tech-stack.md](doc/tech-stack.md) — 기술 스택 정의
- [doc/roadmap.md](doc/roadmap.md) — Phase 1·Phase 2 로드맵
- [doc/wbs.md](doc/wbs.md) — 작업 분해 (WBS)
- [doc/legacy-db-inventory.md](doc/legacy-db-inventory.md) — 레거시 PMS DB 인벤토리
- [doc/project-inquiry-analysis.md](doc/project-inquiry-analysis.md) — 업체별 문의 분석
- [doc/examples/](doc/examples/) — 업체별 케이스 스터디
- [doc/prompts/](doc/prompts/) — 재사용 평가·브리핑 프롬프트

## 인프라

Cloudflare (Pages + Workers + R2 + Hyperdrive + AI Gateway) · Aurora MySQL · AWS OpenSearch · Anthropic Claude.

## 개발·배포 (사용자 챗봇 프론트엔드)

```bash
pnpm install              # 의존성 설치
pnpm dev                  # 로컬 개발 (nuxt dev)
pnpm build                # 프로덕션 빌드
pnpm deploy               # Cloudflare Pages 배포 (.output/public)
```

최초 배포 전 Pages 프로젝트 생성 필요:
```bash
wrangler pages project create malgn-helper
```

`wrangler login` 또는 `CLOUDFLARE_API_TOKEN` 환경변수 필요.
