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
    {
        id: 'faceid',
        name: 'Face ID',
        description: 'Lock your device, then unlock with Face ID. Did it work?',
        type: 'manual',
    },
    {
        id: 'front_cam',
        name: 'Front Camera',
        description: 'Check that the front camera shows a clear image.',
        type: 'camera',
        facingMode: 'user',
    },
    {
        id: 'rear_cam',
        name: 'Rear Camera',
        description: 'Check that the rear camera shows a clear image.',
        type: 'camera',
        facingMode: 'environment',
    },
    {
        id: 'touch',
        name: 'Touch Screen',
        description: 'Touch every cell in the grid below.',
        type: 'touch',
    },
    {
        id: 'mic',
        name: 'Microphone',
        description: 'A short audio clip will be recorded and played back.',
        type: 'microphone',
    },
    {
        id: 'speaker',
        name: 'Speaker',
        description: 'A test tone will play. Can you hear it?',
        type: 'speaker',
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
            case 'manual':   this._setupManual(content, actions, test); break;
            case 'camera':   this._setupCamera(content, actions, test); break;
            case 'touch':    this._setupTouch(content, actions, test); break;
            case 'microphone': this._setupMicrophone(content, actions, test); break;
            case 'speaker':  this._setupSpeaker(content, actions, test); break;
        }
    }

    _addButtons(actions, testId, opts = {}) {
        const { showSkip = false, passDisabled = false } = opts;
        actions.innerHTML = `
            ${showSkip ? '<button class="btn btn-skip" data-action="skip">Skip</button>' : ''}
            <button class="btn btn-fail" data-action="fail">Fail</button>
            <button class="btn btn-pass" data-action="pass" ${passDisabled ? 'disabled' : ''}>Pass</button>
        `;
        actions.querySelectorAll('.btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.action;
                this._record(testId, action === 'pass' ? 'pass' : action === 'fail' ? 'fail' : 'skipped');
            });
        });
    }

    _record(testId, result) {
        this.results[testId] = result;
        this.currentIndex++;
        this._renderTest();
    }

    /* --- Manual Test (Face ID) ------------------------------------ */

    _setupManual(content, actions, test) {
        this._addButtons(actions, test.id);
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

        const passBtn = () => {
            const btn = actions.querySelector('[data-action="pass"]');
            if (btn) btn.disabled = false;
        };

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
        // Mouse fallback for desktop testing
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

        // Don't show pass/fail until playback is done
        actions.innerHTML = '';

        try {
            this._stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        } catch (err) {
            statusEl.textContent = 'Microphone access denied';
            statusEl.className = 'audio-status';
            this._addButtons(actions, test.id);
            return;
        }

        // Record
        statusEl.textContent = 'Recording...';
        statusEl.className = 'audio-status recording';
        const chunks = [];
        this._recorder = new MediaRecorder(this._stream);
        this._recorder.ondataavailable = (e) => { if (e.data.size > 0) chunks.push(e.data); };

        this._recorder.onstop = () => {
            this._recordedBlob = new Blob(chunks, { type: 'audio/webm' });
            this._cleanup(); // stop mic stream

            // Playback
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

        // Show a play button first, then pass/fail after tone finishes
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
        const tested = Object.values(this.results).filter(r => r !== 'skipped').length;

        let listHTML = '';
        for (const test of this.tests) {
            const result = this.results[test.id] || 'skipped';
            const badgeClass = result === 'pass' ? 'pass' : result === 'fail' ? 'fail' : 'skipped';
            const badgeText = result === 'pass' ? 'Pass' : result === 'fail' ? 'Fail' : 'Skipped';
            listHTML += `
                <li>
                    <span class="result-name">${test.name}</span>
                    <span class="result-badge ${badgeClass}">${badgeText}</span>
                </li>`;
        }

        this.container.innerHTML = `
            <div class="results-screen">
                <div class="results-header">
                    <div class="brand">ClearVue</div>
                    <h2>Diagnostic Complete</h2>
                    <div class="results-score">${passed} / ${tested} tests passed</div>
                    <div class="results-timestamp">${human}</div>
                    <div class="results-timestamp">${iso}</div>
                </div>
                <ul class="results-list">${listHTML}</ul>
                <div class="results-actions">
                    <button class="btn btn-start" id="restartBtn">Run Again</button>
                </div>
                <div class="results-footer">&copy; 2026 ClearVue &mdash; clearvue.rhex.app</div>
            </div>
        `;

        this.container.querySelector('#restartBtn').addEventListener('click', () => this.start());

        // Dispatch event for C2C/B2B to hook into
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
    }
}
