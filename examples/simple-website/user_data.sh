#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y nginx

# ----- Static site -----
cat > /usr/share/nginx/html/index.html << 'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${site_title}</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #0f172a; color: #e2e8f0;
           display: flex; flex-direction: column; align-items: center; justify-content: center;
           min-height: 100vh; margin: 0; }
    h1 { font-size: 3rem; margin-bottom: .25rem; }
    .card { background: #1e293b; padding: 2rem 3rem; border-radius: 12px; text-align: center; }
    button { margin-top: 1rem; padding: .6rem 1.4rem; font-size: 1rem; border: 0; border-radius: 8px;
             background: #38bdf8; color: #0f172a; cursor: pointer; }
    button:hover { background: #7dd3fc; }
    #clock { font-family: monospace; font-size: 1.4rem; margin-top: 1rem; }
    small { color: #94a3b8; }
  </style>
</head>
<body>
  <div class="card">
    <h1 id="greeting">Hello, World!</h1>
    <p>Served from <strong id="hostname">…</strong> in <strong id="az">…</strong></p>
    <div id="clock"></div>
    <button id="btn">Say hello</button>
    <p><small>Deployed by Terraform via a Launch Template + user data</small></p>
  </div>
  <script src="app.js"></script>
</body>
</html>
HTML

cat > /usr/share/nginx/html/app.js << 'JS'
// Live clock
function tick() {
  document.getElementById("clock").textContent = new Date().toLocaleString();
}
tick();
setInterval(tick, 1000);

// Rotating greeting on click
const greetings = ["Hello, World!", "Hola, Mundo!", "Bonjour, le Monde!", "Hallo, Welt!", "こんにちは、世界！"];
let i = 0;
document.getElementById("btn").addEventListener("click", () => {
  i = (i + 1) % greetings.length;
  document.getElementById("greeting").textContent = greetings[i];
});

// Pull instance details written at boot
fetch("/meta.json")
  .then(r => r.json())
  .then(m => {
    document.getElementById("hostname").textContent = m.hostname;
    document.getElementById("az").textContent = m.az;
  })
  .catch(() => {});
JS

# ----- Instance metadata (IMDSv2) for the page -----
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
cat > /usr/share/nginx/html/meta.json << JSON
{ "hostname": "$(hostname)", "az": "$AZ" }
JSON

systemctl enable --now nginx
