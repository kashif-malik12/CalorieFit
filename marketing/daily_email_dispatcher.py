#!/usr/bin/env python3
"""
CalorieFit Daily Social Post Email Dispatcher (Compliant 7-Day Growth Engine)
-----------------------------------------------------------------------------
Pulls Resend API configuration and sends 1 ready-to-click, fully compliant
marketing post per day to ali.kashifmalik@gmail.com.
Each post has a pre-filled 1-click submission link targeting a specific subreddit
with verified flair tags, pricing transparency, and zero-spam safety.
"""

import os
import sys
import json
import time
import shutil
import base64
import subprocess
import urllib.parse
from datetime import date
import requests
from pathlib import Path
from dotenv import dotenv_values

# Ensure project root is in sys.path
ROOT_DIR = Path(__file__).resolve().parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

try:
    from marketing.auto_video_generator import build_video
except ImportError:
    from auto_video_generator import build_video

CALORIE_ENV = ROOT_DIR / ".env"
TRADISTER_ENV = Path("/home/deploy/bin/tradister_outreach/.env")

CONFIG = {}
if TRADISTER_ENV.exists():
    CONFIG.update(dotenv_values(TRADISTER_ENV))
if CALORIE_ENV.exists():
    CONFIG.update(dotenv_values(CALORIE_ENV))

def get_cfg(key, default=None):
    return os.environ.get(key) or CONFIG.get(key) or default

RESEND_API_KEY = get_cfg("RESEND_API_KEY")
SENDER_EMAIL = get_cfg("OUTREACH_SENDER_EMAIL", "kashif@tradister-cloud.com")
SENDER_NAME = "CalorieFit Daily Growth"
TO_EMAIL = "ali.kashifmalik@gmail.com"

BUFFER_API_URL = "https://api.buffer.com"
BUFFER_ACCESS_TOKEN = get_cfg("BUFFER_ACCESS_TOKEN")
BUFFER_CHANNELS = [
    ("Instagram", "instagram", get_cfg("BUFFER_INSTAGRAM_CHANNEL_ID")),
    ("TikTok", "tiktok", get_cfg("BUFFER_TIKTOK_CHANNEL_ID")),
    ("Twitter / X", "twitter", get_cfg("BUFFER_TWITTER_CHANNEL_ID")),
]

PAGES_SYNC_DIR = Path("/home/deploy/.cache/caloriefit_pages_sync")
GITHUB_PUSH_REMOTE = "git@github-push:kashif-malik12/CalorieFit.git"
PUBLIC_BASE_URL = "https://kashif-malik12.github.io/CalorieFit"

LOCAL_STATE_DIR = Path(r"/home/deploy/.config")
if LOCAL_STATE_DIR.exists() and os.access(LOCAL_STATE_DIR, os.W_OK):
    STATE_FILE = LOCAL_STATE_DIR / "daily_post_state.json"
else:
    STATE_FILE = ROOT_DIR / ".daily_post_state.json"

PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.caloriefit.app"
WEBSITE_URL = "https://kashif-malik12.github.io/CalorieFit/"

