#!/usr/bin/env python3
"""
CalorieFit Local Automated Video Creation Engine (TikTok / Shorts / Reels)
--------------------------------------------------------------------------
Generates 1080x1920 9:16 vertical promotional videos completely on your local PC
using Pillow, edge-tts (ultra-realistic Microsoft Neural AI Voice), and ffmpeg.
Includes 7 rotating high-conversion video themes for daily posting.
"""

import os
import sys
import glob
import subprocess
import asyncio
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import edge_tts

ROOT_DIR = Path(__file__).resolve().parent.parent
OUTPUT_DIR = ROOT_DIR / "output" / "videos"
BRANDING_DIR = ROOT_DIR / "assets" / "branding"
SCREENSHOTS_DIR = BRANDING_DIR / "screenshots"

FONT_PATH = "C:\\Windows\\Fonts\\segoeuib.ttf"
if not os.path.exists(FONT_PATH):
    FONT_PATH = "C:\\Windows\\Fonts\\arialbd.ttf"
if not os.path.exists(FONT_PATH):
    for linux_font in [
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
    ]:
        if os.path.exists(linux_font):
            FONT_PATH = linux_font
            break

VOICE_NAME = "en-US-ChristopherNeural"  # Professional, confident US male narrator

VIDEO_THEMES = {
    1: {
        "title": "Why I Deleted MyFitnessPal",
        "caption": "Tired of $80/year diet app paywalls 🤦‍♂️ Built an offline-first tracker with zero ads, free barcode scanning & fasting timers. Link in bio! #myfitnesspal #calorietracker #cico #fitnessjourney #loseweight #indiedev #fitnesstips",
        "scenes": [
            {
                "hook_top": "WHY ARE DIET APPS $80/YEAR?!",
                "hook_sub": "Paying $80 to scan a barcode is crazy.",
                "voiceover": "Why are basic diet apps charging eighty dollars a year just to scan food barcodes?",
                "screenshot_idx": 0,
                "badge_text": "🚫 STOP PAYING SUBSCRIPTIONS"
            },
            {
                "hook_top": "MEET CALORIEFIT 🚀",
                "hook_sub": "100% Free, Zero Ads, No Accounts.",
                "voiceover": "I built CalorieFit: a free, offline-first calorie and intermittent fasting tracker for Android.",
                "screenshot_idx": 1,
                "badge_text": "🔒 100% LOCAL-FIRST & PRIVATE"
            },
            {
                "hook_top": "BARCODE & FASTING IN 1 APP ⚡",
                "hook_sub": "Instant barcode lookup + 16:8 fasting timer.",
                "voiceover": "You get a free barcode scanner, daily macro targets, and intermittent fasting timers with ketosis stages.",
                "screenshot_idx": 2,
                "badge_text": "⏳ 16:8 FASTING + MACROS"
            },
            {
                "hook_top": "FREE ON GOOGLE PLAY 👉",
                "hook_sub": "No credit card. No login required.",
                "voiceover": "All data stays private on your phone. Download CalorieFit completely free on Google Play today.",
                "screenshot_idx": 0,
                "badge_text": "📲 SEARCH 'CALORIEFIT' ON GOOGLE PLAY"
            }
        ]
    },
    2: {
        "title": "Free Barcode Scanner Without Paywalls",
        "caption": "Stop paying to scan food barcodes! 🍎 CalorieFit is 100% free with barcode scanning, macros, and offline SQLite storage. Free on Google Play! #nutrition #dietapp #cico #barcodescanner #healthylifestyle #fitness #gymtok",
        "scenes": [
            {
                "hook_top": "FREE BARCODE SCANNER ⚡",
                "hook_sub": "No subscription required to scan food.",
                "voiceover": "Most diet apps locked their barcode scanner behind an eighty dollar yearly subscription.",
                "screenshot_idx": 1,
                "badge_text": "🚫 NO SCANNER PAYWALLS"
            },
            {
                "hook_top": "INSTANT MACRO LOOKUP 🥑",
                "hook_sub": "Protein, carbs, fats & calories in 1 tap.",
                "voiceover": "CalorieFit gives you unlimited barcode scanning and instant macro breakdowns completely free.",
                "screenshot_idx": 2,
                "badge_text": "📊 FULL MACRO BREAKDOWN"
            },
            {
                "hook_top": "ZERO ADS & ZERO POPUPS 🛡️",
                "hook_sub": "Log meals in seconds without interruptions.",
                "voiceover": "No full screen video ads, no monthly fees, and no sign in required.",
                "screenshot_idx": 0,
                "badge_text": "⚡ 1-TAP QUICK LOGGING"
            },
            {
                "hook_top": "GET IT ON GOOGLE PLAY 📲",
                "hook_sub": "Search 'CalorieFit' on the Play Store.",
                "voiceover": "Get CalorieFit free on the Google Play Store and start tracking today.",
                "screenshot_idx": 1,
                "badge_text": "👉 100% FREE ON ANDROID"
            }
        ]
    },
    3: {
        "title": "Stop Using Two Apps for Fasting & Calories",
        "caption": "You don't need Zero for fasting and MyFitnessPal for calories! 🔥 CalorieFit combines 16:8 fasting timers + calorie tracking with zero ads. Free on Play Store! #intermittentfasting #fasting168 #cico #dieting #losefat #gymmotivation #health",
        "scenes": [
            {
                "hook_top": "STOP USING TWO APPS 🤦‍♂️",
                "hook_sub": "One app for fasting, one for calories?",
                "voiceover": "Stop using one app for fasting and a second app for calories, both charging expensive subscriptions.",
                "screenshot_idx": 2,
                "badge_text": "⏳ FASTING + CALORIES IN ONE"
            },
            {
                "hook_top": "BUILT-IN FASTING TIMER 🔥",
                "hook_sub": "14:10, 16:8, 18:6, 20:4 with ketosis stages.",
                "voiceover": "CalorieFit combines an intermittent fasting countdown timer directly with your daily calorie diary.",
                "screenshot_idx": 0,
                "badge_text": "⚡ KETOSIS STAGE TRACKING"
            },
            {
                "hook_top": "1-TAP BREAKFAST LOGGING 🍳",
                "hook_sub": "Break your fast and log macros instantly.",
                "voiceover": "When your fasting window ends, log your meals in seconds with one tap staples or barcode scanning.",
                "screenshot_idx": 1,
                "badge_text": "🥑 INSTANT FOOD LOGGING"
            },
            {
                "hook_top": "100% FREE ON GOOGLE PLAY 📲",
                "hook_sub": "Search 'CalorieFit' on Android.",
                "voiceover": "Zero ads, zero subscriptions, completely free on Google Play. Search CalorieFit now.",
                "screenshot_idx": 2,
                "badge_text": "👉 DOWNLOAD CALORIEFIT"
            }
        ]
    },
    4: {
        "title": "The Only Diet App That Respects Your Privacy",
        "caption": "Did you know diet apps sell your body weight and eating logs to ad brokers? 🛑 CalorieFit is 100% offline-first with local SQLite and PIN lock. Zero cloud tracking! #privacy #cybersecurity #degoogle #android #offlineapp #fitnesstracker #indiedev",
        "scenes": [
            {
                "hook_top": "DO DIET APPS SELL YOUR DATA? 🕵️‍♂️",
                "hook_sub": "Health and weight data sold to ad brokers.",
                "voiceover": "Did you know mainstream diet trackers sell your sensitive weight and health logs to ad brokers?",
                "screenshot_idx": 0,
                "badge_text": "🛑 ZERO DATA BROKERS"
            },
            {
                "hook_top": "100% LOCAL-FIRST SQLITE 🔒",
                "hook_sub": "All logs stay encrypted on your phone.",
                "voiceover": "CalorieFit is completely local-first. All your nutrition logs and weights stay on your phone SQLite database.",
                "screenshot_idx": 1,
                "badge_text": "📱 WORKS 100% OFFLINE"
            },
            {
                "hook_top": "NO ACCOUNTS OR EMAILS 🛡️",
                "hook_sub": "No login screen. Built-in PIN security.",
                "voiceover": "No accounts, no email required, zero tracking pixels, and a built-in privacy PIN lock.",
                "screenshot_idx": 2,
                "badge_text": "🔑 BIOMETRIC & PIN LOCK"
            },
            {
                "hook_top": "PRIVATE & FREE ON ANDROID 📲",
                "hook_sub": "Search 'CalorieFit' on Google Play.",
                "voiceover": "Protect your personal health data. Download CalorieFit free on Google Play today.",
                "screenshot_idx": 0,
                "badge_text": "👉 GET CALORIEFIT FREE"
            }
        ]
    },
    5: {
        "title": "AI Natural Language Meal Estimator",
        "caption": "Just type what you ate and get instant calories & macros! 🤖 CalorieFit has built-in AI meal estimation + free barcode scanning. Zero subscriptions! #ai #artificialintelligence #nutritiontips #macros #caloriedeficit #healthyeating #foodie",
        "scenes": [
            {
                "hook_top": "TIRED OF WEIGHING EVERY GRAM? 🥗",
                "hook_sub": "Meal logging takes too much time.",
                "voiceover": "Tired of spending ten minutes searching through bloated food databases just to log lunch?",
                "screenshot_idx": 1,
                "badge_text": "⚡ FAST AI MEAL LOGGING"
            },
            {
                "hook_top": "AI NATURAL LANGUAGE 🤖",
                "hook_sub": "Type '2 eggs with avocado toast' & get macros.",
                "voiceover": "With CalorieFit, just type or speak what you ate in natural language for instant calorie and macro estimation.",
                "screenshot_idx": 2,
                "badge_text": "🥑 NATURAL LANGUAGE ESTIMATOR"
            },
            {
                "hook_top": "HEALTH CONNECT STEP SYNC ⌚",
                "hook_sub": "Auto-syncs workouts to calculate Net Calories.",
                "voiceover": "It auto syncs your steps with Google Health Connect to calculate your true net calories burned.",
                "screenshot_idx": 0,
                "badge_text": "🔥 TRUE NET CALORIES"
            },
            {
                "hook_top": "DOWNLOAD FREE ON PLAY STORE 📲",
                "hook_sub": "No subscription required.",
                "voiceover": "Enjoy fast AI nutrition tracking with zero ads. Download CalorieFit on Google Play.",
                "screenshot_idx": 1,
                "badge_text": "👉 TRY CALORIEFIT TODAY"
            }
        ]
    },
    6: {
        "title": "Glanceable Home Screen Widgets",
        "caption": "See your remaining calories and fasting window right on your home screen! 📱 CalorieFit has Material 3 widgets with zero ads. Grab it free on Play Store! #androidhomescreen #androidwidgets #cico #fitnessgoals #macros #caloriedeficit",
        "scenes": [
            {
                "hook_top": "CHECK CALORIES IN 1 SECOND 📱",
                "hook_sub": "Glanceable Android home screen widgets.",
                "voiceover": "Stop having to open a bloated app every time you just want to check your remaining protein and calories.",
                "screenshot_idx": 0,
                "badge_text": "📱 HOME SCREEN WIDGETS"
            },
            {
                "hook_top": "REAL-TIME FASTING COUNTDOWN ⏳",
                "hook_sub": "Watch your ketosis stages throughout the day.",
                "voiceover": "CalorieFit gives you clean Android home screen widgets with remaining calories and real-time fasting timers.",
                "screenshot_idx": 2,
                "badge_text": "⏳ GLANCEABLE TIMERS"
            },
            {
                "hook_top": "MATERIAL 3 & OFFLINE FIRST 🎨",
                "hook_sub": "Sleek dynamic theming with zero battery drain.",
                "voiceover": "Designed with modern Material Three theming, ultra low battery drain, and zero intrusive ads.",
                "screenshot_idx": 1,
                "badge_text": "⚡ 100% AD-FREE UI"
            },
            {
                "hook_top": "FREE ON GOOGLE PLAY 📲",
                "hook_sub": "Search 'CalorieFit' on Play Store.",
                "voiceover": "Download CalorieFit completely free on Google Play and customize your widgets today.",
                "screenshot_idx": 0,
                "badge_text": "👉 DOWNLOAD NOW"
            }
        ]
    },
    7: {
        "title": "Indie Developer vs Corporate Bloat",
        "caption": "I spent months building CalorieFit because mainstream diet apps charge $80/yr for basic features. Support an indie developer by trying CalorieFit free on Google Play! #indiedev #buildinpublic #solodev #myfitnesspal #tech #fitnessapp",
        "scenes": [
            {
                "hook_top": "I BUILT A FREE DIET APP 🛠️",
                "hook_sub": "Indie developer fighting subscription bloat.",
                "voiceover": "I spent the last several months building an indie alternative to mainstream corporate diet apps.",
                "screenshot_idx": 1,
                "badge_text": "🛠️ BUILT BY AN INDIE DEV"
            },
            {
                "hook_top": "EVERYTHING YOU NEED IS FREE 🎁",
                "hook_sub": "Barcode scanner, macros, fasting & widgets.",
                "voiceover": "Everything they paywall is free here: barcode scanner, intermittent fasting, and doctor export.",
                "screenshot_idx": 2,
                "badge_text": "🚫 ZERO PAYWALLS"
            },
            {
                "hook_top": "NO ADS • NO LOGINS • OFFLINE 🔒",
                "hook_sub": "All data stays private on your phone.",
                "voiceover": "No accounts, no ads, works offline, and respects your privacy. Built by a developer who uses it every day.",
                "screenshot_idx": 0,
                "badge_text": "🔒 100% PRIVATE DIARY"
            },
            {
                "hook_top": "SUPPORT INDIE APPS ON PLAY STORE 📲",
                "hook_sub": "Search 'CalorieFit' on Google Play.",
                "voiceover": "Support indie software and take control of your health. Search CalorieFit on Google Play.",
                "screenshot_idx": 1,
                "badge_text": "👉 GET CALORIEFIT ON GOOGLE PLAY"
            }
        ]
    }
}

