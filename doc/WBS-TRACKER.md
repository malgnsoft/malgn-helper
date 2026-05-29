# WBS Live Tracker — 자체 완결 빌드 가이드

이 문서 하나만 있으면 어떤 프로젝트에서도 **동일한 WBS Live Tracker 페이지**를 처음부터 만들 수 있다.
프론트엔드(Nuxt) + 백엔드(Hono on Workers) + 영속화(R2) + 자동 저장 흐름을 전부 포함한다.

> 본 프로젝트(`malgn-helper-pms` + `malgn-helper-api`)에서 운영 중인 `/wbs` 페이지의 사양·코드·셋업 절차를 그대로 정리한 자체 완결 사양서.
> 작업 항목 목록(=콘텐츠)은 [WBS.md](./WBS.md)에 있고, 본 문서는 **그것을 보여주고 편집하는 시스템(=툴)** 을 다룬다.

---

## 1. 무엇을 만드는가

웹 페이지 한 화면에 프로젝트 WBS(Work Breakdown Structure)를 표시·편집한다.

- **읽기**: 단계별 진행률, 가중평균, 완료/진행 카운트, 단계별 작업 표
- **편집(인라인)**: 산출물 URL · 목표일 · 완료일 · 상태 — 모두 표 안에서 즉시 수정
- **저장**: 모든 수정은 **800ms 디바운스 후 R2에 자동 저장**. "저장" 버튼 없음
- **공유**: 같은 URL을 열면 다른 사용자도 최신 상태를 즉시 봄
- **백업**: 언제든 현재 상태를 `wbs.json`으로 다운로드

전형적인 "Notion 데이터베이스 + 자동 동기화" 경험을 단일 JSON으로 단순화한 형태.

---

## 2. 디자인 컨셉 — Soft SaaS (Notion / Linear / Height 풍)

| 토큰 | 값 |
| --- | --- |
| 톤 | 라이트, 부드러운 모서리, 옅은 회색 라인 |
| 폰트 | Pretendard Variable (한국어 가독성) |
| 색상 | `neutral` 기반 + 의미색 5가지 |
| 모서리 | `rounded-xl` (카드) / `rounded-md` (인풋·칩) |
| 그림자 | 거의 없음. 플로팅 바만 `shadow-lg shadow-neutral-900/10` |
| 본문 폰트 | 14px 기본, 12~13px 보조 |
| 폭 | `max-w-5xl` 중앙 정렬 |

**의미색 (상태 / 진행률 / 마감)**

| 의미 | Tailwind |
| --- | --- |
| 완료 / 70%+ 진행 | `emerald-500 / 50 / 200 / 700` |
| 진행 중 / 30~69% / 수정 감지 | `amber-500 / 50 / 200 / 700` |
| 대기 / 0% | `neutral-300 / 50 / 200 / 600` |
| 보류 / 마감 초과 | `rose-500 / 50 / 200 / 700` |
| 저장 중 | `sky-500` |

**비주얼 앵커**: 6단계 이모지 `🎯 📐 🛠️ 📚 🧪 🚀` — 화면 상단·각 단계 헤더에 동일 위치로 반복해 시선 동선을 만든다.

**레이아웃 원칙**

1. 상단 히어로 4칸(전체 진행률·완료·진행중 + 여유칸)으로 즉시 요약
2. 단계별 한 줄 리스트(이름·요약·진행률 게이지·건수) → 클릭 시 해당 섹션으로 스크롤
3. 단계별 표는 Notion 데이터베이스 스타일 — 헤더 얇은 회색, 행 호버, 셀이 곧 인풋
4. 우하단 플로팅 바로 자동 저장 상태 노출 (`수정 감지 → 저장 중 → 저장됨 · n초 전`)

---

## 3. 데이터 모델

### 3-1. `wbs.json` 스키마

```ts
type Status = "done" | "in_progress" | "pending" | "blocked";

type Task = {
  id: string;              // 전역 유니크 (예: "P1-3-9")
  taskNo: string;          // 단계 내 표시용 번호 (예: "3-9")
  title: string;
  status: Status;
  note: string | null;
  targetDate: string | null;      // "YYYY-MM-DD"
  completionDate: string | null;  // "YYYY-MM-DD"
  deliverableUrl: string | null;
};

type Stage = {
  id: string;       // "P1-1" 등
  name: string;
  weight: number;   // 합계 100
  progress: number; // 0~100
  summary: string;
  tasks: Task[];
};

type WbsDoc = {
  _meta: {
    lastUpdated: string;  // "YYYY-MM-DD" — 저장 시 자동 갱신
    project: string;
    source: string;       // 외부 참조 문서 경로 (예: "doc/WBS.md")
    editGuide: string;    // 편집 가이드 한 줄
  };
  phase1: { stages: Stage[] };
};
```

