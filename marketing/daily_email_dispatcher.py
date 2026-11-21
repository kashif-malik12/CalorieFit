#!/usr/bin/env python3
"""
CalorieFit Daily Social Post Email Dispatcher
---------------------------------------------
Pulls Resend API configuration from the Tradister project and sends
1 ready-to-click marketing post per day to ali.kashifmalik@gmail.com.
Each post has a pre-filled 1-click submission link targeting a specific subreddit.
"""

import os
import sys
import json
import requests
from pathlib import Path
from dotenv import dotenv_values

TRADISTER_ENV = r"E:\Gdrive\1Business\1a Tradister IT SASU\tradister-finops-cloud\.env"
CONFIG = dotenv_values(TRADISTER_ENV) if os.path.exists(TRADISTER_ENV) else {}

RESEND_API_KEY = CONFIG.get("RESEND_API_KEY") or os.environ.get("RESEND_API_KEY")
SENDER_EMAIL = CONFIG.get("OUTREACH_SENDER_EMAIL") or "kashif@tradister-cloud.com"
SENDER_NAME = "CalorieFit Daily Growth"
TO_EMAIL = "ali.kashifmalik@gmail.com"

STATE_FILE = Path(r"C:\Users\Kashif Malik\.gemini\antigravity\secrets\daily_post_state.json")

