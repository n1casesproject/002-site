#!/bin/bash
# Админка DALER: 002.uz/admin (вход по паролю), правка стартовой страницы, заявки.
# Запускать на сервере под root ПОСЛЕ deploy-daler.sh:  bash deploy-admin.sh
set -e

[ -f /etc/nginx/sites-available/osiris ] || { echo "Сначала запустите deploy-daler.sh (нет настройки Nginx)"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Не найден docker. Сначала запустите deploy-daler.sh"; exit 1; }

echo "== 1. Файлы админки =="
mkdir -p /opt/daler-admin/app /opt/daler-admin/data /var/www/daler-landing /etc/nginx/snippets
cat > /opt/daler-admin/app/server.js <<'SERVER_JS_EOF'
'use strict';
// DALER admin: контент стартовой страницы, заявки, вход по паролю. Без внешних зависимостей (Node 22+).
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = +process.env.PORT || 3100;
const DATA = process.env.DATA_DIR || '/data';
const APP = __dirname;
const ENV_PASS = process.env.ADMIN_PASSWORD || '';
const TG_TOKEN = process.env.TG_BOT_TOKEN || '';
const TG_CHAT = process.env.TG_CHAT_ID || '';
const DEV_LANDING = process.env.DEV_LANDING || '';
fs.mkdirSync(DATA, { recursive: true });

/* ---------- storage ---------- */
function readJSON(name, def) {
  try { return JSON.parse(fs.readFileSync(path.join(DATA, name), 'utf8')); } catch (e) { return def; }
}
function writeJSON(name, obj) {
  const f = path.join(DATA, name), tmp = f + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2));
  fs.renameSync(tmp, f);
}
const SECRET = (function () {
  const s = readJSON('secret.json', null);
  if (s && s.v) return s.v;
  const v = crypto.randomBytes(32).toString('hex');
  writeJSON('secret.json', { v });
  return v;
})();

const DEFAULT_CONTENT = {
  tag: 'Daler & Mirzo AI Masters',
  title: 'DALER',
  subtitle: 'AI-видео, которые невозможно снять камерой, и живая карта мира: камеры, самолёты и спутники в реальном времени.',
  button: 'Открыть карту мира',
  orderButton: 'Заказать ролик',
  instagram: 'https://www.instagram.com/mirzouzs',
  telegram: 'https://t.me/uz_73',
  phone: '',
  email: 'whoopdaler@gmail.com',
  marquee: ['AI-видео', 'AI-агенты', 'Карта мира', 'Камеры онлайн', 'Самолёты', 'Спутники', 'Контент', 'Боты'],
  cards: [
    ['Кино-ролик', 'AI-видео', '#ff4d4d', '#3a0a0a'],
    ['Реклама для бизнеса', 'Reels / Shorts', '#d63a3a', '#1c0606'],
    ['Трансформации', 'Higgsfield', '#ff6a4d', '#2b0c08'],
    ['AI-агент для продаж', 'Автоматизация', '#b82e3a', '#16060a'],
    ['Фильм за день', 'Seedance', '#ff4d6a', '#2a0710'],
    ['Телеграм-бот', 'Боты', '#e0453a', '#190807'],
    ['Контент для бренда', 'Продакшн', '#ff5a4d', '#240a08'],
    ['Музыкальный клип', 'AI-видео', '#c8323a', '#1a0608'],
    ['Карта мира', 'Камеры в реальном времени', '#ff3d3d', '#2a0505'],
    ['Персонаж-бренд', '3D / AI', '#ff7a5a', '#2a100a'],
    ['Instagram под ключ', 'Контент-план', '#d9404a', '#1b070a'],
    ['Свой проект', 'Напишите нам', '#ff4d4d', '#120505']
  ].map(c => ({ title: c[0], tag: c[1], c1: c[2], c2: c[3], media: '' }))
};

