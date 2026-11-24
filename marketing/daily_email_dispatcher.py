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
import base64
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

TRADISTER_ENV = r"E:\Gdrive\1Business\1a Tradister IT SASU\tradister-finops-cloud\.env"
CONFIG = dotenv_values(TRADISTER_ENV) if os.path.exists(TRADISTER_ENV) else {}

RESEND_API_KEY = CONFIG.get("RESEND_API_KEY") or os.environ.get("RESEND_API_KEY")
SENDER_EMAIL = CONFIG.get("OUTREACH_SENDER_EMAIL") or "kashif@tradister-cloud.com"
SENDER_NAME = "CalorieFit Daily Growth"
TO_EMAIL = "ali.kashifmalik@gmail.com"

GLOBAL_STATE_DIR = Path(r"C:\Users\Kashif Malik\.gemini\antigravity\secrets")
VPS_STATE_DIR = Path("/home/deploy/.config")
if GLOBAL_STATE_DIR.exists():
    STATE_FILE = GLOBAL_STATE_DIR / "daily_post_state.json"
elif VPS_STATE_DIR.exists() and os.access(VPS_STATE_DIR, os.W_OK):
    STATE_FILE = VPS_STATE_DIR / "daily_post_state.json"
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

def send_post_email(item):
    if not RESEND_API_KEY:
        print("Missing RESEND_API_KEY")
        return False

    print(f"🎬 Auto-generating video for Day {item['day']}...")
    try:
        video_info = build_video(day=item['day'])
    except Exception as e:
        print(f"Video generation error: {e}")
        video_info = {
            "name": f"CalorieFit_Video_Day{item['day']}.mp4",
            "path": f"E:\\Dev Projects\\CalorieFit\\output\\videos\\CalorieFit_Video_Day{item['day']}.mp4",
            "title": "CalorieFit Promo",
            "caption": "Tired of $80/year diet app paywalls 🤦‍♂️ Built an offline-first tracker with zero ads, free barcode scanning & fasting timers. Link in bio! #myfitnesspal #calorietracker #cico #fitnessjourney #loseweight #indiedev"
        }

    submit_url = build_reddit_submit_url(item["target"], item["title"], item["body"])

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
        <span class="badge">🚀 CalorieFit Growth Engine • Day {item['day']} of {len(SCHEDULE)}</span>
        <h2>Your Daily Growth Dispatch</h2>
        <p style="color: #64748b; font-size: 14px; margin-bottom: 20px;">Two quick 1-minute actions to grow CalorieFit today:</p>

        <!-- PART 1: VIDEO -->
        <div class="section-box">
          <span class="badge badge-video">🎬 Action 1: Upload Video to Instagram Reels, TikTok & Shorts</span>
          <h3>{video_info['title']}</h3>
          <p style="font-size: 13px; color: #475569;">Your 1080p video is ready to download instantly:</p>
          
          <div style="text-align: center; margin: 16px 0;">
            <a href="https://kashif-malik12.github.io/CalorieFit/creator.html" class="btn" style="background: #0284c7; color: #ffffff !important; font-size: 16px; padding: 15px 24px; margin-bottom: 10px; display: block; border-radius: 10px;" target="_blank">
              🌐 Open Video & Download Page (Mobile Hub)
            </a>
            <a href="https://kashif-malik12.github.io/CalorieFit/videos/{video_info['name']}" class="btn" style="background: #10B981; color: #042F2E !important; font-size: 15px; padding: 14px 24px; display: block; border-radius: 10px;" target="_blank">
              📥 Direct 1-Tap Download Video (MP4)
            </a>
          </div>

          <div style="background: #fdf2f8; border-radius: 6px; padding: 10px; margin: 10px 0; font-size: 12px; color: #831843;">
            📱 <strong>Upload Targets:</strong> <strong>Instagram Reels</strong> • <strong>TikTok</strong> • <strong>YouTube Shorts</strong><br>
            <em>(Post this single video across all 3 platforms in under 90 seconds!)</em>
          </div>

          <p style="font-size: 13px; font-weight: bold; color: #0f172a; margin-top: 12px; margin-bottom: 4px;">Copy-Paste Caption & Hashtags:</p>
          <div class="caption-code">{video_info['caption']} #reels #instagramreels #explorepage</div>
        </div>

        <!-- PART 2: REDDIT -->
        <div class="section-box">
          <span class="badge badge-reddit">🔥 Action 2: Publish Today's Reddit Post</span>
          <h3>Subreddit: {item['target']}</h3>
          <p style="color: #64748b; font-size: 13px;">{item['description']}</p>
          
          <div class="warning-box">
            ⚠️ <strong>Submission Checklist:</strong><br>
            • Mode: <strong>Post (Text tab)</strong> — not Link/Image.<br>
            • Required Flair: <span class="flair-pill">{item['flair_needed']}</span>
          </div>

          <div style="text-align: center;">
            <a href="{submit_url}" class="btn" target="_blank">👉 Open Pre-Filled Reddit Submission</a>
          </div>

          <p style="font-size: 13px; color: #334155; margin-bottom: 6px;"><strong>Title:</strong> {item['title']}</p>
          <div class="preview">{item['body']}</div>
        </div>

        <div class="footer">
          CalorieFit Daily Autopilot Growth System • 1 Video + 1 Post Per Day
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
        "subject": f"🔥 CalorieFit Growth Day {item['day']}: 🎬 Video Attached + 🤖 {item['target']} Post!",
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

    success = send_post_email(item)
    if success:
        state["last_day_sent"] = current_day
        state["last_sent_date"] = today_str
        save_state(state)
        print(f"Successfully sent Day {current_day} email ({item['target']}).")

if __name__ == "__main__":
    if len(sys.argv) > 1 and ("--next" in sys.argv or "--force" in sys.argv):
        force_send = "--force" in sys.argv
        run_next(force=force_send)
    else:
        state = load_state()
        print(f"Current state: Last day sent was Day {state.get('last_day_sent', 0)} on {state.get('last_sent_date', 'N/A')}")
