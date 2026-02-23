#!/usr/bin/env python3
"""
ClearVue App Store Screenshot Generator
Creates 5 marketing screenshots at 1284x2778 (6.7" iPhone 12-14 Pro Max)
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

# --- Constants ---
W, H = 1284, 2778
OUT = os.path.dirname(os.path.abspath(__file__))

# Colors (matching app theme)
BG = (10, 10, 10)
SURFACE = (29, 29, 31)
TEXT_PRIMARY = (245, 245, 247)
TEXT_SECONDARY = (161, 161, 166)
TEXT_MUTED = (134, 134, 139)
TEXT_DIM = (72, 72, 74)
GREEN = (48, 209, 88)
RED = (255, 69, 58)
BLUE = (0, 113, 227)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)

# Fonts
FONT_PATH = "/System/Library/Fonts/SFNS.ttf"
MONO_PATH = "/System/Library/Fonts/SFNSMono.ttf"
ROUND_PATH = "/System/Library/Fonts/SFNSRounded.ttf"


def font(size):
    return ImageFont.truetype(FONT_PATH, size)


def font_mono(size):
    return ImageFont.truetype(MONO_PATH, size)


def font_round(size):
    return ImageFont.truetype(ROUND_PATH, size)


def rounded_rect(draw, xy, radius, fill=None, outline=None, width=1):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def text_center(draw, text, y, fnt, fill=TEXT_PRIMARY):
    """Draw horizontally centered text."""
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    x = (W - tw) // 2
    draw.text((x, y), text, font=fnt, fill=fill)


def draw_phone_frame(draw, x, y, w, h):
    """Draw iPhone-like frame (rounded rect border)."""
    radius = 60
    # Outer bezel
    rounded_rect(draw, (x - 4, y - 4, x + w + 4, y + h + 4), radius + 4,
                 fill=None, outline=(58, 58, 60), width=3)
    # Inner screen area
    rounded_rect(draw, (x, y, x + w, y + h), radius, fill=BG)
    # Dynamic island
    island_w, island_h = 200, 56
    ix = x + (w - island_w) // 2
    iy = y + 20
    rounded_rect(draw, (ix, iy, ix + island_w, iy + island_h), island_h // 2, fill=BLACK)


def draw_status_bar(draw, x, y, w):
    """Draw a simple iOS status bar."""
    # Time
    time_font = font(28)
    draw.text((x + 46, y + 24), "9:41", font=time_font, fill=WHITE)
    # Signal dots, wifi, battery (right side) - simplified
    bx = x + w - 120
    by = y + 30
    # Battery outline
    rounded_rect(draw, (bx, by, bx + 44, by + 20), 4, outline=WHITE, width=2)
    draw.rectangle((bx + 44, by + 5, bx + 48, by + 15), fill=WHITE)
    # Battery fill
    draw.rectangle((bx + 3, by + 3, bx + 38, by + 17), fill=GREEN)
    # Signal bars
    for i in range(4):
        bh = 6 + i * 4
        draw.rectangle((bx - 70 + i * 10, by + 20 - bh, bx - 63 + i * 10, by + 20), fill=WHITE)


def draw_progress_bar(draw, x, y, w, pct, h=6):
    """Draw a thin progress bar."""
    rounded_rect(draw, (x, y, x + w, y + h), h // 2, fill=SURFACE)
    if pct > 0:
        fill_w = int(w * pct)
        rounded_rect(draw, (x, y, x + fill_w, y + h), h // 2, fill=WHITE)


def draw_test_row(draw, x, y, w, name, method, status):
    """Draw a single test result row."""
    name_font = font(28)
    method_font = font(22)
    badge_font = font(22)

    # Test name
    draw.text((x, y), name, font=name_font, fill=TEXT_PRIMARY)
    # Verification method
    draw.text((x, y + 36), method, font=method_font, fill=TEXT_MUTED)

    # Status badge
    if status == "Pass":
        badge_bg = (22, 80, 38)
        badge_fg = GREEN
    elif status == "Fail":
        badge_bg = (80, 22, 22)
        badge_fg = RED
    else:
        badge_bg = SURFACE
        badge_fg = TEXT_MUTED

    badge_w = 80
    badge_h = 34
    bx = x + w - badge_w
    by = y + 8
    rounded_rect(draw, (bx, by, bx + badge_w, by + badge_h), badge_h // 2, fill=badge_bg)
    # Center badge text
    bbbox = draw.textbbox((0, 0), status, font=badge_font)
    btw = bbbox[2] - bbbox[0]
    bth = bbbox[3] - bbbox[1]
    draw.text((bx + (badge_w - btw) // 2, by + (badge_h - bth) // 2 - 2), status, font=badge_font, fill=badge_fg)

    # Separator line
    draw.line((x, y + 74, x + w, y + 74), fill=(38, 38, 40), width=1)


# === Screenshot 1: Results View (Hero) ===
def create_results_screenshot():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Marketing text at top
    text_center(draw, "Know Your Phone's", 120, font(72), WHITE)
    text_center(draw, "True Condition", 210, font(72), WHITE)
    text_center(draw, "Get a verified diagnostic report in 2 minutes", 320, font(34), TEXT_SECONDARY)

    # Phone frame
    px, py, pw, ph = 95, 440, 1100, 2280
    draw_phone_frame(draw, px, py, pw, ph)
    draw_status_bar(draw, px, py, pw)

    # Screen content inside phone
    sx = px + 40
    sy = py + 100
    sw = pw - 80

    # CLEARVUE label
    label_font = font(20)
    text_center(draw, "CLEARVUE", sy, label_font, TEXT_DIM)

    # Title
    title_font = font(52)
    text_center(draw, "Diagnostic Complete", sy + 50, title_font, WHITE)

    # Score
    score_font = font(40)
    text_center(draw, "15 / 17 tests passed", sy + 130, score_font, GREEN)
    text_center(draw, "(2 not testable on this device)", sy + 185, font(24), TEXT_MUTED)

    # Timestamp
    text_center(draw, "23 Feb 2026 at 2:41 pm", sy + 230, font_mono(22), TEXT_DIM)

    # Device info card
    cy = sy + 290
    rounded_rect(draw, (sx, cy, sx + sw, cy + 130), 16, fill=SURFACE)
    info_font = font(24)
    draw.text((sx + 24, cy + 16), "iPhone 15 Pro", font=info_font, fill=TEXT_PRIMARY)
    draw.text((sx + 24, cy + 50), "iOS 18.3.1", font=info_font, fill=TEXT_SECONDARY)
    draw.text((sx + sw // 2, cy + 16), "256 GB", font=info_font, fill=TEXT_PRIMARY)
    draw.text((sx + sw // 2, cy + 50), "Battery: 96%", font=info_font, fill=TEXT_SECONDARY)
    draw.text((sx + 24, cy + 88), "IMEI: 35 291064 123456 7", font=font_mono(22), fill=TEXT_DIM)

    # Test results list
    tests = [
        ("Face ID", "Biometric API", "Pass"),
        ("Display", "Color panel inspection", "Pass"),
        ("Front Camera", "AI lens analysis", "Pass"),
        ("Rear Camera", "AI lens analysis", "Pass"),
        ("Touch Screen", "60-zone grid", "Pass"),
        ("Microphone", "Record & playback", "Pass"),
        ("Speaker", "Audio output", "Pass"),
        ("Wi-Fi", "Connectivity check", "Pass"),
        ("Cellular", "Carrier signal", "Pass"),
        ("Bluetooth", "Radio scan", "Pass"),
        ("NFC", "Tag reader session", "N/A"),
        ("GPS", "Location fix", "Pass"),
        ("Proximity", "Sensor event", "Pass"),
        ("Motion Sensors", "Accel + gyro", "Pass"),
        ("Vibration", "Haptic feedback", "Pass"),
        ("Hardware Buttons", "Vol + side button", "Pass"),
        ("Silent Switch", "Ringer detection", "N/A"),
    ]

    ty = cy + 160
    for name, method, status in tests:
        if ty + 80 > py + ph - 120:
            break
        draw_test_row(draw, sx, ty, sw, name, method, status)
        ty += 80

    # Bottom buttons (partially visible)
    btn_y = py + ph - 110
    btn_w = sw // 2 - 10
    rounded_rect(draw, (sx, btn_y, sx + btn_w, btn_y + 64), 32, fill=WHITE)
    btn_font = font(26)
    bbbox = draw.textbbox((0, 0), "Share Report PDF", font=btn_font)
    btw = bbbox[2] - bbbox[0]
    draw.text((sx + (btn_w - btw) // 2, btn_y + 18), "Share Report PDF", font=btn_font, fill=BLACK)

    rounded_rect(draw, (sx + btn_w + 20, btn_y, sx + sw, btn_y + 64), 32, fill=SURFACE)
    bbbox = draw.textbbox((0, 0), "Run Again", font=btn_font)
    btw = bbbox[2] - bbbox[0]
    draw.text((sx + btn_w + 20 + (btn_w - btw) // 2, btn_y + 18), "Run Again", font=btn_font, fill=TEXT_SECONDARY)

    img.save(os.path.join(OUT, "01_results.png"), "PNG")
    print("Created 01_results.png")


# === Screenshot 2: Camera AI Analysis ===
def create_camera_screenshot():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Marketing text
    text_center(draw, "AI-Powered", 120, font(72), WHITE)
    text_center(draw, "Lens Analysis", 210, font(72), WHITE)
    text_center(draw, "Detect scratches and defects on both cameras", 320, font(34), TEXT_SECONDARY)

    # Phone frame
    px, py, pw, ph = 95, 440, 1100, 2280
    draw_phone_frame(draw, px, py, pw, ph)
    draw_status_bar(draw, px, py, pw)

    sx = px + 40
    sy = py + 100
    sw = pw - 80

    # Navigation bar
    draw.text((px + pw // 2 - 60, sy - 10), "CLEARVUE", font=font(20), fill=TEXT_DIM)

    # Progress bar
    draw_progress_bar(draw, sx, sy + 30, sw, 4 / 17)
    draw.text((sx, sy + 48), "Test 4 of 17", font=font(22), fill=TEXT_MUTED)

    # Title
    draw.text((sx, sy + 100), "Rear Camera", font=font(44), fill=WHITE)

    # Camera preview area (simulated photo)
    cam_x = sx + (sw - 700) // 2
    cam_y = sy + 180
    cam_w, cam_h = 700, 940
    rounded_rect(draw, (cam_x, cam_y, cam_x + cam_w, cam_y + cam_h), 20, fill=(20, 25, 20))

    # Simulate a blurry photo (green-tinted rectangle with some variation)
    for y_offset in range(0, cam_h, 8):
        g = 30 + int(20 * math.sin(y_offset * 0.02))
        r = 15 + int(10 * math.sin(y_offset * 0.015 + 1))
        b = 12 + int(8 * math.sin(y_offset * 0.025 + 2))
        draw.rectangle((cam_x + 4, cam_y + y_offset, cam_x + cam_w - 4, cam_y + y_offset + 7),
                        fill=(r, g, b))

    # Camera label badge (top left)
    badge_x = cam_x + 16
    badge_y = cam_y + 16
    rounded_rect(draw, (badge_x, badge_y, badge_x + 100, badge_y + 36), 18, fill=(40, 40, 40, 180))
    draw.text((badge_x + 16, badge_y + 6), "REAR", font=font(22), fill=WHITE)

    # Hardware check badge (top right)
    check_x = cam_x + cam_w - 52
    check_y = cam_y + 16
    rounded_rect(draw, (check_x, check_y, check_x + 36, check_y + 36), 18, fill=(22, 80, 38))
    draw.text((check_x + 8, check_y + 4), "\u2713", font=font(24), fill=GREEN)

    # AI Result badge (bottom center) - "Lens OK"
    ai_w = 200
    ai_h = 48
    ai_x = cam_x + (cam_w - ai_w) // 2
    ai_y = cam_y + cam_h - 64
    rounded_rect(draw, (ai_x, ai_y, ai_x + ai_w, ai_y + ai_h), ai_h // 2, fill=(22, 80, 38))
    text_center(draw, "Lens OK", ai_y + 10, font(28), GREEN)

    # AI analysis detail text
    detail_y = cam_y + cam_h + 30
    text_center(draw, "No scratches or defects detected", detail_y, font(28), TEXT_SECONDARY)
    text_center(draw, "Analyzed by Claude AI vision model", detail_y + 42, font(22), TEXT_DIM)

    # Pass / Fail / Skip buttons
    btn_y = detail_y + 110
    btn_h = 64
    # Pass button
    btn_w = sw // 3 - 12
    rounded_rect(draw, (sx, btn_y, sx + btn_w, btn_y + btn_h), 32, fill=(22, 80, 38))
    bbbox = draw.textbbox((0, 0), "Pass", font=font(28))
    btw = bbbox[2] - bbbox[0]
    draw.text((sx + (btn_w - btw) // 2, btn_y + 16), "Pass", font=font(28), fill=GREEN)

    # Fail button
    fx = sx + btn_w + 12
    rounded_rect(draw, (fx, btn_y, fx + btn_w, btn_y + btn_h), 32, fill=(80, 22, 22))
    bbbox = draw.textbbox((0, 0), "Fail", font=font(28))
    btw = bbbox[2] - bbbox[0]
    draw.text((fx + (btn_w - btw) // 2, btn_y + 16), "Fail", font=font(28), fill=RED)

    # Skip button
    skx = fx + btn_w + 12
    rounded_rect(draw, (skx, btn_y, skx + btn_w, btn_y + btn_h), 32, fill=SURFACE)
    bbbox = draw.textbbox((0, 0), "Skip", font=font(28))
    btw = bbbox[2] - bbbox[0]
    draw.text((skx + (btn_w - btw) // 2, btn_y + 16), "Skip", font=font(28), fill=TEXT_MUTED)

    img.save(os.path.join(OUT, "02_camera_ai.png"), "PNG")
    print("Created 02_camera_ai.png")


# === Screenshot 3: Touch Test ===
def create_touch_screenshot():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Marketing text
    text_center(draw, "Test Every Pixel", 120, font(72), WHITE)
    text_center(draw, "On Your Screen", 210, font(72), WHITE)
    text_center(draw, "60-zone touch grid verifies full screen responsiveness", 320, font(34), TEXT_SECONDARY)

    # Phone frame
    px, py, pw, ph = 95, 440, 1100, 2280
    draw_phone_frame(draw, px, py, pw, ph)

    # Touch grid (fullscreen inside phone)
    cols, rows = 6, 10
    gap = 3
    margin = 8
    grid_x = px + margin
    grid_y = py + margin
    grid_w = pw - margin * 2
    grid_h = ph - margin * 2 - 80  # Leave room for counter

    cell_w = (grid_w - gap * (cols - 1)) // cols
    cell_h = (grid_h - gap * (rows - 1)) // rows

    # Define which cells are "touched" (create a diagonal sweep pattern)
    touched = set()
    for r in range(rows):
        for c in range(cols):
            # Fill about 70% of cells in a natural sweep pattern
            if r < 7 or (r == 7 and c < 4):
                touched.add((r, c))

    for r in range(rows):
        for c in range(cols):
            cx = grid_x + c * (cell_w + gap)
            cy = grid_y + r * (cell_h + gap)
            color = GREEN if (r, c) in touched else SURFACE
            rounded_rect(draw, (cx, cy, cx + cell_w, cy + cell_h), 6, fill=color)

    # Bottom counter
    counter_y = py + ph - 70
    text_center(draw, "46 / 60", counter_y, font_mono(32), TEXT_MUTED)

    img.save(os.path.join(OUT, "03_touch_test.png"), "PNG")
    print("Created 03_touch_test.png")


# === Screenshot 4: Landing Page ===
def create_landing_screenshot():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Marketing text
    text_center(draw, "Free. Private.", 120, font(72), WHITE)
    text_center(draw, "On-Device.", 210, font(72), WHITE)
    text_center(draw, "17 hardware tests, zero data leaves your phone", 320, font(34), TEXT_SECONDARY)

    # Phone frame
    px, py, pw, ph = 95, 440, 1100, 2280
    draw_phone_frame(draw, px, py, pw, ph)
    draw_status_bar(draw, px, py, pw)

    sx = px + 60
    sy = py + 100
    sw = pw - 120

    # CLEARVUE label
    text_center(draw, "CLEARVUE", sy + 200, font(24), TEXT_DIM)

    # Hero title with gradient effect (simulate with two-tone)
    title_y = sy + 280
    text_center(draw, "iPhone", title_y, font(80), WHITE)
    text_center(draw, "Diagnostic", title_y + 95, font(80), TEXT_SECONDARY)

    # Subtitle
    sub_y = title_y + 230
    text_center(draw, "Run a comprehensive diagnostic", sub_y, font(30), TEXT_SECONDARY)
    text_center(draw, "on your iPhone. Get a shareable", sub_y + 44, font(30), TEXT_SECONDARY)
    text_center(draw, "report with verified test results.", sub_y + 88, font(30), TEXT_SECONDARY)

    # CTA button
    btn_w = 400
    btn_h = 72
    btn_x = px + (pw - btn_w) // 2
    btn_y = sub_y + 160
    rounded_rect(draw, (btn_x, btn_y, btn_x + btn_w, btn_y + btn_h), btn_h // 2, fill=WHITE)
    bbbox = draw.textbbox((0, 0), "Start Diagnostic", font=font(30))
    btw = bbbox[2] - bbbox[0]
    draw.text((btn_x + (btn_w - btw) // 2, btn_y + 18), "Start Diagnostic", font=font(30), fill=BLACK)

    # Feature cards
    card_y = btn_y + 130
    card_h = 100
    card_gap = 16
    features = [
        ("17 Functional Tests", "Camera, touch, audio, sensors, connectivity"),
        ("PDF Downloadable Report", "Timestamped results you can share"),
        ("0 Data Sent Nowhere", "All tests run locally on your device"),
    ]

    for i, (title, desc) in enumerate(features):
        cy = card_y + i * (card_h + card_gap)
        rounded_rect(draw, (sx, cy, sx + sw, cy + card_h), 16, fill=SURFACE)
        draw.text((sx + 24, cy + 16), title, font=font(26), fill=TEXT_PRIMARY)
        draw.text((sx + 24, cy + 52), desc, font=font(22), fill=TEXT_MUTED)

    img.save(os.path.join(OUT, "04_landing.png"), "PNG")
    print("Created 04_landing.png")


# === Screenshot 5: Display Test ===
def create_display_screenshot():
    img = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(img)

    # Marketing text
    text_center(draw, "Dead Pixel &", 120, font(72), WHITE)
    text_center(draw, "Display Check", 210, font(72), WHITE)
    text_center(draw, "Full-screen color panels reveal display defects", 320, font(34), TEXT_SECONDARY)

    # Phone frame
    px, py, pw, ph = 95, 440, 1100, 2280
    draw_phone_frame(draw, px, py, pw, ph)

    # Full-screen blue color (simulating the color test)
    blue_fill = (0, 122, 255)
    rounded_rect(draw, (px + 4, py + 4, px + pw - 4, py + ph - 4), 56, fill=blue_fill)

    # Dynamic island overlay
    island_w, island_h = 200, 56
    ix = px + (pw - island_w) // 2
    iy = py + 20
    rounded_rect(draw, (ix, iy, ix + island_w, iy + island_h), island_h // 2, fill=BLACK)

    # Bottom info badge
    badge_w = 500
    badge_h = 72
    badge_x = px + (pw - badge_w) // 2
    badge_y = py + ph - 120
    rounded_rect(draw, (badge_x, badge_y, badge_x + badge_w, badge_y + badge_h), 20,
                 fill=(0, 0, 0, 128))
    # Semi-transparent overlay - simulate with darker blue
    rounded_rect(draw, (badge_x, badge_y, badge_x + badge_w, badge_y + badge_h), 20,
                 fill=(0, 60, 130))
    text_center(draw, "Blue  \u2022  3 of 5 \u2014 Tap to continue", badge_y + 20, font(26), WHITE)

    img.save(os.path.join(OUT, "05_display_test.png"), "PNG")
    print("Created 05_display_test.png")


# === Generate all ===
if __name__ == "__main__":
    print(f"Generating App Store screenshots ({W}x{H})...")
    print(f"Output: {OUT}/")
    print()
    create_results_screenshot()
    create_camera_screenshot()
    create_touch_screenshot()
    create_landing_screenshot()
    create_display_screenshot()
    print()
    print("Done! 5 screenshots generated.")
