/**
 * Clearvue Test Runner
 * Shared functional test suite for B2B and C2C diagnostic apps.
 *
 * Usage:
 *   const runner = new TestRunner(containerEl);
 *   runner.start();
 */

/* ------------------------------------------------------------------ */
/*  Device Info Detection                                              */
/* ------------------------------------------------------------------ */

const DeviceInfo = {
    detect() {
        const ua = navigator.userAgent;
        const info = {};

        const iosMatch = ua.match(/OS (\d+[_\.]\d+[_\.]?\d*)/);
        if (iosMatch) {
            info.iosVersion = iosMatch[1].replace(/_/g, '.');
        }

        info.screenResolution = `${screen.width}\u00d7${screen.height}`;
        info.devicePixelRatio = window.devicePixelRatio || 1;
        info.modelGuess = this._guessModel(screen.width, screen.height, window.devicePixelRatio);

        return info;
    },

    _guessModel(w, h, dpr) {
        const key = `${Math.min(w, h)}x${Math.max(w, h)}@${dpr}`;
        const models = {
            '393x852@3': 'iPhone 15 / 15 Pro / 16',
            '430x932@3': 'iPhone 15 Plus / 15 Pro Max / 16 Plus',
            '402x874@3': 'iPhone 16 Pro',
            '440x956@3': 'iPhone 16 Pro Max',
            '390x844@3': 'iPhone 14 / 13',
            '428x926@3': 'iPhone 14 Plus / 13 Pro Max',
            '375x812@3': 'iPhone 13 mini / 12 mini / X / XS',
            '414x896@3': 'iPhone 11 Pro Max / XS Max',
            '414x896@2': 'iPhone 11 / XR',
            '375x667@2': 'iPhone SE (2nd/3rd gen) / 8',
            '320x568@2': 'iPhone SE (1st gen)',
        };
        return models[key] || null;
    },

    validateIMEI(imei) {
        if (imei.length !== 15 || !/^\d{15}$/.test(imei)) return false;
        let sum = 0;
        for (let i = 0; i < imei.length; i++) {
            let d = parseInt(imei[i], 10);
            if (i % 2 === 1) {
                d *= 2;
                if (d > 9) d -= 9;
            }
            sum += d;
        }
        return sum % 10 === 0;
    },
};

/* ------------------------------------------------------------------ */
/*  Test Definitions                                                   */
/* ------------------------------------------------------------------ */

const TEST_DEFS = [
    // --- Biometric & Display ---
    { id: 'faceid', name: 'Face ID', description: 'Verifying Face ID biometric hardware.', verification: 'demo' },
    { id: 'display', name: 'Display Quality', description: 'Checking display for dead pixels and discoloration.', verification: 'demo' },

    // --- Cameras ---
    { id: 'front_cam', name: 'Front Camera', description: 'Testing front-facing camera functionality.', verification: 'demo' },
    { id: 'rear_cam', name: 'Rear Camera', description: 'Testing rear camera functionality.', verification: 'demo' },

    // --- Input ---
    { id: 'touch', name: 'Touch Screen', description: 'Verifying touch screen responsiveness.', verification: 'demo' },

    // --- Audio ---
    { id: 'mic', name: 'Microphone', description: 'Testing microphone audio input.', verification: 'demo' },
    { id: 'speaker', name: 'Speaker', description: 'Testing speaker audio output.', verification: 'demo' },

    // --- Connectivity ---
    { id: 'wifi', name: 'Wi-Fi', description: 'Testing Wi-Fi connectivity.', verification: 'demo' },
    { id: 'bluetooth', name: 'Bluetooth', description: 'Verifying Bluetooth radio functionality.', verification: 'demo' },
    { id: 'cellular', name: 'Cellular Signal', description: 'Testing cellular data connectivity.', verification: 'demo' },
    { id: 'gps', name: 'GPS / Location', description: 'Verifying GPS hardware and location services.', verification: 'demo' },

    // --- Sensors & Hardware ---
    { id: 'accel_gyro', name: 'Accelerometer / Gyroscope', description: 'Testing motion sensor hardware.', verification: 'demo' },
    { id: 'buttons', name: 'Physical Buttons', description: 'Verifying physical button functionality.', verification: 'demo' },
];