SCHEDULE = [
    {
        "day": 1,
        "target": "r/androidapps",
        "flair_needed": "Developer",
        "title": "[DEV] CalorieFit - I got tired of $80/year diet subscriptions and ads, so I built a 100% free, offline calorie & fasting tracker (No accounts, no ads)",
        "body": f"""Hey r/androidapps!

A few months ago, I got tired of $80/year subscriptions, paywalled barcode scanners, and intrusive ads on mainstream diet apps. So I built CalorieFit: a 100% free, private, offline calorie & intermittent fasting tracker for Android.

💰 Pricing & Monetization:
• Price: 100% Free
• Ads: Zero ads / No banners / No popups
• Subscriptions / IAP: None ($0)
• Accounts: None required (No email or login)

🛡️ Privacy & Permissions:
• 100% Local-First: All nutrition and fasting logs stay in your phone's SQLite DB.
• Telemetry: Zero third-party ad SDKs or trackers.
• Health Connect: Uses official Android Health Connect locally to sync steps and workout calories.

✨ Key Features:
• 🔒 100% Local-First & Private SQLite database
• 🚫 Free barcode scanner & macro breakdown
• 📸 AI Vision & Natural Language food estimator
• ⏳ Intermittent Fasting Timer (14:10, 16:8, 18:6, 20:4) with ketosis stages
• ⌚ Google Health Connect Sync for true Net Calories
• 📱 Home Screen glanceable widgets
• 📄 CSV / Clinical Doctor export

Google Play: {PLAY_STORE_URL}
Website & Privacy: {WEBSITE_URL}

I'd love your honest feedback and feature suggestions!""",
        "description": "The premier Android apps community (900k+ members). Essential to use the [DEV] tag and select the 'Developer' flair."
    },
    {
        "day": 2,
        "target": "r/CICO",
        "flair_needed": "None / Resource",
        "title": "Tired of paid calorie tracker subscriptions, so I built a 100% free ad-free offline tracker (CalorieFit)",
        "body": f"""Hey everyone!

Like many here doing CICO, I was frustrated by how bloated traditional calorie trackers have become. Having basic features like barcode scanning and macro breakdown locked behind $80/year paywalls made staying consistent harder than it should be.

I created CalorieFit as a completely free, private alternative:
• ⚡ 1-Tap Quick Staples: Log coffee, eggs, or protein shakes in under 2 seconds.
• 🤖 AI Natural Language Estimator: Type or dictate meals to get estimated macros immediately.
• ⏳ Fasting + Calories in One Place: Track 16:8 or 20:4 fasting without needing a second app.
• 📱 Home Screen Widgets: See remaining calories and protein target instantly.
• 🔒 No ads, no subscriptions, no accounts.

Google Play: {PLAY_STORE_URL}
Website: {WEBSITE_URL}

Hope this helps others on their CICO journey!""",
        "description": "Calories In, Calories Out community (300k+ members). High conversion for people looking for free barcode scanning."
    },
    {
        "day": 3,
        "target": "r/intermittentfasting",
        "flair_needed": "Resource / Tool",
        "title": "I built an ad-free fasting tracker + calorie counter in one app so you don't need two subscriptions (CalorieFit)",
        "body": f"""Hey fasting fam!

Most people use one app for fasting (Zero or Fastic) and another for calories (MyFitnessPal), with both charging expensive yearly subscriptions.

I combined both into CalorieFit:
• ⏳ 14:10, 16:8, 18:6, 20:4 and circadian fasts with physiological ketosis stages.
• 📊 Full daily macro & calorie diary with free barcode scanner.
• 🔒 100% Local-First: Zero cloud servers, all logs stay private on your phone.
• 🚫 Zero ads, zero paywalls.

Google Play: {PLAY_STORE_URL}

Would love your thoughts and suggestions!""",
        "description": "900,000+ members doing intermittent fasting. Huge appetite for tools that combine fasting + calorie tracking without ads."
    },
    {
        "day": 4,
        "target": "r/alphaandbetausers",
        "flair_needed": "Android",
        "title": "[Android] CalorieFit - Free, offline-first calorie & fasting tracker with on-device AI food scanning (Seeking feedback)",
        "body": f"""Hey everyone,

I built CalorieFit: a 100% free, offline-first calorie and intermittent fasting tracker for Android.

Most popular diet trackers charge $80/year for basic barcode scanning and inject video ads. I wanted to build a clean, private alternative:
• 🔒 100% Local-First: All logs stay in local SQLite on your phone. No accounts or logins required.
• 🚫 Zero Ads & Zero Paywalls: Free barcode scanner, free macro tracking.
• 📸 AI Vision Food Scanner: On-device plate detection and natural language meal estimator.
• ⏳ Fasting Companion: 14:10, 16:8, 18:6, 20:4 windows with ketosis stages.
• ⌚ Health Connect Sync: Automatically computes Net Calories.

Google Play: {PLAY_STORE_URL}
Website: {WEBSITE_URL}

I would really appreciate your feedback on the user interface, diary logging speed, and any bugs you encounter!""",
        "description": "Subreddit specifically created for developers to share new apps and gather tester feedback. Self-promotion is 100% welcome."
    },
    {
        "day": 5,
        "target": "r/loseit",
        "flair_needed": "Resources / Tools",
        "title": "Free alternative to MyFitnessPal with no ads, barcode paywall, or accounts (CalorieFit)",
        "body": f"""Hey everyone!

Like many of you on a weight loss journey, I was frustrated by how bloated traditional calorie trackers have become. Having basic features like barcode scanning and fasting tracking paywalled behind expensive monthly subscriptions ($80+/year) made staying consistent harder than it should be.

I created CalorieFit as a streamlined, completely free tool for people who just want to get their calories and macros logged quickly without fuss:
• ⚡ 1-Tap Quick Staples: Log coffee, eggs, or protein shakes in under 2 seconds.
• 🤖 AI Natural Language Estimator: Type or dictate meals to get estimated macros immediately.
• ⏳ Fasting + Calories in One Place: Track 16:8 fasting without needing a separate fasting app.
• 📱 Home Screen Widgets: See remaining calories and protein target on your home screen.
• 🔒 No ads, no subscriptions, no accounts required.

Google Play: {PLAY_STORE_URL}

Hope this helps some of you hit your fitness and fat loss goals! Let me know if you run into any bugs or have feature requests.""",
        "description": "4 million members. The largest and most supportive weight loss community on Reddit."
    },
    {
        "day": 6,
        "target": "r/SideProject",
        "flair_needed": "Feedback",
        "title": "I built CalorieFit: A 100% free, offline-first diet & fasting tracker with on-device AI to fight $80/yr subscription bloat",
        "body": f"""Hey r/SideProject!

I spent the last several months building CalorieFit, an offline-first Android app designed to push back against the ridiculous subscription bloat in the health and diet space ($80/year just to scan food barcodes!).

Tech stack & architecture:
• Flutter / Dart with embedded SQLite for instantaneous local-first read/writes.
• On-device ML Kit & natural language parsing for intelligent meal macro estimation.
• Android Health Connect integration for native step & workout synchronization.
• Material 3 UI with dynamic theming and home-screen glanceable widgets.
• 100% free with no ads, zero monetization, and zero telemetry.

Google Play: {PLAY_STORE_URL}
Website: {WEBSITE_URL}

I'd really appreciate feedback on UX, performance, and feature roadmapping!""",
        "description": "Indie developer community (250k+ members). High engagement for tech stack and product feedback."
    },
    {
        "day": 7,
        "target": "r/droidappshowcase",
        "flair_needed": "App Showcase",
        "title": "CalorieFit: Free, offline calorie tracker & fasting timer with camera AI (No ads)",
        "body": f"""Hey Android users!

Check out CalorieFit: a 100% free, zero-ad, private offline tracker for Android.

Key features:
• 🔒 100% Local-First: All nutrition and fasting logs stay in your phone's SQLite DB. No account needed.
• 🚫 Zero Ads & Zero Paywalls: Free barcode scanner, free macro tracking.
• 📸 AI Vision & Natural Language: Camera food scanning and fast text estimator.
• ⏳ Intermittent Fasting Timer: 14:10, 16:8, 18:6, 20:4 windows with ketosis stages.
• ⌚ Google Health Connect Sync: Automatically computes true Net Calories.

Google Play: {PLAY_STORE_URL}
Website: {WEBSITE_URL}

Give it a try and let me know your thoughts!""",
        "description": "Dedicated Android app showcase community for direct downloads."
    }
]

