/**
 * ClearVue Test Runner
 * Shared functional test suite for B2B and C2C diagnostic apps.
 *
 * Usage:
 *   const runner = new TestRunner(containerEl);
 *   runner.start();
 */

/* ------------------------------------------------------------------ */
/*  Test Definitions                                                   */
/* ------------------------------------------------------------------ */

const TEST_DEFS = [
    // --- Biometric & Display ---
    {
        id: 'faceid',
        name: 'Face ID',
        description: 'Lock your screen (press the side button), then unlock using Face ID.',
        type: 'manual',
        verification: 'self-reported',
        note: 'Uses same TrueDepth camera as Front Camera test',
    },
    {
        id: 'display',
        name: 'Display Quality',
        description: 'Full-screen color panels will appear. Check each for dead pixels, discoloration, or backlight bleed. Tap to advance through each color.',
        type: 'display',
        verification: 'self-reported',
        colors: ['#ffffff', '#ff0000', '#00ff00', '#0000ff', '#000000'],
        colorNames: ['White', 'Red', 'Green', 'Blue', 'Black'],
    },
    {
        id: 'truetone',
        name: 'True Tone',
        description: 'Go to Settings \u203a Display & Brightness. Toggle True Tone on and off. Does the screen tint shift between warm and cool?',
        type: 'manual',
        verification: 'self-reported',
        extraButtons: ['not_supported'],
    },
    {
        id: 'proximity',
        name: 'Proximity Sensor',
        description: 'Make a phone call (or call voicemail). Cover the top of the screen with your hand. The screen should turn off.',
        type: 'manual',
        verification: 'self-reported',
    },

    // --- Cameras ---
    {
        id: 'front_cam',
        name: 'Front Camera',
        description: 'Check that the front camera shows a clear image.',
        type: 'camera',
        facingMode: 'user',
        verification: 'tested',
    },
    {
        id: 'rear_cam',
        name: 'Rear Camera',
        description: 'Check that the rear camera shows a clear image.',
        type: 'camera',
        facingMode: 'environment',
        verification: 'tested',
    },

    // --- Input ---
    {
        id: 'touch',
        name: 'Touch Screen',
        description: 'Touch every cell in the grid below.',
        type: 'touch',
        verification: 'tested',
    },

    // --- Audio ---
    {
        id: 'mic',
        name: 'Microphone',
        description: 'A short audio clip will be recorded and played back.',
        type: 'microphone',
        verification: 'tested',
    },
    {
        id: 'speaker',
        name: 'Speaker',
        description: 'A test tone will play. Can you hear it?',
        type: 'speaker',
        verification: 'tested',
    },

    // --- Connectivity ---
    {
        id: 'wifi',
        name: 'Wi-Fi',
        description: 'Testing Wi-Fi connectivity...',
        type: 'connectivity',
        subtype: 'wifi',
        verification: 'tested',
    },
    {
        id: 'bluetooth',
        name: 'Bluetooth',
        description: 'Not available in browser. This test runs in the ClearVue iOS app.',
        type: 'unsupported',
        verification: 'untestable',
        reason: 'Bluetooth testing requires native hardware access. Available in the ClearVue iOS app.',
    },
    {
        id: 'cellular',
        name: 'Cellular Signal',
        description: 'Disable Wi-Fi, then confirm you have cellular data connectivity.',
        type: 'connectivity',
        subtype: 'cellular',
        verification: 'self-reported',
    },
    {
        id: 'gps',
        name: 'GPS / Location',
        description: 'Requesting location access to verify GPS hardware...',
        type: 'geolocation',
        verification: 'tested',
        timeout: 10000,
    },

    // --- Sensors & Hardware ---
    {
        id: 'accel_gyro',
        name: 'Accelerometer / Gyroscope',
        description: 'Tilt and rotate your device in all directions.',
        type: 'motion',
        verification: 'tested',
    },
    {
        id: 'vibration',
        name: 'Vibration (Taptic Engine)',
        description: 'Testing haptic feedback...',
        type: 'vibration',
        verification: 'self-reported',
    },
    {
        id: 'buttons',
        name: 'Physical Buttons',
        description: 'Test each physical button when prompted.',
        type: 'buttons',
        verification: 'self-reported',
    },
    {
        id: 'nfc',
        name: 'NFC',
        description: 'Not available in browser. This test runs in the ClearVue iOS app.',
        type: 'unsupported',
        verification: 'untestable',
        reason: 'NFC testing requires native hardware access. Available in the ClearVue iOS app.',
    },
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
        this._stream = null;        // active MediaStream (camera / mic)
        this._audioCtx = null;      // AudioContext for speaker test
        this._recorder = null;      // MediaRecorder for mic test
        this._recordedBlob = null;
        this._motionHandler = null; // DeviceMotion listener
        this._volumeAudio = null;   // Hidden <audio> for volume button detection
        this._displayOverlay = null; // Full-screen color panel overlay
    }

    start() {
        this.currentIndex = 0;
        this.results = {};
        this._renderTest();
    }

    /* --- Rendering ------------------------------------------------ */

    _renderTest() {
        this._cleanup();
        const test = this.tests[this.currentIndex];
        if (!test) { this._renderResults(); return; }

        const pct = Math.round((this.currentIndex / this.tests.length) * 100);
        this.container.innerHTML = `
            <div class="test-header">
                <div class="brand">ClearVue</div>
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

        const content = this.container.querySelector('#testContent');
        const actions = this.container.querySelector('#testActions');

        switch (test.type) {
            case 'manual':       this._setupManual(content, actions, test); break;
            case 'camera':       this._setupCamera(content, actions, test); break;
            case 'touch':        this._setupTouch(content, actions, test); break;
            case 'microphone':   this._setupMicrophone(content, actions, test); break;
            case 'speaker':      this._setupSpeaker(content, actions, test); break;
            case 'display':      this._setupDisplay(content, actions, test); break;
            case 'connectivity': this._setupConnectivity(content, actions, test); break;
            case 'unsupported':  this._setupUnsupported(content, actions, test); break;
            case 'geolocation':  this._setupGeolocation(content, actions, test); break;
            case 'motion':       this._setupMotion(content, actions, test); break;
            case 'vibration':    this._setupVibration(content, actions, test); break;
            case 'buttons':      this._setupButtons(content, actions, test); break;
        }
    }

    _addButtons(actions, testId, opts = {}) {
        const { showSkip = false, passDisabled = false, showNotTestable = false } = opts;
        actions.innerHTML = `
            ${showSkip ? '<button class="btn btn-skip" data-action="skip">Skip</button>' : ''}
            ${showNotTestable ? '<button class="btn btn-not-testable" data-action="not_testable">Not Supported</button>' : ''}
            <button class="btn btn-fail" data-action="fail">Fail</button>
            <button class="btn btn-pass" data-action="pass" ${passDisabled ? 'disabled' : ''}>Pass</button>
        `;
        actions.querySelectorAll('.btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.action;
                const map = { pass: 'pass', fail: 'fail', skip: 'skipped', not_testable: 'not_testable' };
                this._record(testId, map[action] || 'skipped');
            });
        });
    }

    _record(testId, result) {
        this.results[testId] = result;
        this.currentIndex++;
        this._renderTest();
    }

    /* --- Manual Test ---------------------------------------------- */

    _setupManual(content, actions, test) {
        if (test.extraButtons && test.extraButtons.includes('not_supported')) {
            this._addButtons(actions, test.id, { showNotTestable: true });
        } else {
            this._addButtons(actions, test.id);
        }
    }

    /* --- Camera Tests --------------------------------------------- */

    async _setupCamera(content, actions, test) {
        content.innerHTML = `
            <div class="camera-preview" id="camPreview">
                <div class="camera-label">${test.facingMode === 'user' ? 'Front' : 'Rear'}</div>
                <video id="camVideo" autoplay playsinline muted></video>
            </div>
        `;
        this._addButtons(actions, test.id);

        try {
            this._stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: test.facingMode, width: { ideal: 1280 }, height: { ideal: 960 } },
                audio: false,
            });
            const video = this.container.querySelector('#camVideo');
            video.srcObject = this._stream;
        } catch (err) {
            const preview = this.container.querySelector('#camPreview');
            preview.innerHTML = `<div class="camera-error">Camera access denied or unavailable.<br>${err.message}</div>`;
        }
    }

    /* --- Touch Screen Test ---------------------------------------- */

    _setupTouch(content, actions, test) {
        const total = 24; // 4x6
        let touched = 0;
        const touchedSet = new Set();

        content.innerHTML = `
            <div class="touch-grid" id="touchGrid"></div>
            <div class="touch-counter" id="touchCounter">0 / ${total}</div>
        `;

        const grid = this.container.querySelector('#touchGrid');
        const counter = this.container.querySelector('#touchCounter');

        for (let i = 0; i < total; i++) {
            const cell = document.createElement('div');
            cell.className = 'touch-cell';
            cell.dataset.index = i;
            grid.appendChild(cell);
        }

        const handleTouch = (e) => {
            e.preventDefault();
            const touches = e.changedTouches || [e];
            for (const t of touches) {
                const el = document.elementFromPoint(t.clientX, t.clientY);
                if (el && el.classList.contains('touch-cell') && !touchedSet.has(el.dataset.index)) {
                    touchedSet.add(el.dataset.index);
                    el.classList.add('touched');
                    touched++;
                    counter.textContent = `${touched} / ${total}`;
                    if (touched >= total) {
                        this._record(test.id, 'pass');
                    }
                }
            }
        };

        grid.addEventListener('touchstart', handleTouch, { passive: false });
        grid.addEventListener('touchmove', handleTouch, { passive: false });
        grid.addEventListener('mousedown', handleTouch);
        grid.addEventListener('mouseover', (e) => { if (e.buttons === 1) handleTouch(e); });

        this._addButtons(actions, test.id, { passDisabled: true });
    }

    /* --- Microphone Test ------------------------------------------ */

    async _setupMicrophone(content, actions, test) {
        const RECORD_SECONDS = 3;

        content.innerHTML = `
            <div class="audio-status" id="audioStatus">Preparing...</div>
            <div class="audio-timer" id="audioTimer">${RECORD_SECONDS}.0</div>
        `;

        const statusEl = this.container.querySelector('#audioStatus');
        const timerEl = this.container.querySelector('#audioTimer');

        actions.innerHTML = '';

        try {
            this._stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        } catch (err) {
            statusEl.textContent = 'Microphone access denied';
            statusEl.className = 'audio-status';
            this._addButtons(actions, test.id);
            return;
        }

        statusEl.textContent = 'Recording...';
        statusEl.className = 'audio-status recording';
        const chunks = [];
        this._recorder = new MediaRecorder(this._stream);
        this._recorder.ondataavailable = (e) => { if (e.data.size > 0) chunks.push(e.data); };

        this._recorder.onstop = () => {
            this._recordedBlob = new Blob(chunks, { type: 'audio/webm' });
            this._cleanup();

            statusEl.textContent = 'Playing back...';
            statusEl.className = 'audio-status playing';
            const audio = new Audio(URL.createObjectURL(this._recordedBlob));

            let playTime = 0;
            const playInterval = setInterval(() => {
                playTime += 0.1;
                timerEl.textContent = playTime.toFixed(1);
            }, 100);

            audio.onended = () => {
                clearInterval(playInterval);
                statusEl.textContent = 'Did you hear the recording?';
                statusEl.className = 'audio-status';
                this._addButtons(actions, test.id);
            };
            audio.play().catch(() => {
                clearInterval(playInterval);
                statusEl.textContent = 'Playback failed. Could you hear anything?';
                statusEl.className = 'audio-status';
                this._addButtons(actions, test.id);
            });
        };

        this._recorder.start();

        let remaining = RECORD_SECONDS;
        const interval = setInterval(() => {
            remaining -= 0.1;
            if (remaining <= 0) {
                clearInterval(interval);
                timerEl.textContent = '0.0';
                if (this._recorder && this._recorder.state === 'recording') {
                    this._recorder.stop();
                }
            } else {
                timerEl.textContent = remaining.toFixed(1);
            }
        }, 100);
    }

    /* --- Speaker Test --------------------------------------------- */

    _setupSpeaker(content, actions, test) {
        const TONE_SECONDS = 2;

        content.innerHTML = `
            <div class="tone-indicator" id="toneIndicator">
                <span class="icon">&#9835;</span>
            </div>
            <div class="audio-status" id="speakerStatus">Tap Play to start</div>
        `;

        const indicator = this.container.querySelector('#toneIndicator');
        const statusEl = this.container.querySelector('#speakerStatus');

        actions.innerHTML = `<button class="btn btn-start" id="playToneBtn">Play Test Tone</button>`;

        const playBtn = this.container.querySelector('#playToneBtn');
        playBtn.addEventListener('click', () => {
            playBtn.disabled = true;
            indicator.classList.add('active');
            statusEl.textContent = 'Playing 1kHz tone...';

            this._audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            const osc = this._audioCtx.createOscillator();
            const gain = this._audioCtx.createGain();
            osc.type = 'sine';
            osc.frequency.value = 1000;
            gain.gain.value = 0.5;
            osc.connect(gain);
            gain.connect(this._audioCtx.destination);
            osc.start();

            setTimeout(() => {
                osc.stop();
                indicator.classList.remove('active');
                statusEl.textContent = 'Did you hear the tone?';
                this._addButtons(actions, test.id);
            }, TONE_SECONDS * 1000);
        });
    }

    /* --- Display Quality Test ------------------------------------- */

    _setupDisplay(content, actions, test) {
        const colors = test.colors;
        const names = test.colorNames;

        content.innerHTML = `
            <p class="display-instruction">Tap the button below to start the full-screen color test. Examine each panel carefully for dead pixels or discoloration, then tap to advance.</p>
        `;

        actions.innerHTML = `<button class="btn btn-start" id="startDisplayBtn">Start Color Test</button>`;

        this.container.querySelector('#startDisplayBtn').addEventListener('click', () => {
            let colorIndex = 0;

            const overlay = document.createElement('div');
            overlay.className = 'display-overlay';
            overlay.style.backgroundColor = colors[colorIndex];
            const isLight = (c) => ['#ffffff', '#00ff00'].includes(c);
            overlay.innerHTML = `
                <div class="display-overlay-label" style="color:${isLight(colors[0]) ? '#000' : '#fff'}">
                    <span id="displayColorName">${names[colorIndex]}</span>
                    <span id="displayColorCount">1 / ${colors.length} &mdash; Tap to continue</span>
                </div>
            `;
            document.body.appendChild(overlay);
            this._displayOverlay = overlay;

            const nameEl = overlay.querySelector('#displayColorName');
            const countEl = overlay.querySelector('#displayColorCount');
            const labelEl = overlay.querySelector('.display-overlay-label');

            overlay.addEventListener('click', () => {
                colorIndex++;
                if (colorIndex < colors.length) {
                    overlay.style.backgroundColor = colors[colorIndex];
                    nameEl.textContent = names[colorIndex];
                    countEl.innerHTML = `${colorIndex + 1} / ${colors.length} &mdash; Tap to continue`;
                    labelEl.style.color = isLight(colors[colorIndex]) ? '#000' : '#fff';
                } else {
                    overlay.remove();
                    this._displayOverlay = null;
                    const body = this.container.querySelector('#testBody');
                    if (body) {
                        body.querySelector('h2').textContent = 'Display Quality';
                        body.querySelector('.test-description').textContent = 'Did you notice any dead pixels, discoloration, or backlight bleed?';
                    }
                    content.innerHTML = '';
                    this._addButtons(actions, test.id);
                }
            });
        });
    }

    /* --- Connectivity Tests --------------------------------------- */

    async _setupConnectivity(content, actions, test) {
        const isWifi = test.subtype === 'wifi';

        content.innerHTML = `
            <div class="connectivity-status" id="connStatus">Testing...</div>
            <div class="connectivity-info" id="connInfo"></div>
        `;

        const statusEl = this.container.querySelector('#connStatus');
        const infoEl = this.container.querySelector('#connInfo');

        if (isWifi) {
            const details = [];

            if (!navigator.onLine) {
                statusEl.textContent = 'No network connection detected';
                statusEl.className = 'connectivity-status error';
                details.push('Device reports: Offline');
                infoEl.innerHTML = details.join('<br>');
                this._addButtons(actions, test.id);
                return;
            }

            details.push('Device reports: Online');

            if (navigator.connection) {
                const conn = navigator.connection;
                if (conn.effectiveType) details.push(`Type: ${conn.effectiveType}`);
                if (conn.downlink) details.push(`Downlink: ${conn.downlink} Mbps`);
            }

            try {
                const controller = new AbortController();
                const timeout = setTimeout(() => controller.abort(), 5000);
                const start = performance.now();
                await fetch(window.location.origin, { mode: 'no-cors', signal: controller.signal });
                clearTimeout(timeout);
                const elapsed = Math.round(performance.now() - start);
                details.push(`Latency: ${elapsed}ms`);
                statusEl.textContent = 'Wi-Fi Connected';
                statusEl.className = 'connectivity-status success';
            } catch (err) {
                statusEl.textContent = 'Network request failed';
                statusEl.className = 'connectivity-status error';
                details.push(`Error: ${err.message}`);
            }

            infoEl.innerHTML = details.join('<br>');
            this._addButtons(actions, test.id);

        } else {
            // Cellular: manual confirmation
            statusEl.textContent = 'Cellular Signal Check';
            const details = [];

            if (navigator.connection) {
                const conn = navigator.connection;
                if (conn.effectiveType) details.push(`Connection type: ${conn.effectiveType}`);
                if (conn.downlink) details.push(`Downlink: ${conn.downlink} Mbps`);
                infoEl.innerHTML = details.join('<br>');
            } else {
                infoEl.innerHTML = 'Turn off Wi-Fi and verify you have cellular data connectivity, then report below.';
            }

            this._addButtons(actions, test.id);
        }
    }

    /* --- Unsupported Test ----------------------------------------- */

    _setupUnsupported(content, actions, test) {
        content.innerHTML = `
            <div class="unsupported-icon">&#x1F4F1;</div>
            <div class="unsupported-reason">${test.reason}</div>
            <div class="unsupported-app-hint">Available in the ClearVue iOS app</div>
        `;
        actions.innerHTML = `
            <button class="btn btn-not-testable" data-action="not_testable">Mark Not Testable</button>
        `;
        actions.querySelector('.btn').addEventListener('click', () => {
            this._record(test.id, 'not_testable');
        });
    }

    /* --- Geolocation Test ----------------------------------------- */

    _setupGeolocation(content, actions, test) {
        content.innerHTML = `
            <div class="connectivity-status" id="geoStatus">Requesting location...</div>
            <div class="audio-timer" id="geoTimer">10s</div>
            <div class="connectivity-info" id="geoInfo"></div>
        `;

        const statusEl = this.container.querySelector('#geoStatus');
        const timerEl = this.container.querySelector('#geoTimer');
        const infoEl = this.container.querySelector('#geoInfo');

        if (!navigator.geolocation) {
            statusEl.textContent = 'Geolocation not available';
            statusEl.className = 'connectivity-status error';
            timerEl.textContent = '--';
            this._addButtons(actions, test.id);
            return;
        }

        let remaining = test.timeout / 1000;
        const interval = setInterval(() => {
            remaining--;
            timerEl.textContent = `${remaining}s`;
            if (remaining <= 0) clearInterval(interval);
        }, 1000);

        navigator.geolocation.getCurrentPosition(
            (position) => {
                clearInterval(interval);
                statusEl.textContent = 'Location Acquired';
                statusEl.className = 'connectivity-status success';
                const lat = position.coords.latitude.toFixed(4);
                const lon = position.coords.longitude.toFixed(4);
                const acc = Math.round(position.coords.accuracy);
                infoEl.innerHTML = `Lat: ${lat}, Lon: ${lon}<br>Accuracy: ${acc}m`;
                timerEl.textContent = 'GPS OK';
                this._addButtons(actions, test.id);
            },
            (error) => {
                clearInterval(interval);
                statusEl.textContent = 'Location Failed';
                statusEl.className = 'connectivity-status error';
                const msgs = { 1: 'Permission denied', 2: 'Position unavailable', 3: 'Timed out' };
                infoEl.textContent = msgs[error.code] || error.message;
                timerEl.textContent = '--';
                this._addButtons(actions, test.id);
            },
            { enableHighAccuracy: true, timeout: test.timeout, maximumAge: 0 }
        );
    }

    /* --- Motion Sensor Test --------------------------------------- */

    async _setupMotion(content, actions, test) {
        content.innerHTML = `
            <div class="motion-visual" id="motionVisual">
                <div class="motion-dot" id="motionDot"></div>
            </div>
            <div class="connectivity-status" id="motionStatus">Waiting for sensor data...</div>
            <div class="motion-data" id="motionData"></div>
        `;

        const statusEl = this.container.querySelector('#motionStatus');
        const dataEl = this.container.querySelector('#motionData');
        const dot = this.container.querySelector('#motionDot');

        // iOS 13+ requires permission from a user gesture
        if (typeof DeviceMotionEvent !== 'undefined' &&
            typeof DeviceMotionEvent.requestPermission === 'function') {
            actions.innerHTML = `<button class="btn btn-start" id="motionPermBtn">Enable Motion Sensors</button>`;
            this.container.querySelector('#motionPermBtn').addEventListener('click', async () => {
                try {
                    const perm = await DeviceMotionEvent.requestPermission();
                    if (perm === 'granted') {
                        this._startMotionListening(content, actions, test, statusEl, dataEl, dot);
                    } else {
                        statusEl.textContent = 'Motion sensor permission denied';
                        statusEl.className = 'connectivity-status error';
                        this._addButtons(actions, test.id);
                    }
                } catch (err) {
                    statusEl.textContent = 'Permission request failed';
                    statusEl.className = 'connectivity-status error';
                    this._addButtons(actions, test.id);
                }
            });
        } else {
            // Non-iOS or permission not required
            this._startMotionListening(content, actions, test, statusEl, dataEl, dot);
        }
    }

    _startMotionListening(content, actions, test, statusEl, dataEl, dot) {
        let sampleCount = 0;
        let dataReceived = false;

        this._motionHandler = (event) => {
            const a = event.accelerationIncludingGravity;
            const r = event.rotationRate;

            if (a && (a.x !== null || a.y !== null || a.z !== null)) {
                dataReceived = true;
                sampleCount++;

                if (dot && a.x !== null && a.y !== null) {
                    const x = Math.min(Math.max(a.x * 5, -40), 40);
                    const y = Math.min(Math.max(a.y * 5, -40), 40);
                    dot.style.transform = `translate(${x}px, ${-y}px)`;
                }

                if (sampleCount % 10 === 0) {
                    dataEl.innerHTML = `
                        Accel: x=${a.x?.toFixed(1)} y=${a.y?.toFixed(1)} z=${a.z?.toFixed(1)}<br>
                        ${r ? `Gyro: \u03b1=${r.alpha?.toFixed(0)} \u03b2=${r.beta?.toFixed(0)} \u03b3=${r.gamma?.toFixed(0)}` : ''}
                    `;
                }

                if (sampleCount === 30 && !actions.querySelector('.btn')) {
                    statusEl.textContent = 'Sensor data detected';
                    statusEl.className = 'connectivity-status success';
                    this._addButtons(actions, test.id);
                }
            }
        };

        window.addEventListener('devicemotion', this._motionHandler);
        actions.innerHTML = '';

        setTimeout(() => {
            if (!dataReceived) {
                statusEl.textContent = 'No motion data received';
                statusEl.className = 'connectivity-status error';
                this._addButtons(actions, test.id);
            }
        }, 3000);
    }

    /* --- Vibration Test ------------------------------------------- */

    _setupVibration(content, actions, test) {
        const iosMatch = navigator.userAgent.match(/OS (\d+)_/);
        const iosVersion = iosMatch ? parseInt(iosMatch[1], 10) : 0;

        if (iosVersion >= 18) {
            content.innerHTML = `
                <div class="connectivity-status" id="vibStatus">Ready to test haptic feedback</div>
                <p class="vibration-note">A toggle switch will trigger the Taptic Engine.</p>
            `;

            const wrapper = document.createElement('div');
            wrapper.style.cssText = 'position:absolute;left:-9999px;opacity:0;pointer-events:none;';
            const label = document.createElement('label');
            label.id = 'hapticLabel';
            const input = document.createElement('input');
            input.type = 'checkbox';
            input.setAttribute('switch', '');
            label.appendChild(input);
            wrapper.appendChild(label);
            content.appendChild(wrapper);

            actions.innerHTML = `<button class="btn btn-start" id="triggerHapticBtn">Trigger Haptic</button>`;

            this.container.querySelector('#triggerHapticBtn').addEventListener('click', () => {
                const statusEl = this.container.querySelector('#vibStatus');
                label.click();
                setTimeout(() => { label.click(); }, 300);
                setTimeout(() => { label.click(); }, 600);

                setTimeout(() => {
                    statusEl.textContent = 'Did you feel a vibration?';
                    this._addButtons(actions, test.id);
                }, 800);
            });

        } else if (typeof navigator.vibrate === 'function') {
            // Non-Safari fallback (desktop testing)
            content.innerHTML = `<div class="connectivity-status">Testing vibration...</div>`;
            navigator.vibrate([200, 100, 200]);
            setTimeout(() => {
                content.querySelector('.connectivity-status').textContent = 'Did you feel a vibration?';
                this._addButtons(actions, test.id);
            }, 600);

        } else {
            content.innerHTML = `
                <div class="unsupported-icon">&#x2718;</div>
                <div class="unsupported-reason">
                    Haptic feedback cannot be triggered from the browser on iOS ${iosVersion || '(version unknown)'}.<br>
                    This feature requires iOS 18 or later.
                </div>
            `;
            actions.innerHTML = `
                <button class="btn btn-not-testable" data-action="not_testable">Mark Not Testable</button>
            `;
            actions.querySelector('.btn').addEventListener('click', () => {
                this._record(test.id, 'not_testable');
            });
        }
    }

    /* --- Physical Buttons Test ------------------------------------ */

    _setupButtons(content, actions, test) {
        const steps = [
            { label: 'Volume Up', detect: 'volume' },
            { label: 'Volume Down', detect: 'volume' },
            { label: 'Side Button (Power)', detect: 'manual' },
            { label: 'Mute Switch', detect: 'manual' },
        ];
        let stepIndex = 0;
        const stepResults = [];

        // Silent audio for volumechange detection
        const audio = document.createElement('audio');
        audio.src = 'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA=';
        audio.loop = true;
        audio.volume = 0.5;
        document.body.appendChild(audio);
        this._volumeAudio = audio;
        audio.play().catch(() => {});

        const renderStep = () => {
            if (stepIndex >= steps.length) {
                // Summary
                const allPassed = stepResults.every(r => r);
                content.innerHTML = `
                    <div class="buttons-summary">
                        ${steps.map((s, i) => `
                            <div class="button-step-result">
                                <span>${s.label}</span>
                                <span class="${stepResults[i] ? 'step-pass' : 'step-fail'}">
                                    ${stepResults[i] ? 'Confirmed' : 'Failed'}
                                </span>
                            </div>
                        `).join('')}
                    </div>
                `;
                this._addButtons(actions, test.id);
                return;
            }

            const step = steps[stepIndex];
            content.innerHTML = `
                <div class="button-prompt">
                    <div class="button-prompt-step">Button ${stepIndex + 1} of ${steps.length}</div>
                    <div class="button-prompt-label">Press: ${step.label}</div>
                    <div class="button-prompt-hint" id="buttonHint">
                        ${step.detect === 'volume' ? 'Listening for volume change...' : 'Tap Confirm when done'}
                    </div>
                </div>
            `;

            if (step.detect === 'volume') {
                let detected = false;

                const volumeHandler = () => {
                    if (!detected) {
                        detected = true;
                        const hint = this.container.querySelector('#buttonHint');
                        if (hint) {
                            hint.textContent = `${step.label} detected!`;
                            hint.className = 'button-prompt-hint detected';
                        }
                        stepResults.push(true);
                        audio.removeEventListener('volumechange', volumeHandler);
                        setTimeout(() => { stepIndex++; renderStep(); }, 800);
                    }
                };

                audio.addEventListener('volumechange', volumeHandler);

                actions.innerHTML = `
                    <button class="btn btn-fail" data-action="fail">Didn't Work</button>
                    <button class="btn btn-pass" data-action="confirm">Confirm Pressed</button>
                `;
                actions.querySelector('[data-action="fail"]').addEventListener('click', () => {
                    audio.removeEventListener('volumechange', volumeHandler);
                    stepResults.push(false);
                    stepIndex++;
                    renderStep();
                });
                actions.querySelector('[data-action="confirm"]').addEventListener('click', () => {
                    audio.removeEventListener('volumechange', volumeHandler);
                    stepResults.push(true);
                    stepIndex++;
                    renderStep();
                });

            } else {
                actions.innerHTML = `
                    <button class="btn btn-fail" data-action="fail">Didn't Work</button>
                    <button class="btn btn-pass" data-action="confirm">Confirm Pressed</button>
                `;
                actions.querySelector('[data-action="fail"]').addEventListener('click', () => {
                    stepResults.push(false);
                    stepIndex++;
                    renderStep();
                });
                actions.querySelector('[data-action="confirm"]').addEventListener('click', () => {
                    stepResults.push(true);
                    stepIndex++;
                    renderStep();
                });
            }
        };

        renderStep();
    }

    /* --- Results -------------------------------------------------- */

    _renderResults() {
        this._cleanup();
        const now = new Date();
        const iso = now.toISOString();
        const human = now.toLocaleString('en-US', {
            year: 'numeric', month: 'long', day: 'numeric',
            hour: 'numeric', minute: '2-digit', hour12: true,
        });

        const passed = Object.values(this.results).filter(r => r === 'pass').length;
        const tested = Object.values(this.results).filter(r => r === 'pass' || r === 'fail').length;
        const notTestable = Object.values(this.results).filter(r => r === 'not_testable').length;
        const scoreExtra = notTestable > 0 ? ` <span class="results-note">(${notTestable} not testable)</span>` : '';

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

            const verLabel = test.verification === 'self-reported'
                ? '<span class="result-verification">Self-reported</span>'
                : test.verification === 'untestable'
                ? '<span class="result-verification app-available">Available in iOS app</span>'
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
                    <div class="brand">ClearVue</div>
                    <h2>Diagnostic Complete</h2>
                    <div class="results-score">${passed} / ${tested} tests passed${scoreExtra}</div>
                    <div class="results-timestamp">${human}</div>
                    <div class="results-timestamp">${iso}</div>
                </div>
                <div class="app-promo">
                    <div class="app-promo-badge">iOS App</div>
                    <div class="app-promo-text">Get the full ClearVue experience &mdash; Bluetooth, NFC, Face ID, and 3 more tests verified automatically.</div>
                    <div class="app-promo-note">Coming soon to the App Store</div>
                </div>
                <ul class="results-list">${listHTML}</ul>
                <div class="results-actions">
                    <button class="btn btn-start" id="restartBtn">Run Again</button>
                </div>
                <div class="results-footer">&copy; 2026 ClearVue &mdash; clearvue.rhex.app</div>
            </div>
        `;

        this.container.querySelector('#restartBtn').addEventListener('click', () => this.start());

        this.container.dispatchEvent(new CustomEvent('testscomplete', {
            detail: { results: { ...this.results }, timestamp: iso, tests: this.tests },
        }));
    }

    /* --- Cleanup -------------------------------------------------- */

    _cleanup() {
        if (this._stream) {
            this._stream.getTracks().forEach(t => t.stop());
            this._stream = null;
        }
        if (this._audioCtx) {
            this._audioCtx.close().catch(() => {});
            this._audioCtx = null;
        }
        if (this._recorder && this._recorder.state === 'recording') {
            this._recorder.stop();
        }
        this._recorder = null;
        if (this._motionHandler) {
            window.removeEventListener('devicemotion', this._motionHandler);
            this._motionHandler = null;
        }
        if (this._volumeAudio) {
            this._volumeAudio.pause();
            this._volumeAudio.remove();
            this._volumeAudio = null;
        }
        if (this._displayOverlay) {
            this._displayOverlay.remove();
            this._displayOverlay = null;
        }
    }
}
