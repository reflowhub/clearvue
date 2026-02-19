/**
 * ClearVue Device Gate
 * Detects non-iPhone browsers and shows a gate screen with QR code.
 * Users can bypass into "demo mode" — results will be labelled accordingly.
 *
 * Usage: <script src="../shared/static/device-gate.js"></script>
 *        (include before </body> in any C2C page)
 */

(function () {
    const isIPhone = /iPhone/.test(navigator.userAgent) && !window.MSStream;

    // Allow bypass if already accepted demo mode this session
    if (isIPhone || sessionStorage.getItem('clearvue_demo') === '1') return;

    // Inject styles
    const style = document.createElement('style');
    style.textContent = `
        #deviceGate {
            position: fixed;
            inset: 0;
            z-index: 10000;
            background: #0a0a0a;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 1.5rem;
        }
        .gate-card {
            text-align: center;
            max-width: 24rem;
            width: 100%;
        }
        .gate-brand {
            font-size: 0.6875rem;
            font-weight: 600;
            letter-spacing: 0.15em;
            text-transform: uppercase;
            color: #48484a;
            margin-bottom: 1.5rem;
        }
        .gate-title {
            font-size: 2rem;
            font-weight: 700;
            color: #f5f5f7;
            margin-bottom: 0.75rem;
        }
        .gate-desc {
            font-size: 1rem;
            color: #a1a1a6;
            line-height: 1.5;
            margin-bottom: 2rem;
        }
        .gate-qr {
            display: inline-block;
            background: #fff;
            padding: 12px;
            border-radius: 12px;
            margin-bottom: 1rem;
        }
        .gate-qr img {
            display: block;
            border-radius: 4px;
        }
        .gate-url {
            font-size: 0.75rem;
            color: #48484a;
            word-break: break-all;
            margin-bottom: 2.5rem;
        }
        .gate-demo-btn {
            display: inline-block;
            padding: 0.75rem 1.5rem;
            font-size: 0.9375rem;
            font-weight: 600;
            color: #86868b;
            background: #1d1d1f;
            border: none;
            border-radius: 980px;
            cursor: pointer;
            font-family: inherit;
            transition: opacity 0.2s;
            margin-bottom: 0.5rem;
        }
        .gate-demo-btn:hover { opacity: 0.8; }
        .gate-demo-note {
            font-size: 0.6875rem;
            color: #48484a;
        }
    `;
    document.head.appendChild(style);

    // Build gate overlay
    const pageUrl = window.location.href;
    const qrSrc = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(pageUrl)}`;

    const overlay = document.createElement('div');
    overlay.id = 'deviceGate';
    overlay.innerHTML = `
        <div class="gate-card">
            <div class="gate-brand">ClearVue</div>
            <h1 class="gate-title">iPhone Only</h1>
            <p class="gate-desc">
                This diagnostic is designed to run on your iPhone in Safari.
                Scan the QR code below to open it on your device.
            </p>
            <div class="gate-qr">
                <img src="${qrSrc}" alt="QR code to open on iPhone" width="200" height="200">
            </div>
            <p class="gate-url">${pageUrl}</p>
            <button class="gate-demo-btn" id="gateDemoBtn">Continue in demo mode</button>
            <p class="gate-demo-note">Results will be labelled "Demo — non-iPhone device"</p>
        </div>
    `;

    document.body.appendChild(overlay);

    document.getElementById('gateDemoBtn').addEventListener('click', () => {
        sessionStorage.setItem('clearvue_demo', '1');
        overlay.remove();
    });
})();