def load_state():
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"last_day_sent": 0}

def save_state(state):
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        print(f"Warning: could not save state to {STATE_FILE}: {e}")

def build_reddit_submit_url(target, title, body):
    sub = target.replace("r/", "")
    params = urllib.parse.urlencode({
        "title": title,
        "text": body
    })
    return f"https://reddit.com/r/{sub}/submit?{params}"

def sync_video_to_github_pages(video_name, max_wait_seconds=120):
    """Pushes generated video + creator.html to GitHub Pages and waits for live 200 OK."""
    public_url = f"{PUBLIC_BASE_URL}/videos/{video_name}"
    if os.environ.get("GITHUB_ACTIONS") == "true":
        return public_url

    local_video = ROOT_DIR / "docs" / "videos" / video_name
    local_creator = ROOT_DIR / "docs" / "creator.html"
    if not local_video.exists():
        print(f"Warning: {local_video} missing, skipping GitHub Pages sync.")
        return public_url

    try:
        if not (PAGES_SYNC_DIR / ".git").exists():
            PAGES_SYNC_DIR.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                ["git", "clone", "--depth", "1", "--branch", "main", GITHUB_PUSH_REMOTE, str(PAGES_SYNC_DIR)],
                check=True,
                capture_output=True,
                text=True,
            )
        else:
            subprocess.run(["git", "-C", str(PAGES_SYNC_DIR), "fetch", "origin", "main"], check=True, capture_output=True, text=True)
            subprocess.run(["git", "-C", str(PAGES_SYNC_DIR), "reset", "--hard", "origin/main"], check=True, capture_output=True, text=True)

        sync_videos_dir = PAGES_SYNC_DIR / "docs" / "videos"
        sync_videos_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(str(local_video), str(sync_videos_dir / video_name))
        if local_creator.exists():
            shutil.copy2(str(local_creator), str(PAGES_SYNC_DIR / "docs" / "creator.html"))

        subprocess.run(["git", "-C", str(PAGES_SYNC_DIR), "config", "user.name", "CalorieFit Autopilot"], check=True)
        subprocess.run(["git", "-C", str(PAGES_SYNC_DIR), "config", "user.email", "ali.kashifmalik@gmail.com"], check=True)
        subprocess.run(["git", "-C", str(PAGES_SYNC_DIR), "add", "docs/videos/", "docs/creator.html"], check=True)
        diff_res = subprocess.run(["git", "-C", str(PAGES_SYNC_DIR), "diff", "--cached", "--quiet"])
        if diff_res.returncode != 0:
            subprocess.run(
                ["git", "-C", str(PAGES_SYNC_DIR), "commit", "-m", f"Auto-deploy daily marketing video asset ({video_name})"],
                check=True,
                capture_output=True,
                text=True,
            )
            subprocess.run(["git", "-C", str(PAGES_SYNC_DIR), "push", "origin", "main"], check=True, capture_output=True, text=True)
            print(f"🚀 Pushed {video_name} to GitHub Pages.")
        else:
            print(f"ℹ️ {video_name} already up to date on GitHub Pages.")
    except Exception as e:
        print(f"Warning: GitHub Pages sync error: {e}")

    # Wait for GitHub Pages CDN to serve the video before calling Buffer
    deadline = time.time() + max_wait_seconds
    while time.time() < deadline:
        try:
            head = requests.head(public_url, timeout=10, allow_redirects=True)
            if head.status_code == 200:
                print(f"🌐 Verified live video URL: {public_url}")
                return public_url
        except Exception:
            pass
        time.sleep(5)

    print(f"Warning: timed out waiting for {public_url} (proceeding anyway).")
    return public_url

