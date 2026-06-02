// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2026-05-27",
  devtools: { enabled: true },
  // 다크 모드 비활성 — 사용자 OS 설정과 무관하게 항상 라이트 톤.
  // (현재는 color-mode 모듈 미설치 → @nuxt/ui v3나 @nuxtjs/color-mode 추가 시 자동 발효)
  colorMode: {
    preference: "light",
    fallback: "light",
  },
  nitro: {
    preset: "cloudflare-pages",
  },
});