const str = (v, max) => String(v == null ? '' : v).replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '').trim().slice(0, max);
const hex = (v, d) => (/^#[0-9a-fA-F]{6}$/.test(String(v)) ? String(v) : d);
const url = v => { v = str(v, 500); return (v === '' || /^https:\/\//i.test(v) || v.startsWith('/')) ? v : ''; };
function sanitizeContent(c) {
  c = c || {};
  const out = {
    tag: str(c.tag, 80), title: str(c.title, 40) || 'DALER', subtitle: str(c.subtitle, 300),
    button: str(c.button, 40) || 'Открыть карту мира', orderButton: str(c.orderButton, 40) || 'Заказать ролик',
    instagram: url(c.instagram), telegram: url(c.telegram),
    phone: str(c.phone, 30).replace(/[^\d+\-() ]/g, ''), email: str(c.email, 120).replace(/[^\w.@+\-]/g, ''),
    marquee: (Array.isArray(c.marquee) ? c.marquee : []).map(x => str(x, 40)).filter(Boolean).slice(0, 20),
    cards: (Array.isArray(c.cards) ? c.cards : []).slice(0, 24).map(x => ({
      title: str(x && x.title, 60), tag: str(x && x.tag, 50),
      c1: hex(x && x.c1, '#ff4d4d'), c2: hex(x && x.c2, '#120505'), media: url(x && x.media)
    })).filter(x => x.title)
  };
  if (out.cards.length < 3) out.cards = DEFAULT_CONTENT.cards;
  return out;
}
const getContent = () => sanitizeContent(readJSON('content.json', DEFAULT_CONTENT));

/* ---------- auth ---------- */
function hashPass(p, salt) { return crypto.scryptSync(p, salt, 32).toString('hex'); }
function checkPass(p) {
  const a = readJSON('auth.json', null);
  if (a && a.hash) {
    const h = hashPass(p, a.salt);
    return crypto.timingSafeEqual(Buffer.from(h), Buffer.from(a.hash));
  }
  if (!ENV_PASS) return false;
  const x = crypto.createHash('sha256').update(p).digest(), y = crypto.createHash('sha256').update(ENV_PASS).digest();
  return crypto.timingSafeEqual(x, y);
}
function sign(s) { return crypto.createHmac('sha256', SECRET).update(s).digest('hex'); }
function makeSession() {
  const exp = String(Date.now() + 7 * 24 * 3600 * 1000);
  return exp + '.' + sign(exp);
}
function validSession(tok) {
  if (!tok) return false;
  const [exp, sig] = tok.split('.');
  if (!exp || !sig || sign(exp).length !== sig.length) return false;
  if (!crypto.timingSafeEqual(Buffer.from(sign(exp)), Buffer.from(sig))) return false;
  return +exp > Date.now();
}
function cookies(req) {
  const o = {};
  (req.headers.cookie || '').split(';').forEach(p => { const i = p.indexOf('='); if (i > 0) o[p.slice(0, i).trim()] = decodeURIComponent(p.slice(i + 1).trim()); });
  return o;
}
const isAuthed = req => validSession(cookies(req).dsess) && (req.method === 'GET' || req.headers['x-dapi'] === '1');

/* ---------- rate limit ---------- */
const buckets = new Map();
function limited(key, max, windowMs) {
  const now = Date.now();
  let b = buckets.get(key);
  if (!b || b.reset < now) b = { n: 0, reset: now + windowMs };
  b.n++; buckets.set(key, b);
  return b.n > max;
}
setInterval(() => { const now = Date.now(); for (const [k, b] of buckets) if (b.reset < now) buckets.delete(k); }, 600000).unref();
const ipOf = req => String(req.headers['x-real-ip'] || req.socket.remoteAddress || '').slice(0, 64);

/* ---------- telegram ---------- */
async function tg(text) {
  if (!TG_TOKEN || !TG_CHAT) return { ok: false, error: 'not configured' };
  try {
    const r = await fetch('https://api.telegram.org/bot' + TG_TOKEN + '/sendMessage', {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ chat_id: TG_CHAT, text, disable_web_page_preview: true })
    });
    const j = await r.json();
    return { ok: !!j.ok, error: j.description };
  } catch (e) { return { ok: false, error: String(e.message || e) }; }
}

/* ---------- http helpers ---------- */
function send(res, code, body, headers) {
  const h = Object.assign({ 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' }, headers || {});
  if (typeof body === 'object' && !Buffer.isBuffer(body)) { body = JSON.stringify(body); h['content-type'] = 'application/json; charset=utf-8'; }
  res.writeHead(code, h); res.end(body);
}
function readBody(req) {
  return new Promise((resolve, reject) => {
    let n = 0; const chunks = [];
    req.on('data', c => { n += c.length; if (n > 200000) { reject(new Error('too large')); req.destroy(); } else chunks.push(c); });
    req.on('end', () => { try { resolve(chunks.length ? JSON.parse(Buffer.concat(chunks).toString('utf8')) : {}); } catch (e) { reject(new Error('bad json')); } });
    req.on('error', reject);
  });
}

const STATUSES = ['new', 'work', 'done', 'paid', 'rejected'];

const server = http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://x');
  const p = u.pathname.replace(/\/+$/, '') || '/';
  try {
    if (p === '/admin') {
      return send(res, 200, fs.readFileSync(path.join(APP, 'admin.html')), { 'content-type': 'text/html; charset=utf-8', 'x-frame-options': 'DENY', 'referrer-policy': 'no-referrer' });
    }
    if (DEV_LANDING && (p === '/' || p === '/landing/index.html')) {
      return send(res, 200, fs.readFileSync(DEV_LANDING), { 'content-type': 'text/html; charset=utf-8' });
    }

    /* public */
    if (p === '/dapi/content' && req.method === 'GET') {
      return send(res, 200, getContent(), { 'cache-control': 'no-cache' });
    }
    if (p === '/dapi/lead' && req.method === 'POST') {
      if (limited('lead:' + ipOf(req), 5, 3600 * 1000)) return send(res, 429, { error: 'Слишком много заявок, попробуйте позже' });
      const b = await readBody(req);
      if (b.website) return send(res, 200, { ok: true }); // honeypot
      const lead = { id: crypto.randomBytes(6).toString('hex'), name: str(b.name, 80), contact: str(b.contact, 120), message: str(b.message, 1000), status: 'new', note: '', at: new Date().toISOString() };
      if (!lead.name || !lead.contact) return send(res, 400, { error: 'Укажите имя и контакт' });
      const leads = readJSON('leads.json', []);
      leads.unshift(lead); writeJSON('leads.json', leads.slice(0, 2000));
      tg('Новая заявка DALER\nИмя: ' + lead.name + '\nКонтакт: ' + lead.contact + (lead.message ? '\nСообщение: ' + lead.message : ''));
      return send(res, 200, { ok: true });
    }
    if (p === '/dapi/login' && req.method === 'POST') {
      const ip = ipOf(req);
      if (limited('login:' + ip, 5, 15 * 60 * 1000)) return send(res, 429, { error: 'Слишком много попыток. Подождите 15 минут.' });
      const b = await readBody(req);
      if (!checkPass(String(b.password || ''))) return send(res, 401, { error: 'Неверный пароль' });
      const secure = req.headers['x-forwarded-proto'] === 'https' ? '; Secure' : '';
      return send(res, 200, { ok: true }, { 'set-cookie': 'dsess=' + makeSession() + '; HttpOnly; SameSite=Strict; Path=/; Max-Age=604800' + secure });
    }
    if (p === '/dapi/logout' && req.method === 'POST') {
      return send(res, 200, { ok: true }, { 'set-cookie': 'dsess=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0' });
    }
    if (p === '/dapi/me') return send(res, 200, { auth: validSession(cookies(req).dsess) });

    /* admin */
    if (p.startsWith('/dapi/admin')) {
      if (!isAuthed(req)) return send(res, 401, { error: 'auth' });
      if (p === '/dapi/admin/content' && req.method === 'GET') return send(res, 200, getContent());
      if (p === '/dapi/admin/content' && req.method === 'PUT') {
        const c = sanitizeContent(await readBody(req)); writeJSON('content.json', c); return send(res, 200, c);
      }
      if (p === '/dapi/admin/leads' && req.method === 'GET') return send(res, 200, readJSON('leads.json', []));
      let m = p.match(/^\/dapi\/admin\/leads\/([0-9a-f]+)$/);
      if (m && req.method === 'PATCH') {
        const b = await readBody(req); const leads = readJSON('leads.json', []); const l = leads.find(x => x.id === m[1]);
        if (!l) return send(res, 404, { error: 'not found' });
        if (b.status !== undefined && STATUSES.includes(b.status)) l.status = b.status;
        if (b.note !== undefined) l.note = str(b.note, 1000);
        writeJSON('leads.json', leads); return send(res, 200, l);
      }
      if (m && req.method === 'DELETE') {
        writeJSON('leads.json', readJSON('leads.json', []).filter(x => x.id !== m[1])); return send(res, 200, { ok: true });
      }
      if (p === '/dapi/admin/password' && req.method === 'POST') {
        const b = await readBody(req);
        if (!checkPass(String(b.old || ''))) return send(res, 400, { error: 'Старый пароль неверный' });
        const np = String(b.new || '');
        if (np.length < 10) return send(res, 400, { error: 'Новый пароль: минимум 10 символов' });
        const salt = crypto.randomBytes(16).toString('hex');
        writeJSON('auth.json', { salt, hash: hashPass(np, salt) });
        return send(res, 200, { ok: true });
      }
      if (p === '/dapi/admin/tg' && req.method === 'GET') return send(res, 200, { configured: !!(TG_TOKEN && TG_CHAT) });
      if (p === '/dapi/admin/tg-test' && req.method === 'POST') return send(res, 200, await tg('Проверка связи: админка DALER подключена к Telegram.'));
      return send(res, 404, { error: 'not found' });
    }
    return send(res, 404, { error: 'not found' });
  } catch (e) {
    return send(res, 400, { error: String(e.message || e) });
  }
});
server.listen(PORT, process.env.HOST || '127.0.0.1', () => console.log('daler-admin on ' + PORT));

SERVER_JS_EOF
cat > /opt/daler-admin/app/admin.html <<'ADMIN_HTML_EOF'
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>DALER — админка</title>
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link href="https://fonts.googleapis.com/css2?family=Unbounded:wght@500;700;900&family=Space+Mono:wght@400;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root{--bg:#070404;--bg2:#120909;--bg3:#1b0e0e;--line:rgba(255,255,255,.12);--red:#ff4d4d;--red2:#ff8080;--text:#f2ecea;--mute:#9b8f8d;--ok:#3ddc84;--warn:#ffb020;
--fd:'Unbounded','Arial Black',sans-serif;--fm:'Space Mono',ui-monospace,monospace;--fb:'Inter',system-ui,sans-serif}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--fb);font-size:15px;min-height:100vh}
button{font-family:inherit;cursor:pointer}
input,textarea,select{font-family:inherit;font-size:14px;color:var(--text);background:var(--bg2);border:1px solid var(--line);border-radius:10px;padding:10px 12px;width:100%;outline:none}
input:focus,textarea:focus,select:focus{border-color:var(--red)}
input[type=color]{padding:2px;height:40px;width:54px;cursor:pointer}
textarea{resize:vertical;min-height:70px}
label{display:block;font-family:var(--fm);font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:var(--mute);margin:0 0 6px}
.btn{background:var(--red);color:#150606;border:0;border-radius:999px;padding:12px 22px;font-family:var(--fd);font-weight:700;font-size:13px;transition:.2s}
.btn:hover{background:var(--red2)}
.btn.ghost{background:transparent;color:var(--text);border:1px solid var(--line)}
.btn.ghost:hover{border-color:var(--red);color:var(--red)}
.btn.sm{padding:8px 14px;font-size:12px}
.btn.danger{background:transparent;color:#ff7070;border:1px solid rgba(255,112,112,.4)}
/* login */
#login{min-height:100vh;display:grid;place-items:center;padding:20px}
.lbox{width:min(380px,100%);background:var(--bg2);border:1px solid var(--line);border-radius:20px;padding:32px}
.lbox h1{font-family:var(--fd);font-weight:900;font-size:26px;margin-bottom:6px}.lbox h1 span{color:var(--red)}
.lbox p{color:var(--mute);font-size:13px;margin-bottom:22px}
.err{color:#ff7070;font-size:13px;margin-top:12px;min-height:18px}
/* app */
#app{display:none}
header{position:sticky;top:0;z-index:10;display:flex;align-items:center;gap:18px;flex-wrap:wrap;padding:14px clamp(14px,3vw,36px);background:rgba(7,4,4,.92);backdrop-filter:blur(8px);border-bottom:1px solid var(--line)}
.logo{font-family:var(--fd);font-weight:900;font-size:17px}.logo span{color:var(--red)}
.tabs{display:flex;gap:6px;flex:1;flex-wrap:wrap}
.tab{background:transparent;border:1px solid transparent;color:var(--mute);padding:9px 16px;border-radius:999px;font-size:14px;font-weight:600}
.tab.on{color:var(--text);border-color:var(--red);background:rgba(255,77,77,.1)}
.tab .badge{display:inline-block;min-width:20px;padding:1px 6px;margin-left:6px;border-radius:999px;background:var(--red);color:#150606;font-size:11px;font-weight:700;text-align:center}
main{max-width:980px;margin:0 auto;padding:26px clamp(14px,3vw,36px) 120px}
.panel{display:none}.panel.on{display:block}
.sec{background:var(--bg2);border:1px solid var(--line);border-radius:18px;padding:22px;margin-bottom:18px}
.sec h2{font-family:var(--fd);font-size:15px;font-weight:700;margin-bottom:16px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.grid .full{grid-column:1/-1}
@media(max-width:640px){.grid{grid-template-columns:1fr}}
.card{display:grid;grid-template-columns:34px 1.4fr 1.1fr auto auto 1.4fr auto;gap:8px;align-items:center;padding:10px;border:1px solid var(--line);border-radius:12px;margin-bottom:8px;background:var(--bg3)}
.card .n{font-family:var(--fm);color:var(--mute);font-size:12px}
.card .mv{display:flex;gap:4px}
@media(max-width:820px){.card{grid-template-columns:1fr 1fr;}.card .n{display:none}}
.savebar{position:fixed;left:0;right:0;bottom:0;z-index:20;display:flex;gap:12px;align-items:center;justify-content:flex-end;padding:14px clamp(14px,3vw,36px);background:rgba(7,4,4,.94);border-top:1px solid var(--line)}
.savebar .msg{margin-right:auto;font-size:13px;color:var(--mute)}
.msg.ok{color:var(--ok)}.msg.bad{color:#ff7070}
.lead{border:1px solid var(--line);border-radius:14px;padding:16px;margin-bottom:12px;background:var(--bg2)}
.lead .top{display:flex;gap:10px;flex-wrap:wrap;align-items:baseline;margin-bottom:8px}
.lead .nm{font-weight:700;font-size:16px}
.lead .ct{font-family:var(--fm);font-size:13px;color:var(--red2)}
.lead .at{font-family:var(--fm);font-size:11px;color:var(--mute);margin-left:auto}
.lead .ms{color:#d8cfcd;white-space:pre-wrap;margin-bottom:12px;font-size:14px}
.lead .row{display:flex;gap:10px;flex-wrap:wrap;align-items:center}
.lead select{width:auto}.lead textarea{min-height:44px;flex:1;min-width:200px}
.st-new{border-left:4px solid var(--red)}.st-work{border-left:4px solid var(--warn)}.st-done{border-left:4px solid var(--ok)}.st-paid{border-left:4px solid #5aa8ff}.st-rejected{border-left:4px solid #555;opacity:.7}
.empty{color:var(--mute);padding:30px;text-align:center;border:1px dashed var(--line);border-radius:14px}
.filters{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px}
.chip{background:transparent;color:var(--mute);border:1px solid var(--line);border-radius:999px;padding:7px 14px;font-size:13px}
.chip.on{color:var(--text);border-color:var(--red)}
.hint{font-size:13px;color:var(--mute);line-height:1.5;margin-top:10px}
.pill{display:inline-block;padding:3px 10px;border-radius:999px;font-size:12px;font-weight:600}
.pill.ok{background:rgba(61,220,132,.15);color:var(--ok)}.pill.no{background:rgba(255,176,32,.15);color:var(--warn)}
</style>
</head>
<body>

<div id="login">
  <form class="lbox" id="lform">
    <h1>DALER<span>.</span></h1>
    <p>Вход в админ-панель</p>
    <label for="pw">Пароль</label>
    <input id="pw" type="password" autocomplete="current-password" autofocus>
    <div class="err" id="lerr"></div>
    <button class="btn" style="width:100%;margin-top:6px" type="submit">Войти</button>
  </form>
</div>

<div id="app">
  <header>
    <div class="logo">DALER<span>.</span> админка</div>
    <div class="tabs">
      <button class="tab on" data-t="page">Страница</button>
      <button class="tab" data-t="leads">Заявки<span class="badge" id="nb" style="display:none">0</span></button>
      <button class="tab" data-t="settings">Настройки</button>
    </div>
    <a class="btn ghost sm" href="/" target="_blank" style="text-decoration:none">Открыть сайт</a>
    <button class="btn ghost sm" id="logout">Выйти</button>
  </header>

  <main>
    <!-- PAGE -->
    <div class="panel on" id="p-page">
      <div class="sec">
        <h2>Главный экран</h2>
        <div class="grid">
          <div><label>Надпись над заголовком</label><input id="f-tag"></div>
          <div><label>Заголовок</label><input id="f-title"></div>
          <div class="full"><label>Подзаголовок</label><textarea id="f-subtitle"></textarea></div>
          <div><label>Кнопка «карта»</label><input id="f-button"></div>
          <div><label>Кнопка «заказать»</label><input id="f-orderButton"></div>
        </div>
      </div>
      <div class="sec">
        <h2>Контакты и ссылки</h2>
        <div class="grid">
          <div><label>Instagram (https://…)</label><input id="f-instagram"></div>
          <div><label>Telegram (https://t.me/…)</label><input id="f-telegram"></div>
          <div><label>Телефон</label><input id="f-phone" placeholder="+998 95 723 1111"></div>
          <div><label>Почта</label><input id="f-email"></div>
        </div>
      </div>
      <div class="sec">
        <h2>Карточки спирали</h2>
        <div id="cards"></div>
        <button class="btn ghost sm" id="addcard" type="button">+ Добавить карточку</button>
        <p class="hint">«Видео или картинка» — ссылка вида https://… на файл .mp4 / .webm / .jpg / .png. Пусто — будет цветная карточка. Минимум 3 карточки.</p>
      </div>
      <div class="sec">
        <h2>Бегущая строка</h2>
        <label>Каждое слово с новой строки</label>
        <textarea id="f-marquee" style="min-height:120px"></textarea>
      </div>
    </div>

    <!-- LEADS -->
    <div class="panel" id="p-leads">
      <div class="filters" id="filters"></div>
      <div id="leads"></div>
    </div>

    <!-- SETTINGS -->
    <div class="panel" id="p-settings">
      <div class="sec">
        <h2>Уведомления в Telegram</h2>
        <p style="margin-bottom:12px">Состояние: <span id="tgst" class="pill no">проверяю…</span></p>
        <button class="btn ghost sm" id="tgtest" type="button">Отправить тестовое сообщение</button>
        <div class="err" id="tgmsg" style="color:var(--mute)"></div>
        <p class="hint">Токен бота и номер чата задаются на сервере в файле <b>/opt/daler-admin/.env</b> (TG_BOT_TOKEN и TG_CHAT_ID), затем перезапуск: <b>docker restart daler-admin</b>.</p>
      </div>
      <div class="sec">
        <h2>Сменить пароль</h2>
        <div class="grid">
          <div><label>Старый пароль</label><input id="pw-old" type="password" autocomplete="current-password"></div>
          <div><label>Новый пароль (от 10 символов)</label><input id="pw-new" type="password" autocomplete="new-password"></div>
        </div>
        <div style="margin-top:14px"><button class="btn sm" id="pwsave" type="button">Сменить</button></div>
        <div class="err" id="pwmsg"></div>
      </div>
    </div>
  </main>

  <div class="savebar" id="savebar">
    <div class="msg" id="smsg">Изменения сохраняются на сайт сразу после нажатия кнопки.</div>
    <button class="btn" id="save" type="button">Сохранить и опубликовать</button>
  </div>
</div>

<script>
(function(){
  var $=function(s){return document.querySelector(s)};
  function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
  function api(method,path,body){
    return fetch(path,{method:method,credentials:'same-origin',headers:{'content-type':'application/json','x-dapi':'1'},body:body?JSON.stringify(body):undefined})
      .then(function(r){return r.json().catch(function(){return {}}).then(function(j){if(r.status===401&&path.indexOf('/login')<0){showLogin()}; if(!r.ok)throw new Error(j.error||('Ошибка '+r.status)); return j})});
  }
  var content=null, leads=[], filter='all';

  /* login */
  function showLogin(){$('#app').style.display='none';$('#login').style.display='grid'}
  function showApp(){$('#login').style.display='none';$('#app').style.display='block';loadAll()}
  $('#lform').addEventListener('submit',function(e){
    e.preventDefault();$('#lerr').textContent='';
    api('POST','/dapi/login',{password:$('#pw').value}).then(function(){$('#pw').value='';showApp()}).catch(function(err){$('#lerr').textContent=err.message});
  });
  $('#logout').addEventListener('click',function(){api('POST','/dapi/logout').then(showLogin)});
  fetch('/dapi/me',{credentials:'same-origin'}).then(function(r){return r.json()}).then(function(j){j.auth?showApp():showLogin()}).catch(showLogin);

  /* tabs */
  document.querySelectorAll('.tab').forEach(function(b){b.addEventListener('click',function(){
    document.querySelectorAll('.tab').forEach(function(x){x.classList.toggle('on',x===b)});
    document.querySelectorAll('.panel').forEach(function(p){p.classList.toggle('on',p.id==='p-'+b.dataset.t)});
    $('#savebar').style.display=b.dataset.t==='page'?'flex':'none';
    if(b.dataset.t==='leads')loadLeads();
    if(b.dataset.t==='settings')loadTg();
  })});

  function loadAll(){
    api('GET','/dapi/admin/content').then(function(c){content=c;fillPage()});
    loadLeads(true);
  }

  /* page */
  var F=['tag','title','subtitle','button','orderButton','instagram','telegram','phone','email'];
  function fillPage(){
    F.forEach(function(k){$('#f-'+k).value=content[k]||''});
    $('#f-marquee').value=(content.marquee||[]).join('\n');
    renderCards();
  }
  function renderCards(){
    var box=$('#cards');box.innerHTML='';
    content.cards.forEach(function(c,i){
      var d=document.createElement('div');d.className='card';
      d.innerHTML='<span class="n">'+String(i+1).padStart(2,'0')+'</span>'+
        '<input data-k="title" placeholder="Название" value="'+esc(c.title)+'">'+
        '<input data-k="tag" placeholder="Подпись" value="'+esc(c.tag)+'">'+
        '<input data-k="c1" type="color" value="'+esc(c.c1)+'" title="Цвет 1">'+
        '<input data-k="c2" type="color" value="'+esc(c.c2)+'" title="Цвет 2">'+
        '<input data-k="media" placeholder="Видео или картинка (https://…)" value="'+esc(c.media)+'">'+
        '<span class="mv"><button class="btn ghost sm" data-a="up" type="button">↑</button><button class="btn ghost sm" data-a="down" type="button">↓</button><button class="btn danger sm" data-a="del" type="button">✕</button></span>';
      d.querySelectorAll('input').forEach(function(inp){inp.addEventListener('input',function(){c[inp.dataset.k]=inp.value})});
      d.querySelectorAll('button').forEach(function(bt){bt.addEventListener('click',function(){
        var a=bt.dataset.a,cs=content.cards;
        if(a==='del'){if(cs.length<=3){alert('Нужно минимум 3 карточки');return}cs.splice(i,1)}
        if(a==='up'&&i>0){var t=cs[i];cs[i]=cs[i-1];cs[i-1]=t}
        if(a==='down'&&i<cs.length-1){var t2=cs[i];cs[i]=cs[i+1];cs[i+1]=t2}
        renderCards();
      })});
      box.appendChild(d);
    });
  }
  $('#addcard').addEventListener('click',function(){
    if(content.cards.length>=24){alert('Максимум 24 карточки');return}
    content.cards.push({title:'Новая карточка',tag:'',c1:'#ff4d4d',c2:'#120505',media:''});renderCards();
  });
  $('#save').addEventListener('click',function(){
    F.forEach(function(k){content[k]=$('#f-'+k).value});
    content.marquee=$('#f-marquee').value.split('\n');
    var m=$('#smsg');m.className='msg';m.textContent='Сохраняю…';
    api('PUT','/dapi/admin/content',content).then(function(c){content=c;fillPage();m.className='msg ok';m.textContent='Сохранено. Изменения уже на сайте.'})
      .catch(function(e){m.className='msg bad';m.textContent=e.message});
  });

  /* leads */
  var ST={new:'Новая',work:'В работе',done:'Готово',paid:'Оплачено',rejected:'Отказ'};
  function loadLeads(quiet){
    api('GET','/dapi/admin/leads').then(function(l){leads=l;renderLeads()}).catch(function(){});
  }
  function renderLeads(){
    var nn=leads.filter(function(l){return l.status==='new'}).length;
    var nb=$('#nb');nb.textContent=nn;nb.style.display=nn?'inline-block':'none';
    var f=$('#filters');f.innerHTML='';
    ['all','new','work','done','paid','rejected'].forEach(function(s){
      var b=document.createElement('button');b.className='chip'+(filter===s?' on':'');
      b.textContent=(s==='all'?'Все':ST[s])+' ('+(s==='all'?leads.length:leads.filter(function(l){return l.status===s}).length)+')';
      b.addEventListener('click',function(){filter=s;renderLeads()});f.appendChild(b);
    });
    var box=$('#leads');box.innerHTML='';
    var list=leads.filter(function(l){return filter==='all'||l.status===filter});
    if(!list.length){box.innerHTML='<div class="empty">Заявок пока нет</div>';return}
    list.forEach(function(l){
      var d=document.createElement('div');d.className='lead st-'+l.status;
      var dt=new Date(l.at);
      d.innerHTML='<div class="top"><span class="nm">'+esc(l.name)+'</span><span class="ct">'+esc(l.contact)+'</span><span class="at">'+dt.toLocaleString('ru-RU')+'</span></div>'+
        (l.message?'<div class="ms">'+esc(l.message)+'</div>':'')+
        '<div class="row"><select>'+Object.keys(ST).map(function(s){return '<option value="'+s+'"'+(s===l.status?' selected':'')+'>'+ST[s]+'</option>'}).join('')+'</select>'+
        '<textarea placeholder="Заметка">'+esc(l.note)+'</textarea><button class="btn danger sm" type="button">Удалить</button></div>';
      d.querySelector('select').addEventListener('change',function(e){api('PATCH','/dapi/admin/leads/'+l.id,{status:e.target.value}).then(function(x){l.status=x.status;renderLeads()})});
      d.querySelector('textarea').addEventListener('change',function(e){api('PATCH','/dapi/admin/leads/'+l.id,{note:e.target.value})});
      d.querySelector('button').addEventListener('click',function(){if(confirm('Удалить заявку от '+l.name+'?'))api('DELETE','/dapi/admin/leads/'+l.id).then(function(){leads=leads.filter(function(x){return x!==l});renderLeads()})});
      box.appendChild(d);
    });
  }

  /* settings */
  function loadTg(){
    api('GET','/dapi/admin/tg').then(function(j){var p=$('#tgst');p.className='pill '+(j.configured?'ok':'no');p.textContent=j.configured?'подключено':'не настроено'});
  }
  $('#tgtest').addEventListener('click',function(){
    var m=$('#tgmsg');m.textContent='Отправляю…';
    api('POST','/dapi/admin/tg-test').then(function(j){m.style.color=j.ok?'var(--ok)':'#ff7070';m.textContent=j.ok?'Отправлено, проверьте Telegram.':('Не получилось: '+(j.error||'ошибка'))});
  });
  $('#pwsave').addEventListener('click',function(){
    var m=$('#pwmsg');m.style.color='var(--mute)';m.textContent='…';
    api('POST','/dapi/admin/password',{old:$('#pw-old').value,new:$('#pw-new').value}).then(function(){m.style.color='var(--ok)';m.textContent='Пароль изменён.';$('#pw-old').value='';$('#pw-new').value=''})
      .catch(function(e){m.style.color='#ff7070';m.textContent=e.message});
  });
})();
</script>
</body>
</html>

ADMIN_HTML_EOF
cat > /var/www/daler-landing/index.html <<'LANDING_EOF'
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>DALER — AI-видео и глобальная карта мира</title>
<meta name="description" content="Daler & Mirzo AI Masters: AI-видео, AI-агенты и глобальная карта мира с камерами, самолётами и спутниками в реальном времени.">
<meta name="theme-color" content="#070404">
<meta property="og:title" content="DALER — AI-видео и глобальная карта мира">
<meta property="og:description" content="Daler & Mirzo AI Masters: AI-видео, AI-агенты и карта мира: камеры, самолёты, спутники в реальном времени.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://002.uz">
<meta property="og:image" content="https://002.uz/og-image.png">
<meta property="og:locale" content="ru_RU">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Unbounded:wght@500;700;900&family=Space+Mono:wght@400;700&family=Inter:wght@400;500&display=swap" rel="stylesheet">
<style>
:root{
  --bg:#070404; --bg2:#120909; --red:#ff4d4d; --red2:#ff8080; --text:#f2ecea; --mute:#9b8f8d;
  --font-d:'Unbounded','Arial Black',sans-serif; --font-m:'Space Mono',ui-monospace,monospace; --font-b:'Inter',system-ui,sans-serif;
  --R:520px; --CW:230px; --CH:310px;
}
*{box-sizing:border-box;margin:0;padding:0}
html,body{height:100%;overflow:hidden;background:var(--bg);color:var(--text);font-family:var(--font-b);-webkit-font-smoothing:antialiased}
body{overscroll-behavior:none;touch-action:none;cursor:grab}
body.drag{cursor:grabbing}
/* grain */
body::after{content:"";position:fixed;inset:0;pointer-events:none;z-index:50;opacity:.07;
  background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='160'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='2' stitchTiles='stitch'/></filter><rect width='100%' height='100%' filter='url(%23n)'/></svg>")}
.glow{position:fixed;inset:0;background:radial-gradient(60% 50% at 70% 45%,rgba(255,77,77,.16),transparent 70%),radial-gradient(40% 40% at 10% 100%,rgba(255,77,77,.08),transparent 70%);pointer-events:none}
header{position:fixed;top:0;left:0;right:0;display:flex;justify-content:space-between;align-items:center;padding:22px clamp(16px,4vw,48px);z-index:20}
.logo{font-family:var(--font-d);font-weight:900;font-size:18px;letter-spacing:.04em;color:var(--text);text-decoration:none;display:flex;align-items:center;gap:10px}
.logo i{width:12px;height:12px;border-radius:50%;background:var(--red);box-shadow:0 0 18px var(--red);animation:pulse 2s infinite}
@keyframes pulse{50%{opacity:.35}}
nav{display:flex;gap:10px}
nav a{font-family:var(--font-m);font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--text);text-decoration:none;padding:9px 16px;border:1px solid rgba(255,255,255,.18);border-radius:999px;transition:.25s}
nav a:hover{border-color:var(--red);color:var(--red)}
/* hero text */
.hero{position:fixed;left:clamp(16px,4vw,48px);bottom:clamp(90px,14vh,150px);z-index:10;max-width:min(560px,88vw);pointer-events:none}
.tag{font-family:var(--font-m);font-size:12px;letter-spacing:.14em;color:var(--red);text-transform:uppercase;margin-bottom:16px}
h1{text-shadow:0 2px 30px rgba(7,4,4,.8);font-family:var(--font-d);font-weight:900;line-height:.92;font-size:clamp(54px,11vw,150px);letter-spacing:-.02em}
h1 span{color:var(--red)}
.sub{margin-top:20px;font-size:clamp(14px,1.5vw,18px);line-height:1.5;color:#d8cfcd;max-width:460px}
.cta{pointer-events:auto;margin-top:28px;display:inline-flex;align-items:center;gap:12px;font-family:var(--font-d);font-weight:700;font-size:14px;letter-spacing:.04em;color:#120505;background:var(--red);border:0;border-radius:999px;padding:18px 28px;cursor:pointer;transition:.25s;box-shadow:0 0 40px rgba(255,77,77,.35)}
.cta:hover{transform:translateY(-2px);background:var(--red2);box-shadow:0 0 60px rgba(255,77,77,.55)}
.cta b{transition:.25s}.cta:hover b{transform:translateX(5px)}
.hint{position:fixed;right:clamp(16px,4vw,48px);bottom:clamp(90px,14vh,150px);z-index:10;font-family:var(--font-m);font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:var(--mute);writing-mode:vertical-rl;display:flex;align-items:center;gap:12px}
.hint::after{content:"";width:1px;height:60px;background:linear-gradient(var(--red),transparent)}
/* helix */
.stage{position:fixed;inset:0;perspective:1500px;perspective-origin:68% 45%;overflow:hidden}
.helix{position:absolute;left:68%;top:46%;width:0;height:0;transform-style:preserve-3d;will-change:transform}
.card{position:absolute;width:var(--CW);height:var(--CH);margin:calc(var(--CH)/-2) 0 0 calc(var(--CW)/-2);
  border-radius:18px;padding:18px;display:flex;flex-direction:column;justify-content:space-between;
  background:linear-gradient(160deg,var(--c1),var(--c2));border:1px solid rgba(255,255,255,.14);
  backface-visibility:hidden;-webkit-backface-visibility:hidden;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.55);user-select:none;-webkit-user-select:none}
.card::before{content:"";position:absolute;inset:0;background:repeating-linear-gradient(0deg,rgba(255,255,255,.035) 0 1px,transparent 1px 4px);mix-blend-mode:overlay}
.card .n{font-family:var(--font-m);font-size:12px;letter-spacing:.14em;color:rgba(255,255,255,.75)}
.card .ico{position:absolute;right:16px;top:14px;width:38px;height:38px;border-radius:50%;border:1px solid rgba(255,255,255,.4);display:grid;place-items:center}
.card .ico::after{content:"";border-left:11px solid #fff;border-top:7px solid transparent;border-bottom:7px solid transparent;margin-left:3px}
.card h3{font-family:var(--font-d);font-weight:700;font-size:19px;line-height:1.15;position:relative}
.card p{font-family:var(--font-m);font-size:11px;letter-spacing:.06em;color:rgba(255,255,255,.7);margin-top:8px;text-transform:uppercase;position:relative}
/* marquee */
.marq{position:fixed;left:0;right:0;bottom:0;z-index:15;border-top:1px solid rgba(255,255,255,.1);background:rgba(7,4,4,.7);backdrop-filter:blur(6px);overflow:hidden;padding:14px 0;pointer-events:none}
.marq div{display:flex;gap:44px;width:max-content;animation:mq 30s linear infinite;font-family:var(--font-d);font-weight:700;font-size:14px;letter-spacing:.06em;text-transform:uppercase;white-space:nowrap}
.marq span{color:var(--text)} .marq em{font-style:normal;color:var(--red)}
@keyframes mq{to{transform:translateX(-50%)}}
.counter{position:fixed;top:50%;left:clamp(16px,4vw,48px);transform:translateY(-50%);z-index:10;font-family:var(--font-m);font-size:12px;color:var(--mute);letter-spacing:.1em;display:none}
@media (max-width:760px){
  :root{--R:330px;--CW:150px;--CH:200px}
  .helix{left:50%;top:27%}
  .stage{perspective-origin:50% 27%}
  .hero{bottom:84px}
  .hint{display:none}
  nav a{padding:8px 12px;font-size:11px}
  .card h3{font-size:13px;overflow-wrap:anywhere}.card{padding:14px}
}

.cta.alt{background:transparent;color:var(--text);border:1px solid rgba(255,255,255,.28);box-shadow:none;margin-left:10px}
.cta.alt:hover{border-color:var(--red);color:var(--red);background:transparent;box-shadow:none}
.btns{display:flex;flex-wrap:wrap;gap:10px;align-items:center;margin-top:28px}
.btns .cta,.btns .cta.alt{margin:0}
.contacts{margin-top:18px;font-family:var(--font-m);font-size:12px;letter-spacing:.06em;color:var(--mute);pointer-events:auto}
.contacts a{color:var(--text);text-decoration:none;margin-right:18px}.contacts a:hover{color:var(--red)}
.card .media{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:.55}
.card .n,.card .ico,.card>div{position:relative}
.modal{position:fixed;inset:0;z-index:100;display:none;place-items:center;background:rgba(5,3,3,.78);backdrop-filter:blur(6px);padding:18px;touch-action:auto;cursor:auto}
.modal.on{display:grid}
.mbox{width:min(440px,100%);background:#120909;border:1px solid rgba(255,255,255,.14);border-radius:20px;padding:28px;position:relative}
.mbox h2{font-family:var(--font-d);font-weight:900;font-size:22px;margin-bottom:6px}
.mbox p{color:var(--mute);font-size:13px;margin-bottom:18px}
.mbox label{display:block;font-family:var(--font-m);font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:var(--mute);margin:12px 0 6px}
.mbox input,.mbox textarea{width:100%;font:inherit;font-size:15px;color:var(--text);background:#070404;border:1px solid rgba(255,255,255,.14);border-radius:10px;padding:12px;outline:none}
.mbox input:focus,.mbox textarea:focus{border-color:var(--red)}
.mbox textarea{min-height:90px;resize:vertical}
.mbox .x{position:absolute;right:14px;top:12px;background:none;border:0;color:var(--mute);font-size:26px;cursor:pointer}
.mbox .cta{width:100%;justify-content:center;margin-top:18px}
.mbox .hp{position:absolute;left:-9999px;opacity:0}
.mmsg{margin-top:12px;font-size:13px;min-height:18px;color:var(--mute)}
@media (max-width:760px){.btns{margin-top:22px}.cta{padding:15px 20px;font-size:13px}}
@media (prefers-reduced-motion:reduce){.marq div{animation:none}}
</style>
</head>
<body>
<div class="glow"></div>
<header>
  <a class="logo" href="/"><i></i><span id="t-logo">DALER</span></a>
  <nav>
    <a id="l-ig" href="https://www.instagram.com/mirzouzs" target="_blank" rel="noopener">Instagram</a>
    <a id="l-tg" href="https://t.me/uz_73" target="_blank" rel="noopener">Telegram</a>
  </nav>
</header>

<div class="stage"><div class="helix" id="helix"></div></div>

<section class="hero">
  <div class="tag" id="t-tag">[ Daler &amp; Mirzo AI Masters ]</div>
  <h1><span id="t-title" style="color:inherit">DALER</span><span>.</span></h1>
  <p class="sub" id="t-sub">AI-видео, которые невозможно снять камерой, и живая карта мира: камеры, самолёты и спутники в реальном времени.</p>
  <div class="btns">
    <button class="cta" id="go" type="button"><span id="t-btn">Открыть карту мира</span> <b>→</b></button>
    <button class="cta alt" id="order" type="button">Заказать ролик</button>
  </div>
  <div class="contacts" id="contacts"></div>
</section>
<div class="hint">Крутите колесо или тяните</div>

<div class="marq"><div id="mq"></div></div>

<div class="modal" id="modal" role="dialog" aria-modal="true">
  <form class="mbox" id="oform" autocomplete="off">
    <button class="x" type="button" id="mx" aria-label="Закрыть">×</button>
    <h2>Заказать ролик</h2>
    <p>Оставьте контакт, мы свяжемся и всё обсудим.</p>
    <label for="o-name">Имя</label><input id="o-name" maxlength="80" required>
    <label for="o-contact">Телефон или Telegram</label><input id="o-contact" maxlength="120" required>
    <label for="o-msg">Что нужно сделать</label><textarea id="o-msg" maxlength="1000"></textarea>
    <input class="hp" id="o-web" tabindex="-1" autocomplete="off" aria-hidden="true">
    <button class="cta" type="submit">Отправить</button>
    <div class="mmsg" id="omsg"></div>
  </form>
</div>

<noscript><style>html,body{overflow:auto}</style></noscript>
<script>
(function(){
  var DEF={tag:'Daler & Mirzo AI Masters',title:'DALER',subtitle:'',button:'Открыть карту мира',orderButton:'Заказать ролик',instagram:'https://www.instagram.com/mirzouzs',telegram:'https://t.me/uz_73',phone:'',email:'',
    marquee:['AI-видео','AI-агенты','Карта мира','Камеры онлайн','Самолёты','Спутники','Контент','Боты'],
    cards:[['Кино-ролик','AI-видео','#ff4d4d','#3a0a0a'],['Реклама для бизнеса','Reels / Shorts','#d63a3a','#1c0606'],['Трансформации','Higgsfield','#ff6a4d','#2b0c08'],['AI-агент для продаж','Автоматизация','#b82e3a','#16060a'],['Фильм за день','Seedance','#ff4d6a','#2a0710'],['Телеграм-бот','Боты','#e0453a','#190807'],['Контент для бренда','Продакшн','#ff5a4d','#240a08'],['Музыкальный клип','AI-видео','#c8323a','#1a0608'],['Карта мира','Камеры в реальном времени','#ff3d3d','#2a0505'],['Персонаж-бренд','3D / AI','#ff7a5a','#2a100a'],['Instagram под ключ','Контент-план','#d9404a','#1b070a'],['Свой проект','Напишите нам','#ff4d4d','#120505']].map(function(c){return {title:c[0],tag:c[1],c1:c[2],c2:c[3],media:''}})};
  var $=function(i){return document.getElementById(i)};
  function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
  var helix=$('helix'),els=[],N=0,STEP=30,DY=46;
  function css(n){return parseFloat(getComputedStyle(document.documentElement).getPropertyValue(n))||0}
  var R=css('--R');

  function build(cards){
    helix.innerHTML='';els=[];N=cards.length;STEP=360/N;
    cards.forEach(function(c,i){
      var d=document.createElement('div');d.className='card';
      d.style.setProperty('--c1',c.c1);d.style.setProperty('--c2',c.c2);
      var media='';
      if(c.media){media=/\.(mp4|webm)(\?|$)/i.test(c.media)?'<video class="media" src="'+esc(c.media)+'" muted loop playsinline autoplay></video>':'<img class="media" alt="" src="'+esc(c.media)+'">'}
      d.innerHTML=media+'<div class="n">['+String(i+1).padStart(2,'0')+']</div><div class="ico"></div><div><h3>'+esc(c.title)+'</h3><p>'+esc(c.tag)+'</p></div>';
      helix.appendChild(d);els.push(d);
    });
  }
  function apply(c){
    c=c||DEF;
    $('t-tag').textContent='[ '+(c.tag||'')+' ]';
    $('t-title').textContent=c.title||'DALER';$('t-logo').textContent=c.title||'DALER';
    if(c.subtitle)$('t-sub').textContent=c.subtitle;
    $('t-btn').textContent=c.button||'Открыть карту мира';
    $('order').textContent=c.orderButton||'Заказать ролик';
    if(c.instagram)$('l-ig').href=c.instagram;if(c.telegram)$('l-tg').href=c.telegram;
    var ct='';
    if(c.phone)ct+='<a href="tel:'+esc(c.phone.replace(/[^\d+]/g,''))+'">'+esc(c.phone)+'</a>';
    if(c.email)ct+='<a href="mailto:'+esc(c.email)+'">'+esc(c.email)+'</a>';
    $('contacts').innerHTML=ct;
    var words=(c.marquee&&c.marquee.length?c.marquee:DEF.marquee),h='';
    for(var k=0;k<2;k++)words.forEach(function(w){h+='<span>'+esc(w)+'</span><em>✦</em>'});
    $('mq').innerHTML=h+h;
    build(c.cards&&c.cards.length>=3?c.cards:DEF.cards);
  }
  apply(DEF);
  fetch('/dapi/content',{cache:'no-cache'}).then(function(r){return r.ok?r.json():null}).then(function(c){if(c)apply(c)}).catch(function(){});

  var target=0,cur=0,vel=0,drag=false,lastX=0,auto=0.04,modalOpen=false;
  function tick(){
    if(!drag&&!modalOpen){target+=auto+vel;vel*=0.92;}
    cur+=(target-cur)*0.09;
    helix.style.transform='rotateX(-9deg)';
    for(var i=0;i<N;i++){
      var a=((i*STEP-cur)%360+540)%360-180;
      var o=Math.cos(a*Math.PI/180);o=o>0?Math.pow(o,1.4):0;
      els[i].style.opacity=o.toFixed(3);
      els[i].style.transform='rotateY('+a.toFixed(2)+'deg) translateZ('+R+'px) translateY('+(-a/STEP*DY).toFixed(1)+'px)';
    }
    requestAnimationFrame(tick);
  }
  tick();
  var UI='.cta,nav a,.logo,.contacts a,.modal';
  window.addEventListener('wheel',function(e){if(modalOpen)return;e.preventDefault();var d=(e.deltaY+e.deltaX)*0.12;target+=d;vel=d*0.02;},{passive:false});
  function down(x){drag=true;lastX=x;document.body.classList.add('drag')}
  function move(x){if(!drag)return;var dx=x-lastX;lastX=x;var d=-dx*0.35;target+=d;vel=d*0.05}
  function up(){drag=false;document.body.classList.remove('drag')}
  window.addEventListener('mousedown',function(e){if(e.target.closest(UI))return;down(e.clientX)});
  window.addEventListener('mousemove',function(e){move(e.clientX)});
  window.addEventListener('mouseup',up);
  window.addEventListener('touchstart',function(e){if(e.target.closest(UI))return;down(e.touches[0].clientX)},{passive:true});
  window.addEventListener('touchmove',function(e){move(e.touches[0].clientX)},{passive:true});
  window.addEventListener('touchend',up);
  window.addEventListener('keydown',function(e){
    if(e.key==='Escape')closeM();
    if(modalOpen)return;
    if(e.key==='ArrowRight'||e.key==='ArrowDown')target+=STEP;if(e.key==='ArrowLeft'||e.key==='ArrowUp')target-=STEP});
  window.addEventListener('resize',function(){R=css('--R')});

  $('go').addEventListener('click',function(){
    try{document.cookie='daler_map=1; path=/; SameSite=Lax'}catch(e){}
    location.href='/';
  });

  /* order modal */
  function openM(){modalOpen=true;$('modal').classList.add('on');$('omsg').textContent='';setTimeout(function(){$('o-name').focus()},50)}
  function closeM(){modalOpen=false;$('modal').classList.remove('on')}
  $('order').addEventListener('click',openM);
  $('mx').addEventListener('click',closeM);
  $('modal').addEventListener('mousedown',function(e){if(e.target===$('modal'))closeM()});
  $('oform').addEventListener('submit',function(e){
    e.preventDefault();var m=$('omsg');m.style.color='';m.textContent='Отправляю…';
    fetch('/dapi/lead',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({name:$('o-name').value,contact:$('o-contact').value,message:$('o-msg').value,website:$('o-web').value})})
      .then(function(r){return r.json().then(function(j){if(!r.ok)throw new Error(j.error||'Ошибка');return j})})
      .then(function(){m.style.color='#3ddc84';m.textContent='Спасибо! Заявка отправлена, мы скоро свяжемся.';$('oform').reset();setTimeout(closeM,2500)})
      .catch(function(err){m.style.color='#ff7070';m.textContent=err.message||'Не удалось отправить, попробуйте позже'});
  });
})();
</script>
</body>
</html>

LANDING_EOF

echo "== 2. Пароль и настройки =="
NEWPASS=""
if [ ! -f /opt/daler-admin/.env ]; then
  NEWPASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)
  cat > /opt/daler-admin/.env <<EOF
ADMIN_PASSWORD=$NEWPASS
TG_BOT_TOKEN=
TG_CHAT_ID=
EOF
  chmod 600 /opt/daler-admin/.env
fi

echo "== 3. Запуск админки =="
docker rm -f daler-admin >/dev/null 2>&1 || true
docker run -d --name daler-admin --restart unless-stopped \
  -p 127.0.0.1:3100:3100 \
  --env-file /opt/daler-admin/.env \
  -e DATA_DIR=/data -e HOST=0.0.0.0 \
  -v /opt/daler-admin/app:/app:ro \
  -v /opt/daler-admin/data:/data \
  node:22-alpine node /app/server.js

echo "== 4. Nginx =="
if [ -d /etc/letsencrypt/live/002.uz ]; then
  REDIR='if ($scheme = http) { return 301 https://$host$request_uri; }'
else
  REDIR='# HTTPS ещё не включён: выполните certbot, затем снова bash deploy-admin.sh'
  echo "ВНИМАНИЕ: HTTPS ещё нет. Пароль админки передаётся без шифрования. Сначала выполните: certbot --nginx -d 002.uz -d www.002.uz"
fi
cat > /etc/nginx/snippets/daler-admin.conf <<EOF
location ^~ /admin {
    $REDIR
    client_max_body_size 1m;
    proxy_pass http://127.0.0.1:3100;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
location ^~ /dapi/ {
    $REDIR
    client_max_body_size 1m;
    proxy_pass http://127.0.0.1:3100;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
}
EOF
python3 - <<'PYEOF'
import re
f='/etc/nginx/sites-available/osiris'
s=open(f).read()
inc='    include /etc/nginx/snippets/daler-admin.conf;'
if 'daler-admin' not in s:
    s=re.sub(r'(server_name 002\.uz www\.002\.uz;)', r'\1\n'+inc, s)
    open(f,'w').write(s)
PYEOF
nginx -t && systemctl reload nginx

echo
echo "================ ГОТОВО ================"
echo "Админка: https://002.uz/admin"
if [ -n "$NEWPASS" ]; then
  echo "Пароль:  $NEWPASS     (сохраните его; сменить можно в админке, вкладка «Настройки»)"
else
  echo "Пароль:  прежний (хранится в /opt/daler-admin/.env; если меняли в админке, то он там)"
fi
echo "Заявки в Telegram: впишите TG_BOT_TOKEN и TG_CHAT_ID в /opt/daler-admin/.env, затем: docker restart daler-admin"
