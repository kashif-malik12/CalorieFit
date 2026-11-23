# CalorieFit Reddit Launch Posts & Submission Guidelines

> ⚠️ **CRITICAL SUBMISSION CHECKLIST (Avoid AutoMod Instant-Removal)**
> 1. **Post Type:** Always select **"Post" (Text / Self-Post)**. DO NOT submit as a "Link" or "Image" post!
> 2. **Title:** Always begin your title with **`[DEV]`** on r/androidapps and developer subreddits.
> 3. **Post Flair:** Before clicking Submit, click **"Add Flair"** and select **"Developer"** (or **"Dev"**).
> 4. **Pricing Transparency:** Subreddit rules strictly require stating if the app is free, paid, contains ads, or has IAP. Always keep the **Pricing & Permissions** section in the body text.
> 5. **Screenshots:** If Reddit image upload is unavailable in text mode, link your high-res screenshots or Play Store page cleanly.

---

## 1. For `r/androidapps`

* **Post Type:** Text Post (Self-Post)
* **Flair to Select:** `Developer`

**Title:**
> [DEV] CalorieFit - I got tired of $80/year subscriptions and full-screen ads, so I built a 100% free, offline calorie & fasting tracker (No accounts, no ads)

**Post Body:**
```markdown
Hey r/androidapps!

A few months ago, I opened MyFitnessPal to log my breakfast, only to be hit with a 30-second unskippable ad, followed by a popup demanding $79.99/year just to scan a barcode. On top of that, virtually every mainstream diet app requires an account and sells user health & weight data to ad brokers.

So I built what I actually wanted: **CalorieFit**.

---

### 💰 Pricing & Monetization
- **Price:** 100% Free
- **In-App Purchases:** None ($0)
- **Ads:** Zero ads / no banners / no video interruptions
- **Account Required:** None (No login or email needed)

---

### 🛡️ Permissions & Privacy
- **Storage:** 100% Local-First. All food diaries, custom recipes, and weights are stored directly in your phone's on-device SQLite database.
- **Telemetry:** Zero third-party ad SDKs or trackers.
- **Optional Health Sync:** Uses Android Health Connect strictly on-device to sync steps and workout calories.

---

### ✨ Key Features
- **100% Offline & Private:** Operates entirely without an internet connection.
- **Barcode Scanner Included:** Free, fast barcode lookup without subscriptions.
- **Intermittent Fasting Timer:** Built-in 14:10, 16:8, 18:6, 20:4, and circadian fasts with physiological stage tracking (Fat burning, Ketosis).
- **AI Meal Estimator:** Describe what you ate in natural language (e.g. *"2 scrambled eggs with avocado toast"*) or take a photo for instant calories & macros.
- **Google Health Connect & Step Sync:** Auto-syncs steps and workout burns to calculate your true Net Calories (Food - Exercise).
- **Home Screen Glanceable Widgets:** Net calories, macro bars, and fasting companion timers right on your Android home screen.
- **Smart Grocery List:** Automatically aggregates ingredients from your meals into sorted supermarket sections.
- **Clinical CSV & Doctor Export:** One-tap export to share your logs with a doctor or dietitian.
- **7 Languages Supported:** English, Spanish, French, German, Urdu, Arabic (RTL), and Hindi.

---

### 📲 Download & Links
- 👉 **Google Play Store:** https://play.google.com/store/apps/details?id=com.caloriefit.app
- 🌐 **Website & Privacy Policy:** https://kashif-malik12.github.io/CalorieFit/

I would love your honest feedback, bug reports, and suggestions for features you'd like to see added next. I'll be in the comments answering questions!
```

---

## 2. For `r/privacy` & `r/degoogle`

* **Post Type:** Text Post (Self-Post)
* **Flair to Select:** `Software` or `Discussion`

**Title:**
> CalorieFit: An offline-first, zero-telemetry calorie & intermittent fasting app for Android (No accounts, embedded SQLite)

**Post Body:**
```markdown
Hi everyone,

Health and diet data is among the most sensitive personal information we generate: weight fluctuations, eating disorders, skipped meals, and biometric markers. Yet mainstream diet trackers (MyFitnessPal, Noom, Lose It!) are packed with third-party analytics SDKs and ad brokers.

I built **CalorieFit** to be a private, local-first alternative for Android:

### 🔒 Privacy & Architecture Breakdown:
- **Zero Cloud Storage:** All user data, food diaries, body weights, and fasts reside locally in an on-device SQLite database.
- **Zero Telemetry / Zero Ads:** No ad IDs, no tracking pixels, and no commercial analytics SDKs embedded in the app.
- **No Sign-In Required:** Opens directly into the diary without requesting an email, phone number, or Google login.
- **PIN & Biometric Lock:** Built-in 4-digit PIN / biometric lock to protect your diary on your physical device.
- **Health Connect Integration:** Uses Android's official Health Connect framework for on-device step & exercise sync without external cloud APIs.
- **Data Portability:** Full CSV and JSON export whenever you want to backup or share your records.

### 💰 Monetization:
- 100% Free. No subscriptions, no locked features, no ads.

- **Google Play:** https://play.google.com/store/apps/details?id=com.caloriefit.app
- **Privacy Policy & Info:** https://kashif-malik12.github.io/CalorieFit/privacy.html

Happy to answer any technical questions about the local storage schema and permissions!
```

---

## 3. For `r/loseit` & `r/CICO`

* **Post Type:** Text Post (Self-Post)
* **Flair to Select:** `Resources` / `Tools` (or general discussion)

**Title:**
> Free, clean, ad-free alternative to MyFitnessPal with fasting timer, AI meal estimation & barcode lookup [CalorieFit]

**Post Body:**
```markdown
Hey everyone!

Like many of you on a CICO (Calories In, Calories Out) journey, I was frustrated by how bloated traditional calorie trackers have become. Having basic features like barcode scanning and fasting tracking paywalled behind expensive monthly subscriptions ($80+/year) made staying consistent harder than it should be.

I created **CalorieFit** as a streamlined, completely free tool for people who just want to get their calories and macros logged quickly without fuss:

- ⚡ **1-Tap Quick Staples:** Log coffee, eggs, or protein shakes in under 2 seconds right from the top of your diary.
- 🤖 **AI Natural Language Estimator:** Type or dictate *"Grilled chicken salad with 2 tbsp vinaigrette"* to get estimated macros immediately.
- ⏳ **Fasting + Calories in One Place:** Seamlessly track 16:8 or 20:4 fasting without needing a separate fasting app like Zero or Fastic.
- 📱 **Home Screen Widgets:** See your remaining calories and protein target every time you unlock your phone.
- 🔒 **No ads, no subscriptions, no accounts required.** All features and barcode scanning are 100% free.

You can check it out on Google Play:
👉 https://play.google.com/store/apps/details?id=com.caloriefit.app

Website: https://kashif-malik12.github.io/CalorieFit/

Hope this helps some of you hit your fitness and fat loss goals! Let me know if you run into any bugs or have feature requests.
```
