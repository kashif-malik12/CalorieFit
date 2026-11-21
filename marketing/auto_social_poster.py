#!/usr/bin/env python3
"""
CalorieFit Automated Social Marketing Dispatcher
------------------------------------------------
Can run in two modes:
1. Web Intent Auto-Launcher (No API keys needed): Automatically opens pre-filled compose windows in your default browser.
2. Direct API Mode (If REDDIT_* or TWITTER_* environment variables are configured).
"""

import os
import sys
import urllib.parse
import webbrowser

APP_NAME = "CalorieFit"
PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.caloriefit.app"
WEBSITE_URL = "https://kashif-malik12.github.io/CalorieFit/"

REDDIT_TITLE = "I got tired of $80/year paywalls on calorie trackers, so I built a free, ad-free, offline tracker with on-device camera AI"

REDDIT_BODY = f"""I got tired of $80/year subscriptions on calorie trackers, so I spent the last few months building CalorieFit: a 100% free, zero-ad, private offline tracker for Android.

Key features:
• 🔒 100% Local-First: All nutrition and fasting logs stay in your phone's SQLite DB. No account or email needed.
• 🚫 Zero Ads & Zero Paywalls: Free barcode scanner, free macro tracking.
• 📸 AI Vision Food Scanner: On-device ML camera scanner to detect meal plates, calories, and macros with smart non-food filtering.
• ⏳ Intermittent Fasting Timer: 16:8, 18:6, 20:4 windows with ketosis stages.
• 🔥 Front-Page Streak Challenges: Pick your habit goal (1-day kickstart, 10-day challenge, or custom).
• ⌚ Google Health Connect Sync: Automatically computes true Net Calories.

Google Play: {PLAY_STORE_URL}
Website: {WEBSITE_URL}

I'd love your honest feedback to make it better!"""

TWITTER_TEXT = f"""Mainstream diet apps have lost their minds:
• $79.99/yr paywalls just to scan barcodes
• Annoying video ads
• Selling weight data to brokers

So I built CalorieFit for Android:
• 100% Free & No Ads
• On-device AI food camera scanner
• Local SQLite (Works offline)
• Fasting timer + Health Connect sync

Get it free on Google Play:
{PLAY_STORE_URL}"""

def generate_web_intent_urls():
    reddit_query = urllib.parse.urlencode({
        "title": REDDIT_TITLE,
        "text": REDDIT_BODY
    })
    reddit_url = f"https://reddit.com/r/androidapps/submit?{reddit_query}"

    twitter_query = urllib.parse.urlencode({
        "text": TWITTER_TEXT
    })
    twitter_url = f"https://twitter.com/intent/tweet?{twitter_query}"

    fb_query = urllib.parse.urlencode({
        "u": PLAY_STORE_URL
    })
    fb_url = f"https://www.facebook.com/sharer/sharer.php?{fb_query}"

    return {
        "Reddit": reddit_url,
        "Twitter": twitter_url,
        "Facebook": fb_url
    }

def open_all_in_browser():
    urls = generate_web_intent_urls()
    print("Launching pre-filled social media compose windows in your browser...")
    for platform, url in urls.items():
        print(f"Opening {platform}...")
        webbrowser.open(url)
    print("\nDone! All windows opened with pre-filled posts ready for 1-click publishing.")

def post_via_apis_if_configured():
    has_keys = False
    
    # Check Reddit
    reddit_client_id = os.environ.get("REDDIT_CLIENT_ID")
    reddit_secret = os.environ.get("REDDIT_SECRET")
    reddit_username = os.environ.get("REDDIT_USERNAME")
    reddit_password = os.environ.get("REDDIT_PASSWORD")

    if all([reddit_client_id, reddit_secret, reddit_username, reddit_password]):
        try:
            import praw
            r = praw.Reddit(
                client_id=reddit_client_id,
                client_secret=reddit_secret,
                username=reddit_username,
                password=reddit_password,
                user_agent="CalorieFit_Publisher_v1"
            )
            sub = r.subreddit("androidapps")
            submission = sub.submit(title=REDDIT_TITLE, selftext=REDDIT_BODY)
            print(f"Successfully posted to Reddit! URL: {submission.url}")
            has_keys = True
        except Exception as e:
            print(f"Reddit API posting error: {e}")

    # Check Twitter / X
    tw_api_key = os.environ.get("TWITTER_API_KEY")
    tw_api_secret = os.environ.get("TWITTER_API_SECRET")
    tw_access_token = os.environ.get("TWITTER_ACCESS_TOKEN")
    tw_access_secret = os.environ.get("TWITTER_ACCESS_SECRET")

    if all([tw_api_key, tw_api_secret, tw_access_token, tw_access_secret]):
        try:
            import tweepy
            client = tweepy.Client(
                consumer_key=tw_api_key,
                consumer_secret=tw_api_secret,
                access_token=tw_access_token,
                access_token_secret=tw_access_secret
            )
            response = client.create_tweet(text=TWITTER_TEXT)
            print(f"Successfully posted to Twitter / X! Tweet ID: {response.data['id']}")
            has_keys = True
        except Exception as e:
            print(f"Twitter API posting error: {e}")

    if not has_keys:
        print("No API environment keys found. Opening browser with pre-filled 1-click links...")
        open_all_in_browser()

if __name__ == "__main__":
    if "--open" in sys.argv:
        open_all_in_browser()
    else:
        post_via_apis_if_configured()