def build_tweet_text(video_info):
    """Builds a <= 280 char tweet with title, Play Store link, and hashtags."""
    hashtags = "#CalorieFit #CICO #FitnessApp #Android"
    header = f"{video_info['title']} — 100% Free, Zero Ads, Offline Calorie & Fasting Tracker on Android:"
    tweet = f"{header}\n{PLAY_STORE_URL}\n{hashtags}"
    if len(tweet) <= 280:
        return tweet
    max_header = 280 - len(f"\n{PLAY_STORE_URL}\n{hashtags}") - 1
    return f"{header[:max_header].rstrip()}…\n{PLAY_STORE_URL}\n{hashtags}"

def post_to_buffer(video_info, video_public_url):
    """Queues today's video post to Instagram, TikTok, and Twitter/X via Buffer GraphQL."""
    if not BUFFER_ACCESS_TOKEN:
        print("BUFFER_ACCESS_TOKEN not configured; skipping Buffer auto-queue.")
        return []

    mutation = """
    mutation CreatePost($input: CreatePostInput!) {
      createPost(input: $input) {
        ... on PostActionSuccess {
          post {
            id
            status
            dueAt
          }
        }
        ... on NotFoundError { message }
        ... on UnauthorizedError { message }
        ... on UnexpectedError { message }
        ... on RestProxyError { message }
        ... on LimitReachedError { message }
        ... on InvalidInputError { message }
      }
    }
    """
    headers = {
        "Authorization": f"Bearer {BUFFER_ACCESS_TOKEN}",
        "Content-Type": "application/json",
    }

    results = []
    for label, service, channel_id in BUFFER_CHANNELS:
        if not channel_id:
            continue

        post_input = {
            "channelId": channel_id,
            "schedulingType": "automatic",
            "mode": "addToQueue",
            "assets": [
                {
                    "video": {
                        "url": video_public_url,
                        "metadata": {"title": video_info["title"]},
                    }
                }
            ],
        }

        if service == "instagram":
            post_input["text"] = f"{video_info['caption']} #reels #instagramreels"
            post_input["metadata"] = {"instagram": {"type": "reel", "shouldShareToFeed": True}}
        elif service == "tiktok":
            post_input["text"] = video_info["caption"]
            post_input["metadata"] = {"tiktok": {"title": video_info["title"]}}
        elif service == "twitter":
            post_input["text"] = build_tweet_text(video_info)
        else:
            post_input["text"] = video_info["caption"]

        try:
            res = requests.post(
                BUFFER_API_URL,
                headers=headers,
                json={"query": mutation, "variables": {"input": post_input}},
                timeout=30,
            )
            data = res.json()
            if data.get("errors"):
                err = "; ".join(e.get("message", str(e)) for e in data["errors"])
                print(f"❌ Buffer GraphQL error ({label}): {err}")
                results.append({"platform": label, "success": False, "error": err})
                continue

            payload = (data.get("data") or {}).get("createPost") or {}
            if payload.get("post"):
                post = payload["post"]
                print(f"✅ Buffer queued {label}: id={post['id']} status={post.get('status')} dueAt={post.get('dueAt')}")
                results.append({
                    "platform": label,
                    "success": True,
                    "post_id": post["id"],
                    "status": post.get("status"),
                    "due_at": post.get("dueAt"),
                })
            else:
                err = payload.get("message") or str(payload)
                print(f"❌ Buffer rejected {label}: {err}")
                results.append({"platform": label, "success": False, "error": err})
        except Exception as e:
            print(f"❌ Buffer exception ({label}): {e}")
            results.append({"platform": label, "success": False, "error": str(e)})

    return results