/* ------------------------------------------------------------------ */
/*  TestRunner Class                                                   */
/* ------------------------------------------------------------------ */

class TestRunner {
    constructor(container) {
        this.container = container;
        this.tests = TEST_DEFS;
        this.results = {};
        this.currentIndex = 0;
        this.phase = 'deviceInfo';
        this.deviceInfo = {};
        this.imei = null;
    }

    start() {
        this.deviceInfo = DeviceInfo.detect();
        this.phase = 'deviceInfo';
        this._renderDeviceInfo();
    }

    _startTests() {
        this.currentIndex = 0;
        this.results = {};
        this.phase = 'testing';
        this._renderTest();
    }

    /* --- Device Info Screen ---------------------------------------- */

    _renderDeviceInfo() {
        const info = this.deviceInfo;
        let rows = '';
        if (info.modelGuess) {
            rows += `<div class="device-info-row"><span>Model (estimated)</span><span>${info.modelGuess}</span></div>`;
        }
        if (info.iosVersion) {
            rows += `<div class="device-info-row"><span>iOS Version</span><span>${info.iosVersion}</span></div>`;
        }
        rows += `<div class="device-info-row"><span>Screen</span><span>${info.screenResolution} @${info.devicePixelRatio}x</span></div>`;

        this.container.innerHTML = `
            <div class="device-info-screen">
                <div class="device-info-header">
                    <div class="device-info-icon">\u24D8</div>
                    <h2>Device Information</h2>
                    <p class="device-info-desc">Auto-detected device details for your diagnostic report.</p>
                </div>
                <div class="device-info-card">${rows}</div>
                <div class="device-info-actions">
                    <button class="btn btn-start" id="diContinueBtn">Start Tests</button>
                </div>
            </div>
        `;

        this.container.querySelector('#diContinueBtn').addEventListener('click', () => {
            this.imei = null;
            this._startTests();
        });
    }

    /* --- Rendering ------------------------------------------------ */

    _renderTest() {
        this._cleanup();
        const test = this.tests[this.currentIndex];
        if (!test) { this._renderResults(); return; }

        const pct = Math.round((this.currentIndex / this.tests.length) * 100);
        const backDisabled = this.currentIndex === 0 ? 'disabled' : '';

        this.container.innerHTML = `
            <div class="test-header">
                <div class="test-nav">
                    <button class="nav-btn" id="navBack" ${backDisabled} aria-label="Go back">\u25C0</button>
                    <span class="brand">Clearvue</span>
                    <div class="nav-right">
                        <button class="nav-btn" id="navRepeat" aria-label="Repeat test">\u21BB</button>
                        <button class="nav-btn" id="navExit" aria-label="Exit">\u2715</button>
                    </div>
                </div>
                <div class="progress-bar"><div class="progress-fill" style="width:${pct}%"></div></div>
                <div class="progress-text">Test ${this.currentIndex + 1} of ${this.tests.length}</div>
            </div>
            <div class="test-body" id="testBody">
                <h2>${test.name}</h2>
                <p class="test-description">${test.description}</p>
                <div id="testContent"></div>
            </div>
            <div class="test-actions" id="testActions"></div>
        `;

        this.container.querySelector('#navBack').addEventListener('click', () => this._goBack());
        this.container.querySelector('#navRepeat').addEventListener('click', () => this._repeatTest());
        this.container.querySelector('#navExit').addEventListener('click', () => this._confirmExit());

        const content = this.container.querySelector('#testContent');
        const actions = this.container.querySelector('#testActions');

        // Demo mode: all tests auto-pass with brief visual
        this._setupDemoTest(content, actions, test);
    }

