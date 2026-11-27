# CalorieFit (`com.caloriefit.app`) — Product Summary

**Repo:** `/home/deploy/projects/caloriefit/`  
**Live URLs:** `https://caloriefit.tradister.com` • **Play Store:** `com.caloriefit.app` • **Hub:** `https://kashif-malik12.github.io/CalorieFit/`

---

## 1. Project Summary
Offline-first, zero-tracker, privacy-focused Android calorie & Health Connect tracking app built for global consumers tired of paywalled subscriptions and intrusive ads.

## 2. Technical Summary
- **Mobile App & CI/CD:** Native Android Kotlin + local-first SQLite + Health Connect integration + 7 localized Play Store languages (`https://github.com/kashif-malik12/CalorieFit.git`, `main`); `.github/workflows/ci.yml` & `deploy_playstore.yml` handle builds/releases.
- **Web & Video Assets:** Static site at `caloriefit/web/` (`caloriefit.tradister.com`) and GitHub Pages showcase (`docs/index.html`, `docs/creator.html`, `docs/videos/`).
- **Automation (`marketing/daily_email_dispatcher.py`):** Runs daily at `09:00 UTC` via VPS cron (with `.github/workflows/daily_marketing.yml` manual fallback); renders 1080×1920 9:16 MP4 videos via Pillow + `edge-tts` + `ffmpeg`, tracks 7-day state in `~/.config/daily_post_state.json`, dispatches via Buffer & Resend.

## 3. Marketing Summary
- **Channels:**
  - **Buffer Socials (`@caloriefit11` IG/TikTok, `@CalorieFit11` X):** Automated daily 9:16 video publishing (`isQueuePaused: false`).
  - **Reddit Daily Loop:** Emails 1-click pre-filled Reddit launch submissions (`r/androidapps`, `r/CICO`, `r/loseit`, `r/SideProject`).
  - **ASO & SEO:** Localized Play Store keywords + 3 static SEO articles (`docs/articles/`).