def render_buffer_status_html(buffer_results):
    """Renders a rich Buffer schedule card for the email."""
    if not buffer_results:
        return (
            '<div style="background:#fef2f2;border:1px solid #fecaca;border-radius:10px;padding:16px;'
            'margin-bottom:22px;font-size:13px;color:#991b1b;">'
            '⚠️ <strong>Buffer Auto-Queue:</strong> Not configured or no channels ran — post manually.'
            '</div>'
        )

    platform_icons = {"Instagram": "📸", "TikTok": "🎵", "Twitter": "🐦", "X": "🐦"}
    rows = []
    all_ok = all(r.get("success") for r in buffer_results)
    for r in buffer_results:
        icon = platform_icons.get(r["platform"], "📲")
        if r.get("success"):
            due_raw = r.get("due_at") or ""
            try:
                from datetime import datetime as _dt
                due_dt = _dt.strptime(due_raw[:19], "%Y-%m-%dT%H:%M:%S")
                due_str = due_dt.strftime("%b %-d · %H:%M UTC")
            except Exception:
                due_str = due_raw or "Next queue slot"
            rows.append(
                f'<tr>'
                f'<td style="padding:8px 12px;border-bottom:1px solid #d1fae5;">{icon} <strong>{r["platform"]}</strong></td>'
                f'<td style="padding:8px 12px;border-bottom:1px solid #d1fae5;color:#065f46;">✅ Scheduled</td>'
                f'<td style="padding:8px 12px;border-bottom:1px solid #d1fae5;font-family:monospace;font-size:12px;">{due_str}</td>'
                f'</tr>'
            )
        else:
            rows.append(
                f'<tr>'
                f'<td style="padding:8px 12px;border-bottom:1px solid #fecaca;">{icon} <strong>{r["platform"]}</strong></td>'
                f'<td colspan="2" style="padding:8px 12px;border-bottom:1px solid #fecaca;color:#991b1b;">❌ {r.get("error","Failed")}</td>'
                f'</tr>'
            )

    header_bg = "#ecfdf5" if all_ok else "#fffbeb"
    header_border = "#6ee7b7" if all_ok else "#fcd34d"
    headline = "🤖 Buffer Auto-Posted — Nothing To Do!" if all_ok else "⚠️ Buffer Partial — Check Below"
    sub = "Your video has been queued to all channels automatically." if all_ok else "Some channels failed — manual upload may be needed."

    return (
        f'<div style="background:{header_bg};border:1px solid {header_border};border-radius:12px;'
        f'padding:18px 20px;margin-bottom:22px;">'
        f'<div style="font-size:16px;font-weight:700;color:#065f46;margin-bottom:4px;">{headline}</div>'
        f'<div style="font-size:13px;color:#374151;margin-bottom:14px;">{sub}</div>'
        f'<table style="width:100%;border-collapse:collapse;background:#ffffff;border-radius:8px;overflow:hidden;'
        f'border:1px solid #a7f3d0;font-size:13px;">'
        f'<thead><tr style="background:#d1fae5;">'
        f'<th style="padding:8px 12px;text-align:left;color:#065f46;">Platform</th>'
        f'<th style="padding:8px 12px;text-align:left;color:#065f46;">Status</th>'
        f'<th style="padding:8px 12px;text-align:left;color:#065f46;">Scheduled For</th>'
        f'</tr></thead>'
        f'<tbody>{"".join(rows)}</tbody>'
        f'</table>'
        f'</div>'
    )

