# Window AI — Cloudflare Edition

Sab kuch Cloudflare par: **ek Worker** frontend (`public/index.html`) aur API dono serve karta hai, **D1** database me users/chats/memory/tokens hain, **Turnstile** CAPTCHA hai. Railway ya koi aur server nahi chahiye.

```
wrangler.toml        ← public settings + D1 binding (yahan koi secret nahi)
schema.sql           ← database tables
src/index.js         ← API (auth, tokens, chats, memory, tools, admin)
src/lib/             ← auth (Google + Turnstile), D1 store, AI router/providers, brand guard, prompts
public/index.html    ← frontend (API_BASE = "auto")
test/                ← 24 automated tests
.dev.vars.example    ← sirf local testing ke liye
```

## Status (honest)

| Cheez | Status |
|---|---|
| Worker code, 24 tests | Pass. D1 ki jagah SQLite-based nakli D1, aur provider/Google/Turnstile ke mock responses use hue |
| Wrangler deploy / bundling | **Test nahi hua** (yahan wrangler install nahi ho saka). Pehli deploy par koi error aaye to mujhe error bhej dena |
| Asli D1, Google login, Turnstile, AI providers | **Test nahi hue**, credentials chahiye |
| Google login | `GOOGLE_CLIENT_ID` ke bina band, "not configured" dikhata hai |
| CAPTCHA | Turnstile keys ke bina login band; skip nahi hota |
| AI replies | Kam az kam ek provider key chahiye, warna "not set up" error, fake reply nahi |
| PDF / DOCX editing | **Cloudflare version me supported nahi**; clear error aata hai. Text/code files (txt, md, csv, json, html, js, py, ...) chalti hain |
| Rate limiting | Worker me sirf halka (har isolate ka apna). Asli protection ke liye Cloudflare WAF Rate Limiting rule lagayein (neeche) |

## Deploy (Windows/Mac/Linux, Node 20+ chahiye)

1. ZIP extract karein, folder me terminal kholein: `npm install`
2. `npx wrangler login`
3. Database banayein: `npx wrangler d1 create window-ai-db`. Jo `database_id` print ho use `wrangler.toml` me `PASTE_YOUR_D1_DATABASE_ID` ki jagah daalein.
4. Tables banayein: `npm run db:init`
5. Pehli deploy: `npm run deploy`. Aakhir me aapka URL milega, jaise `https://window-ai.<aapka-naam>.workers.dev`. (Abhi login "not configured" dikhayega, ye normal hai.)
6. **Turnstile:** Cloudflare Dashboard → Turnstile → Add widget → hostname me apna Worker hostname daalein. Aapko *Site key* aur *Secret key* milengi.
   - Site key (public) → `wrangler.toml` me `CAPTCHA_SITE_KEY`
   - Secret key → `npx wrangler secret put CAPTCHA_SECRET_KEY` (ye paste karne ko poochta hai, file me kuch save nahi hota)
7. **Google:** Google Cloud Console → APIs & Services → Credentials → OAuth client ID (Web application). *Authorized JavaScript origins* me apna Worker URL daalein. **Client Secret ki zarurat nahi**, sirf Client ID chahiye, use `wrangler.toml` me `GOOGLE_CLIENT_ID` me daalein.
8. **AI keys (secrets)**, har ek ke liye alag command, paste karne par terminal me nahi dikhti:
   ```
   npx wrangler secret put GEMINI_API_KEY
   npx wrangler secret put GROK_API_KEY
   npx wrangler secret put MISTRAL_API_KEY
   npx wrangler secret put NVIDIA_API_KEY
   npx wrangler secret put COHERE_API_KEY
   npx wrangler secret put SAMBANOVA_API_KEY
   ```
   Jis provider ki key nahi hai use skip karein. Dashboard se bhi ho sakta hai: Workers & Pages → window-ai → Settings → Variables and Secrets → **Secret**.
9. Dobara deploy: `npm run deploy`
10. Check: `https://<aapka-url>/api/config` kholein. `ready` me `google`, `captcha`, `ai`, `database` sab `true` hone chahiye. Jo `false` hai wahi baaki hai.

Naye secret add karne ke baad dobara deploy zaroori nahi hota, lekin `wrangler.toml` ki public settings badlein to deploy karna padta hai.

## Window AI branding

User ko sirf "Window AI" dikhta hai: system prompt + output filter (`src/lib/brand.js`). Provider ka naam kisi response me nahi jata. Filter "I am Gemini / trained by Google" jaise jumlon ko badalta hai; 100% guarantee nahi, deploy ke baad har provider se ek baar "tum kaun ho?" puch kar check karein. Task ke hisab se provider ka order `src/lib/ai.js` (`DEFAULT_ROUTES`) me hai, ya variable `ROUTE_CHAT="mistral,gemini"` se badlein. Fail hone par agla provider khud use hota hai.

Default model names sirf starting point hain. Apne provider dashboard se confirm karein aur zarurat ho to `GEMINI_MODEL`, `MISTRAL_MODEL` waghera variable (wrangler.toml `[vars]`) se badlein.

## Tokens, plans, WhatsApp

- Har naye account ko server 100,000 tokens deta hai (`STARTER_TOKENS`). Har request pehle tokens reserve karti hai, asli usage ke hisab se settle hoti hai, fail ho to refund.
- Pro/Ultra ke liye checkout nahi, button `https://wa.me/923178036357` kholta hai. Payment ke baad aap tokens/plan khud dein: pehle `npx wrangler secret put ADMIN_TOKEN`, phir

  ```
  curl -X POST https://<aapka-url>/api/admin/grant \
    -H "x-admin-token: <ADMIN_TOKEN>" -H "Content-Type: application/json" \
    -d '{"username":"ali_khan","plan":"pro","tokens":500000}'
  ```

## Rate limiting (recommended)

Dashboard → Security → WAF → Rate limiting rules → URI path starts with `/api/auth/` → 10 requests / 1 minute per IP → Block.

## Local test

```
npm test                 # 24 tests, wrangler ki zarurat nahi
npx wrangler dev         # local run (.dev.vars.example ko .dev.vars me copy karein)
```

## Cloudflare limits

Workers/D1 ki free aur paid limits (requests, CPU time, subrequests) Cloudflare ki docs me dekhein. Zyada users aane par Workers Paid plan lena pad sakta hai.

## Agar page Blogger par hi rakhna ho

Zaruri nahi, Worker page khud serve karta hai. Phir bhi chahein to `public/index.html` me `API_BASE` ko Worker URL par set karein aur `ALLOWED_ORIGINS` me blog ka URL daalein; Turnstile aur Google ke origins me bhi blog domain add karna hoga. Ye maine Blogger par test nahi kiya.
