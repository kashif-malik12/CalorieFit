# CalorieFit Project Guidelines

## 🔒 Secret Zero-Leakage & API Key Policy (CRITICAL)
- **Zero Hardcoded Secrets:** Never commit, push, hardcode, or log API keys (`RESEND_API_KEY`, Play Store service account keys, signing passwords, etc.), `.env` files, or keystore files (`upload-keystore.jks`) in source files, scripts, or Git repositories.
- **Environment Variables & GitHub Secrets Only:** Inject secrets via local `.env` (excluded in `.gitignore`) or GitHub Repository Secrets (`Settings -> Secrets and variables -> Actions`).
- **Pre-Commit / Pre-Push Secret Verification:** Always audit `git status` and `git diff --staged` before committing or pushing to GitHub (`origin`).

## 📍 Project & Infrastructure Locations
- **Project Source:** `/home/deploy/projects/caloriefit`
- **Git Remote (`origin`):** `https://github.com/kashif-malik12/CalorieFit.git`
- **Marketing Assets & Scripts:** `/home/deploy/projects/caloriefit/marketing/` and `/home/deploy/projects/caloriefit/docs/`
- **GitHub Workflows:** `/home/deploy/projects/caloriefit/.github/workflows/`

## 💾 Backups
- **Full VPS Snapshot + Mega.nz:** `/home/deploy/bin/bundle_full_vps_backup.sh` (`45 2 * * *` UTC) → `/home/deploy/backups/daily_full/vps_complete_backup_YYYY-MM-DD.tar.gz` → `mega:VPS_Backups/` (archives `projects/caloriefit`; 7-day local / 30-day Mega retention).
- **Git Remote:** `https://github.com/kashif-malik12/CalorieFit.git` (source code and `docs/` pages only; never push `.env` or keystores).
- **Note:** CalorieFit is **not** included in `/home/deploy/bin/backup_to_github_vault.sh` or `/home/deploy/bin/backup_to_cloudflare_r2.sh`.

## 📧 Marketing & Notification Emails
- **`09:00 UTC` daily (GitHub Actions):** `.github/workflows/daily_marketing.yml` runs `python marketing/daily_email_dispatcher.py --force` using GitHub Secret `RESEND_API_KEY` (`OUTREACH_SENDER_EMAIL: kashif@tradister-cloud.com`), sending 1 daily marketing post/video email to `ali.kashifmalik@gmail.com` and pushing updated assets to `docs/videos/` and `docs/creator.html`.
- *(Note: When `marketing/daily_email_dispatcher.py` is run locally on the VPS, it also checks `/home/deploy/bin/tradister_outreach/.env` if present.)*

## ⏰ All Scheduled Tasks
### GitHub Actions
- `0 9 * * *` UTC — `.github/workflows/daily_marketing.yml` (`CalorieFit Daily Autopilot Growth Engine`, also supports `workflow_dispatch`)
- On push / PR to `main` — `.github/workflows/ci.yml` (`CalorieFit CI`: runs `flutter test`)
- On tag `v*` / manual — `.github/workflows/deploy_playstore.yml` (`Deploy to Google Play Store`)

### VPS Crontab (`crontab -l`)
- `45 2 * * *` — `/home/deploy/bin/bundle_full_vps_backup.sh` (includes `projects/caloriefit` in daily VPS tarball & Mega upload)
- `0 9 * * *` — `/usr/bin/python3 /home/deploy/projects/caloriefit/marketing/daily_email_dispatcher.py --next` (daily video render, Buffer social dispatch, and Reddit pack email)
- `0 20 * * *` — `/usr/bin/python3 /home/deploy/bin/generate_daily_marketing_summary.py` (nightly CEO executive marketing review at 21:00 CET for Superi / i360 at `#summary`)
