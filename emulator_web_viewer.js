const http = require('http');
const { spawn, execFile } = require('child_process');
const path = require('path');

const adbPath = process.env.LOCALAPPDATA 
  ? path.join(process.env.LOCALAPPDATA, 'Android', 'Sdk', 'platform-tools', 'adb.exe')
  : 'adb';

const PORT = 8088;

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SHOPZO — Live Android Device</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #0F5132;
      --primary-light: #198754;
      --primary-container: #D1E7DD;
      --surface: #0f172a;
      --card: #1e293b;
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, sans-serif;
    }
    body {
      background: linear-gradient(135deg, #090d16 0%, #0f172a 50%, #111e2e 100%);
      color: var(--text);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 24px 16px;
    }
    header {
      text-align: center;
      margin-bottom: 20px;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 12px;
      border-radius: 9999px;
      background: rgba(25, 135, 84, 0.2);
      border: 1px solid rgba(25, 135, 84, 0.4);
      color: #34d399;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 8px;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background: #10b981;
      border-radius: 50%;
      box-shadow: 0 0 10px #10b981;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(0.8); }
    }
    h1 {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      background: linear-gradient(135deg, #ffffff 0%, #cbd5e1 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    p.subtitle {
      color: var(--text-muted);
      font-size: 14px;
      margin-top: 4px;
    }
    .container {
      display: flex;
      gap: 32px;
      align-items: flex-start;
      justify-content: center;
      max-width: 1000px;
      width: 100%;
    }
    /* Phone Shell */
    .phone-wrapper {
      position: relative;
      background: #020617;
      padding: 14px;
      border-radius: 46px;
      box-shadow: 0 25px 60px -15px rgba(0, 0, 0, 0.8),
                  0 0 0 3px #334155,
                  0 0 30px rgba(15, 81, 50, 0.3);
      user-select: none;
    }
    .notch {
      position: absolute;
      top: 22px;
      left: 50%;
      transform: translateX(-50%);
      width: 14px;
      height: 14px;
      background: #000;
      border-radius: 50%;
      z-index: 10;
      border: 2px solid #1e293b;
    }
    .screen-container {
      position: relative;
      width: 360px;
      height: 740px;
      border-radius: 34px;
      overflow: hidden;
      background: #000;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    #screen {
      width: 100%;
      height: 100%;
      object-fit: fill;
      display: block;
      pointer-events: none;
    }
    .nav-bar {
      display: flex;
      justify-content: space-around;
      align-items: center;
      background: #000;
      height: 48px;
      border-radius: 0 0 34px 34px;
      margin-top: -48px;
      position: relative;
      z-index: 5;
    }
    .nav-btn {
      background: transparent;
      border: none;
      color: #94a3b8;
      font-size: 18px;
      cursor: pointer;
      padding: 8px 24px;
      border-radius: 8px;
      transition: all 0.15s;
    }
    .nav-btn:hover {
      background: rgba(255,255,255,0.1);
      color: #fff;
    }
    /* Side Control Panel */
    .panel {
      flex: 1;
      max-width: 400px;
      background: var(--card);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 20px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .panel-section-title {
      font-size: 15px;
      font-weight: 700;
      color: #e2e8f0;
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .input-group {
      display: flex;
      gap: 8px;
    }
    input[type="text"] {
      flex: 1;
      background: #0f172a;
      border: 1px solid #334155;
      color: #fff;
      padding: 10px 14px;
      border-radius: 10px;
      font-size: 14px;
      outline: none;
      transition: border-color 0.2s;
    }
    input[type="text"]:focus {
      border-color: var(--primary-light);
    }
    button.btn {
      background: var(--primary);
      color: #fff;
      border: none;
      padding: 10px 18px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
    }
    button.btn:hover {
      background: var(--primary-light);
    }
    .btn-secondary {
      background: #334155;
      color: #cbd5e1;
    }
    .btn-secondary:hover {
      background: #475569;
      color: #fff;
    }
    .quick-keys {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 8px;
    }
    .quick-keys button {
      padding: 10px;
      border-radius: 8px;
      background: #0f172a;
      border: 1px solid #334155;
      color: #cbd5e1;
      cursor: pointer;
      font-size: 13px;
      font-weight: 500;
      transition: all 0.15s;
    }
    .quick-keys button:hover {
      background: #1e293b;
      border-color: #64748b;
      color: #fff;
    }
    .features-list {
      list-style: none;
      font-size: 13px;
      color: #94a3b8;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .features-list li {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .features-list li::before {
      content: "✓";
      color: #10b981;
      font-weight: bold;
    }
  </style>
</head>
<body>
  <header>
    <div class="badge">
      <span class="status-dot"></span>
      Active Android Emulator (Pixel 3a — API 34)
    </div>
    <h1>SHOPZO Mobile Application</h1>
    <p class="subtitle">Click anywhere directly on the phone screen to interact with the live native app</p>
  </header>

  <div class="container">
    <div class="phone-wrapper">
      <div class="notch"></div>
      <div class="screen-container" id="screenBox">
        <img id="screen" src="/screen.png" alt="Android Screen" />
      </div>
      <div class="nav-bar">
        <button class="nav-btn" onclick="sendKey(4)" title="Back">◀</button>
        <button class="nav-btn" onclick="sendKey(3)" title="Home">●</button>
        <button class="nav-btn" onclick="sendKey(187)" title="Recents">■</button>
      </div>
    </div>

    <div class="panel">
      <div>
        <div class="panel-section-title">⌨️ Type into Phone</div>
        <div class="input-group">
          <input type="text" id="textInput" placeholder="Enter text to type..." onkeydown="if(event.key==='Enter') sendText()" />
          <button class="btn" onclick="sendText()">Send</button>
        </div>
      </div>

      <div>
        <div class="panel-section-title">⚡ Navigation & Controls</div>
        <div class="quick-keys">
          <button onclick="sendKey(4)">↩ Back</button>
          <button onclick="sendKey(66)">⏎ Enter / Submit</button>
          <button onclick="sendKey(67)">⌫ Backspace</button>
          <button onclick="swipe('up')">⬆ Scroll Up</button>
          <button onclick="swipe('down')">⬇ Scroll Down</button>
          <button onclick="refreshScreen()">🔄 Refresh</button>
        </div>
      </div>

      <div>
        <div class="panel-section-title">📱 Live App Status</div>
        <ul class="features-list">
          <li><strong>Package:</strong> com.shopzo.app</li>
          <li><strong>Current Screen:</strong> Dashboard (Home)</li>
          <li><strong>Logged-in User:</strong> Rishi (Shop Owner)</li>
          <li><strong>Shop ID:</strong> SZ-J7JI8E</li>
          <li><strong>Database:</strong> Room SQLite (Offline First)</li>
          <li><strong>Architecture:</strong> MVVM + Jetpack Compose</li>
        </ul>
      </div>

      <div style="background: rgba(16, 185, 129, 0.1); border: 1px solid rgba(16, 185, 129, 0.2); border-radius: 12px; padding: 12px; font-size: 13px; color: #a7f3d0;">
        💡 <strong>Tip:</strong> Click on buttons, cards, or bottom navigation tabs directly inside the phone screen to navigate!
      </div>
    </div>
  </div>

  <script>
    const screenImg = document.getElementById('screen');
    const screenBox = document.getElementById('screenBox');
    let isFetching = false;
    let refreshTimer = null;

    function refreshScreen() {
      if (isFetching) return;
      isFetching = true;
      const img = new Image();
      img.src = '/screen.png?t=' + Date.now();
      img.onload = () => {
        screenImg.src = img.src;
        isFetching = false;
      };
      img.onerror = () => {
        isFetching = false;
      };
    }

    // Auto-refresh every 700ms
    refreshTimer = setInterval(refreshScreen, 700);

    // Mouse tap on screen
    let startX = 0;
    let startY = 0;
    let startTime = 0;

    screenBox.addEventListener('mousedown', (e) => {
      const rect = screenBox.getBoundingClientRect();
      startX = Math.round(((e.clientX - rect.left) / rect.width) * 1080);
      startY = Math.round(((e.clientY - rect.top) / rect.height) * 2160);
      startTime = Date.now();
    });

    screenBox.addEventListener('mouseup', (e) => {
      const rect = screenBox.getBoundingClientRect();
      const endX = Math.round(((e.clientX - rect.left) / rect.width) * 1080);
      const endY = Math.round(((e.clientY - rect.top) / rect.height) * 2160);
      const duration = Date.now() - startTime;

      const dist = Math.hypot(endX - startX, endY - startY);
      if (dist < 20) {
        // Tap
        fetch('/tap?x=' + startX + '&y=' + startY, { method: 'POST' })
          .then(() => setTimeout(refreshScreen, 150));
      } else {
        // Drag / Swipe
        fetch('/swipe?x1=' + startX + '&y1=' + startY + '&x2=' + endX + '&y2=' + endY + '&ms=' + Math.max(100, Math.min(duration, 500)), { method: 'POST' })
          .then(() => setTimeout(refreshScreen, 250));
      }
    });

    function sendKey(code) {
      fetch('/key?code=' + code, { method: 'POST' })
        .then(() => setTimeout(refreshScreen, 200));
    }

    function sendText() {
      const input = document.getElementById('textInput');
      const val = input.value.trim();
      if (!val) return;
      fetch('/text?text=' + encodeURIComponent(val), { method: 'POST' })
        .then(() => {
          input.value = '';
          setTimeout(refreshScreen, 200);
        });
    }

    function swipe(dir) {
      const x = 540;
      let y1 = 1500, y2 = 500;
      if (dir === 'up') {
        y1 = 1500; y2 = 600;
      } else {
        y1 = 600; y2 = 1500;
      }
      fetch('/swipe?x1=' + x + '&y1=' + y1 + '&x2=' + x + '&y2=' + y2 + '&ms=250', { method: 'POST' })
        .then(() => setTimeout(refreshScreen, 300));
    }
  </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');

  if (url.pathname === '/' || url.pathname === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(html);
    return;
  }

  if (url.pathname === '/screen.png') {
    res.writeHead(200, {
      'Content-Type': 'image/png',
      'Cache-Control': 'no-store, no-cache, must-revalidate',
      'Pragma': 'no-cache'
    });
    const proc = spawn(adbPath, ['exec-out', 'screencap', '-p']);
    proc.stdout.pipe(res);
    proc.stderr.on('data', (d) => console.error('screencap err:', d.toString()));
    return;
  }

  if (url.pathname === '/tap') {
    const x = url.searchParams.get('x');
    const y = url.searchParams.get('y');
    if (x && y) {
      execFile(adbPath, ['shell', 'input', 'tap', x, y], (err) => {
        if (err) console.error('tap err:', err);
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('OK');
      });
    } else {
      res.writeHead(400);
      res.end('Missing x or y');
    }
    return;
  }

  if (url.pathname === '/swipe') {
    const x1 = url.searchParams.get('x1');
    const y1 = url.searchParams.get('y1');
    const x2 = url.searchParams.get('x2');
    const y2 = url.searchParams.get('y2');
    const ms = url.searchParams.get('ms') || '300';
    if (x1 && y1 && x2 && y2) {
      execFile(adbPath, ['shell', 'input', 'swipe', x1, y1, x2, y2, ms], (err) => {
        if (err) console.error('swipe err:', err);
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('OK');
      });
    } else {
      res.writeHead(400);
      res.end('Missing params');
    }
    return;
  }

  if (url.pathname === '/key') {
    const code = url.searchParams.get('code');
    if (code) {
      execFile(adbPath, ['shell', 'input', 'keyevent', code], (err) => {
        if (err) console.error('key err:', err);
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('OK');
      });
    } else {
      res.writeHead(400);
      res.end('Missing code');
    }
    return;
  }

  if (url.pathname === '/text') {
    const text = url.searchParams.get('text');
    if (text) {
      const sanitized = text.replace(/ /g, '%s');
      execFile(adbPath, ['shell', 'input', 'text', sanitized], (err) => {
        if (err) console.error('text err:', err);
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('OK');
      });
    } else {
      res.writeHead(400);
      res.end('Missing text');
    }
    return;
  }

  res.writeHead(404);
  res.end('Not Found');
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`SHOPZO Live Device Mirror running at http://localhost:${PORT}`);
});
