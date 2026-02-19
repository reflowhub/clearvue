# iPhone Diagnostic Testing Application

## Project Overview

Build a diagnostic testing platform for iPhones with two modes:

1. **B2B Operator Tool** — macOS application for factory-reset iPhones. Collects device info via USB and runs functional tests, outputting results to CSV for grading devices before resale.
2. **C2C Consumer Web App** — Public-access mobile browser app (hosted, no install required). Consumers self-diagnose their own iPhones and generate shareable test reports for peer-to-peer sales. Serves as a free marketing/trust tool for the ClearVue brand.

## Target Users

- **B2B**: Solo operator processing wiped iPhones. Devices arrive at Setup Assistant screen, need to be tested and graded, then erased before selling.
- **C2C**: Consumers selling their iPhone who want a credible diagnostic report to share with prospective buyers. Accessed via public URL on their own device's Safari browser.

## Core Requirements

### Automated Data Collection (via USB)
- IMEI
- Serial number
- Model name (e.g., "iPhone 13 Pro")
- Storage capacity (GB)
- iOS version
- Battery health percentage
- Battery cycle count
- Activation Lock status (clean/locked)

### Functional Tests (via web UI on device)

#### Biometric & Display

- Face ID — prompt unlock, tester confirms pass/fail
- Touch screen — grid test, user touches all zones
- Display quality — full-screen color panels (white, red, green, blue, black) for dead pixel / discoloration check, tester confirms pass/fail
- True Tone — toggle on/off in test prompt, tester confirms color shift visible
- Proximity sensor — cover top of screen, detect screen dim event

#### Cameras

- Front camera — capture frame, tester confirms image quality
- Rear camera — capture frame, tester confirms image quality

#### Audio

- Microphone — record short clip, playback for verification
- Speaker — play test tone, tester confirms audible

#### Connectivity

- Wi-Fi — check navigator.connection / attempt fetch to known endpoint, report signal strength
- Bluetooth — use Web Bluetooth API to scan for nearby devices, confirm radio works
- Cellular signal — navigator.connection effectiveType / downlink check (reports connection type: 4G/5G)
- GPS/Location — request geolocation permission, confirm fix acquired within timeout

#### Sensors & Hardware

- Accelerometer/Gyroscope — use DeviceMotion API, prompt user to tilt device, verify sensor data streams
- Vibration (Taptic Engine) — trigger haptic feedback (iOS 18+: checkbox-switch workaround; older iOS: mark untestable), tester confirms felt
- Physical buttons — prompt user to press volume up, volume down, side button, and mute switch; detect via keydown events or volume change where possible, otherwise tester confirms pass/fail
- NFC — use Web NFC API if available, otherwise mark as untestable (note: Safari has limited NFC support)

### Output (B2B)

- CSV file with all device info and test results
- One row per device
- Timestamped

### Output (C2C)

- On-screen results summary with timestamp (ISO 8601 + human-readable local time)
- PDF export — downloadable/shareable diagnostic report (see PDF Report section below)

## Technical Architecture