### 3-2. 초기 시드 예시 (`public/wbs.json`)

R2가 비었을 때 fallback으로 한 번 읽힌 뒤, 첫 저장 때 R2에 복사된다. 이후 시드 파일은 사용되지 않는다.

```json
{
  "_meta": {
    "lastUpdated": "2026-05-29",
    "project": "Malgn Helper",
    "source": "doc/WBS.md",
    "editGuide": "각 항목 수정 즉시 API(R2)에 자동 저장됨"
  },
  "phase1": {
    "stages": [
      {
        "id": "P1-1",
        "name": "착수 / 분석",
        "weight": 10,
        "progress": 70,
        "summary": "요구사항·범위·이해관계자 정리",
        "tasks": [
          {
            "id": "P1-1-1",
            "taskNo": "1-1",
            "title": "이해관계자 인터뷰",
            "status": "done",
            "note": null,
            "targetDate": "2026-05-20",
            "completionDate": "2026-05-18",
            "deliverableUrl": null
          }
        ]
      }
    ]
  }
}
```

### 3-3. 비즈니스 규칙

- `weightedAverage = round(Σ(stage.progress × stage.weight) / Σ(stage.weight), 0.1)`
- `isOverdue(task) = task.status !== "done" && task.targetDate && task.targetDate < _meta.lastUpdated`
- 빈 문자열은 모두 `null`로 정규화 (입력값 ↔ JSON 직렬화 안정성)

---

## 4. 아키텍처

```
브라우저 (Nuxt 페이지 /wbs)
    │
    │  GET  /wbs   ← 초기 로드
    │  PUT  /wbs   ← 800ms 디바운스 후
    ▼
<api> Worker (Hono on Cloudflare Workers)
    │
    │  R2.get("wbs/wbs.json")
    │  R2.put("wbs/wbs.json", body)
    ▼
Cloudflare R2 bucket
```

**핵심 결정**

- **R2 단일 객체**(`wbs/wbs.json`)에 전체 문서를 통째로 저장. 동시 편집은 가정하지 않음(team 내부 도구).
- **DB 미사용**. WBS 1건만 다루므로 D1/MySQL은 과도. R2 + JSON으로 충분.
- **localStorage 미사용**. 자동 저장 + 공유가 목표이므로 클라이언트 로컬 상태는 두지 않음.
- **초기 시드는 `public/`에 정적 호스팅** → R2 비었을 때 1회만 사용.
- **인증은 의도적으로 생략**(MVP). 사내 운영자만 URL을 알도록 운영. 필요 시 Cloudflare Access로 페이지 + API 동시 보호.

---

## 5. 백엔드 구현 (Hono on Workers)

### 5-1. `wrangler.jsonc`

```jsonc
{
  "$schema": "https://json.schemastore.org/wrangler.json",
  "name": "<api-worker-name>",
  "account_id": "<your-account-id>",
  "main": "src/index.ts",
  "compatibility_date": "2026-05-27",
  "compatibility_flags": ["nodejs_compat"],
  "observability": { "enabled": true },

  "r2_buckets": [
    { "binding": "R2", "bucket_name": "<your-r2-bucket>" }
  ]
}
```

### 5-2. `src/index.ts` (전체)

```ts
import { Hono } from "hono";
import { cors } from "hono/cors";

type Bindings = {
  R2: R2Bucket;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use(
  "*",
  cors({
    origin: (origin) => {
      if (!origin) return "*";
      if (/\.pages\.dev$/.test(origin)) return origin;
      if (/\.malgnsoft\.com$/.test(origin)) return origin;   // ← 자기 도메인 패턴으로 교체
      if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) return origin;
      return null;
    },
    allowMethods: ["GET", "PUT", "POST", "OPTIONS"],
    allowHeaders: ["Content-Type"],
    maxAge: 86400,
  }),
);

app.get("/", (c) => c.json({ name: "wbs-api", status: "ok" }));
app.get("/healthz", (c) => c.json({ ok: true }));

const WBS_KEY = "wbs/wbs.json";

app.get("/wbs", async (c) => {
  const obj = await c.env.R2.get(WBS_KEY);
  if (!obj) return c.json({ exists: false }, 404);
  const body = await obj.text();
  return new Response(body, {
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      ETag: obj.httpEtag,
    },
  });
});

app.put("/wbs", async (c) => {
  const text = await c.req.text();
  try {
    JSON.parse(text);
  } catch {
    return c.json({ error: "invalid json" }, 400);
  }
  if (text.length > 1_000_000) {
    return c.json({ error: "payload too large" }, 413);
  }
  await c.env.R2.put(WBS_KEY, text, {
    httpMetadata: { contentType: "application/json; charset=utf-8" },
  });
  return c.json({ ok: true, size: text.length, savedAt: new Date().toISOString() });
});

export default app;
```

