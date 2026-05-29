# Cloudflare Access — `/admin/*` 보호 가이드

`/admin/*` 라우트(현재: `/admin/cost`)와 함께 모든 노출 위험 페이지·API를 Cloudflare Access로 보호하는 단계별 가이드.

> 현재 상태: **무인증**. URL을 아는 사람은 누구나 비용·DB 탐색 엔드포인트에 접근 가능. 사내 운영 중에는 OK이지만, 공개 도메인에 둘 거라면 반드시 적용해야 한다.

---

## 보호 대상

| 자원 | 호스트 | 경로 |
| --- | --- | --- |
| LLM 비용 대시보드 | `malgn-helper-pms.pages.dev` | `/admin/*` |
| 비용 집계 API | `malgn-helper-api.malgnsoft.workers.dev` | `/admin/*` |
| DB 탐색 임시 엔드포인트 | `malgn-helper-api.malgnsoft.workers.dev` | `/db/*` |

---

## 사전 준비

1. Cloudflare Zero Trust 무료 플랜 활성화 (월 50명까지)
2. 보호할 도메인이 Cloudflare에 등록되어 있어야 함
   - `*.pages.dev` 와 `*.workers.dev`는 기본적으로 Access 적용 가능
   - 커스텀 도메인이면 해당 zone 등록 필요

---

## 1) Access Application 만들기

### Pages 페이지 (PMS) 보호

1. https://one.dash.cloudflare.com → 좌측 **Access** → **Applications** → **Add an application** → **Self-hosted**
2. 입력:
   - **Application name**: `malgn-helper-pms admin`
   - **Session Duration**: `24h` (또는 원하는 값)
   - **Application domain**:
     - Subdomain: `malgn-helper-pms`
     - Domain: `pages.dev`
     - Path: `/admin/*`
3. **Identity providers**: One-time PIN (이메일 OTP) 또는 회사 SSO(Google Workspace/Okta 등)
4. **Add a policy**:
   - **Policy name**: `staff only`
   - **Action**: `Allow`
   - **Include**:
     - `Emails ending in` → `@malgnsoft.com`
   - 또는: `Emails` → 명시적 화이트리스트

### API Worker 보호

같은 절차로 두 번째 Application 추가:

- Subdomain: `malgn-helper-api`
- Domain: `workers.dev`
- Path: `/admin/*` (또는 `/db/*`까지 보호하려면 추가 Application)
- 동일 policy 적용

---

## 2) Worker가 Access JWT를 검증하도록 (옵션, 강력 권장)

Access를 켜도 *직접 Worker 도메인 IP에 도달하는 우회 요청*은 막을 수 없다. Worker 측에서 한 번 더 검증해야 완전:

```ts
// src/middleware/access.ts
import { jwtVerify, createRemoteJWKSet } from "jose";

const JWKS = createRemoteJWKSet(
  new URL("https://<team>.cloudflareaccess.com/cdn-cgi/access/certs"),
);
const AUD = "<application-aud-tag>"; // Access Application의 AUD

export async function requireAccess(c: any) {
  const token = c.req.header("cf-access-jwt-assertion");
  if (!token) return c.json({ error: "no-access-jwt" }, 401);
  try {
    await jwtVerify(token, JWKS, {
      issuer: "https://<team>.cloudflareaccess.com",
      audience: AUD,
    });
  } catch {
    return c.json({ error: "invalid-access-jwt" }, 401);
  }
}
```

라우트에 적용:

```ts
app.use("/admin/*", async (c, next) => {
  const fail = await requireAccess(c);
  if (fail) return fail;
  await next();
});
```

AUD는 Access Application 상세에서 확인 (Audience tag).

---

## 3) PMS에서 페이지가 Access 토큰을 자동으로 처리하도록

Pages 도메인 자체에 Access를 걸면 브라우저가 자동 로그인 → cookie/header 자동 첨부. **추가 코드 불필요**.

PMS → API 호출 시 cross-origin이면 `credentials: "include"` 필요할 수 있음:

```ts
fetch(`${API_BASE}/admin/cost`, { credentials: "include" })
```

만약 API가 다른 zone이면 별도 Application 통과 — 사용자가 한 번 더 OTP 로그인.

---

## 4) DB 탐색 엔드포인트 보호 (`/db/*`)

`/db/whoami`, `/db/tables`, `/db/columns/:t`, `/db/sample/:t` 모두 운영 전 단계 노출. Access Application 추가하거나, **차라리 제거** 후 필요 시 일회용 admin 엔드포인트로 다시 만드는 게 깔끔.

---

## 5) 적용 후 검증

```bash
# Access 없이 호출 → 302 (Access 로그인 페이지로 리다이렉트) 또는 401
curl -sS -o /dev/null -w "%{http_code}\n" https://malgn-helper-api.malgnsoft.workers.dev/admin/cost
# → 302 또는 401 기대

# 브라우저에서 페이지 접속 → OTP 메일 → 로그인 → 정상 표시
```

---

## 6) 비상시 해제

- Dashboard → Access → Applications → 해당 Application → **Delete**
- Worker 측 미들웨어는 그대로 두면 401만 반환 → 미들웨어 임시 주석 처리 후 재배포

---

## 비용

- Zero Trust Free: **50명까지 무료**
- 그 이상: 사용자당 월 $3 (Standard) — 현재 운영팀 규모면 무료 한도 안에 충분

---

## 참고

- 공식 가이드: https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/self-hosted-apps/
- Worker에서 JWT 검증: https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/
- AUD 위치: Application 상세 → **Overview** 탭 → "Application Audience (AUD) Tag"