```
┌─────────────────────────────────────────────┐
│  macOS (Python application)                 │
│                                             │
│  ├── Device Manager                         │
│  │     └── pymobiledevice3 for USB comms    │
│  │                                          │
│  ├── Web Server (FastAPI)                   │
│  │     ├── GET /dashboard → operator UI     │
│  │     ├── GET /test → iPhone test page     │
│  │     └── POST /results → receive results  │
│  │                                          │
│  └── CSV Writer                             │
│        └── Append results to output.csv     │
│                                             │
└──────────────┬──────────────────────────────┘
               │ USB
               ▼
┌─────────────────────────────────────────────┐
│  iPhone (Safari)                            │
│  - Opens test page served by Mac            │
│  - Runs functional tests                    │
│  - POSTs results back                       │
└─────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Python 3.11+ |
| iOS communication | pymobiledevice3 |
| Web server | FastAPI |
| Frontend | Vanilla HTML/CSS/JS (no framework) |
| Data storage | CSV file (B2B) |
| Client-side OCR (C2C) | Tesseract.js v6+ (WASM, runs in browser) |
| Client-side PDF (C2C) | jsPDF 2.x |
| Server-side PDF (B2B) | WeasyPrint or ReportLab |

## File Structure (Monorepo)

```
clearvue/
├── iphone-diagnostic-spec.md       # This spec
│
├── shared/                          # Code used by both B2B and C2C
│   ├── static/
│   │   ├── tests.js                 # All functional test logic (cameras, mic, touch, sensors, etc.)
│   │   └── tests.css                # Test UI styling (shared)
│   └── templates/
│       └── test.html                # Test runner page (shared by both apps)
│
├── b2b/                             # macOS operator tool
│   ├── main.py                      # Entry point, starts server
│   ├── device.py                    # pymobiledevice3 wrapper, reads device info
│   ├── server.py                    # FastAPI routes (B2B)
│   ├── csv_writer.py                # Handles CSV output
│   ├── pdf_writer.py                # Server-side PDF generation (WeasyPrint/ReportLab)
│   ├── templates/
│   │   └── dashboard.html           # Operator view (runs in Chrome on Mac)
│   ├── output/
│   │   └── results.csv              # Generated output
│   └── requirements.txt
│
├── c2c/                             # Public consumer web app
│   ├── index.html                   # Landing page ("Start Free Diagnostic" CTA)
│   ├── diagnose.html                # Screenshot upload + device info + test runner
│   ├── report.html                  # Results display + PDF download + share link
│   ├── static/
│   │   ├── c2c.js                   # C2C-specific logic (screenshot upload, OCR, PDF gen)
│   │   ├── c2c.css                  # Mobile-optimized styles
│   │   └── vendor/
│   │       ├── tesseract.min.js     # Client-side OCR (WASM)
│   │       └── jspdf.min.js         # Client-side PDF generation
│   └── api/                         # Optional backend for shareable links
│       ├── server.py                # FastAPI routes (C2C report storage)
│       └── requirements.txt
│
└── PhoneCheck/                      # Reference materials
    └── lxQ-TDMcG.pdf
```

### Shared Code

The `shared/` directory contains the functional test suite used by both apps:

- `shared/static/tests.js` — all browser-based test logic (camera access, touch grid, audio recording, sensor checks, etc.). Both B2B's `test.html` and C2C's `diagnose.html` import this same file.
- `shared/templates/test.html` — the sequential test runner UI. B2B serves it via FastAPI; C2C includes it directly.

This means a bug fix or new test added to `shared/` updates both apps automatically.

## Detailed Specifications

### B2B: b2b/device.py

Functions needed:

```python
def list_connected_devices() -> list[str]:
    """Return list of UDIDs for connected iOS devices"""

def get_device_info(udid: str) -> dict:
    """
    Return device information:
    {
        "udid": str,
        "imei": str,
        "serial": str,
        "model": str,           # Human readable, e.g., "iPhone 13 Pro"
        "storage_gb": int,
        "ios_version": str,
        "battery_health": int,  # Percentage
        "battery_cycles": int
    }
    """

def get_activation_lock_status(serial: str) -> str:
    """Return 'clean' or 'locked'"""

def open_url_on_device(udid: str, url: str) -> bool:
    """Open Safari on device to specified URL"""