### 5-3. `package.json` 최소 의존

```json
{
  "dependencies": { "hono": "^4.0.0" },
  "devDependencies": { "wrangler": "^4.0.0", "typescript": "^5.0.0" }
}
```

### 5-4. 셋업·배포

```bash
# 1) R2 버킷 (대화형 프롬프트가 떠도 자동 거절)
echo "no" | wrangler r2 bucket create <your-r2-bucket>

# 2) 배포
pnpm run deploy
# → 배포 URL: https://<worker-name>.<subdomain>.workers.dev
```

### 5-5. 스모크 테스트

```bash
curl -i https://<api>/healthz
curl -X PUT https://<api>/wbs -H 'Content-Type: application/json' \
  --data-binary @public/wbs.json
curl -s https://<api>/wbs | head -c 200
```

---

## 6. 프론트엔드 구현 (Nuxt 3)

### 6-1. 전제

- Nuxt 3 + Cloudflare Pages 프리셋(`output dir = dist/`)
- Tailwind CSS v4 (`@source "../.."` 직접 스캔 권장)
- Pretendard Variable 폰트
- @nuxt/ui는 **선택 사항**. 본 페이지는 순수 Tailwind 클래스만 사용

### 6-2. 단일 파일 — `pages/wbs.vue` (전체)

> 그대로 복사하면 동작한다. `API_BASE`만 자기 Worker URL로 바꿀 것.