    _setupDemoTest(content, actions, test) {
        content.innerHTML = `
            <div class="demo-indicator">
                <div class="demo-ring"></div>
                <div class="demo-check" id="demoCheck"></div>
            </div>
            <div class="demo-status-label" id="demoLabel">Testing...</div>
        `;
        actions.innerHTML = '';

        setTimeout(() => {
            const ring = this.container.querySelector('.demo-ring');
            const check = this.container.querySelector('#demoCheck');
            const label = this.container.querySelector('#demoLabel');
            if (ring) ring.classList.add('complete');
            if (check) check.classList.add('visible');
            if (label) {
                label.textContent = 'Passed';
                label.classList.add('passed');
            }
            setTimeout(() => this._record(test.id, 'pass'), 600);
        }, 1500);
    }

    _record(testId, result) {
        this.results[testId] = result;
        this.currentIndex++;
        this._renderTest();
    }

    /* --- Navigation ----------------------------------------------- */

    _goBack() {
        if (this.currentIndex <= 0) return;
        const prevTest = this.tests[this.currentIndex - 1];
        delete this.results[prevTest.id];
        this.currentIndex--;
        this._renderTest();
    }

    _repeatTest() {
        const test = this.tests[this.currentIndex];
        if (test) delete this.results[test.id];
        this._renderTest();
    }

    _confirmExit() {
        const overlay = document.createElement('div');
        overlay.className = 'exit-confirm-overlay';
        overlay.innerHTML = `
            <div class="exit-confirm-card">
                <h3>Exit Diagnostic?</h3>
                <p>Your test progress will be lost.</p>
                <div class="exit-confirm-actions">
                    <button class="btn btn-start" id="exitCancel">Continue Testing</button>
                    <button class="btn btn-fail" id="exitConfirm">Exit</button>
                </div>
            </div>
        `;
        document.body.appendChild(overlay);

        overlay.querySelector('#exitCancel').addEventListener('click', () => overlay.remove());
        overlay.querySelector('#exitConfirm').addEventListener('click', () => {
            overlay.remove();
            this._cleanup();
            window.location.href = 'index.html';
        });
    }

    /* --- Results -------------------------------------------------- */