def send_post_email(item, video_info=None, buffer_results=None):
    if not RESEND_API_KEY:
        print("Missing RESEND_API_KEY")
        return False

    if video_info is None:
        print(f"🎬 Auto-generating video for Day {item['day']}...")
        try:
            video_info = build_video(day=item['day'])
        except Exception as e:
            print(f"Video generation error: {e}")
            video_info = {
                "name": f"CalorieFit_Video_Day{item['day']}.mp4",
                "path": str(ROOT_DIR / "docs" / "videos" / f"CalorieFit_Video_Day{item['day']}.mp4"),
                "title": "CalorieFit Promo",
                "caption": "Tired of $80/year diet app paywalls 🤦‍♂️ Built an offline-first tracker with zero ads, free barcode scanning & fasting timers. Link in bio! #myfitnesspal #calorietracker #cico #fitnessjourney #loseweight #indiedev"
            }

    submit_url = build_reddit_submit_url(item["target"], item["title"], item["body"])
    buffer_banner_html = render_buffer_status_html(buffer_results or [])

    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; color: #1e293b; padding: 20px; }}
        .card {{ background: #ffffff; border-radius: 12px; padding: 24px; max-width: 640px; margin: 0 auto; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }}
        .badge {{ display: inline-block; background: #e0e7ff; color: #3730a3; padding: 5px 12px; border-radius: 6px; font-size: 13px; font-weight: bold; margin-bottom: 12px; }}
        .badge-video {{ background: #fdf2f8; color: #9d174d; border: 1px solid #fbcfe8; }}
        .badge-reddit {{ background: #ffedd5; color: #c2410c; border: 1px solid #fed7aa; }}
        .flair-pill {{ display: inline-block; background: #fef3c7; color: #92400e; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 600; border: 1px solid #fde68a; }}
        .section-box {{ background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 18px; margin-bottom: 20px; }}
        .warning-box {{ background: #fffbeb; border-left: 4px solid #f59e0b; padding: 12px; border-radius: 6px; margin: 15px 0; font-size: 13px; color: #78350f; }}
        h2 {{ color: #0f172a; margin-top: 6px; margin-bottom: 8px; }}
        h3 {{ color: #0f172a; margin-top: 0; font-size: 17px; }}
        .btn {{ display: inline-block; background: #ff4500; color: #ffffff !important; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 16px; margin: 16px 0; text-align: center; }}
        .btn:hover {{ background: #e03d00; }}
        .path {{ font-family: Consolas, monospace; background: #e2e8f0; padding: 3px 6px; border-radius: 4px; font-size: 12px; word-break: break-all; color: #0f172a; font-weight: bold; }}
        .caption-code {{ display: block; background: #f1f5f9; padding: 12px; border-radius: 6px; font-size: 13px; line-height: 1.5; color: #334155; margin-top: 8px; border: 1px solid #cbd5e1; }}
        .preview {{ background: #f1f5f9; padding: 14px; border-radius: 8px; font-size: 13px; line-height: 1.5; white-space: pre-wrap; color: #334155; }}
        .footer {{ font-size: 12px; color: #64748b; margin-top: 24px; text-align: center; border-top: 1px solid #e2e8f0; padding-top: 14px; }}
      </style>
    </head>
    <body>
      <div class="card">
        <!-- HEADER -->
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:4px;">
          <span class="badge">🚀 CalorieFit Growth Engine</span>
          <span class="badge" style="background:#fef3c7;color:#92400e;border:1px solid #fde68a;">Day {item['day']} of {len(SCHEDULE)}</span>
        </div>
        <h2 style="margin-top:10px;margin-bottom:4px;">{video_info['title']}</h2>
        <p style="color:#64748b;font-size:13px;margin-top:0;margin-bottom:20px;">
          Your daily CalorieFit growth dispatch — Buffer has queued your social posts automatically.
          Your only manual action today is the Reddit post below. 👇
        </p>

        <!-- BUFFER STATUS CARD -->
        {buffer_banner_html}

        <!-- PART 1: VIDEO BACKUP (manual fallback) -->
        <div class="section-box">
          <span class="badge badge-video">🎬 Video: Buffer Is Handling It — Backup Links Below</span>
          <p style="font-size:13px;color:#475569;margin-top:10px;margin-bottom:12px;">
            Buffer will auto-publish to Instagram, TikTok &amp; Twitter at the times shown above.
            If you ever need to post manually or grab the file for YouTube Shorts:
          </p>

          <div style="text-align:center;margin:12px 0;">
            <a href="https://kashif-malik12.github.io/CalorieFit/creator.html" class="btn"
               style="background:#0284c7;color:#ffffff !important;font-size:15px;padding:13px 22px;
                      margin-bottom:10px;display:block;border-radius:10px;" target="_blank">
              🌐 Open Creator Hub (Download &amp; Preview)
            </a>
            <a href="https://kashif-malik12.github.io/CalorieFit/videos/{video_info['name']}" class="btn"
               style="background:#10B981;color:#042F2E !important;font-size:14px;padding:12px 22px;
                      display:block;border-radius:10px;" target="_blank">
              📥 Direct MP4 Download
            </a>
          </div>

          <p style="font-size:13px;font-weight:bold;color:#0f172a;margin-top:14px;margin-bottom:4px;">
            📋 Caption &amp; Hashtags (copy-paste for YouTube Shorts or manual posts):
          </p>
          <div class="caption-code">{video_info['caption']} #reels #instagramreels #explorepage</div>
        </div>

        <!-- PART 2: REDDIT (manual action required) -->
        <div class="section-box">
          <span class="badge badge-reddit">🔥 Action Required: Post to Reddit Today</span>
          <h3 style="margin-top:10px;">Subreddit: {item['target']}</h3>
          <p style="color:#64748b;font-size:13px;margin-bottom:12px;">{item['description']}</p>

          <div class="warning-box">
            ⚠️ <strong>Checklist before posting:</strong><br>
            • Use <strong>Post tab (Text)</strong> — not Link or Image.<br>
            • Add flair: <span class="flair-pill">{item['flair_needed']}</span>
          </div>

          <div style="text-align:center;margin:16px 0;">
            <a href="{submit_url}" class="btn" target="_blank">👉 Open Pre-Filled Reddit Post</a>
          </div>

          <p style="font-size:13px;color:#334155;margin-bottom:6px;"><strong>Title:</strong> {item['title']}</p>
          <div class="preview">{item['body']}</div>
        </div>

        <div class="footer">
          CalorieFit Daily Autopilot Growth System &nbsp;•&nbsp; 🤖 Buffer auto-posts video &nbsp;•&nbsp; ✍️ You post Reddit
        </div>
      </div>
    </body>
    </html>
    """

    attachments = []
    if os.path.exists(video_info.get("path", "")):
        try:
            with open(video_info["path"], "rb") as f:
                b64_content = base64.b64encode(f.read()).decode("utf-8")
            attachments.append({
                "filename": video_info["name"],
                "content": b64_content
            })
            print(f"📎 Attached {video_info['name']} directly to email.")
        except Exception as e:
            print(f"Attachment error: {e}")

    payload = {
        "from": f"{SENDER_NAME} <{SENDER_EMAIL}>",
        "to": [TO_EMAIL],
        "subject": f"🤖 CalorieFit Day {item['day']} | Buffer Posted ✅ + Reddit Action Needed 👉 {item['target']}",
        "html": html_content
    }
    if attachments:
        payload["attachments"] = attachments

    headers = {
        "Authorization": f"Bearer {RESEND_API_KEY}",
        "Content-Type": "application/json"
    }

    try:
        res = requests.post("https://api.resend.com/emails", headers=headers, json=payload, timeout=15)
        print(f"Dispatched Day {item['day']} ({item['target']}) -> Status {res.status_code}")
        if res.status_code not in (200, 201):
            print(f"Resend Error Response: {res.text}")
        return res.status_code in (200, 201)
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False

def run_next(force=False):
    today_str = str(date.today())
    state = load_state()
    
    if not force and state.get("last_sent_date") == today_str:
        print(f"Post already sent today ({today_str}). Use --force to send again.")
        return

    if state.get("last_day_sent", 0) > 0:
        current_day = (state["last_day_sent"] % len(SCHEDULE)) + 1
    elif os.environ.get("GITHUB_ACTIONS") == "true":
        current_day = (date.today().toordinal() % len(SCHEDULE)) + 1
    else:
        current_day = 1
    
    item = next((s for s in SCHEDULE if s["day"] == current_day), SCHEDULE[0])

    print(f"🎬 Auto-generating video for Day {item['day']}...")
    try:
        video_info = build_video(day=item["day"])
    except Exception as e:
        print(f"Video generation error: {e}")
        video_info = {
            "name": f"CalorieFit_Video_Day{item['day']}.mp4",
            "path": str(ROOT_DIR / "docs" / "videos" / f"CalorieFit_Video_Day{item['day']}.mp4"),
            "title": "CalorieFit Promo",
            "caption": "Tired of $80/year diet app paywalls 🤦‍♂️ Built an offline-first tracker with zero ads, free barcode scanning & fasting timers. Link in bio! #myfitnesspal #calorietracker #cico #fitnessjourney #loseweight #indiedev",
        }

    video_public_url = sync_video_to_github_pages(video_info["name"])
    buffer_results = post_to_buffer(video_info, video_public_url)

    success = send_post_email(item, video_info=video_info, buffer_results=buffer_results)
    if success or any(r.get("success") for r in buffer_results):
        state["last_day_sent"] = current_day
        state["last_sent_date"] = today_str
        save_state(state)
        print(f"Successfully processed Day {current_day} ({item['target']}).")

if __name__ == "__main__":
    if len(sys.argv) > 1 and ("--next" in sys.argv or "--force" in sys.argv):
        force_send = "--force" in sys.argv
        run_next(force=force_send)
    else:
        state = load_state()
        print(f"Current state: Last day sent was Day {state.get('last_day_sent', 0)} on {state.get('last_sent_date', 'N/A')}")