```vue
<!--
  pages/wbs.vue
  WBS Live Tracker — Soft SaaS (Notion/Linear/Height 풍)
  데이터: API GET /wbs (R2) → 없으면 /wbs.json fallback
  편집: 모든 수정은 800ms 디바운스 후 PUT /wbs로 자동 영구 저장
-->
<script setup lang="ts">
useHead({ title: "WBS" });

type Status = "done" | "in_progress" | "pending" | "blocked";

type Task = {
  id: string;
  taskNo: string;
  title: string;
  status: Status;
  note: string | null;
  targetDate: string | null;
  completionDate: string | null;
  deliverableUrl: string | null;
};

type Stage = {
  id: string;
  name: string;
  weight: number;
  progress: number;
  summary: string;
  tasks: Task[];
};

type WbsDoc = {
  _meta: { lastUpdated: string; project: string; source: string; editGuide: string };
  phase1: { stages: Stage[] };
};

// ⚠️ 자기 환경에 맞게 교체
const API_BASE = "https://<api-worker-name>.<subdomain>.workers.dev";

const wbs = ref<WbsDoc | null>(null);
const pending = ref(true);
const error = ref<Error | null>(null);

type TaskPatch = Partial<
  Pick<Task, "deliverableUrl" | "status" | "targetDate" | "completionDate" | "note">
>;

async function loadWbs() {
  pending.value = true;
  error.value = null;
  try {
    const apiRes = await fetch(`${API_BASE}/wbs`, { cache: "no-store" });
    if (apiRes.ok) {
      wbs.value = (await apiRes.json()) as WbsDoc;
    } else if (apiRes.status === 404) {
      const seed = await fetch("/wbs.json", { cache: "no-store" });
      if (!seed.ok) throw new Error(`seed ${seed.status}`);
      wbs.value = (await seed.json()) as WbsDoc;
    } else {
      throw new Error(`api ${apiRes.status}`);
    }
  } catch (e) {
    error.value = e as Error;
  } finally {
    pending.value = false;
  }
}
onMounted(loadWbs);

// ── 자동 저장 ──────────────────────────────────────────
type SaveState = "idle" | "dirty" | "saving" | "saved" | "error";
const saveState = ref<SaveState>("idle");
const lastSavedAt = ref<Date | null>(null);
const saveError = ref<string | null>(null);
let saveTimer: ReturnType<typeof setTimeout> | null = null;

async function saveNow() {
  if (!wbs.value) return;
  if (saveTimer) { clearTimeout(saveTimer); saveTimer = null; }
  const payload = {
    ...wbs.value,
    _meta: { ...wbs.value._meta, lastUpdated: new Date().toISOString().slice(0, 10) },
  };
  saveState.value = "saving";
  saveError.value = null;
  try {
    const res = await fetch(`${API_BASE}/wbs`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error(`save ${res.status}`);
    lastSavedAt.value = new Date();
    saveState.value = "saved";
    wbs.value._meta = payload._meta;
  } catch (e) {
    saveError.value = (e as Error).message;
    saveState.value = "error";
  }
}

function scheduleSave() {
  saveState.value = "dirty";
  if (saveTimer) clearTimeout(saveTimer);
  saveTimer = setTimeout(saveNow, 800);
}

function setOverride(taskId: string, patch: TaskPatch) {
  if (!wbs.value) return;
  for (const s of wbs.value.phase1.stages) {
    const idx = s.tasks.findIndex((t) => t.id === taskId);
    if (idx === -1) continue;
    const cur = s.tasks[idx];
    const next: Task = {
      ...cur,
      ...patch,
      deliverableUrl: patch.deliverableUrl !== undefined ? patch.deliverableUrl || null : cur.deliverableUrl,
      targetDate: patch.targetDate !== undefined ? patch.targetDate || null : cur.targetDate,
      completionDate: patch.completionDate !== undefined ? patch.completionDate || null : cur.completionDate,
      note: patch.note !== undefined ? patch.note || null : cur.note,
    };
    s.tasks.splice(idx, 1, next);
    scheduleSave();
    return;
  }
}

// ── 파생 상태 ──────────────────────────────────────────
const mergedStages = computed<Stage[]>(() => wbs.value?.phase1.stages ?? []);
const PROJECT_NAME = computed(() => wbs.value?._meta.project ?? "Project");
const LAST_UPDATED = computed(() => wbs.value?._meta.lastUpdated ?? "—");

const weightedAverage = computed(() => {
  const st = mergedStages.value;
  if (!st.length) return 0;
  // 가중평균(%) = Σ(weight × progress) / Σ(weight). progress가 이미 %단위이므로 추가 /100 없음.
  const w = st.reduce((s, x) => s + x.weight, 0);
  const p = st.reduce((s, x) => s + x.weight * x.progress, 0);
  return Math.round((p / w) * 10) / 10;
});

const allTasks = computed(() => mergedStages.value.flatMap((s) => s.tasks));
const totalCounts = computed(() => {
  const acc: Record<Status, number> = { done: 0, in_progress: 0, pending: 0, blocked: 0 };
  for (const t of allTasks.value) acc[t.status]++;
  return acc;
});

function isOverdue(t: Task) {
  if (t.status === "done" || !t.targetDate) return false;
  return t.targetDate < LAST_UPDATED.value;
}

const statusMeta: Record<Status, { label: string; chipCls: string; emoji: string }> = {
  done:        { label: "완료",   chipCls: "bg-emerald-50 text-emerald-700 border-emerald-200", emoji: "✓" },
  in_progress: { label: "진행 중", chipCls: "bg-amber-50 text-amber-700 border-amber-200",       emoji: "◐" },
  pending:     { label: "대기",   chipCls: "bg-neutral-50 text-neutral-600 border-neutral-200", emoji: "○" },
  blocked:     { label: "보류",   chipCls: "bg-rose-50 text-rose-700 border-rose-200",          emoji: "✕" },
};

function progressFill(pct: number) {
  if (pct >= 70) return "bg-emerald-500";
  if (pct >= 30) return "bg-amber-500";
  if (pct > 0)   return "bg-neutral-400";
  return "bg-neutral-200";
}

const stageEmoji = ["🎯", "📐", "🛠️", "📚", "🧪", "🚀"];

// ── 백업 다운로드 ─────────────────────────────────────
const currentJsonString = computed(() => wbs.value ? JSON.stringify(wbs.value, null, 2) + "\n" : "");
function downloadJson() {
  const blob = new Blob([currentJsonString.value], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url; a.download = "wbs.json"; a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

// ── "n초 전" 갱신 ─────────────────────────────────────
const savedAgo = ref("");
let agoTimer: ReturnType<typeof setInterval> | null = null;
function formatAgo(d: Date) {
  const s = Math.floor((Date.now() - d.getTime()) / 1000);
  if (s < 5) return "방금";
  if (s < 60) return `${s}초 전`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}분 전`;
  return `${Math.floor(m / 60)}시간 전`;
}
onMounted(() => {
  agoTimer = setInterval(() => {
    savedAgo.value = lastSavedAt.value ? formatAgo(lastSavedAt.value) : "";
  }, 1000);
});
onUnmounted(() => {
  if (agoTimer) clearInterval(agoTimer);
  if (saveTimer) clearTimeout(saveTimer);
});