```

### B2B: b2b/server.py

Routes:

```
GET  /                  → Redirect to /dashboard
GET  /dashboard         → Operator dashboard (serves b2b/templates/dashboard.html)
GET  /test/{udid}       → Test page for specific device (serves shared/templates/test.html)
POST /api/devices       → List connected devices with info
POST /api/start/{udid}  → Open test page on device Safari
POST /api/results       → Receive test results from device, write to CSV
GET  /api/export        → Download CSV file
GET  /api/export/pdf/{udid} → Download PDF report for a specific device
```

### B2B: b2b/templates/dashboard.html

Operator interface showing:

- List of connected devices with auto-pulled info
- Status for each device (pending/testing/complete)
- "Start Test" button per device (opens Safari on phone)
- Test results when complete
- Export CSV button
- Export PDF button (per device)

Auto-refresh device list every 2 seconds.

### Shared: shared/templates/test.html

Sequential test flow on iPhone (used by both B2B and C2C):

1. **Face ID Test**
   - Display: "Lock your device, then unlock with Face ID"
   - Buttons: Pass / Fail

2. **Display Quality Test**
   - Full-screen color panels: white, red, green, blue, black
   - User swipes through each, checks for dead pixels / discoloration
   - Buttons: Pass / Fail

3. **True Tone Test**
   - Prompt: "Is True Tone enabled? Compare warm vs cool screen tint"
   - Buttons: Pass / Fail / Not Supported

4. **Proximity Sensor Test**
   - Prompt: "Cover the top of your screen with your hand"
   - Detect screen dim event
   - Buttons: Pass / Fail

5. **Front Camera Test**
   - Access camera via getUserMedia()
   - Display live preview
   - Buttons: Pass / Fail

6. **Rear Camera Test**
   - Switch to rear camera
   - Display live preview
   - Buttons: Pass / Fail

7. **Touch Screen Test**
   - Display 4x6 grid of boxes
   - Each box highlights when touched
   - All boxes must be touched to proceed
   - Auto-pass when complete, Fail button available

8. **Microphone Test**
   - Record 3 seconds of audio
   - Play back recording
   - Buttons: Pass / Fail

9. **Speaker Test**
   - Play 1kHz tone for 2 seconds
   - Buttons: Pass / Fail

10. **Wi-Fi Test**
    - Check navigator.connection, attempt fetch to known endpoint
    - Auto-pass if connected, display connection type
    - Buttons: Pass / Fail

11. **Bluetooth Test**
    - Attempt Web Bluetooth scan (if supported)
    - Buttons: Pass / Fail / Not Testable

12. **Cellular Signal Test**
    - Read navigator.connection effectiveType / downlink
    - Display connection type (4G/5G/LTE)
    - Buttons: Pass / Fail

13. **GPS/Location Test**
    - Request geolocation permission
    - Confirm fix acquired within 10s timeout
    - Buttons: Pass / Fail

14. **Accelerometer/Gyroscope Test**
    - Prompt: "Tilt your device in all directions"
    - Monitor DeviceMotion API for sensor data
    - Auto-pass if data streams detected, Fail button available

15. **Vibration Test**
    - Trigger haptic feedback (iOS 18+ workaround or mark untestable)
    - Buttons: Pass / Fail / Not Testable

16. **Physical Buttons Test**
    - Prompt: "Press Volume Up, Volume Down, Side Button, and toggle Mute Switch"
    - Detect where possible via events, otherwise manual confirm
    - Buttons: Pass / Fail

17. **Complete**
    - Show summary of all results
    - B2B: auto-submit to server, display "Return device to operator"
    - C2C: display results with timestamp, show "Download PDF" and "Share" buttons

### B2B: b2b/csv_writer.py

```python
def write_result(device_info: dict, test_results: dict) -> None:
    """
    Append row to output/results.csv
    
    Columns:
    imei, serial, model, storage_gb, ios_version, battery_health, 
    battery_cycles, activation_lock, faceid, front_cam, rear_cam, 
    touch, mic, speaker, tested_at
    
    Create file with headers if doesn't exist.
    """
