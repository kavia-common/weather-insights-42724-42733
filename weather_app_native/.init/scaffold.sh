#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/weather-insights-42724-42733/weather_app_native"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
TS=$(date +%s)
# Warn if partial install artifacts exist
if [ -d node_modules ] || [ -f package-lock.json ]; then echo "NOTICE: Existing node_modules or package-lock.json present; scaffold will avoid destructive changes." >&2; fi
# Init package.json if absent, otherwise back it up
if [ ! -f package.json ]; then
  npm init -y >/dev/null
else
  cp package.json "package.json.bak.$TS" 2>/dev/null || true
fi
# Ensure deterministic minimal fields and scripts
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));p.main=p.main||'main.js';p.scripts=p.scripts||{};p.scripts.start=p.scripts.start||'electron .';p.scripts.build=p.scripts.build||'electron-builder --linux --publish never';p.scripts.test=p.scripts.test||'jest --config=jest.config.js';p.dependencies=p.dependencies||{};p.devDependencies=p.devDependencies||{};fs.writeFileSync('package.json',JSON.stringify(p,null,2))"
# Create minimal main.js if missing
if [ ! -f main.js ]; then
  cat > main.js <<'JS'
const { app, BrowserWindow } = require('electron')
let win=null
function createWindow() {
  win = new BrowserWindow({ width: 800, height: 600 })
  win.loadFile('index.html')
}
app.whenReady().then(createWindow)
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); })
function handleSig(){ try { if (win) win.close(); } catch(e){}; app.quit(); }
process.on('SIGTERM', handleSig); process.on('SIGINT', handleSig)
JS
fi
# Create minimal index.html if missing
if [ ! -f index.html ]; then
  cat > index.html <<'HTML'
<!doctype html>
<html><body><h1>Weather App (dev)</h1><div id="root">No data</div><script>console.log('renderer ready')</script></body></html>
HTML
fi
# Create start helper (overwrites to keep deterministic behavior)
cat > start.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(pwd)"
if [ -x ./node_modules/.bin/electron ]; then exec ./node_modules/.bin/electron .; else exec npm start; fi
SH
chmod 755 start.sh

# Print summary
echo "Scaffold complete at $WORKSPACE"