function scrollToStage(stageId: string) {
  document.getElementById(`stage-${stageId}`)?.scrollIntoView({ behavior: "smooth", block: "start" });
}
</script>

<template>
  <div class="min-h-screen bg-neutral-50/60 pb-24">
    <div class="mx-auto max-w-5xl px-6 pt-10 sm:px-10 sm:pt-14">
      <!-- HEADER -->
      <header class="mt-4 flex items-start justify-between gap-4">
        <div class="flex items-start gap-3">
          <span class="mt-1 text-[30px]">📋</span>
          <div>
            <h1 class="text-[28px] font-semibold tracking-tight text-neutral-900">
              {{ PROJECT_NAME }} · Phase 1
            </h1>
            <p class="mt-1 text-[14px] text-neutral-500">
              마지막 현행화 {{ LAST_UPDATED }}
            </p>
          </div>
        </div>
      </header>

      <!-- LOADING / ERROR -->
      <div v-if="pending" class="mt-8 rounded-xl border border-neutral-200 bg-white p-6 text-[14px] text-neutral-500">
        로딩 중…
      </div>
      <div v-else-if="error" class="mt-8 rounded-xl border border-rose-200 bg-rose-50 p-6 text-[14px] text-rose-700">
        로드 실패: {{ error.message }}
      </div>

      <template v-else>
        <!-- HERO -->
        <section class="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-4">
          <div class="rounded-xl border border-neutral-200 bg-white p-5 sm:col-span-2">
            <p class="text-[12px] text-neutral-500">전체 진행률</p>
            <p class="mt-1 text-[36px] font-semibold tracking-tight text-neutral-900 tabular-nums">
              {{ weightedAverage }}<span class="ml-0.5 text-[24px] text-neutral-400">%</span>
            </p>
            <div class="mt-4 h-1.5 overflow-hidden rounded-full bg-neutral-100">
              <div class="h-full rounded-full bg-neutral-900 transition-all" :style="{ width: weightedAverage + '%' }" />
            </div>
          </div>
          <div class="rounded-xl border border-neutral-200 bg-white p-5">
            <div class="flex items-center gap-1.5">
              <span class="inline-block size-1.5 rounded-full bg-emerald-500" />
              <p class="text-[12px] text-neutral-500">완료</p>
            </div>
            <p class="mt-1 text-[30px] font-semibold text-neutral-900 tabular-nums">
              {{ totalCounts.done }}<span class="text-[16px] text-neutral-400">/{{ allTasks.length }}</span>
            </p>
          </div>
          <div class="rounded-xl border border-neutral-200 bg-white p-5">
            <div class="flex items-center gap-1.5">
              <span class="inline-block size-1.5 rounded-full bg-amber-500" />
              <p class="text-[12px] text-neutral-500">진행 중</p>
            </div>
            <p class="mt-1 text-[30px] font-semibold text-neutral-900 tabular-nums">
              {{ totalCounts.in_progress }}
            </p>
          </div>
        </section>

        <!-- STAGES OVERVIEW -->
        <section class="mt-8">
          <h2 class="mb-2 text-[14px] font-semibold text-neutral-700">단계별 진행률</h2>
          <ul class="overflow-hidden rounded-xl border border-neutral-200 bg-white">
            <li
              v-for="(s, i) in mergedStages" :key="s.id"
              class="grid cursor-pointer grid-cols-[24px_24px_1fr_auto_140px_auto] items-center gap-4 px-4 py-3 hover:bg-neutral-50"
              :class="i > 0 ? 'border-t border-neutral-100' : ''"
              @click="scrollToStage(s.id)"
            >
              <span class="text-[18px] leading-none">{{ stageEmoji[i] }}</span>
              <span class="font-mono text-[14px] tabular-nums text-neutral-400">{{ String(i + 1).padStart(2, "0") }}</span>
              <div class="min-w-0">
                <p class="truncate text-[14px] font-medium text-neutral-900">{{ s.name }}</p>
                <p class="truncate text-[14px] text-neutral-500">{{ s.summary }}</p>
              </div>
              <span class="text-[14px] text-neutral-400">{{ s.tasks.length }}건</span>
              <div class="flex items-center gap-2.5">
                <div class="h-1 w-24 overflow-hidden rounded-full bg-neutral-100">
                  <div :class="['h-full rounded-full', progressFill(s.progress)]" :style="{ width: s.progress + '%' }" />
                </div>
                <span class="w-9 text-right text-[14px] font-medium tabular-nums text-neutral-700">{{ s.progress }}%</span>
              </div>
              <span class="text-neutral-300">→</span>
            </li>
          </ul>
        </section>

        <!-- STAGE DETAILS -->
        <section v-for="(s, sIdx) in mergedStages" :key="s.id" :id="`stage-${s.id}`" class="mt-10">
          <div class="flex items-baseline justify-between gap-3">
            <div class="flex items-baseline gap-2.5">
              <span class="text-[20px] leading-none">{{ stageEmoji[sIdx] }}</span>
              <h2 class="text-[18px] font-semibold tracking-tight text-neutral-900">{{ s.name }}</h2>
              <span class="font-mono text-[14px] text-neutral-400">{{ s.id }}</span>
            </div>
            <div class="flex items-center gap-3 text-[14px] text-neutral-500">
              <span>비중 {{ s.weight }}%</span>
              <span class="text-neutral-200">·</span>
              <span class="font-medium text-neutral-700">진행 {{ s.progress }}%</span>
            </div>
          </div>
          <p class="mt-1 text-[14px] text-neutral-500">{{ s.summary }}</p>
          <div class="mt-3 h-1 overflow-hidden rounded-full bg-neutral-100">
            <div :class="['h-full rounded-full', progressFill(s.progress)]" :style="{ width: s.progress + '%' }" />
          </div>

          <div class="mt-4 overflow-hidden rounded-xl border border-neutral-200 bg-white">
            <table class="w-full text-[14px]">
              <thead>
                <tr class="border-b border-neutral-100 text-[14px] font-medium text-neutral-500">
                  <th class="w-20 px-3 py-2 text-left">ID</th>
                  <th class="px-3 py-2 text-left">작업 · 산출물</th>
                  <th class="w-36 px-3 py-2 text-left">목표일</th>
                  <th class="w-36 px-3 py-2 text-left">완료일</th>
                  <th class="w-28 px-3 py-2 text-left">상태</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(t, ti) in s.tasks" :key="t.id"
                  class="align-top hover:bg-neutral-50/60"
                  :class="ti > 0 ? 'border-t border-neutral-100' : ''"
                >
                  <td class="px-3 py-3 font-mono text-[14px] tabular-nums text-neutral-400">{{ s.id }}-{{ t.taskNo }}</td>
                  <td class="px-3 py-3">
                    <p class="text-[13.5px] font-medium text-neutral-900">{{ t.title }}</p>
                    <p v-if="t.note" class="mt-0.5 text-[14px] leading-relaxed text-neutral-500">{{ t.note }}</p>
                    <div class="mt-2 flex items-center gap-2">
                      <span class="text-[14px] text-neutral-400">🔗</span>
                      <input
                        :value="t.deliverableUrl ?? ''" type="url" placeholder="산출물 URL 입력"
                        class="min-w-0 flex-1 rounded-md border border-transparent bg-transparent px-1.5 py-1 font-mono text-[13px] text-neutral-700 placeholder:text-neutral-400 hover:border-neutral-200 focus:border-neutral-300 focus:bg-white focus:outline-none focus:ring-1 focus:ring-neutral-200"
                        @change="(e) => setOverride(t.id, { deliverableUrl: (e.target as HTMLInputElement).value || null })"
                      />
                      <a v-if="t.deliverableUrl" :href="t.deliverableUrl" target="_blank" rel="noopener"
                         class="shrink-0 rounded-md px-1.5 py-1 text-[14px] text-neutral-500 hover:bg-neutral-100 hover:text-neutral-900">
                        열기 ↗
                      </a>
                    </div>
                  </td>
                  <td class="whitespace-nowrap px-2 py-3">
                    <input
                      type="date" :value="t.targetDate ?? ''"
                      :class="['w-full rounded-md border border-transparent bg-transparent px-1.5 py-1 font-mono text-[12px] tabular-nums hover:border-neutral-200 focus:border-neutral-300 focus:bg-white focus:outline-none focus:ring-1 focus:ring-neutral-200',
                               isOverdue(t) ? 'font-semibold text-rose-600' : 'text-neutral-600']"
                      @change="(e) => setOverride(t.id, { targetDate: (e.target as HTMLInputElement).value || null })"
                    />
                  </td>
                  <td class="whitespace-nowrap px-2 py-3">
                    <input
                      type="date" :value="t.completionDate ?? ''"
                      class="w-full rounded-md border border-transparent bg-transparent px-1.5 py-1 font-mono text-[12px] tabular-nums text-emerald-700 hover:border-neutral-200 focus:border-neutral-300 focus:bg-white focus:outline-none focus:ring-1 focus:ring-neutral-200"
                      @change="(e) => setOverride(t.id, { completionDate: (e.target as HTMLInputElement).value || null })"
                    />
                  </td>
                  <td class="whitespace-nowrap px-3 py-3">
                    <label :class="['relative inline-flex cursor-pointer items-center gap-1.5 whitespace-nowrap rounded-md border px-2 py-0.5 text-[13px] font-medium hover:brightness-95',
                                    statusMeta[t.status].chipCls]">
                      <span class="text-[13px]">{{ statusMeta[t.status].emoji }}</span>
                      {{ statusMeta[t.status].label }}
                      <select
                        :value="t.status" class="absolute inset-0 cursor-pointer opacity-0"
                        @change="(e) => setOverride(t.id, { status: (e.target as HTMLSelectElement).value as Status })"
                      >
                        <option v-for="(meta, key) in statusMeta" :key="key" :value="key">
                          {{ meta.emoji }} {{ meta.label }}
                        </option>
                      </select>
                    </label>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </template>
    </div>

    <!-- FLOATING AUTOSAVE STATUS -->
    <div v-if="saveState !== 'idle'"
         class="fixed bottom-6 left-1/2 z-50 flex -translate-x-1/2 items-center gap-2.5 rounded-full border border-neutral-200 bg-white px-3 py-2 shadow-lg shadow-neutral-900/10">
      <span class="flex items-center gap-2 pl-1 text-[14px] text-neutral-700">
        <template v-if="saveState === 'dirty'">
          <span class="inline-block size-1.5 rounded-full bg-amber-500" /><span>수정 감지…</span>
        </template>
        <template v-else-if="saveState === 'saving'">
          <span class="inline-block size-1.5 animate-pulse rounded-full bg-sky-500" /><span>저장 중…</span>
        </template>
        <template v-else-if="saveState === 'saved'">
          <span class="inline-block size-1.5 rounded-full bg-emerald-500" />
          <span>저장됨 <span class="text-neutral-400">· {{ savedAgo }}</span></span>
        </template>
        <template v-else-if="saveState === 'error'">
          <span class="inline-block size-1.5 rounded-full bg-rose-500" />
          <span class="text-rose-700">저장 실패: {{ saveError }}</span>
        </template>
      </span>
      <span class="h-4 w-px bg-neutral-200" />
      <button v-if="saveState === 'error'"
              class="rounded-md bg-neutral-900 px-3 py-1 text-[14px] font-medium text-white hover:bg-neutral-700"
              @click="saveNow">재시도</button>
      <button class="rounded-md px-2.5 py-1 text-[14px] text-neutral-600 hover:bg-neutral-100"
              @click="downloadJson" title="현재 상태를 wbs.json으로 다운로드">↓ 백업</button>
    </div>
  </div>