    _renderResults() {
        this._cleanup();
        this.phase = 'results';
        const now = new Date();
        const human = now.toLocaleString('en-US', {
            year: 'numeric', month: 'long', day: 'numeric',
            hour: 'numeric', minute: '2-digit', hour12: true,
        });

        const passed = Object.values(this.results).filter(r => r === 'pass').length;
        const tested = Object.values(this.results).filter(r => r === 'pass' || r === 'fail').length;
        const notTestable = Object.values(this.results).filter(r => r === 'not_testable').length;
        const scoreExtra = notTestable > 0 ? ` <span class="results-note">(${notTestable} not testable)</span>` : '';

        // Device info card
        const info = this.deviceInfo;
        let deviceRows = '';
        if (info.modelGuess) {
            deviceRows += `<div class="device-info-row"><span>Model (est.)</span><span>${info.modelGuess}</span></div>`;
        }
        if (info.iosVersion) {
            deviceRows += `<div class="device-info-row"><span>iOS</span><span>${info.iosVersion}</span></div>`;
        }
        deviceRows += `<div class="device-info-row"><span>Screen</span><span>${info.screenResolution} @${info.devicePixelRatio}x</span></div>`;
        if (this.imei) {
            deviceRows += `<div class="device-info-row"><span>IMEI</span><span class="mono">${this.imei}</span></div>`;
        }

        // Test results list
        let listHTML = '';
        for (const test of this.tests) {
            const result = this.results[test.id] || 'skipped';
            let badgeClass, badgeText;
            switch (result) {
                case 'pass':         badgeClass = 'pass';         badgeText = 'Pass'; break;
                case 'fail':         badgeClass = 'fail';         badgeText = 'Fail'; break;
                case 'not_testable': badgeClass = 'not-testable'; badgeText = 'Not Testable'; break;
                default:             badgeClass = 'skipped';      badgeText = 'Skipped'; break;
            }

            const verLabel = test.verification === 'demo'
                ? '<span class="result-verification">Demo</span>'
                : '';

            listHTML += `
                <li>
                    <span class="result-name">${test.name}${verLabel}</span>
                    <span class="result-badge ${badgeClass}">${badgeText}</span>
                </li>`;
        }

        this.container.innerHTML = `
            <div class="results-screen">
                <div class="results-header">
                    <div class="brand">Clearvue</div>
                    <h2>Diagnostic Complete</h2>
                    <div class="results-score">${passed} / ${tested} tests passed${scoreExtra}</div>
                    <div class="results-timestamp">${human}</div>
                </div>
                <div class="results-device-card">${deviceRows}</div>
                <div class="app-promo">
                    <div class="app-promo-badge">iOS App</div>
                    <div class="app-promo-text">Get the full Clearvue experience &mdash; Bluetooth, Face ID, and more verified with native hardware access.</div>
                    <div class="app-promo-note">Coming soon to the App Store</div>
                </div>
                <ul class="results-list">${listHTML}</ul>
                <div class="imei-section results-imei" id="imeiSection">
                    <label class="imei-label">IMEI Required</label>
                    <p class="imei-desc">Enter your IMEI to include it in the diagnostic results.</p>
                    <input type="text" id="resultsImeiInput" class="imei-input"
                           placeholder="Enter or paste IMEI" inputmode="numeric"
                           maxlength="15" autocomplete="off">
                    <div class="imei-error hidden" id="resultsImeiError">Invalid IMEI \u2014 must be 15 digits</div>
                    <div class="imei-instructions">
                        <div class="imei-instructions-title">How to find your IMEI:</div>
                        <div>1. Go to <strong>Settings &gt; General &gt; About</strong></div>
                        <div>2. Long-press the <strong>IMEI</strong> to copy it</div>
                        <div>3. Come back here and paste</div>
                    </div>
                    <button class="btn btn-start btn-sm" id="saveImeiBtn">Save IMEI</button>
                </div>
                <div class="results-actions">
                    <button class="btn btn-start" id="restartBtn">Run Again</button>
                </div>
                <div class="results-footer">&copy; 2026 Clearvue &mdash; clearvue.rhex.app</div>
            </div>
        `;

        this.container.querySelector('#restartBtn').addEventListener('click', () => {
            this._startTests();
        });

        // IMEI input in results
        const imeiSection = this.container.querySelector('#imeiSection');
        const imeiInput = this.container.querySelector('#resultsImeiInput');
        const imeiError = this.container.querySelector('#resultsImeiError');

        if (this.imei) {
            imeiSection.style.display = 'none';
        }

        imeiInput.addEventListener('input', () => {
            imeiInput.value = imeiInput.value.replace(/\D/g, '');
            imeiError.classList.add('hidden');
        });

        this.container.querySelector('#saveImeiBtn').addEventListener('click', () => {
            const val = imeiInput.value.trim();
            if (!val) {
                imeiError.textContent = 'IMEI is required';
                imeiError.classList.remove('hidden');
                return;
            }
            if (!DeviceInfo.validateIMEI(val)) {
                imeiError.textContent = 'Invalid IMEI \u2014 must be 15 digits';
                imeiError.classList.remove('hidden');
                return;
            }
            this.imei = val;
            // Update device card with IMEI
            const deviceCard = this.container.querySelector('.results-device-card');
            deviceCard.innerHTML += `<div class="device-info-row"><span>IMEI</span><span class="mono">${val}</span></div>`;
            imeiSection.style.display = 'none';
        });

        this.container.dispatchEvent(new CustomEvent('testscomplete', {
            detail: { results: { ...this.results }, timestamp: now.toISOString(), tests: this.tests },
        }));
    }

    /* --- Cleanup -------------------------------------------------- */

    _cleanup() {
        // No hardware resources to clean up in demo mode
    }
}
