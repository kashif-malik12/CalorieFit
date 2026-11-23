#!/usr/bin/env python3
"""
CalorieFit "Search & Rescue" Lead Finder
---------------------------------------
Searches public Reddit discussions in the past 7 days for users asking for
alternatives to MyFitnessPal, free calorie counters, or ad-free diet apps.
Outputs active threads and ready-to-copy authentic replies.
"""

import sys
import time
import urllib.parse
import requests

SEARCH_QUERIES = [
    'MyFitnessPal alternative',
    'free calorie tracker',
    'calorie tracker no ads',
    'free barcode scanner calorie',
    'fasting app alternative'
]

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 CalorieFitLeadFinder/1.0"
}

def search_reddit():
    print("=" * 70)
    print("🔍 Scanning Reddit for High-Intent CalorieFit Leads (Last 7 Days)...")
    print("=" * 70)

    found_posts = []
    seen_ids = set()

    for q in SEARCH_QUERIES:
        url = f"https://www.reddit.com/search.json?q={urllib.parse.quote(q)}&sort=new&t=week&limit=10"
        try:
            res = requests.get(url, headers=HEADERS, timeout=10)
            if res.status_code == 200:
                data = res.json().get("data", {}).get("children", [])
                for item in data:
                    post = item.get("data", {})
                    p_id = post.get("id")
                    if p_id and p_id not in seen_ids:
                        seen_ids.add(p_id)
                        found_posts.append({
                            "id": p_id,
                            "title": post.get("title", ""),
                            "subreddit": post.get("subreddit_name_prefixed", ""),
                            "url": f"https://reddit.com{post.get('permalink', '')}",
                            "author": post.get("author", ""),
                            "num_comments": post.get("num_comments", 0)
                        })
            time.sleep(1) # respectful rate-limiting
        except Exception as e:
            print(f"Error querying '{q}': {e}")

    print("\n💡 Tip: You can also instantly find the latest active threads on Google via:")
    google_search_url = "https://www.google.com/search?q=site%3Areddit.com+%22MyFitnessPal+alternative%22+OR+%22free+calorie+tracker%22&tbs=qdr:w"
    print(f"👉 {google_search_url}\n")

    print(f"\n🎯 Found {len(found_posts)} active discussions where users are looking for an app like CalorieFit:\n")

    for i, p in enumerate(found_posts[:8], 1):
        print(f"[{i}] {p['subreddit']} • {p['title']}")
        print(f"    🔗 Thread: {p['url']}")
        print(f"    💬 Comments: {p['num_comments']}")
        print("    📝 Recommended Reply Template:")
        reply = (
            f"    \"I was frustrated by the exact same paywalls and video ads, so I built an offline-first app called CalorieFit for Android.\n"
            f"     It's 100% free with zero ads, includes the barcode scanner, intermittent fasting timers (16:8), and all data stays private in your phone's SQLite DB.\n"
            f"     Check it out here: https://play.google.com/store/apps/details?id=com.caloriefit.app - hope it helps!\""
        )
        print(reply)
        print("-" * 70)

if __name__ == "__main__":
    search_reddit()