</template>
```

### 6-3. 자동 저장 상태 머신

```
[idle] ─ 첫 편집 ─▶ [dirty] ─ 800ms 무편집 ─▶ [saving] ─ 200 OK ─▶ [saved]
                       │                              │
                       └─ 추가 편집 시 타이머 재시작     └─ 실패 시 ▶ [error] ─ 재시도 ─▶ [saving]
```

- 새 편집이 들어오면 timer 갱신 → 디바운스 보장
- `saving` 중 새 편집은 다음 사이클에서 통째로 PUT (변경 단위가 아닌 문서 단위)
- 페이지 unmount 시 timer cleanup. 저장 누락 위험은 디바운스 800ms로 한정됨
- 더 강건하게 가려면 `beforeunload` 핸들러에서 `saveState === 'dirty'`일 때 `navigator.sendBeacon`으로 마지막 PUT을 보낼 수 있음

---

## 7. 새 프로젝트에서 초기화하기 — 체크리스트

1. **Cloudflare**
   - 계정에서 R2 활성화
   - `wrangler r2 bucket create <my-bucket>`
2. **백엔드 (`<api>` 레포)**
   - `pnpm add hono` / `pnpm add -D wrangler typescript`
   - 위 §5-1, §5-2 그대로 복사. `name`, `account_id`, `bucket_name`만 교체
   - `pnpm wrangler deploy` → API URL 확보
3. **프론트엔드 (`<pages>` 레포, Nuxt 3)**
   - `pages/wbs.vue` 생성 → §6-2 복사 → `API_BASE`를 자기 API URL로 교체
   - `public/wbs.json`에 §3-2 형태의 초기 시드 작성
   - 한 번 빌드·배포 후 페이지 접속 → 첫 편집 시 R2에 자동 시드됨
4. **CORS 확인**
   - §5-2의 `origin` 함수에 자기 페이지 도메인 패턴 추가
5. **검증**
   - 다른 브라우저에서 같은 URL을 열어 변경 즉시 반영되는지 확인
   - 네트워크 탭에서 PUT이 800ms 디바운스 후 1회만 가는지 확인

> 인증이 필요한 환경이면 **Cloudflare Access**로 `<pages>` 도메인과 `<api>/wbs` 라우트를 동시에 보호하는 것이 가장 단순. 인증 코드 작성 불필요.

---

## 8. 운영 메모

| 항목 | 방침 |
| --- | --- |
| 동시 편집 충돌 | last-write-wins. ETag 기반 conditional PUT은 미적용 (사내 1~3명 운영 가정) |
| 백업 | 우하단 `↓ 백업` 버튼으로 수시 다운로드. 또는 R2 versioning 활성화 권장 |
| 시드 갱신 | `public/wbs.json` 수정은 **R2가 비어 있을 때만** 의미가 있음. 운영 중에는 R2가 정본 |
| 마이그레이션 | 스키마 변경 시 `_meta.schemaVersion` 필드를 추가하고 `app.put`에서 변환 |
| 모니터링 | Workers `observability: true`로 PUT 실패 로그 추적 |
| 보안 | 현재 무인증. 공개 도메인에 둘 거라면 반드시 Access 또는 토큰 헤더 검증 추가 |

---

## 9. 디자인 변형 가이드

이 페이지의 디자인 토큰은 의도적으로 단순하다. 다음 한 줄만 바꿔도 분위기가 크게 달라진다.

- **다크 모드**: 컨테이너 `bg-neutral-50/60` → `bg-neutral-950`, 카드 `bg-white` → `bg-neutral-900`, 라인 `border-neutral-200` → `border-neutral-800`. 텍스트 명도만 반전
- **밀도 ↑**: `px-3 py-3` → `px-2 py-2`, 본문 `text-[14px]` → `text-[13px]`
- **에디토리얼**: 헤더에 serif 디스플레이 폰트(`Instrument Serif` 등) + 본문 mono. 카드 모서리 `rounded-xl` → `rounded-none`
- **터미널/IDE**: 카드 제거, 단일 `pre`, JetBrains Mono, 좌측 라인 거터 추가

색·간격은 토큰화돼 있어서 한 파일에서 전체 분위기를 바꿀 수 있다.

---

## 10. 알려진 한계

- **다중 사용자 동시 편집 시 마지막 저장이 이김** — 실시간 동기화(WebSocket/SSE)는 없음
- **인증 없음** — 외부 노출 시 Cloudflare Access 등으로 별도 보호 필요
- **이력 추적 없음** — R2 versioning을 켜거나, PUT 시점에 `wbs/history/<ts>.json`로 스냅샷 저장하면 해결 가능
- **Phase 1만 모델링** — `phase1.stages[]` 구조. Phase 2 이상은 동일 패턴으로 키 추가 후 컴포넌트에서 반복 렌더링

---

## 11. 본 프로젝트의 실제 값 (참고)

| 키 | 값 |
| --- | --- |
| API URL | `https://malgn-helper-api.malgnsoft.workers.dev` |
| API 레포 | `~/Projects/malgn-helper-api` |
| Pages 레포 | `~/Projects/malgn-helper-pms` |
| R2 버킷 | `malgn-helper-files` (key: `wbs/wbs.json`) |
| 페이지 URL | `https://malgn-helper-pms.pages.dev/wbs` |
| 시드 위치 | `malgn-helper-pms/public/wbs.json` |
| Cloudflare account_id | `d2b8c5524b7259214fa302f1fecb4ad6` (Info@malgnsoft.com) |