SCHEDULE = [
    {
        "day": 1,
        "target": "r/droidappshowcase",
        "title": "CalorieFit: Free, offline calorie tracker with camera AI",
        "link": "https://reddit.com/r/droidappshowcase/submit?title=CalorieFit%3A%20Free%2C%20offline%20calorie%20tracker%20with%20camera%20AI&text=I%20got%20tired%20of%20%2480%2Fyear%20subscriptions%20on%20calorie%20trackers%2C%20so%20I%20spent%20the%20last%20few%20months%20building%20CalorieFit%3A%20a%20100%25%20free%2C%20zero-ad%2C%20private%20offline%20tracker%20for%20Android.%0A%0AKey%20features%3A%0A%E2%80%A2%20%F0%9F%94%92%20100%25%20Local-First%3A%20All%20nutrition%20and%20fasting%20logs%20stay%20in%20your%20phone's%20SQLite%20DB.%20No%20account%20or%20email%20needed.%0A%E2%80%A2%20%F0%9F%9A%AB%20Zero%20Ads%20%26%20Zero%20Paywalls%3A%20Free%20barcode%20scanner%2C%20free%20macro%20tracking.%0A%E2%80%A2%20%F0%9F%93%B8%20AI%20Vision%20Food%20Scanner%3A%20On-device%20ML%20camera%20scanner%20to%20detect%20meal%20plates%2C%20calories%2C%20and%20macros%20with%20smart%20non-food%20filtering.%0A%E2%80%A2%20%E2%8F%B3%20Intermittent%20Fasting%20Timer%3A%2016%3A8%2C%2018%3A6%2C%2020%3A4%20windows%20with%20ketosis%20stages.%0A%E2%80%A2%20%F0%9F%94%A5%20Front-Page%20Streak%20Challenges%3A%20Pick%20your%20habit%20goal%20(1-day%20kickstart%2C%2010-day%20challenge%2C%20or%20custom).%0A%E2%80%A2%20%E2%8C%9A%20Google%20Health%20Connect%20Sync%3A%20Automatically%20computes%20true%20Net%20Calories.%0A%0AGoogle%20Play%3A%20https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.caloriefit.app%0AWebsite%3A%20https%3A%2F%2Fkashif-malik12.github.io%2FCalorieFit%2F",
        "description": "Android app showcase subreddit. Great for tech feedback and early Android adopters."
    },
    {
        "day": 2,
        "target": "r/CICO",
        "title": "Tired of paid calorie tracker subscriptions, so I built a 100% free ad-free offline tracker (CalorieFit)",
        "link": "https://reddit.com/r/CICO/submit?title=Tired%20of%20paid%20calorie%20tracker%20subscriptions%2C%20so%20I%20built%20a%20100%25%20free%20ad-free%20offline%20tracker%20(CalorieFit)&text=Like%20many%20here%20doing%20CICO%2C%20I%20got%20tired%20of%20apps%20charging%20%2480%2Fyear%20just%20to%20scan%20barcodes%20and%20macros.%0A%0ASo%20I%20built%20CalorieFit%20for%20Android%3A%0A%E2%80%A2%20100%25%20Free%20%26%20No%20Ads%0A%E2%80%A2%20All%20data%20stored%20locally%20on%20your%20device%20(no%20accounts%2C%20works%20offline)%0A%E2%80%A2%20On-device%20AI%20camera%20food%20scanner%20and%20natural%20language%20estimator%0A%E2%80%A2%20Intermittent%20fasting%20timer%20%2B%20Google%20Health%20Connect%20sync%0A%0AIt's%20free%20on%20Google%20Play%3A%20https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.caloriefit.app%0A%0AHope%20it%20helps%20others%20on%20their%20CICO%20journey!",
        "description": "Calories In, Calories Out community (300k members). Perfect audience seeking free barcode and macro tracking."
    },
    {
        "day": 3,
        "target": "r/intermittentfasting",
        "title": "I built an ad-free fasting tracker + calorie counter in one app so you don't need two subscriptions (CalorieFit)",
        "link": "https://reddit.com/r/intermittentfasting/submit?title=I%20built%20an%20ad-free%20fasting%20tracker%20%2B%20calorie%20counter%20in%20one%20app%20so%20you%20don't%20need%20two%20subscriptions%20(CalorieFit)&text=Hey%20fasting%20fam!%20Most%20people%20use%20one%20app%20for%20fasting%20(Zero)%20and%20another%20for%20calories%20(MyFitnessPal)%2C%20both%20charging%20expensive%20subscriptions.%0A%0AI%20combined%20both%20into%20CalorieFit%3A%0A%E2%80%A2%2016%3A8%2C%2018%3A6%2C%2020%3A4%20and%20custom%20fasting%20timers%20with%20ketosis%20stages%0A%E2%80%A2%20Full%20macro%20%26%20calorie%20budget%20diary%20with%20AI%20camera%20scanning%0A%E2%80%A2%20100%25%20Free%2C%20zero%20ads%2C%20all%20data%20stays%20private%20on%20your%20phone.%0A%0AGoogle%20Play%3A%20https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.caloriefit.app",
        "description": "900,000+ members doing 16:8 and 20:4 fasting who hate paying for Zero or Simple subscriptions."
    },
    {
        "day": 4,
        "target": "r/privacy",
        "title": "CalorieFit: An offline-first, local SQLite calorie & fasting tracker with zero tracking telemetry",
        "link": "https://reddit.com/r/privacy/submit?title=CalorieFit%3A%20An%20offline-first%2C%20local%20SQLite%20calorie%20%26%20fasting%20tracker%20with%20zero%20tracking%20telemetry&text=Mainstream%20health%20apps%20routinely%20share%20intimate%20weight%20and%20habit%20data%20with%20data%20brokers.%0A%0AI%20wanted%20a%20diet%20tracker%20that%20respects%20digital%20rights%2C%20so%20I%20built%20CalorieFit%3A%0A%E2%80%A2%20No%20accounts%20or%20emails%20collected%0A%E2%80%A2%20All%20logs%20stay%20in%20local%20SQLite%20on-device%0A%E2%80%A2%20AI%20food%20scanner%20runs%20on-device%20using%20Google%20ML%20Kit%20without%20cloud%20photo%20uploads%0A%E2%80%A2%20Zero%20ad%20SDKs%20or%20trackers%0A%0AGoogle%20Play%3A%20https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.caloriefit.app%0AWebsite%3A%20https%3A%2F%2Fkashif-malik12.github.io%2FCalorieFit%2F",
        "description": "Privacy-focused users who refuse cloud trackers and demand offline-only apps."
    },
    {
        "day": 5,
        "target": "r/loseit",
        "title": "Free alternative to MyFitnessPal with no ads or barcode paywall (CalorieFit)",
        "link": "https://reddit.com/r/loseit/submit?title=Free%20alternative%20to%20MyFitnessPal%20with%20no%20ads%20or%20barcode%20paywall%20(CalorieFit)&text=Hi%20everyone%2C%20like%20many%20here%20trying%20to%20stay%20consistent%20with%20weight%20loss%2C%20the%20recent%20paywalls%20and%20video%20ads%20on%20diet%20apps%20were%20driving%20me%20crazy.%0A%0ASo%20I%20built%20CalorieFit%20as%20a%20free%20indie%20alternative%20for%20Android%3A%0A%E2%80%A2%20Free%20barcode%20scanner%20%26%20camera%20food%20AI%0A%E2%80%A2%20Zero%20ads%2C%20works%20offline%0A%E2%80%A2%20Fasting%20timer%20%2B%20streak%20challenge%20habits%0A%0APlay%20Store%3A%20https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.caloriefit.app%0A%0AHope%20it%20helps%20your%20journey!",
        "description": "4 million members. The largest weight loss support group on the internet."
    }
]