```

### CSV Output Format (B2B)

```csv
imei,serial,model,storage_gb,ios_version,battery_health,battery_cycles,activation_lock,faceid,touch,display,true_tone,proximity,front_cam,rear_cam,mic,speaker,wifi,bluetooth,cellular,gps,accel_gyro,vibration,buttons,nfc,tested_at
359461082123456,F2LXXX123,iPhone 13 Pro,128,17.4,89,412,clean,pass,pass,pass,pass,pass,pass,pass,pass,pass,pass,pass,pass,pass,pass,pass,pass,n/a,2026-01-28T14:32:00
```

### B2B: b2b/requirements.txt

```
pymobiledevice3>=2.0.0
fastapi>=0.109.0
uvicorn>=0.27.0
weasyprint>=62.0        # Server-side PDF generation
```

### C2C: c2c/api/requirements.txt

```
fastapi>=0.109.0
uvicorn>=0.27.0
```

Note: Tesseract.js and jsPDF are client-side JS libraries loaded in the browser — they live in `c2c/static/vendor/` and have no Python dependencies.

## Workflow (B2B)

1. Operator plugs wiped iPhone into Mac via USB
2. Dashboard shows device with auto-collected info
3. Operator manually skips Setup Assistant on device (tap through) OR uses Apple Configurator
4. Once device is at home screen, operator clicks "Start Test"
5. Safari opens on iPhone with test page
6. Tester runs through each functional test
7. Results auto-submit, appear on dashboard
8. Operator erases device, moves to next
9. Export CSV at end of batch

## Workflow (C2C Consumer)

1. Consumer visits `clearvue.rhex.app` on their iPhone in Safari
2. Landing page explains what the test does, no login required
3. Consumer taps "Start Free Diagnostic"
4. App auto-detects what it can (model via user agent, iOS version, screen size)
5. **Screenshot verification step**: app guides user through two screenshots:
   - Step A: "Go to Settings > General > About — take a screenshot, then come back and upload it"
   - Step B: "Go to Settings > Battery > Battery Health — take a screenshot, then come back and upload it"
6. App runs client-side OCR (Tesseract.js) on uploaded screenshots to extract IMEI, serial, storage, battery health
7. Extracted values shown to user for confirmation; user corrects if OCR misread
8. Sequential functional test flow runs (same browser-based tests as B2B)
9. Results summary screen displays with timestamp
10. Consumer taps "Download PDF Report" or "Share Report"
11. PDF generates client-side with test results + screenshot thumbnails as visual proof
12. Optional: consumer can copy a shareable link (results stored temporarily server-side with unique ID)

---

## C2C Consumer Web App — Detailed Spec

### Overview

A publicly accessible, mobile-optimized web app that runs entirely in Safari on the consumer's own iPhone. No app install, no login, no payment. Serves as a trust-building marketing tool for ClearVue while giving consumers a credible diagnostic report to share with buyers.

### What C2C Can and Cannot Access

| Data Point | B2B (USB) | C2C (Browser) | C2C Method |
| --- | --- | --- | --- |
| IMEI | Yes | Screenshot-verified | Screenshot of Settings > About + OCR extraction |
| Serial number | Yes | Screenshot-verified | Screenshot of Settings > About + OCR extraction |
| Model name | Yes | Partial | User agent string + user confirmation |
| Storage capacity | Yes | Screenshot-verified | Screenshot of Settings > About + OCR extraction |
| iOS version | Yes | Yes | `navigator.userAgent` parsing |
| Battery health | Yes | Screenshot-verified | Screenshot of Settings > Battery Health + OCR extraction |
| Battery cycle count | Yes | No | Not shown in iOS Settings UI |
| Activation Lock | Yes | No | Not testable from browser |
| All functional tests | Yes | Yes | Same browser APIs |

### C2C Technical Architecture

```
┌─────────────────────────────────────────────────┐
│  Hosted Web Server (FastAPI or static + API)     │
│                                                  │
│  ├── Static Frontend (mobile-optimized)          │
│  │     ├── Landing page                          │
│  │     ├── Device info form                      │
│  │     ├── Test runner (same test.js logic)       │
│  │     ├── Results display                       │
│  │     └── PDF generator (client-side)           │
│  │                                               │
│  ├── API (optional, for shareable links)         │
│  │     ├── POST /api/c2c/results → store results │
│  │     └── GET /api/c2c/report/{id} → view report│
│  │                                               │
│  └── Analytics (anonymous usage tracking)        │
│                                                  │
└─────────────────────────────────────────────────┘
         │
         │ HTTPS (consumer's own connection)
         ▼
┌─────────────────────────────────────────────────┐
│  Consumer's iPhone (Safari)                      │
│  - Visits public URL                             │
│  - Runs all browser-based functional tests       │
│  - Generates PDF report locally                  │
│  - Optionally shares via link                    │
└─────────────────────────────────────────────────┘
```

### C2C Routes

```
GET  /                     → Landing page with "Start Free Diagnostic" CTA
GET  /diagnose             → Device info form + test runner
POST /api/c2c/results      → Store results, return unique report ID
GET  /report/{id}          → Shareable report view (read-only, public)
GET  /report/{id}/pdf      → Server-generated PDF fallback
```

### C2C Device Info Collection — Screenshot Verification

Instead of relying on self-reported text input (easy to fabricate), the C2C app uses a **screenshot upload + OCR** workflow to extract and verify device info. This produces a more credible report for prospective buyers.

#### Screenshot Upload Flow

**Step 1 — Settings > General > About screenshot:**

- App displays visual guide: "Open Settings > General > About. Take a screenshot. Come back here and upload it."
- Include annotated example screenshot showing where IMEI, serial, storage, and model appear
- User taps "Upload Screenshot" — standard file input (`<input type="file" accept="image/*">`) opens photo picker
- On upload, Tesseract.js runs client-side OCR to extract: model name, storage capacity, IMEI, serial number
- Extracted values shown in editable fields for user to confirm or correct

**Step 2 — Settings > Battery > Battery Health screenshot:**

- App displays visual guide: "Open Settings > Battery > Battery Health & Charging. Take a screenshot."
- User uploads screenshot
- OCR extracts: Maximum Capacity percentage
- Value shown for user confirmation

#### OCR Implementation

- Library: Tesseract.js v6+ (runs entirely in-browser via WebAssembly, no server upload)
- Language: English only (iOS Settings screens)
- Processing: client-side — screenshot image data never leaves the user's device
- Fallback: if OCR fails to parse, user can manually enter values (labeled "manual entry — unverified" on report)
- Performance: ~2-4 seconds per screenshot on modern iPhones

#### Verification Labels on Report

| Source | Label on Report | Credibility |
| --- | --- | --- |
| OCR-extracted from screenshot | "Screenshot-verified" | High — screenshot thumbnail included as proof |
| Manual entry (OCR failed) | "Self-reported" | Lower — no visual proof |
| Auto-detected (user agent) | "Auto-detected" | Medium — browser-derived |
| Browser API (functional test) | "Tested" | High — verified by test |

#### Screenshot Thumbnails in PDF

- Both uploaded screenshots are embedded as thumbnail images in the PDF report
- Positioned in a "Verification Evidence" section after the test results
- Allows buyer to visually confirm the device info matches the screenshots
- Screenshots are resized/compressed client-side before PDF embedding (max 400px wide)

#### Manual Entry Fallback

If user cannot or chooses not to upload screenshots, they can skip to manual entry:

- Model name — dropdown (auto-detected from user agent where possible)
- Storage capacity — dropdown (32/64/128/256/512GB/1TB)
- Battery health % — text input
- IMEI (optional) — text input, with instructions: "Dial *#06#"
- Serial number (optional) — text input

All manually entered fields are labeled "Self-reported (unverified)" on the final report.

### C2C Test Flow

Same sequential test flow as B2B (all browser-based functional tests). The test page is identical — the only differences are:

- Device info collected via screenshot OCR instead of USB (see Screenshot Verification above)
- Battery cycle count and Activation Lock status not available (no USB access)
- Results display includes clear labeling: "Screenshot-verified" / "Self-reported" / "Tested"

### C2C Results Display

On-screen results page showing:

- ClearVue branding and report header
- Timestamp: both ISO 8601 (`2026-01-28T14:32:00Z`) and human-readable (`January 28, 2026 at 2:32 PM`)
- Device info section (with "self-reported" labels where applicable)
- Test results grid: each test with pass/fail/untestable status
- Overall summary score (e.g., "14/15 tests passed")
- "Download PDF" button
- "Copy Share Link" button (if server storage enabled)
- ClearVue footer with branding

---

## PDF Diagnostic Report

### Applies To

Both B2B (operator can export per-device) and C2C (consumer downloads directly).

### Generation Method

- **C2C**: Client-side PDF generation using jsPDF (no server round-trip, works offline after page load)
- **B2B**: Server-side generation via WeasyPrint or ReportLab (operator clicks "Export PDF" from dashboard)
- **Shareable link fallback**: Server-side PDF generation at `/report/{id}/pdf`

### PDF Report Contents

```
┌──────────────────────────────────────────────┐
│  ClearVue iPhone Diagnostic Report           │
│                                              │
│  Report ID: CVR-2026-01-28-A3F9             │
│  Generated: January 28, 2026 at 2:32 PM EST │
│                                              │
│  ─── Device Information ───────────────────  │
│  Model:          iPhone 13 Pro               │
│  Storage:        128 GB                      │
│  iOS Version:    17.4                        │
│  IMEI:           359461082123456  [if provided]│
│  Serial:         F2LXXX123       [if provided]│
│  Battery Health:  89%            [source]     │
│  Battery Cycles:  412            [B2B only]   │
│  Activation Lock: Clean          [B2B only]   │
│                                              │
│  ─── Functional Test Results ─────────────── │
│                                              │
│  Face ID              ✓ Pass                 │
│  Touch Screen         ✓ Pass                 │
│  Display Quality      ✓ Pass                 │
│  True Tone            ✓ Pass                 │
│  Proximity Sensor     ✓ Pass                 │
│  Front Camera         ✓ Pass                 │
│  Rear Camera          ✓ Pass                 │
│  Microphone           ✓ Pass                 │
│  Speaker              ✓ Pass                 │
│  Wi-Fi                ✓ Pass                 │
│  Bluetooth            ✓ Pass                 │
│  Cellular Signal      ✓ Pass                 │
│  GPS/Location         ✓ Pass                 │
│  Accelerometer/Gyro   ✓ Pass                 │
│  Vibration            ✓ Pass                 │
│  Physical Buttons     ✗ Fail                 │
│  NFC                  — Not Testable         │
│                                              │
│  Overall: 15/16 tests passed                 │
│                                              │
│  ─── Verification Evidence (C2C only) ────── │
│                                              │
│  [Settings > About screenshot thumbnail]     │
│  [Battery Health screenshot thumbnail]       │
│  Source labels: Screenshot-verified /         │
│                 Self-reported / Auto-detected │
│                                              │
│  ─── Report Metadata ─────────────────────── │
│  Source: [ClearVue B2B Tool / ClearVue C2C]  │
│  Self-reported fields marked with *          │
│  Verify report: clearvue.rhex.app/report/ID  │
│                                              │
│  © 2026 ClearVue — clearvue.rhex.app        │
└──────────────────────────────────────────────┘
```

---

## B2B Notes

- Device must be past Setup Assistant (at home screen) for Safari to open
- For devices stuck at Setup Assistant, operator should use Apple Configurator 2 to skip setup automatically, or tap through manually
- pymobiledevice3 can read device info even at Setup Assistant, but cannot open URLs until device is activated
- Test page should work offline once loaded (no external dependencies)
- Dashboard should handle multiple devices connected simultaneously

## C2C Notes

- No login, no payment, no app install — frictionless access is critical for adoption
- Must work in Safari on iOS 15+ (vast majority of iPhones in resale market)
- Web Bluetooth API has limited Safari support — mark Bluetooth as "untestable" on unsupported browsers with graceful fallback
- NFC testing via Web NFC is not supported in Safari — always mark as "not testable" on iOS
- `navigator.vibrate()` is not supported in Safari — on iOS 18+, use the checkbox-switch haptic workaround (`<input type="checkbox" switch>` + programmatic label click); on older iOS, mark vibration test as "not testable"
- Self-reported data should be clearly labeled on reports to maintain credibility
- Consider rate limiting and basic abuse prevention (e.g., max 10 reports per IP per day)
- Report share links should expire after 30 days
- All data collection must include a privacy notice / consent banner

## C2C Implementation Plan

### Phase 1 — Landing Page + Core Test Runner

**Goal**: Get a working test page live at `clearvue.rhex.app` that runs functional tests and shows results.

**Files to create:**

- `c2c/index.html` — landing page with ClearVue branding, "Start Free Diagnostic" button
- `c2c/diagnose.html` — loads the shared test runner
- `shared/static/tests.js` — implement first 6 core tests: Face ID, front camera, rear camera, touch screen, microphone, speaker
- `shared/static/tests.css` — mobile-first test UI styling
- `shared/templates/test.html` — sequential test runner shell (step indicator, pass/fail buttons, navigation)

**Steps:**

1. Scaffold `c2c/` directory with `index.html` landing page (static HTML, ClearVue branding, mobile viewport meta)
2. Build `shared/templates/test.html` — test runner framework: step-by-step UI, progress bar, pass/fail/skip buttons per test, results collection in JS object
3. Implement core tests in `shared/static/tests.js`:
   - Face ID (manual confirm — prompt + pass/fail)
   - Front camera (`getUserMedia({ video: { facingMode: "user" } })`)
   - Rear camera (`getUserMedia({ video: { facingMode: "environment" } })`)
   - Touch screen (4x6 grid, touch event listeners, highlight on touch)
   - Microphone (`getUserMedia({ audio: true })` + MediaRecorder + playback)
   - Speaker (AudioContext oscillator, 1kHz tone for 2s)
4. Build `c2c/diagnose.html` — imports `shared/static/tests.js`, wires up test runner, collects results into JS object
5. Add results summary screen at end of test flow — show pass/fail for each test with timestamp
6. Test on physical iPhone in Safari — verify camera/mic permissions, touch grid, audio playback all work
7. Deploy static files to `clearvue.rhex.app`

**Done when**: A user can visit the URL, tap Start, run through 6 tests, and see a results summary with timestamp.

---

### Phase 2 — Remaining Tests + Safari Compatibility

**Goal**: Implement all 17 tests, handle Safari-specific limitations gracefully.

**Steps:**

1. Add display quality test — full-screen color panels (white/red/green/blue/black), swipe or tap to advance, pass/fail
2. Add True Tone test — instructional prompt, pass/fail/not supported buttons
3. Add proximity sensor test — listen for `DeviceLightEvent` or use ambient light sensor API; fallback to manual confirm
4. Add Wi-Fi test — `navigator.connection` check + `fetch()` to known endpoint with timeout
5. Add Bluetooth test — `navigator.bluetooth.requestDevice()` wrapped in try/catch; show "Not Testable" on Safari (no Web Bluetooth support)
6. Add cellular signal test — `navigator.connection.effectiveType` + `downlink` reading
7. Add GPS/Location test — `navigator.geolocation.getCurrentPosition()` with 10s timeout
8. Add accelerometer/gyroscope test — `DeviceMotionEvent.requestPermission()` (required on iOS 13+), then listen for motion data, auto-pass if data streams
9. Add vibration test — detect iOS version; iOS 18+: use checkbox-switch haptic workaround; older: mark "Not Testable"
10. Add physical buttons test — prompt each button in sequence, detect via `volumechange` event (volume buttons), manual confirm for side button and mute switch
11. Add NFC test — always mark "Not Testable" on iOS Safari (no Web NFC support)
12. Update results summary to handle all 17 tests with pass/fail/not testable states
13. Test full suite on multiple iPhone models (iPhone 12, 13, 14, 15 series) across iOS 15-18

**Done when**: All 17 tests run on Safari iOS 15+, with graceful "Not Testable" labels for unsupported APIs.

---

### Phase 3 — Screenshot OCR + Device Info Collection

**Goal**: Add screenshot upload workflow with Tesseract.js to extract and verify device info.

**Steps:**

1. Add Tesseract.js v6 to `c2c/static/vendor/` (download WASM + worker files for offline use)
2. Build screenshot upload UI in `c2c/diagnose.html` — two-step flow before tests begin:
   - Step A: visual guide for Settings > General > About, upload button (`<input type="file" accept="image/*">`)
   - Step B: visual guide for Settings > Battery > Battery Health, upload button
   - "Skip — enter manually" link for fallback
3. Implement OCR extraction in `c2c/static/c2c.js`:
   - Initialize Tesseract worker on page load (preload for speed)
   - On screenshot upload: run `worker.recognize(image)`, parse text output
   - Settings > About parser: regex extraction for model name, storage (e.g., "128 GB"), IMEI (15 digits), serial number
   - Battery Health parser: regex for "Maximum Capacity" + percentage
4. Show extracted values in editable confirmation form — user reviews and corrects if needed
5. Auto-detect from user agent: iOS version, approximate model name — pre-fill as "Auto-detected" values
6. Build manual entry fallback form (dropdowns + text inputs) for when OCR is skipped or fails
7. Apply verification labels to each data point: "Screenshot-verified" / "Auto-detected" / "Self-reported"
8. Store screenshot image data in memory (base64) for later PDF embedding
9. Test OCR accuracy on screenshots from multiple iPhone models and iOS versions
10. Test with non-English iOS Settings (should label as "OCR failed" and fall back to manual)

**Done when**: Users can upload Settings screenshots, see extracted device info, confirm values, then proceed to tests. All values carry verification labels.

---

### Phase 4 — PDF Report Generation

**Goal**: Generate a branded, downloadable PDF report with test results, device info, and screenshot evidence.

**Steps:**

1. Add jsPDF 2.x to `c2c/static/vendor/`
2. Build `c2c/report.html` — results display page with:
   - ClearVue branding header
   - Timestamp (ISO 8601 + human-readable)
   - Device info section with verification labels
   - Test results grid (pass/fail/not testable with icons)
   - Overall score (e.g., "14/16 tests passed")
   - "Download PDF" button
   - "Copy Share Link" button (disabled until Phase 5)
3. Implement PDF generation in `c2c/static/c2c.js`:
   - Generate unique report ID (format: `CVR-YYYY-MM-DD-XXXX`)
   - Build PDF layout matching the spec wireframe: header, device info, test results table, verification evidence section, footer
   - Embed screenshot thumbnails (resized to max 400px wide, compressed as JPEG)
   - Add ClearVue branding, report metadata, verification URL placeholder
4. Wire "Download PDF" button — `jsPDF.save('clearvue-report-{id}.pdf')`
5. Test PDF generation on Safari iOS — verify file downloads correctly, images render, text is readable
6. Test PDF on desktop (open the downloaded file) — verify formatting holds

**Done when**: User completes tests, sees results page, taps "Download PDF", and gets a branded report with all device info, test results, and screenshot thumbnails.

---

### Phase 5 — Shareable Links + Backend API (Optional)

**Goal**: Allow users to share reports via URL. Requires a lightweight backend.

**Steps:**

1. Build `c2c/api/server.py` — FastAPI app with:
   - `POST /api/c2c/results` — accepts JSON report data + base64 screenshot images, stores in DB/filesystem, returns unique report ID
   - `GET /report/{id}` — serves read-only HTML report view
   - `GET /report/{id}/pdf` — server-side PDF generation fallback (for sharing with non-Safari users)
2. Add SQLite or JSON file storage for reports (lightweight, no external DB dependency for MVP)
3. Implement rate limiting: max 10 reports per IP per day
4. Add report expiry: auto-delete reports after 30 days
5. Add privacy notice / consent banner before any data is stored server-side
6. Wire "Copy Share Link" button on `c2c/report.html` — POST results to API, receive URL, copy to clipboard
7. Build read-only report view at `/report/{id}` — same layout as `report.html` but populated from stored data
8. Add verification URL to PDF footer: `clearvue.rhex.app/report/{id}`
9. Deploy API alongside static frontend
10. Test end-to-end: complete diagnostic → share link → open on another device → view report

**Done when**: Users can share a `clearvue.rhex.app/report/{id}` link with prospective buyers. Links expire after 30 days.

---

### Phase 6 — Polish + Launch

**Goal**: Production readiness, performance, and branding.

**Steps:**

1. Add loading states and progress indicators for OCR processing and PDF generation
2. Add error handling for all browser API permission denials (camera, mic, location) — show helpful "Permission denied" messages with instructions
3. Optimize Tesseract.js loading — lazy-load WASM only when screenshot upload begins
4. Add `<meta>` tags for mobile web app: viewport, theme-color, apple-mobile-web-app-capable
5. Add favicon and Apple touch icon (ClearVue branding)
6. Add anonymous analytics (page views, test completion rate, PDF downloads) — lightweight, privacy-respecting
7. Add "Powered by ClearVue" branding throughout with link to main site
8. Cross-device testing: iPhone SE, iPhone 12 mini, iPhone 14, iPhone 15 Pro Max, iPhone 16 — verify layout and tests work across screen sizes
9. Performance audit: ensure full diagnostic flow (including OCR + PDF) completes in under 5 minutes
10. Write brief user-facing FAQ: "What does this test?", "Is my data private?", "How do I share my report?"

**Done when**: App is deployed, branded, performant, and ready for public use at `clearvue.rhex.app`.

---

## Future Enhancements (out of scope for MVP)

- Barcode scanner integration for tracking
- Photo capture for cosmetic grading
- Apple Configurator automation via CLI
- Batch erase functionality
- Database storage instead of CSV
- Print labels with device grade
- QR code on PDF report linking to online verification
- Consumer account creation for report history
- API for marketplace integrations (eBay, Swappa, Facebook Marketplace)