def get_audio_duration(audio_path):
    cmd = [
        "ffprobe", "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        str(audio_path)
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
    return float(res.stdout.strip())

async def generate_tts(text, output_path):
    communicate = edge_tts.Communicate(text, VOICE_NAME, rate="+5%")
    await communicate.save(str(output_path))

def create_rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), size], radius=radius, fill=255)
    return mask

def render_scene_frame(scene, screenshot_path, out_path, frame_w=1080, frame_h=1920):
    base = Image.new("RGBA", (frame_w, frame_h), (15, 23, 42, 255))
    draw = ImageDraw.Draw(base)

    # Gradient blend (Slate #0F172A to Forest Emerald #064E3B)
    for y in range(frame_h):
        ratio = y / frame_h
        r = int(15 * (1 - ratio) + 6 * ratio)
        g = int(23 * (1 - ratio) + 78 * ratio)
        b = int(42 * (1 - ratio) + 59 * ratio)
        draw.line([(0, y), (frame_w, y)], fill=(r, g, b))

    # Glow accents
    glow_color = (16, 185, 129, 35)
    draw.ellipse([-150, 100, 450, 700], fill=glow_color)
    draw.ellipse([650, 1100, 1250, 1700], fill=glow_color)

    # App Logo Watermark
    logo_path = BRANDING_DIR / "caloriefit_logo.png"
    if logo_path.exists():
        logo = Image.open(logo_path).convert("RGBA")
        logo.thumbnail((420, 110), Image.Resampling.LANCZOS)
        logo_x = (frame_w - logo.width) // 2
        base.paste(logo, (logo_x, 80), logo)

    # Fonts
    font_hook = ImageFont.truetype(FONT_PATH, 52)
    font_sub = ImageFont.truetype(FONT_PATH, 34)
    font_badge = ImageFont.truetype(FONT_PATH, 28)

    # Top Hook Title
    hook_text = scene["hook_top"]
    sub_text = scene["hook_sub"]
    badge_text = scene["badge_text"]

    bbox_hook = draw.textbbox((0, 0), hook_text, font=font_hook)
    hook_w = bbox_hook[2] - bbox_hook[0]
    hook_x = (frame_w - hook_w) // 2
    hook_y = 210

    draw.text((hook_x + 3, hook_y + 3), hook_text, font=font_hook, fill=(0, 0, 0, 180))
    draw.text((hook_x, hook_y), hook_text, font=font_hook, fill=(255, 230, 0, 255))

    # Subtext
    bbox_sub = draw.textbbox((0, 0), sub_text, font=font_sub)
    sub_w = bbox_sub[2] - bbox_sub[0]
    sub_x = (frame_w - sub_w) // 2
    sub_y = hook_y + 75
    draw.text((sub_x, sub_y), sub_text, font=font_sub, fill=(241, 245, 249, 255))

    # Center Phone Mockup
    phone_w = 680
    phone_h = 1180
    phone_x = (frame_w - phone_w) // 2
    phone_y = 400

    # Phone drop shadow
    shadow = Image.new("RGBA", (phone_w + 60, phone_h + 60), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([(30, 30), (phone_w + 30, phone_h + 30)], radius=45, fill=(0, 0, 0, 140))
    shadow = shadow.filter(ImageFilter.GaussianBlur(25))
    base.paste(shadow, (phone_x - 30, phone_y - 20), shadow)

    # Phone Outer Bezel
    bezel = Image.new("RGBA", (phone_w, phone_h), (255, 255, 255, 0))
    b_draw = ImageDraw.Draw(bezel)
    b_draw.rounded_rectangle([(0, 0), (phone_w, phone_h)], radius=45, fill=(30, 41, 59, 255), outline=(71, 85, 105, 255), width=6)

    # Screenshot inside phone
    if screenshot_path and os.path.exists(screenshot_path):
        screen_img = Image.open(screenshot_path).convert("RGBA")
        inner_w = phone_w - 28
        inner_h = phone_h - 28
        
        screen_ratio = screen_img.width / screen_img.height
        target_ratio = inner_w / inner_h
        if screen_ratio > target_ratio:
            new_h = screen_img.height
            new_w = int(new_h * target_ratio)
            left = (screen_img.width - new_w) // 2
            screen_img = screen_img.crop((left, 0, left + new_w, new_h))
        else:
            new_w = screen_img.width
            new_h = int(new_w / target_ratio)
            top = (screen_img.height - new_h) // 2
            screen_img = screen_img.crop((0, top, new_w, top + new_h))

        screen_resized = screen_img.resize((inner_w, inner_h), Image.Resampling.LANCZOS)
        inner_mask = create_rounded_mask((inner_w, inner_h), radius=35)
        bezel.paste(screen_resized, (14, 14), inner_mask)

    base.paste(bezel, (phone_x, phone_y), bezel)

    # Bottom Badge
    bbox_badge = draw.textbbox((0, 0), badge_text, font=font_badge)
    badge_w = bbox_badge[2] - bbox_badge[0] + 50
    badge_h = 60
    badge_x = (frame_w - badge_w) // 2
    badge_y = 1660

    draw.rounded_rectangle([(badge_x, badge_y), (badge_x + badge_w, badge_y + badge_h)], radius=30, fill=(16, 185, 129, 255))
    text_x = badge_x + 25
    text_y = badge_y + 14
    draw.text((text_x, text_y), badge_text, font=font_badge, fill=(255, 255, 255, 255))

    base.convert("RGB").save(str(out_path), "PNG", quality=95)

def build_video(day=1):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    tmp_dir = OUTPUT_DIR / f"temp_day_{day}"
    tmp_dir.mkdir(parents=True, exist_ok=True)

    theme = VIDEO_THEMES.get(day, VIDEO_THEMES[1])
    scenes = theme["scenes"]

    screenshots = sorted(list(SCREENSHOTS_DIR.glob("*.jpeg")) + list(SCREENSHOTS_DIR.glob("*.png")))
    if not screenshots:
        screenshots = [BRANDING_DIR / "feature-graphic-1024x500.png"]

    scene_clips = []
    print(f"🎬 Rendering Video for Day {day}: '{theme['title']}'...")

    for i, scene in enumerate(scenes, 1):
        audio_path = tmp_dir / f"scene_{i}.mp3"
        asyncio.run(generate_tts(scene["voiceover"], audio_path))
        duration = get_audio_duration(audio_path) + 0.4

        shot_idx = scene["screenshot_idx"] % len(screenshots)
        shot_path = screenshots[shot_idx]

        frame_path = tmp_dir / f"scene_{i}.png"
        render_scene_frame(scene, shot_path, frame_path)

        clip_path = tmp_dir / f"clip_{i}.mp4"
        cmd = [
            "ffmpeg", "-y",
            "-loop", "1", "-i", str(frame_path),
            "-i", str(audio_path),
            "-vf", "zoompan=z='min(zoom+0.0005,1.04)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920:fps=30",
            "-c:v", "libx264", "-preset", "fast", "-crf", "18",
            "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-ar", "48000", "-ac", "2", "-b:a", "192k",
            "-t", str(duration),
            "-shortest",
            str(clip_path)
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        scene_clips.append(clip_path)

    concat_list_path = tmp_dir / "concat_list.txt"
    with open(concat_list_path, "w") as f:
        for clip in scene_clips:
            f.write(f"file '{clip.resolve()}'\n")

    final_video_name = f"CalorieFit_Video_Day{day}.mp4"
    final_video_path = OUTPUT_DIR / final_video_name

    concat_cmd = [
        "ffmpeg", "-y",
        "-f", "concat", "-safe", "0",
        "-i", str(concat_list_path),
        "-c", "copy",
        str(final_video_path)
    ]
    subprocess.run(concat_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    # Cleanup temp
    for f in tmp_dir.glob("*"):
        try:
            f.unlink()
        except Exception:
            pass
    try:
        tmp_dir.rmdir()
    except Exception:
        pass

    # Copy to docs/videos for GitHub Pages instant download hub
    docs_video_dir = ROOT_DIR / "docs" / "videos"
    docs_video_dir.mkdir(parents=True, exist_ok=True)
    import shutil
    shutil.copy2(str(final_video_path), str(docs_video_dir / final_video_name))

    print(f"🎉 SUCCESS: Video rendered -> {final_video_path}")
    return {
        "path": final_video_path,
        "name": final_video_name,
        "caption": theme["caption"],
        "title": theme["title"]
    }

if __name__ == "__main__":
    day_num = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 1
    build_video(day=day_num)