def load_state():
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"last_day_sent": 1}

def save_state(state):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)

def send_post_email(item):
    if not RESEND_API_KEY:
        print("Missing RESEND_API_KEY")
        return False

    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; color: #1e293b; padding: 20px; }}
        .card {{ background: #ffffff; border-radius: 12px; padding: 24px; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; }}
        .badge {{ display: inline-block; background: #e0e7ff; color: #3730a3; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: bold; margin-bottom: 12px; }}
        h2 {{ color: #0f172a; margin-top: 0; }}
        .btn {{ display: inline-block; background: #ff4500; color: #ffffff !important; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 16px; margin: 20px 0; }}
        .preview {{ background: #f1f5f9; padding: 14px; border-radius: 8px; font-size: 13px; line-height: 1.5; }}
        .footer {{ font-size: 12px; color: #64748b; margin-top: 20px; text-align: center; }}
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">🔥 Reddit Post Day {item['day']} • {item['target']}</span>
        <h2>Today's Post: {item['target']}</h2>
        <p>{item['description']}</p>
        
        <div style="text-align: center;">
          <a href="{item['link']}" class="btn" target="_blank">👉 Click to Publish on Reddit (5 Seconds)</a>
        </div>

        <p style="font-size: 13px; color: #475569;"><strong>Title:</strong> {item['title']}</p>

        <div class="footer">
          CalorieFit Daily Growth Automation • 1 Post Per Day
        </div>
      </div>
    </body>
    </html>
    """

    payload = {
        "from": f"{SENDER_NAME} <{SENDER_EMAIL}>",
        "to": [TO_EMAIL],
        "subject": f"🔥 CalorieFit Post Day {item['day']}: {item['target']} (Ready to publish!)",
        "html": html_content
    }

    headers = {
        "Authorization": f"Bearer {RESEND_API_KEY}",
        "Content-Type": "application/json"
    }

    res = requests.post("https://api.resend.com/emails", headers=headers, json=payload)
    print(f"Dispatched Day {item['day']} ({item['target']}) -> Status {res.status_code}")
    return res.status_code == 200

def run_next():
    state = load_state()
    current_day = state.get("last_day_sent", 0) + 1
    
    item = next((s for s in SCHEDULE if s["day"] == current_day), None)
    if not item:
        print("Schedule complete or reset needed.")
        item = SCHEDULE[0]
        current_day = 1

    success = send_post_email(item)
    if success:
        state["last_day_sent"] = current_day
        save_state(state)
        print(f"Successfully sent Day {current_day} email.")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--next":
        run_next()
    else:
        state = load_state()
        print(f"Current state: Last day sent was Day {state.get('last_day_sent', 0)}")
