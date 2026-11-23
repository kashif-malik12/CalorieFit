#!/usr/bin/env python3
"""
CalorieFit Action Email Dispatcher
----------------------------------
Sends direct, actionable emails to ali.kashifmalik@gmail.com with exact
instructions, file paths, and 1-click links for each task.
"""

import os
import sys
import json
import requests
from dotenv import dotenv_values

TRADISTER_ENV = r"E:\Gdrive\1Business\1a Tradister IT SASU\tradister-finops-cloud\.env"
CONFIG = dotenv_values(TRADISTER_ENV) if os.path.exists(TRADISTER_ENV) else {}

RESEND_API_KEY = CONFIG.get("RESEND_API_KEY") or os.environ.get("RESEND_API_KEY")
SENDER_EMAIL = CONFIG.get("OUTREACH_SENDER_EMAIL") or "kashif@tradister-cloud.com"
SENDER_NAME = "CalorieFit Assistant"
TO_EMAIL = "ali.kashifmalik@gmail.com"

def send_custom_action_email(subject, title, badge, action_text, button_text, button_url, details_html):
    if not RESEND_API_KEY:
        print("Missing RESEND_API_KEY")
        return False

    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #f8fafc; color: #1e293b; padding: 20px; }}
        .card {{ background: #ffffff; border-radius: 12px; padding: 26px; max-width: 620px; margin: 0 auto; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }}
        .badge {{ display: inline-block; background: #e0e7ff; color: #3730a3; padding: 5px 12px; border-radius: 6px; font-size: 13px; font-weight: bold; margin-bottom: 12px; }}
        h2 {{ color: #0f172a; margin-top: 6px; margin-bottom: 10px; }}
        .btn {{ display: inline-block; background: #2563eb; color: #ffffff !important; padding: 14px 28px; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 16px; margin: 18px 0; }}
        .btn:hover {{ background: #1d4ed8; }}
        .box {{ background: #f1f5f9; padding: 16px; border-radius: 8px; font-size: 14px; line-height: 1.6; margin: 14px 0; }}
        .path {{ font-family: Consolas, monospace; background: #e2e8f0; padding: 2px 6px; border-radius: 4px; font-size: 12px; word-break: break-all; }}
        .footer {{ font-size: 12px; color: #64748b; margin-top: 24px; text-align: center; border-top: 1px solid #e2e8f0; padding-top: 14px; }}
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">{badge}</span>
        <h2>{title}</h2>
        <p style="color: #475569; font-size: 15px;">{action_text}</p>
        
        {details_html}

        <div style="text-align: center;">
          <a href="{button_url}" class="btn" target="_blank">{button_text}</a>
        </div>

        <div class="footer">
          CalorieFit Assistant • Direct Action Dispatcher
        </div>
      </div>
    </body>
    </html>
    """

    payload = {
        "from": f"{SENDER_NAME} <{SENDER_EMAIL}>",
        "to": [TO_EMAIL],
        "subject": subject,
        "html": html_content
    }

    headers = {
        "Authorization": f"Bearer {RESEND_API_KEY}",
        "Content-Type": "application/json"
    }

    try:
        res = requests.post("https://api.resend.com/emails", headers=headers, json=payload, timeout=15)
        print(f"Action email '{subject}' dispatched -> Status {res.status_code}")
        return res.status_code in (200, 201)
    except Exception as e:
        print(f"Failed to send email: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--video":
        details = """
        <div class="box" style="background: #fdf2f8; border: 1px solid #fbcfe8; color: #831843;">
          <strong>🎬 Script 1: "Why I Deleted MyFitnessPal" (20 Seconds)</strong><br><br>
          <strong>0:00 - 0:04 (The Hook):</strong> Screen record MyFitnessPal asking for $79.99 for barcode scanner or showing an ad.<br>
          <em>Text on screen: "Why is an app charging $80/yr just to scan food barcodes?"</em><br><br>
          <strong>0:04 - 0:12 (The Solution):</strong> Open CalorieFit. Opens instantly, no login, tap scan.<br>
          <em>Text on screen: "Switched to CalorieFit. 100% free, zero ads, no accounts."</em><br><br>
          <strong>0:12 - 0:20 (The Result):</strong> Scan any grocery item in 1 second. Show instant macros.<br>
          <em>Text on screen: "Even has fasting timers & widgets. Free on Google Play."</em>
        </div>
        <div class="box">
          <strong>📋 Copy-Paste TikTok Caption & Tags:</strong><br>
          <code>Tired of $80/year diet app paywalls 🤦‍♂️ Built an offline-first tracker with zero ads, free barcode scanning & fasting timers. Link in bio! #myfitnesspal #calorietracker #cico #fitnessjourney #loseweight #indiedev #fitnesstips</code>
        </div>
        <div class="box" style="background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46;">
          <strong>💡 Pro Tip: Same or New Videos?</strong><br>
          Do <strong>NOT</strong> upload the exact same video file twice (TikTok suppresses duplicate files). Instead, use the <strong>same 20-second formula</strong> while scanning different foods (e.g. Video 1: Coffee & eggs, Video 2: Protein bar, Video 3: Fasting timer countdown).
        </div>
        """
        send_custom_action_email(
            subject="🎬 Action: 20-Second TikTok / Shorts Video Plan (High Conversion)",
            title="Create a 20-Second Phone Video",
            badge="TikTok & YouTube Shorts",
            action_text="Here is your exact 20-second screen-record script to get hundreds of organic downloads.",
            button_text="👉 View Full Video Scripts on PC",
            button_url="https://kashif-malik12.github.io/CalorieFit/",
            details_html=details
        )
    elif len(sys.argv) > 1 and sys.argv[1] == "--social-setup":
        details = """
        <div class="box" style="background: #fdf2f8; border: 1px solid #fbcfe8; color: #831843;">
          <strong>📸 Instagram Profile:</strong><br>
          • <strong>Username:</strong> @caloriefit.app<br>
          • <strong>Name:</strong> CalorieFit | Free Calorie Tracker<br>
          • <strong>Bio:</strong><br>
          🥗 100% Free calorie counter & fasting tracker.<br>
          🚫 Zero ads • Free barcode scanner • No accounts.<br>
          👇 Download free on Google Play:
        </div>
        <div class="box" style="background: #f0fdf4; border: 1px solid #bbf7d0; color: #166534;">
          <strong>🎵 TikTok Profile:</strong><br>
          • <strong>Username:</strong> @caloriefitapp<br>
          • <strong>Bio:</strong> Tired of $80/year diet paywalls? CalorieFit is 100% free, offline & ad-free! Free on Google Play 👇
        </div>
        <div class="box" style="background: #eff6ff; border: 1px solid #bfdbfe; color: #1e40af;">
          <strong>▶️ YouTube Channel:</strong><br>
          • <strong>Channel Name:</strong> CalorieFit App<br>
          • <strong>Handle:</strong> @CalorieFitApp
        </div>
        <div class="box">
          <strong>🖼️ Profile Picture to Use:</strong><br>
          <span class="path">E:\\Dev Projects\\CalorieFit\\output\\play_store\\play-icon-512.png</span>
        </div>
        """
        send_custom_action_email(
            subject="🚀 Social Setup Kit: Instagram, TikTok & YouTube Profiles",
            title="5-Minute Social Accounts Setup",
            badge="Social Channels Kit",
            action_text="Here is your quick copy-paste kit to create your official CalorieFit accounts on Instagram, TikTok, and YouTube in 5 minutes.",
            button_text="👉 View Google Play Store Page",
            button_url="https://play.google.com/store/apps/details?id=com.caloriefit.app",
            details_html=details
        )
    elif len(sys.argv) > 1 and sys.argv[1] == "--video-ready":
        details = """
        <div class="box" style="background: #ecfdf5; border: 1px solid #a7f3d0; color: #065f46;">
          <strong>🎉 Your automated video is ready on your PC!</strong><br><br>
          • <strong>File Location:</strong><br>
          <span class="path">E:\\Dev Projects\\CalorieFit\\output\\videos\\CalorieFit_TikTok_Short_1.mp4</span><br><br>
          • <strong>Format:</strong> 1080x1920 Vertical (9:16) with Neural AI Voiceover & Mockups<br>
          • <strong>Length:</strong> 28 seconds (Ideal for TikTok / Shorts / Reels)
        </div>
        <div class="box">
          <strong>📋 Copy-Paste Caption & Hashtags:</strong><br>
          <code>Tired of $80/year diet app paywalls Built an offline-first tracker with zero ads, free barcode scanning and fasting timers. Link in bio! #myfitnesspal #calorietracker #cico #fitnessjourney #loseweight #indiedev #fitnesstips</code>
        </div>
        <div class="box" style="background: #fffbeb; border: 1px solid #fde68a; color: #92400e;">
          <strong>⚡ 1-Minute Action:</strong><br>
          Transfer this MP4 to your phone (via WhatsApp/Google Drive/USB) or upload directly via TikTok Studio / YouTube Studio on your PC!
        </div>
        """
        send_custom_action_email(
            subject="🎬 New Video Ready to Post: CalorieFit_TikTok_Short_1.mp4",
            title="Your Automated Video is Ready!",
            badge="Automated Video Engine",
            action_text="The local engine on your PC just rendered your first 1080x1920 vertical video complete with realistic AI voiceover and app mockups.",
            button_text="👉 Open Video Folder on PC",
            button_url="https://kashif-malik12.github.io/CalorieFit/",
            details_html=details
        )
    elif len(sys.argv) > 1 and sys.argv[1] == "--photos":
        details = """
        <div class="box">
          <strong>📁 Ready Assets on Your Computer:</strong><br>
          • <strong>Cover Photo (1024x500):</strong><br>
            <span class="path">E:\\Dev Projects\\CalorieFit\\output\\play_store\\feature-graphic-1024x500.png</span><br><br>
          • <strong>App Icon (512x512):</strong><br>
            <span class="path">E:\\Dev Projects\\CalorieFit\\output\\play_store\\play-icon-512.png</span><br><br>
          • <strong>Phone Screenshots:</strong><br>
            <span class="path">E:\\Dev Projects\\CalorieFit\\assets\\branding\\screenshots\\</span>
        </div>
        <div class="box" style="background: #fffbeb; border: 1px solid #fde68a; color: #92400e;">
          <strong>⚡ 2-Minute Steps:</strong><br>
          1. Click the button below to open Google Play Console.<br>
          2. Go to <strong>Store presence &gt; Main store listing &gt; Graphics</strong>.<br>
          3. Drag & drop the Cover Photo and Screenshots into their boxes and click <strong>Save</strong>.
        </div>
        """
        send_custom_action_email(
            subject="📸 Action Needed: Update CalorieFit Store Photos & Cover Graphic",
            title="Update Store Graphics & Screenshots",
            badge="Google Play Store Action",
            action_text="Your brand-new 1024x500 cover photo and store assets are generated and ready on your computer.",
            button_text="👉 Open Google Play Console Graphics",
            button_url="https://play.google.com/console",
            details_html=details
        )
