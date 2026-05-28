// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: "2026-05-27",
  devtools: { enabled: true },
  nitro: {
    preset: "cloudflare-pages",
  },
});
