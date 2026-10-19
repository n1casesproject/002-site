#!/bin/bash
# Сайт MD (002.uz): чёрно-белая страница + админка 002.uz/admin. Карта OSIRIS удаляется.
# Запускать на сервере под root:  bash deploy-md.sh
set -e

echo "== 1. Docker и Nginx =="
command -v docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
command -v nginx >/dev/null 2>&1 || { apt-get update -y && apt-get install -y nginx; }

echo "== 2. Удаляю карту OSIRIS и старые файлы =="
docker rm -f osiris daler daler-admin md-admin >/dev/null 2>&1 || true
docker rmi -f daler:latest ghcr.io/simplifaisoul/osiris:latest >/dev/null 2>&1 || true
docker image prune -f >/dev/null 2>&1 || true
rm -rf /opt/daler-src /var/www/daler-landing
rm -f /etc/nginx/snippets/daler-*.conf /etc/nginx/sites-enabled/osiris /etc/nginx/sites-available/osiris /etc/nginx/sites-enabled/default
rm -f "$HOME/deploy-osiris.sh" "$HOME/deploy-daler.sh" "$HOME/deploy-admin.sh"

echo "== 3. Файлы сайта =="
mkdir -p /var/www/md-site /opt/md-admin/app /opt/md-admin/data/uploads
chmod 755 /opt/md-admin /opt/md-admin/data /opt/md-admin/data/uploads
cat > /var/www/md-site/index.html <<'LANDING_EOF'
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>MD — AI-видео и AI-агенты</title>
<meta name="description" content="MD AI Masters: AI-видео, которые невозможно снять камерой, и AI-агенты для вашего бизнеса.">
<meta name="theme-color" id="mtheme" content="#000000">
<meta property="og:title" content="MD — AI-видео и AI-агенты">
<meta property="og:description" content="MD AI Masters: AI-видео и AI-агенты для вашего бизнеса.">
<meta property="og:type" content="website">
<meta property="og:url" content="https://002.uz">
<meta property="og:image" content="https://002.uz/og-image.png">
<meta property="og:locale" content="ru_RU">
<meta name="twitter:card" content="summary_large_image">
<link rel="icon" href="/favicon-32x32.png" type="image/png" sizes="32x32">
<link rel="icon" href="/favicon-16x16.png" type="image/png" sizes="16x16">
<link rel="icon" href="/favicon.ico" sizes="48x48">
<link rel="icon" href="/android-chrome-192x192.png" type="image/png" sizes="192x192">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Unbounded:wght@500;700;900&family=Space+Mono:wght@400;700&family=Inter:wght@400;500&display=swap" rel="stylesheet">
<script>try{var _t=localStorage.getItem('md_theme');if(_t==='light')document.documentElement.setAttribute('data-theme','light');var _l=localStorage.getItem('md_lang');if(_l==='uz'||_l==='en')document.documentElement.lang=_l}catch(e){}</script>
<style>
:root{
  --bg:#000; --bg2:#0c0c0c; --red:#ffffff; --red2:#d0d0d0; --text:#f5f5f5; --mute:#8c8c8c;
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
.glow{position:fixed;inset:0;background:radial-gradient(60% 50% at 70% 45%,rgba(255,255,255,.09),transparent 70%),radial-gradient(40% 40% at 10% 100%,rgba(255,255,255,.05),transparent 70%);pointer-events:none}
header{position:fixed;top:0;left:0;right:0;display:flex;justify-content:space-between;align-items:center;padding:22px clamp(16px,4vw,48px);z-index:20}
.logo{font-family:var(--font-d);font-weight:900;font-size:18px;letter-spacing:.04em;color:var(--text);text-decoration:none;display:flex;align-items:center;gap:10px}
.logoimg{height:40px;width:auto;border-radius:9px;display:block}
.sr{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
.logo i{width:12px;height:12px;border-radius:50%;background:var(--red);box-shadow:0 0 18px var(--red);animation:pulse 2s infinite}
@keyframes pulse{50%{opacity:.35}}
nav{display:flex;gap:10px}
nav a{font-family:var(--font-m);font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--text);text-decoration:none;padding:9px 16px;border:1px solid rgba(255,255,255,.18);border-radius:999px;transition:.25s}
nav a:hover{border-color:var(--red);color:var(--red)}
/* hero text */
.hero{position:fixed;left:clamp(16px,4vw,48px);bottom:clamp(90px,14vh,150px);z-index:10;max-width:min(560px,88vw);pointer-events:none}
.tag{font-family:var(--font-m);font-size:12px;letter-spacing:.14em;color:var(--red);text-transform:uppercase;margin-bottom:16px}
h1{text-shadow:0 2px 30px rgba(0,0,0,.8);font-family:var(--font-d);font-weight:900;line-height:.92;font-size:clamp(54px,11vw,150px);letter-spacing:-.02em}
h1 span{color:var(--red)}
.sub{margin-top:20px;font-size:clamp(14px,1.5vw,18px);line-height:1.5;color:#d4d4d4;max-width:460px}
.cta{pointer-events:auto;margin-top:28px;display:inline-flex;align-items:center;gap:12px;font-family:var(--font-d);font-weight:700;font-size:14px;letter-spacing:.04em;color:#000;background:var(--red);border:0;border-radius:999px;padding:18px 28px;cursor:pointer;transition:.25s;box-shadow:0 0 40px rgba(255,255,255,.35)}
.cta:hover{transform:translateY(-2px);background:var(--red2);box-shadow:0 0 60px rgba(255,255,255,.55)}
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
.card .n,.card h3,.card p{text-shadow:0 1px 8px rgba(0,0,0,.55)}
.card .n{font-family:var(--font-m);font-size:12px;letter-spacing:.14em;color:rgba(255,255,255,.75)}
.card .ico{position:absolute;right:16px;top:14px;width:38px;height:38px;border-radius:50%;border:1px solid rgba(255,255,255,.4);display:grid;place-items:center}
.card .ico::after{content:"";border-left:11px solid #fff;border-top:7px solid transparent;border-bottom:7px solid transparent;margin-left:3px}
.card h3{font-family:var(--font-d);font-weight:700;font-size:19px;line-height:1.15;position:relative}
.card p{font-family:var(--font-m);font-size:11px;letter-spacing:.06em;color:rgba(255,255,255,.7);margin-top:8px;text-transform:uppercase;position:relative}
/* marquee */
.marq{position:fixed;left:0;right:0;bottom:0;z-index:15;border-top:1px solid rgba(255,255,255,.1);background:rgba(0,0,0,.7);backdrop-filter:blur(6px);overflow:hidden;padding:14px 0;pointer-events:none}
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
.card{cursor:pointer}
.card .media{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:1;pointer-events:none}
.card.hasm::after{content:"";position:absolute;inset:0;background:linear-gradient(to top,rgba(0,0,0,.78),rgba(0,0,0,0) 55%);pointer-events:none}
.card.hasm::before{display:none}
.card .play{position:absolute;right:16px;top:14px;width:38px;height:38px;border-radius:50%;background:rgba(0,0,0,.45);border:1px solid rgba(255,255,255,.5);display:grid;place-items:center;z-index:2}
.card .play::before{content:"";border-left:11px solid #fff;border-top:7px solid transparent;border-bottom:7px solid transparent;margin-left:3px}
.card.hasm>div:last-child,.card.hasm .n{z-index:2}
.dbox{width:min(980px,100%);max-height:100%;overflow:auto;background:#0c0c0c;border:1px solid rgba(255,255,255,.14);border-radius:20px;display:grid;grid-template-columns:minmax(0,1.7fr) minmax(240px,1fr);position:relative}
.dmedia{background:#000;display:grid;place-items:center;min-height:240px;border-radius:20px 0 0 20px;overflow:hidden}
.dmedia video,.dmedia img{width:100%;max-height:78vh;display:block;object-fit:contain;background:#000}
.dside{padding:32px 28px;display:flex;flex-direction:column;justify-content:center;gap:12px}
.dside .dn{font-family:var(--font-m);font-size:12px;letter-spacing:.14em;color:var(--mute)}
.dside h2{font-family:var(--font-d);font-weight:900;font-size:26px;line-height:1.1;overflow-wrap:anywhere}
.dside p{color:var(--mute);font-size:14px}
.dside .cta{margin-top:10px;justify-content:center;width:100%}
.dbox .x{position:absolute;right:12px;top:8px;z-index:3;background:rgba(0,0,0,.5);border:0;color:#fff;font-size:26px;width:38px;height:38px;border-radius:50%;cursor:pointer;line-height:1}
@media (max-width:760px){.dbox{grid-template-columns:1fr;max-height:92vh}.dmedia{border-radius:20px 20px 0 0}.dside{padding:20px}}
.card .n,.card .ico,.card>div{position:relative}
.modal{position:fixed;inset:0;z-index:100;display:none;place-items:center;background:rgba(0,0,0,.82);backdrop-filter:blur(6px);padding:18px;touch-action:auto;cursor:auto}
.modal.on{display:grid}
.mbox{width:min(440px,100%);background:#0c0c0c;border:1px solid rgba(255,255,255,.14);border-radius:20px;padding:28px;position:relative}
.mbox h2{font-family:var(--font-d);font-weight:900;font-size:22px;margin-bottom:6px}
.mbox p{color:var(--mute);font-size:13px;margin-bottom:18px}
.mbox label{display:block;font-family:var(--font-m);font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:var(--mute);margin:12px 0 6px}
.mbox input,.mbox textarea{width:100%;font:inherit;font-size:15px;color:var(--text);background:#000;border:1px solid rgba(255,255,255,.14);border-radius:10px;padding:12px;outline:none}
.mbox input:focus,.mbox textarea:focus{border-color:var(--red)}
.mbox textarea{min-height:90px;resize:vertical}
.mbox .x{position:absolute;right:14px;top:12px;background:none;border:0;color:var(--mute);font-size:26px;cursor:pointer}
.mbox .cta{width:100%;justify-content:center;margin-top:18px}
.mbox .hp{position:absolute;left:-9999px;opacity:0}
.mmsg{margin-top:12px;font-size:13px;min-height:18px;color:var(--mute)}
@media (max-width:760px){.btns{margin-top:22px}.cta{padding:15px 20px;font-size:13px}}
@media (prefers-reduced-motion:reduce){.marq div{animation:none}}

/* controls */
.hr{display:flex;align-items:center;gap:10px}
.ctl{position:relative}
.cb{font-family:var(--font-m);font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--text);background:transparent;border:1px solid rgba(255,255,255,.18);border-radius:999px;padding:9px 14px;cursor:pointer;display:inline-flex;align-items:center;gap:8px;transition:.25s;line-height:1}
.cb:hover{border-color:var(--red);color:var(--red)}
.cb i{font-style:normal;font-size:10px}
.tb{width:38px;height:38px;padding:0;justify-content:center}
.tb .i-sun{display:none}
html[data-theme=light] .tb .i-sun{display:block}
html[data-theme=light] .tb .i-moon{display:none}
.lm{position:absolute;right:0;top:calc(100% + 8px);min-width:150px;background:#0c0c0c;border:1px solid rgba(255,255,255,.16);border-radius:14px;padding:6px;display:none;box-shadow:0 20px 50px rgba(0,0,0,.6)}
.lang.open .lm{display:block}
.lm button{display:block;width:100%;text-align:left;font-family:var(--font-b);font-size:14px;color:var(--text);background:none;border:0;border-radius:9px;padding:10px 12px;cursor:pointer}
.lm button:hover{background:rgba(255,255,255,.08)}
.lm button.on{color:var(--red);font-weight:500}
.lm button.on::after{content:" ✓"}
/* light theme: белый → небесно-голубой, акцент из логотипа */
html[data-theme=light]{--bg:#f2f9ff;--bg2:#fff;--red:#0a84d6;--red2:#0670b5;--text:#0b1b2b;--mute:#52697f}
html[data-theme=light],html[data-theme=light] body{background:linear-gradient(160deg,#ffffff 0%,#e8f4ff 48%,#c3e0f8 100%) fixed}
html[data-theme=light] body::after{opacity:.025}
html[data-theme=light] .glow{background:radial-gradient(60% 50% at 70% 45%,rgba(10,132,214,.16),transparent 70%),radial-gradient(40% 40% at 10% 100%,rgba(10,132,214,.1),transparent 70%)}
html[data-theme=light] nav a,html[data-theme=light] .cb{border-color:rgba(11,27,43,.2);background:rgba(255,255,255,.55)}
html[data-theme=light] nav a:hover,html[data-theme=light] .cb:hover{border-color:var(--red);color:var(--red)}
html[data-theme=light] .lm{background:#fff;border-color:rgba(11,27,43,.14);box-shadow:0 20px 50px rgba(10,100,170,.22)}
html[data-theme=light] .lm button:hover{background:#eaf4fd}
html[data-theme=light] h1{text-shadow:none}
html[data-theme=light] .sub{color:#33485e}
html[data-theme=light] .cta{color:#fff;box-shadow:0 10px 34px rgba(10,132,214,.38)}
html[data-theme=light] .cta:hover{box-shadow:0 14px 44px rgba(10,132,214,.5)}
html[data-theme=light] .cta.alt{background:rgba(255,255,255,.6);color:var(--text);border:1px solid rgba(11,27,43,.25);box-shadow:none}
html[data-theme=light] .cta.alt:hover{border-color:var(--red);color:var(--red);background:#fff}
html[data-theme=light] .contacts a{color:var(--text)}
html[data-theme=light] .card:not(.hasm){background:linear-gradient(160deg,#ffffff,#cde4f7);border-color:rgba(10,132,214,.28);box-shadow:0 20px 50px rgba(10,100,170,.25)}
html[data-theme=light] .card.hasm{box-shadow:0 20px 50px rgba(10,100,170,.3);border-color:rgba(255,255,255,.7)}
html[data-theme=light] .card:not(.hasm)::before{display:none}
html[data-theme=light] .card:not(.hasm) .n,html[data-theme=light] .card:not(.hasm) p{color:#4a6580}
html[data-theme=light] .card:not(.hasm) h3{color:#0b1b2b}
html[data-theme=light] .card:not(.hasm) .n,html[data-theme=light] .card:not(.hasm) h3,html[data-theme=light] .card:not(.hasm) p{text-shadow:none}
html[data-theme=light] .card:not(.hasm) .ico{border-color:rgba(10,132,214,.5)}
html[data-theme=light] .card:not(.hasm) .ico::after{border-left-color:var(--red)}
html[data-theme=light] .marq{background:rgba(255,255,255,.72);border-top-color:rgba(10,132,214,.18)}
html[data-theme=light] .modal{background:rgba(214,234,251,.78)}
html[data-theme=light] .mbox,html[data-theme=light] .dbox{background:#fff;border-color:rgba(10,132,214,.22);box-shadow:0 30px 80px rgba(10,100,170,.28)}
html[data-theme=light] .mbox input,html[data-theme=light] .mbox textarea{background:#f2f9ff;border-color:rgba(11,27,43,.16);color:var(--text)}
html[data-theme=light] .mbox .x{color:var(--mute)}
@media (max-width:760px){.hr{gap:6px}.cb{padding:8px 10px;font-size:10px}.tb{width:34px;height:34px}.logoimg{height:32px}header{padding:16px 12px}nav{gap:6px}}
</style>
</head>
<body>
<div class="glow"></div>
<header>
  <a class="logo" href="/"><img class="logoimg" src="/logo.png" alt="MD"><span class="sr" id="t-logo">MD</span></a>
  <div class="hr">
  <nav>
    <a id="l-ig" href="https://www.instagram.com/mirzouzs" target="_blank" rel="noopener">Instagram</a>
    <a id="l-tg" href="https://t.me/uz_73" target="_blank" rel="noopener">Telegram</a>
  </nav>
  <div class="ctl lang" id="lang">
    <button class="cb" id="lang-b" type="button" aria-haspopup="true" aria-expanded="false"><span id="lang-t">Язык</span><i>▾</i></button>
    <div class="lm" id="lang-m" role="menu">
      <button type="button" data-l="ru" role="menuitem">Русский</button>
      <button type="button" data-l="uz" role="menuitem">O‘zbekcha</button>
      <button type="button" data-l="en" role="menuitem">English</button>
    </div>
  </div>
  <button class="ctl cb tb" id="theme-b" type="button" aria-label="Тема">
    <svg class="i-moon" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>
    <svg class="i-sun" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
  </button>
  </div>
</header>

<div class="stage"><div class="helix" id="helix"></div></div>

<section class="hero">
  <div class="tag" id="t-tag">[ MD AI Masters ]</div>
  <h1><span id="t-title" style="color:inherit">MD</span><span>.</span></h1>
  <p class="sub" id="t-sub">AI-видео, которые невозможно снять камерой, и AI-агенты для вашего бизнеса.</p>
  <div class="btns">
    <button class="cta" id="order" type="button"><span id="t-order">Заказать ролик</span> <b>→</b></button>
    <a class="cta alt" id="tg-btn" href="https://t.me/uz_73" target="_blank" rel="noopener" style="text-decoration:none">Написать в Telegram</a>
  </div>
  <div class="contacts" id="contacts"></div>
</section>
<div class="hint" id="t-hint">Крутите колесо или тяните</div>

<div class="marq"><div id="mq"></div></div>

<div class="modal" id="modal" role="dialog" aria-modal="true">
  <form class="mbox" id="oform" autocomplete="off">
    <button class="x" type="button" id="mx" aria-label="Закрыть">×</button>
    <h2 id="m-h">Заказать ролик</h2>
    <p id="m-p">Оставьте контакт, мы свяжемся и всё обсудим.</p>
    <label for="o-name" id="m-ln">Имя</label><input id="o-name" maxlength="80" required>
    <label for="o-contact" id="m-lc">Телефон или Telegram</label><input id="o-contact" maxlength="120" required>
    <label for="o-msg" id="m-lm">Что нужно сделать</label><textarea id="o-msg" maxlength="1000"></textarea>
    <input class="hp" id="o-web" tabindex="-1" autocomplete="off" aria-hidden="true">
    <button class="cta" type="submit" id="m-s">Отправить</button>
    <div class="mmsg" id="omsg"></div>
  </form>
</div>

<div class="modal" id="dmodal" role="dialog" aria-modal="true">
  <div class="dbox">
    <button class="x" type="button" id="dx" aria-label="Закрыть">×</button>
    <div class="dmedia" id="dmedia"></div>
    <div class="dside">
      <div class="dn" id="dn"></div>
      <h2 id="dt"></h2>
      <p id="dg"></p>
      <button class="cta" type="button" id="dorder">Заказать</button>
    </div>
  </div>
</div>

<noscript><style>html,body{overflow:auto}</style></noscript>
<script>
(function(){
  var DEF={tag:'MD AI Masters',title:'MD',subtitle:'AI-видео, которые невозможно снять камерой, и AI-агенты для вашего бизнеса.',button:'Написать в Telegram',orderButton:'Заказать ролик',instagram:'https://www.instagram.com/mirzouzs',telegram:'https://t.me/uz_73',phone:'',email:'',
    marquee:['AI-видео','AI-агенты','Реклама','Контент','Боты','Автоматизация'],
    cards:[['Кино-ролик','AI-видео','#9a9a9a','#0d0d0d'],['Реклама для бизнеса','Reels / Shorts','#7d7d7d','#101010'],['Трансформации','Higgsfield','#b0b0b0','#0b0b0b'],['AI-агент для продаж','Автоматизация','#6a6a6a','#111111'],['Фильм за день','Seedance','#a5a5a5','#0e0e0e'],['Телеграм-бот','Боты','#858585','#0c0c0c'],['Контент для бренда','Продакшн','#bababa','#101010'],['Музыкальный клип','AI-видео','#737373','#0a0a0a'],['Персонаж-бренд','3D / AI','#a0a0a0','#111111'],['Instagram под ключ','Контент-план','#8a8a8a','#0d0d0d'],['Свой проект','Напишите нам','#b5b5b5','#0b0b0b']].map(function(c){return {title:c[0],tag:c[1],c1:c[2],c2:c[3],media:''}})};
  var $=function(i){return document.getElementById(i)};
  function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}

  /* ---- языки и тема ---- */
  var LANG='ru';try{var sl=localStorage.getItem('md_lang');if(sl==='uz'||sl==='en')LANG=sl}catch(e){}
  var UI_T={
    ru:{lang:'Язык',hint:'Крутите колесо или тяните',mh:'Заказать ролик',mp:'Оставьте контакт, мы свяжемся и всё обсудим.',ln:'Имя',lc:'Телефон или Telegram',lm:'Что нужно сделать',ms:'Отправить',dorder:'Заказать',theme:'Тема: ночь / день',close:'Закрыть',sending:'Отправляю…',ok:'Спасибо! Заявка отправлена, мы скоро свяжемся.',fail:'Не удалось отправить, попробуйте позже',want:'Хочу заказать: ',title:'MD — AI-видео и AI-агенты',desc:'MD AI Masters: AI-видео, которые невозможно снять камерой, и AI-агенты для вашего бизнеса.'},
    uz:{lang:'Til',hint:'G‘ildirakni aylantiring yoki torting',mh:'Video buyurtma qilish',mp:'Aloqa ma’lumotingizni qoldiring, biz bog‘lanib, hammasini muhokama qilamiz.',ln:'Ism',lc:'Telefon yoki Telegram',lm:'Nima qilish kerak',ms:'Yuborish',dorder:'Buyurtma berish',theme:'Mavzu: tun / kun',close:'Yopish',sending:'Yuborilmoqda…',ok:'Rahmat! Ariza yuborildi, tez orada bog‘lanamiz.',fail:'Yuborib bo‘lmadi, keyinroq urinib ko‘ring',want:'Buyurtma bermoqchiman: ',title:'MD — AI-video va AI-agentlar',desc:'MD AI Masters: kamerada suratga olib bo‘lmaydigan AI-videolar va biznesingiz uchun AI-agentlar.'},
    en:{lang:'Language',hint:'Spin the wheel or drag',mh:'Order a video',mp:'Leave your contact and we will get back to you to discuss everything.',ln:'Name',lc:'Phone or Telegram',lm:'What do you need',ms:'Send',dorder:'Order',theme:'Theme: night / day',close:'Close',sending:'Sending…',ok:'Thank you! Your request was sent, we will contact you soon.',fail:'Could not send, please try again later',want:'I would like to order: ',title:'MD — AI video and AI agents',desc:'MD AI Masters: AI videos you cannot shoot with a camera, and AI agents for your business.'}
  };
  var TR_ROWS=[
    ['AI-видео, которые невозможно снять камерой, и AI-агенты для вашего бизнеса.','Kamerada suratga olib bo‘lmaydigan AI-videolar va biznesingiz uchun AI-agentlar.','AI videos you cannot shoot with a camera, and AI agents for your business.'],
    ['Написать в Telegram','Telegramga yozish','Message on Telegram'],
    ['Заказать ролик','Video buyurtma qilish','Order a video'],
    ['AI-видео','AI-video','AI video'],['AI-агенты','AI-agentlar','AI agents'],['Реклама','Reklama','Ads'],['Контент','Kontent','Content'],['Боты','Botlar','Bots'],['Автоматизация','Avtomatlashtirish','Automation'],
    ['Кино-ролик','Kino-rolik','Cinematic video'],['Реклама для бизнеса','Biznes uchun reklama','Business ads'],['Трансформации','Transformatsiyalar','Transformations'],['AI-агент для продаж','Sotuvlar uchun AI-agent','AI sales agent'],['Фильм за день','Bir kunda film','A film in a day'],['Телеграм-бот','Telegram-bot','Telegram bot'],['Контент для бренда','Brend uchun kontent','Brand content'],['Музыкальный клип','Musiqiy klip','Music video'],['Персонаж-бренд','Brend-qahramon','Brand character'],['Instagram под ключ','Instagram to‘liq tayyor holda','Instagram turnkey'],['Свой проект','O‘z loyihangiz','Your project'],
    ['Продакшн','Produksiya','Production'],['Контент-план','Kontent-reja','Content plan'],['Напишите нам','Bizga yozing','Write to us']
  ];
  var TRM={};TR_ROWS.forEach(function(r){TRM[r[0]]={uz:r[1],en:r[2]}});
  function tr(x){x=x==null?'':String(x);return LANG==='ru'?x:(TRM[x]?TRM[x][LANG]:x)}
  var lastC=null;
  function setT(id,k){var e=$(id);if(e)e.textContent=UI_T[LANG][k]}
  function applyLang(){
    var T=UI_T[LANG];document.documentElement.lang=LANG;
    setT('lang-t','lang');setT('t-hint','hint');setT('m-h','mh');setT('m-p','mp');setT('m-ln','ln');setT('m-lc','lc');setT('m-lm','lm');setT('m-s','ms');setT('dorder','dorder');
    $('theme-b').setAttribute('aria-label',T.theme);$('theme-b').title=T.theme;$('mx').setAttribute('aria-label',T.close);$('dx').setAttribute('aria-label',T.close);
    document.title=T.title;var md=document.querySelector('meta[name=description]');if(md)md.setAttribute('content',T.desc);
    document.querySelectorAll('#lang-m button').forEach(function(b){b.classList.toggle('on',b.dataset.l===LANG)});
    apply(lastC);
  }
  function applyTheme(t){
    if(t==='light')document.documentElement.setAttribute('data-theme','light');else document.documentElement.removeAttribute('data-theme');
    var m=$('mtheme');if(m)m.setAttribute('content',t==='light'?'#eaf4ff':'#000000');
  }
  var THEME=document.documentElement.getAttribute('data-theme')==='light'?'light':'dark';
  var helix=$('helix'),els=[],N=0,STEP=30,DY=46;
  function css(n){return parseFloat(getComputedStyle(document.documentElement).getPropertyValue(n))||0}
  var R=css('--R');

  function build(cards){
    helix.innerHTML='';els=[];N=cards.length;STEP=360/N;
    cards.forEach(function(c,i){
      var d=document.createElement('div');d.className='card';
      d.style.setProperty('--c1',c.c1);d.style.setProperty('--c2',c.c2);
      var media='';
      if(c.media){media=/\.(mp4|mov|m4v|webm)(\?|$)/i.test(c.media)?'<video class="media" src="'+esc(c.media)+'" muted loop playsinline autoplay></video>':'<img class="media" alt="" src="'+esc(c.media)+'">'}
      if(c.media)d.classList.add('hasm');
      d.innerHTML=media+'<div class="n">['+String(i+1).padStart(2,'0')+']</div>'+(c.media?'<div class="play"></div>':'<div class="ico"></div>')+'<div><h3>'+esc(tr(c.title))+'</h3><p>'+esc(tr(c.tag))+'</p></div>';
      d.addEventListener('click',function(){if(moved>6)return;openD(c,i)});
      helix.appendChild(d);els.push(d);
    });
  }
  function apply(c){
    c=c||DEF;lastC=c;
    $('t-tag').textContent='[ '+(c.tag||'')+' ]';
    $('t-title').textContent=c.title||'MD';$('t-logo').textContent=c.title||'MD';
    if(c.subtitle)$('t-sub').textContent=tr(c.subtitle);
    $('t-order').textContent=tr(c.orderButton||'Заказать ролик');
    $('tg-btn').textContent=tr(c.button||'Написать в Telegram');
    if(c.instagram)$('l-ig').href=c.instagram;if(c.telegram){$('l-tg').href=c.telegram;$('tg-btn').href=c.telegram}
    var ct='';
    if(c.phone)ct+='<a href="tel:'+esc(c.phone.replace(/[^\d+]/g,''))+'">'+esc(c.phone)+'</a>';
    if(c.email)ct+='<a href="mailto:'+esc(c.email)+'">'+esc(c.email)+'</a>';
    $('contacts').innerHTML=ct;
    var words=(c.marquee&&c.marquee.length?c.marquee:DEF.marquee),h='';
    for(var k=0;k<2;k++)words.forEach(function(w){h+='<span>'+esc(tr(w))+'</span><em>✦</em>'});
    $('mq').innerHTML=h+h;
    build(c.cards&&c.cards.length>=3?c.cards:DEF.cards);
  }
  apply(DEF);applyLang();
  fetch('/dapi/content',{cache:'no-cache'}).then(function(r){return r.ok?r.json():null}).then(function(c){if(c)apply(c)}).catch(function(){});

  var target=0,cur=0,vel=0,drag=false,lastX=0,auto=0.04,modalOpen=false,moved=0;
  function tick(){
    if(!drag&&!modalOpen){target+=auto+vel;vel*=0.92;}
    cur+=(target-cur)*0.09;
    helix.style.transform='rotateX(-9deg)';
    for(var i=0;i<N;i++){
      var a=((i*STEP-cur)%360+540)%360-180;
      var o=Math.cos(a*Math.PI/180);o=o>0?Math.pow(o,1.4):0;
      els[i].style.opacity=o.toFixed(3);els[i].style.pointerEvents=o>0.5?'auto':'none';
      els[i].style.transform='rotateY('+a.toFixed(2)+'deg) translateZ('+R+'px) translateY('+(-a/STEP*DY).toFixed(1)+'px)';
    }
    requestAnimationFrame(tick);
  }
  tick();
  var UI='.cta,nav a,.logo,.contacts a,.modal,a.cta,.ctl';
  window.addEventListener('wheel',function(e){if(modalOpen)return;e.preventDefault();var d=(e.deltaY+e.deltaX)*0.12;target+=d;vel=d*0.02;},{passive:false});
  function down(x){drag=true;lastX=x;moved=0;document.body.classList.add('drag')}
  function move(x){if(!drag)return;var dx=x-lastX;lastX=x;moved+=Math.abs(dx);var d=-dx*0.35;target+=d;vel=d*0.05}
  function up(){drag=false;document.body.classList.remove('drag')}
  window.addEventListener('mousedown',function(e){if(e.target.closest(UI))return;down(e.clientX)});
  window.addEventListener('mousemove',function(e){move(e.clientX)});
  window.addEventListener('mouseup',up);
  window.addEventListener('touchstart',function(e){if(e.target.closest(UI))return;down(e.touches[0].clientX)},{passive:true});
  window.addEventListener('touchmove',function(e){move(e.touches[0].clientX)},{passive:true});
  window.addEventListener('touchend',up);
  window.addEventListener('keydown',function(e){
    if(e.key==='Escape'){closeM();closeD();langEl.classList.remove('open')}
    if(modalOpen)return;
    if(e.key==='ArrowRight'||e.key==='ArrowDown')target+=STEP;if(e.key==='ArrowLeft'||e.key==='ArrowUp')target-=STEP});
  window.addEventListener('resize',function(){R=css('--R')});

  /* card detail */
  var curCard=null;
  function openD(c,i){
    curCard=c;modalOpen=true;
    var m=$('dmedia');m.innerHTML='';
    if(c.media){
      if(/\.(mp4|mov|m4v|webm)(\?|$)/i.test(c.media)){var v=document.createElement('video');v.src=c.media;v.controls=true;v.autoplay=true;v.loop=true;v.playsInline=true;m.appendChild(v);var pr=v.play();if(pr&&pr.catch)pr.catch(function(){})}
      else{var im=document.createElement('img');im.src=c.media;im.alt=tr(c.title);m.appendChild(im)}
    }else{m.style.background='linear-gradient(160deg,'+c.c1+','+c.c2+')';m.style.minHeight='260px'}
    $('dn').textContent='['+String(i+1).padStart(2,'0')+']';$('dt').textContent=tr(c.title);$('dg').textContent=tr(c.tag);
    $('dmodal').classList.add('on');
  }
  function closeD(){
    var m=$('dmedia');var v=m.querySelector('video');if(v){v.pause();v.removeAttribute('src');v.load()}
    m.innerHTML='';m.style.background='';m.style.minHeight='';$('dmodal').classList.remove('on');
    if(!$('modal').classList.contains('on'))modalOpen=false;
  }
  $('dx').addEventListener('click',closeD);
  $('dmodal').addEventListener('mousedown',function(e){if(e.target===$('dmodal'))closeD()});
  $('dorder').addEventListener('click',function(){
    var t=curCard&&tr(curCard.title);closeD();openM();
    if(t&&!$('o-msg').value)$('o-msg').value=UI_T[LANG].want+t;
  });

  /* lang + theme controls */
  var langEl=$('lang');
  $('lang-b').addEventListener('click',function(e){e.stopPropagation();var o=langEl.classList.toggle('open');$('lang-b').setAttribute('aria-expanded',o)});
  document.querySelectorAll('#lang-m button').forEach(function(b){b.addEventListener('click',function(){
    LANG=b.dataset.l;try{localStorage.setItem('md_lang',LANG)}catch(e){}
    langEl.classList.remove('open');applyLang();
  })});
  document.addEventListener('click',function(e){if(!langEl.contains(e.target))langEl.classList.remove('open')});
  $('theme-b').addEventListener('click',function(){
    THEME=THEME==='light'?'dark':'light';try{localStorage.setItem('md_theme',THEME)}catch(e){}
    applyTheme(THEME);
  });
  applyTheme(THEME);

  /* order modal */
  function openM(){modalOpen=true;$('modal').classList.add('on');$('omsg').textContent='';setTimeout(function(){$('o-name').focus()},50)}
  function closeM(){modalOpen=false;$('modal').classList.remove('on')}
  $('order').addEventListener('click',openM);
  $('mx').addEventListener('click',closeM);
  $('modal').addEventListener('mousedown',function(e){if(e.target===$('modal'))closeM()});
  $('oform').addEventListener('submit',function(e){
    e.preventDefault();var m=$('omsg');m.style.color='';m.textContent=UI_T[LANG].sending;
    fetch('/dapi/lead',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({name:$('o-name').value,contact:$('o-contact').value,message:$('o-msg').value,website:$('o-web').value})})
      .then(function(r){return r.json().then(function(j){if(!r.ok)throw new Error(j.error||'Ошибка');return j})})
      .then(function(){m.style.color='#3ddc84';m.textContent=UI_T[LANG].ok;$('oform').reset();setTimeout(closeM,2500)})
      .catch(function(err){m.style.color='#ff7070';m.textContent=err.message||UI_T[LANG].fail});
  });
})();
</script>
</body>
</html>

LANDING_EOF
base64 -d > /var/www/md-site/logo.png <<'B64_EOF'
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
B64_EOF
base64 -d > /var/www/md-site/favicon-16x16.png <<'B64_EOF'
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAABDElEQVR42s1SsUrDUBQ99zX0NSJKU5pU0CXQISKST/AT/AEn1/oHTdd8gbsuTn6DILiKuJQgUhGcXJTahzFt7nVoUjOaRTzDXe4593Auh0QEdaBQE38pEIAFKGcV1ZzWik0AEXJGozySpumSbdv2j4ABBTx94ehufrar+huN06vXm7HZfz8fP0w6jmOMcV03iiKtNREVDtMcOWF0+9mXxfX9R5cweX6JhkPf90VkcDJIkiQMQ2Yu7GcLOdiyRnvNx2l+ebzTWm+xQEqgkqpw2LRojTjoNi8OO29mvu3aVq8Xx3HbaZuZ8TwvCAIRUUpR9QMsEEARCACQZdlyq7Veceg31WBmpVQNwT/v0jfdA3fyBSVSrwAAAABJRU5ErkJggg==
B64_EOF
base64 -d > /var/www/md-site/favicon-32x32.png <<'B64_EOF'
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAACU0lEQVR42u2UP2hTURTGv3PufS95iZJYTWu1jVoUKqhL1A5WHZyLdKhgtG6ik0r9Aw7FQRR061Jc26FQqC4OBgSR2kFE6GJp1UFwKAataYtpycu79zg8Km3SPyh0EPJN79337v3dc853DokINlOMTVYNUAPUAICueBfACgAoWrFuBSLCRIBYa4mocqMIM1ev01qjwgqYVnleXyJSwdAVJ04s4vakObtdruzRZSuaYKxoxRPTi3effOo4tetEw9d79x9DrDFm6ZKwxra0tNzs6dnd1FTB4OXJAZAv48UPufq21Pex5DCVAtGKP3wrtT/8/Pzl9MR0MP7+3cjIUyKKetHIkmIxb3h4+Hw2WywWwzjWrIGCOBGcSasbowvk22uHvcnv/slHX5p3uO7BBBS7ym1oqB8cHIhGveUbc7lcZ2fn1NRUJpMxxiilVgcQUTlA37HIgGuv5+bni0H/q5nUNuf1rb1H7oz7lkASGDM7O5dKucYYZjbGaK2TyaTrukEQbOAiAsA058uDTKzwy/Q+mznQqEYvN9fF1IIhpRXMyp8BIqo2z9oAglIAQSD9p7c2Kps9FN+5RYkg4jmkmSxprZOJhFLqTx4AFAoF3/e11hsAyiJGyAIElK30ticAsVaY6WcJxYCCsp/P57MXLzhah7UMbTM29qatra21tTVsiFVcFAZZ71BHPeocCr8FVoxFmIBzR5PH00563/6uri4v6oGImZk5vHV396WhoaF4PB4mbeNG+zet12jLRwUTqqsWhkIQa2219/56VNTGdQ1QA/xHgN8iUPoXwjzbwgAAAABJRU5ErkJggg==
B64_EOF
base64 -d > /var/www/md-site/apple-touch-icon.png <<'B64_EOF'
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
B64_EOF
base64 -d > /var/www/md-site/favicon.ico <<'B64_EOF'
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
B64_EOF
base64 -d > /var/www/md-site/android-chrome-192x192.png <<'B64_EOF'
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
B64_EOF
base64 -d > /var/www/md-site/og-image.png <<'B64_EOF'
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mRArfJ6zBCBE41AIguqChU35vkct4qQe8IAHPOABD1j3yzfGnHjiifh0LJSe+9znnn766UBBYGFrmLB9+DSjA27gLVh0IAQNQhDURCbEjrCGmnSo33c95jGPOfjgg7EbWzS99KUvfdWrXoUJxIJvx4sABAnrr8UFQqSJQhBUTyZE+mhDdXdzO/dkr9OmfFHs7e6W3vCGNxx11FGYQCz7ea6BRUgcrfnnaC+Gty5XtKBACBSEIKjmWFjbr0Dki+5KT37yk5eXlzcWMqHWqNfrvfOd79xvv/2oFWmivG9qwbWDCcH8ddYiAiFoEIKgBWRCaNZaWlo67rjj1vGAW7duPfroo7FnWljd//73P/300xs3dbMguhZQIpgQQcI637KFA0LQIARBTWdC7K1rqz0P6O3JTTzxxBPvstsk1G698IUvPPXUU5tFgK0/7yIwYbNQs2XXtSGztFjfNKBBCILawYT4Bq2n1revTGvyRfEKY1/0xje+ccuWLXWGQAzp7g6y/h+rus0hgoQAQtAgBEFgwrp88+FLdPe63/3ud+SRR67LNDLzU5/6VEwpdNBBB732ta8FcbVpqIvMhAgSzuho+ziADh61EARBELReeuYzn/mjH/1o349z1FFHHXroodgn7Ys+/OEP33LLLbsZTFEUS0tL/X5/eXn5oIMOus997nOf+9xn3TsD7bte9rKXvec977n88ssX7Q6u7/hrFRhg5nUZz3odZ54H37vDrvtgZjp1jdOiACFuOQRBzdVwOOz1eu3YnLVeT3/609/61rfu+3Ge8YxnYDL3Uf/0T//0gx/84O6yzZYtWx7+8IcfddRRRx111HHHHVcHLC+K4o1vfOPzn/98cGCbyLARTAgBCEGDEARBdWTCDd9OYa+5Gx177LGbNm1aWVnZx2t/2tOe1qYteIMGc+utt55//vnnn3+++5VHPepRJ5100qmnnvoLv/ALGzj444477uSTTz7rrLOAgut1gXXYHNZnJHOmzVYGCTf8aPsygPbXEIIGIQhqDRNib1d/9fv9fTefOPDAAx/72MeCBjd8MCJy2WWXvelNb3rMYx7zkpe85IILLtjAS3jd61436ylqgelfE693XWw58EGG9kXoZw1BEARB66l97zV64oknFkWBmazPJrIsy8985jOnnHLKaaedduWVV27IVTzsYQ97ylOeMjs0WuTlseGX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x49bugqjRtEaozBiymiEh4f37t3b7MknT56sl0PaN43sNqwZygdqqyUeW9W/kLGoDAAAAJawsv3gkiVLXnnllXbt2in/NH78eE9Pz/v377skzpGRkUePHrVygslkKisrKykpuXnz5rVr144dO7Z79+7Dhw8rw0lNTTUbQmJiotntB955550XX3xRebxFixZlZWWyg5s2bRo0aFDD0piamjp69Og6T+M4buDAgXFxcYMGDQoJCRGikZWVdfXq1V27dqWkpKSlpdl+0549e44YMWLIkCGtWrUKDAz09vbOy8vLzs5OT0/fu3fvjh07rl+/Xt+EdOjQ4dChQ2b/NGnSpL179yqPv/32288//7zyeFhYWHl5eZ1NNOkAUSvbD3777bfz589v06aN8k/x8fEeHh7KArXv2jC2L0DaunXrBx98sEePHp07dw4ICPD19dXpdIWFhfn5+enp6WfOnNm0aZOlgo6IiNi/f3994/bhhx9++OGHZpM/cODAkSNHDhw4MCQkJDg4uKysLDs7++rVq3v27Nm+fXt6erqVmmApJm+99daSJUtkB999992nn37a7Pnh4eHl5eXvvffenDlzGlkKGzZsmD17docOHQ4ePGj2hDfffFOMm3WD+u6778aNG6c8fvfu3c6dO+NboymthRACAABwYCPS7ljp60tJSendu/eTTz6p/JO3t/eYMWPWr19PZ6J0Ol2TJk2aNGkSGBjYrVu3cePGvfXWWxkZGW+88UZKSkqDg01ISDBrg5YICAhwaDLHjx//+uuvR0dHSw96eHj4+vpGRETExsa+884727dvf++998x29kprZnx8/EsvvaRcfCU4ODg4ODg6OnrixImVlZXJyckff/yxWfewVz1/8MEHzdpgw7AihDt37uzZs+esWbPMVu+4uLhff/3VCa1PMUCzuRcdHf3Xv/512LBhyj8FBgYGBgZGREQIW2WcPHlywYIFv//+u+Ma3GPHjn311VdlbiPUt/bt248YMWLBggU7duxYtGjRiRMn8OZXn/xodpxwQ75BqKwAAABYoU2bNn379jX7p9OnT9+6dWv79u0NMEk6myAdO3b86aefLPU51ElkZOSXX35Zr0scIYRChnh4eHz55ZcrV66U2aCSuLi4lJSU+fPnW7I1Ly+vr776atWqVXUuxanX6ydPnvzbb781OA/rLN8OHTr8+9//tleYrVq1sjRe9OzZs7dv3965c6elQKzMPHTc7giykKdPn56SkmLWBpX06NFj3bp1L7zwgiOi5OHhsXjx4uXLl9fZ0zVq1KjNmze/8MIL6ttmQ2UOg/GiDs0Q9BACAIB6Pg+q37zOynhRoSdt165dFRUVbm5uyhPGjh3btGnTkpKSBt+9Z8+eNo6KJIScOHGiMZ17Iu+9996OHTsuXLhQr6u8vLxWrVrl7e1dr6v8/f0dUWqenp7r16+3ZPJKdDrd22+/3b59++eee072Jx8fn40bN3bt2tX2u7u7u//jH/+IjIx8+eWX7fvIeHl5rVixor6ZbOXhtd49SAjZt2+fper9wAMPNGnSpLS0tMFx6N69+8iRI208+fTp08Lmh2KrNCkp6aOPPqrvTV9//fXs7OxVq1bZ0U49PT1/+eUX27fu0Ol0b7zxRtu2befPn4/vCNAmEEIAAADMOK2VXj5h6/l79+79/vvvQ4YMUZ7QtGnT+Pj4X375pcHR692794IFC2w8+ZtvvrGLEOr1+qlTp7777rv1uuqLL76Iioqqr7Z5eno6olg/++wz221QZPr06efPn//000+lWbF8+fJ62aDIE088cfXqVWloja+l//73vzt27GjHym+ll0+wr3v37qWmpg4cOFB5QpMmTcaMGbNu3brG/N7x+uuv23jyihUrhCiJPyV88MEHDbvvggULNm7cWFBQYK+c/L//+796beQoMG3atIsXL3722WeqeZciDigX22+twiGjqv+BHAAAtPnxa9u2raUBdffu3RMXApG2U2U89NBDVOVPYWHhjz/++OOPPyYnJ1vpA+zQoUO9gn3++efru3UBcdgEwkmTJtV3mxCRt956KyIiQvzfGTNmjBgxosExeeONN9q3b2+XKsrz/Lx58xISEuyYUa1bt+7Zs6el6n3kyBHh37t27bIUgmyHemcyefLkBtcfPz8/s0ubNIykpKQG58Prr78urSFYWJXpFGECYb1ADyEAAAA2sOIVO3furKioEP69ffv2v/zlL2ZPGzNmjJeXV3FxMSUpun79unQJnH/961+zZ89WnlavYa5Dhgz561//2oDIWGrQnzlz5sqVK9LTbF+JVK/Xv/baa2b/lJWVtXjx4iNHjpSVlXXp0uWPf/xjZGSkvI1iMLz55ptCnjRp0sRSUAI3bty4evVqly5dfH19zZ7g5ub2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
B64_EOF
printf 'google-site-verification: google79e0a3010c3fd3d3.html' > /var/www/md-site/google79e0a3010c3fd3d3.html
cat > /opt/md-admin/app/server.js <<'SERVER_JS_EOF'
'use strict';
// MD admin: контент стартовой страницы, заявки, вход по паролю. Без внешних зависимостей (Node 22+).
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
const UPLOADS = path.join(DATA, 'uploads');
fs.mkdirSync(UPLOADS, { recursive: true, mode: 0o755 });
const MAX_UPLOAD = 300 * 1024 * 1024;
const MIME = { mp4: 'video/mp4', mov: 'video/quicktime', m4v: 'video/mp4', webm: 'video/webm', jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', webp: 'image/webp', gif: 'image/gif' };
function sniff(buf, ext) {
  const h = buf.subarray(0, 12);
  if (ext === 'mp4' || ext === 'mov' || ext === 'm4v') return h.subarray(4, 8).toString() === 'ftyp';
  if (ext === 'webm') return h[0] === 0x1a && h[1] === 0x45 && h[2] === 0xdf && h[3] === 0xa3;
  if (ext === 'jpg' || ext === 'jpeg') return h[0] === 0xff && h[1] === 0xd8 && h[2] === 0xff;
  if (ext === 'png') return h.subarray(1, 4).toString() === 'PNG';
  if (ext === 'webp') return h.subarray(0, 4).toString() === 'RIFF' && h.subarray(8, 12).toString() === 'WEBP';
  if (ext === 'gif') return h.subarray(0, 3).toString() === 'GIF';
  return false;
}
function saveUpload(req, ext) {
  return new Promise((resolve, reject) => {
    const name = crypto.randomBytes(10).toString('hex') + '.' + ext;
    const f = path.join(UPLOADS, name), ws = fs.createWriteStream(f, { mode: 0o644 });
    let n = 0, head = null, failed = false;
    const fail = (m) => { if (failed) return; failed = true; ws.destroy(); fs.unlink(f, () => {}); reject(new Error(m)); };
    req.on('data', c => {
      if (failed) return;
      n += c.length;
      if (n > MAX_UPLOAD) { fail('Файл больше 300 МБ'); req.destroy(); return; }
      if (!head) head = Buffer.from(c.subarray(0, 12));
      ws.write(c);
    });
    req.on('end', () => {
      if (failed) return;
      ws.end(() => {
        if (!n || !head || !sniff(head, ext)) { fs.unlink(f, () => {}); return reject(new Error('Файл не похож на ' + ext.toUpperCase())); }
        resolve({ url: '/media/' + name, name, size: n });
      });
    });
    req.on('error', () => fail('Загрузка прервана'));
  });
}
function cleanOrphans(content) {
  try {
    const used = new Set(content.cards.map(c => (c.media || '').replace('/media/', '')));
    const now = Date.now();
    fs.readdirSync(UPLOADS).forEach(f => {
      const fp = path.join(UPLOADS, f);
      if (!used.has(f) && now - fs.statSync(fp).mtimeMs > 3600 * 1000) fs.unlink(fp, () => {});
    });
  } catch (e) {}
}
function serveMedia(req, res, name) {
  const ext = name.split('.').pop();
  const fp = path.join(UPLOADS, name);
  if (!/^[0-9a-f]{20}\.[a-z0-9]+$/.test(name) || !MIME[ext] || !fs.existsSync(fp)) return send(res, 404, { error: 'not found' });
  const size = fs.statSync(fp).size;
  const h = { 'content-type': MIME[ext], 'accept-ranges': 'bytes', 'cache-control': 'public, max-age=31536000, immutable', 'x-content-type-options': 'nosniff' };
  const r = /bytes=(\d*)-(\d*)/.exec(req.headers.range || '');
  if (r) {
    let a = r[1] ? +r[1] : 0, b = r[2] ? +r[2] : size - 1;
    if (!r[1] && r[2]) { a = Math.max(0, size - +r[2]); b = size - 1; }
    if (a > b || a >= size) { res.writeHead(416, { 'content-range': 'bytes */' + size }); return res.end(); }
    b = Math.min(b, size - 1);
    res.writeHead(206, Object.assign(h, { 'content-range': 'bytes ' + a + '-' + b + '/' + size, 'content-length': b - a + 1 }));
    return fs.createReadStream(fp, { start: a, end: b }).pipe(res);
  }
  res.writeHead(200, Object.assign(h, { 'content-length': size }));
  fs.createReadStream(fp).pipe(res);
}

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
  tag: 'MD AI Masters',
  title: 'MD',
  subtitle: 'AI-видео, которые невозможно снять камерой, и AI-агенты для вашего бизнеса.',
  button: 'Написать в Telegram',
  orderButton: 'Заказать ролик',
  instagram: 'https://www.instagram.com/mirzouzs',
  telegram: 'https://t.me/uz_73',
  phone: '',
  email: 'whoopdaler@gmail.com',
  marquee: ['AI-видео', 'AI-агенты', 'Реклама', 'Контент', 'Боты', 'Автоматизация'],
  cards: [
    ['Кино-ролик', 'AI-видео', '#9a9a9a', '#0d0d0d'],
    ['Реклама для бизнеса', 'Reels / Shorts', '#7d7d7d', '#101010'],
    ['Трансформации', 'Higgsfield', '#b0b0b0', '#0b0b0b'],
    ['AI-агент для продаж', 'Автоматизация', '#6a6a6a', '#111111'],
    ['Фильм за день', 'Seedance', '#a5a5a5', '#0e0e0e'],
    ['Телеграм-бот', 'Боты', '#858585', '#0c0c0c'],
    ['Контент для бренда', 'Продакшн', '#bababa', '#101010'],
    ['Музыкальный клип', 'AI-видео', '#737373', '#0a0a0a'],
    ['Персонаж-бренд', '3D / AI', '#a0a0a0', '#111111'],
    ['Instagram под ключ', 'Контент-план', '#8a8a8a', '#0d0d0d'],
    ['Свой проект', 'Напишите нам', '#b5b5b5', '#0b0b0b']
  ].map(c => ({ title: c[0], tag: c[1], c1: c[2], c2: c[3], media: '' }))
};

const str = (v, max) => String(v == null ? '' : v).replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '').trim().slice(0, max);
const hex = (v, d) => (/^#[0-9a-fA-F]{6}$/.test(String(v)) ? String(v) : d);
const url = v => { v = str(v, 500); return (v === '' || /^https:\/\//i.test(v) || v.startsWith('/')) ? v : ''; };
function sanitizeContent(c) {
  c = c || {};
  const out = {
    tag: str(c.tag, 80), title: str(c.title, 40) || 'MD', subtitle: str(c.subtitle, 300),
    button: str(c.button, 40) || 'Написать в Telegram', orderButton: str(c.orderButton, 40) || 'Заказать ролик',
    instagram: url(c.instagram), telegram: url(c.telegram),
    phone: str(c.phone, 30).replace(/[^\d+\-() ]/g, ''), email: str(c.email, 120).replace(/[^\w.@+\-]/g, ''),
    marquee: (Array.isArray(c.marquee) ? c.marquee : []).map(x => str(x, 40)).filter(Boolean).slice(0, 20),
    cards: (Array.isArray(c.cards) ? c.cards : []).slice(0, 24).map(x => ({
      title: str(x && x.title, 60), tag: str(x && x.tag, 50),
      c1: hex(x && x.c1, '#9a9a9a'), c2: hex(x && x.c2, '#0d0d0d'), media: url(x && x.media)
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

    let mm = p.match(/^\/media\/([^/]+)$/);
    if (mm && (req.method === 'GET' || req.method === 'HEAD')) return serveMedia(req, res, mm[1]);

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
      tg('Новая заявка MD\nИмя: ' + lead.name + '\nКонтакт: ' + lead.contact + (lead.message ? '\nСообщение: ' + lead.message : ''));
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
      if (p === '/dapi/admin/upload' && req.method === 'POST') {
        if (req.headers['x-dapi'] !== '1') return send(res, 403, { error: 'csrf' });
        const ext = String(u.searchParams.get('ext') || '').toLowerCase();
        if (!MIME[ext]) return send(res, 400, { error: 'Разрешены: mp4, mov, webm, jpg, png, webp, gif' });
        return send(res, 200, await saveUpload(req, ext));
      }
      if (p === '/dapi/admin/content' && req.method === 'GET') return send(res, 200, getContent());
      if (p === '/dapi/admin/content' && req.method === 'PUT') {
        const c = sanitizeContent(await readBody(req)); writeJSON('content.json', c); cleanOrphans(c); return send(res, 200, c);
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
      if (p === '/dapi/admin/tg-test' && req.method === 'POST') return send(res, 200, await tg('Проверка связи: админка MD подключена к Telegram.'));
      return send(res, 404, { error: 'not found' });
    }
    return send(res, 404, { error: 'not found' });
  } catch (e) {
    return send(res, 400, { error: String(e.message || e) });
  }
});
server.listen(PORT, process.env.HOST || '127.0.0.1', () => console.log('md-admin on ' + PORT));

SERVER_JS_EOF
cat > /opt/md-admin/app/admin.html <<'ADMIN_HTML_EOF'
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>MD — админка</title>
<link rel="icon" href="/favicon-32x32.png" type="image/png">
<link href="https://fonts.googleapis.com/css2?family=Unbounded:wght@500;700;900&family=Space+Mono:wght@400;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root{--bg:#000;--bg2:#0c0c0c;--bg3:#161616;--line:rgba(255,255,255,.14);--red:#ffffff;--red2:#d0d0d0;--text:#f5f5f5;--mute:#8c8c8c;--ok:#3ddc84;--warn:#ffb020;
--fd:'Unbounded','Arial Black',sans-serif;--fm:'Space Mono',ui-monospace,monospace;--fb:'Inter',system-ui,sans-serif}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--bg);color:var(--text);font-family:var(--fb);font-size:15px;min-height:100vh}
button{font-family:inherit;cursor:pointer}
input,textarea,select{font-family:inherit;font-size:14px;color:var(--text);background:var(--bg2);border:1px solid var(--line);border-radius:10px;padding:10px 12px;width:100%;outline:none}
input:focus,textarea:focus,select:focus{border-color:var(--red)}
input[type=color]{padding:2px;height:40px;width:54px;cursor:pointer}
textarea{resize:vertical;min-height:70px}
label{display:block;font-family:var(--fm);font-size:11px;letter-spacing:.1em;text-transform:uppercase;color:var(--mute);margin:0 0 6px}
.btn{background:var(--red);color:#000;border:0;border-radius:999px;padding:12px 22px;font-family:var(--fd);font-weight:700;font-size:13px;transition:.2s}
.btn:hover{background:var(--red2)}
.btn.ghost{background:transparent;color:var(--text);border:1px solid var(--line)}
.btn.ghost:hover{border-color:var(--red);color:var(--red)}
.btn.sm{padding:8px 14px;font-size:12px}
.btn.danger{background:transparent;color:#ff7070;border:1px solid rgba(255,112,112,.4)}
/* login */
#login{min-height:100vh;display:grid;place-items:center;padding:20px}
.lbox{width:min(380px,100%);background:var(--bg2);border:1px solid var(--line);border-radius:20px;padding:32px}
.lbox h1{margin-bottom:14px}
.lbox p{color:var(--mute);font-size:13px;margin-bottom:22px}
.err{color:#ff7070;font-size:13px;margin-top:12px;min-height:18px}
/* app */
#app{display:none}
header{position:sticky;top:0;z-index:10;display:flex;align-items:center;gap:18px;flex-wrap:wrap;padding:14px clamp(14px,3vw,36px);background:rgba(0,0,0,.92);backdrop-filter:blur(8px);border-bottom:1px solid var(--line)}
.logo{font-family:var(--fd);font-weight:900;font-size:15px;display:flex;align-items:center}
.tabs{display:flex;gap:6px;flex:1;flex-wrap:wrap}
.tab{background:transparent;border:1px solid transparent;color:var(--mute);padding:9px 16px;border-radius:999px;font-size:14px;font-weight:600}
.tab.on{color:var(--text);border-color:var(--red);background:rgba(255,255,255,.1)}
.tab .badge{display:inline-block;min-width:20px;padding:1px 6px;margin-left:6px;border-radius:999px;background:var(--red);color:#000;font-size:11px;font-weight:700;text-align:center}
main{max-width:980px;margin:0 auto;padding:26px clamp(14px,3vw,36px) 120px}
.panel{display:none}.panel.on{display:block}
.sec{background:var(--bg2);border:1px solid var(--line);border-radius:18px;padding:22px;margin-bottom:18px}
.sec h2{font-family:var(--fd);font-size:15px;font-weight:700;margin-bottom:16px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.grid .full{grid-column:1/-1}
@media(max-width:640px){.grid{grid-template-columns:1fr}}
.card{display:grid;grid-template-columns:34px 1.4fr 1.1fr auto auto auto;gap:8px;align-items:center;padding:10px;border:1px solid var(--line);border-radius:12px;margin-bottom:8px;background:var(--bg3)}
.card .n{font-family:var(--fm);color:var(--mute);font-size:12px}
.card .mv{display:flex;gap:4px}
.card .mrow{grid-column:1/-1;display:flex;gap:10px;align-items:center;flex-wrap:wrap;padding-top:8px;border-top:1px dashed var(--line)}
.card .thumb{width:64px;height:64px;border-radius:10px;border:1px solid var(--line);background:#000 center/cover;object-fit:cover;flex:none;display:grid;place-items:center;color:var(--mute);font-size:11px;font-family:var(--fm)}
.card .mrow input[data-k=media]{flex:1;min-width:180px}
.card .pg{flex-basis:100%;height:6px;border-radius:3px;background:var(--line);overflow:hidden;display:none}
.card .pg i{display:block;height:100%;width:0;background:#fff;transition:width .15s}
.card .pm{flex-basis:100%;font-size:12px;color:var(--mute);min-height:0}
@media(max-width:820px){.card{grid-template-columns:1fr 1fr;}.card .n{display:none}}
.savebar{position:fixed;left:0;right:0;bottom:0;z-index:20;display:flex;gap:12px;align-items:center;justify-content:flex-end;padding:14px clamp(14px,3vw,36px);background:rgba(0,0,0,.94);border-top:1px solid var(--line)}
.savebar .msg{margin-right:auto;font-size:13px;color:var(--mute)}
.msg.ok{color:var(--ok)}.msg.bad{color:#ff7070}
.lead{border:1px solid var(--line);border-radius:14px;padding:16px;margin-bottom:12px;background:var(--bg2)}
.lead .top{display:flex;gap:10px;flex-wrap:wrap;align-items:baseline;margin-bottom:8px}
.lead .nm{font-weight:700;font-size:16px}
.lead .ct{font-family:var(--fm);font-size:13px;color:#d0d0d0}
.lead .at{font-family:var(--fm);font-size:11px;color:var(--mute);margin-left:auto}
.lead .ms{color:#d8cfcd;white-space:pre-wrap;margin-bottom:12px;font-size:14px}
.lead .row{display:flex;gap:10px;flex-wrap:wrap;align-items:center}
.lead select{width:auto}.lead textarea{min-height:44px;flex:1;min-width:200px}
.st-new{border-left:4px solid #fff}.st-work{border-left:4px solid #b5b5b5}.st-done{border-left:4px solid #707070}.st-paid{border-left:4px solid #4a4a4a}.st-rejected{border-left:4px solid #2f2f2f;opacity:.7}
.empty{color:var(--mute);padding:30px;text-align:center;border:1px dashed var(--line);border-radius:14px}
.filters{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:16px}
.chip{background:transparent;color:var(--mute);border:1px solid var(--line);border-radius:999px;padding:7px 14px;font-size:13px}
.chip.on{color:var(--text);border-color:var(--red)}
.hint{font-size:13px;color:var(--mute);line-height:1.5;margin-top:10px}
.pill{display:inline-block;padding:3px 10px;border-radius:999px;font-size:12px;font-weight:600}
.pill.ok{background:rgba(255,255,255,.18);color:#fff}.pill.no{background:rgba(255,255,255,.08);color:#aaa}
</style>
</head>
<body>

<div id="login">
  <form class="lbox" id="lform">
    <h1><img src="/logo.png" alt="MD" style="height:44px;border-radius:9px;display:block"></h1>
    <p>Вход в админ-панель</p>
    <label for="pw">Пароль</label>
    <input id="pw" type="password" autocomplete="current-password" autofocus>
    <div class="err" id="lerr"></div>
    <button class="btn" style="width:100%;margin-top:6px" type="submit">Войти</button>
  </form>
</div>

<div id="app">
  <header>
    <div class="logo"><img src="/logo.png" alt="MD" style="height:30px;border-radius:7px;vertical-align:middle;margin-right:10px">админка</div>
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
          <div><label>Вторая кнопка (ведёт в Telegram)</label><input id="f-button"></div>
          <div><label>Главная кнопка (форма заявки)</label><input id="f-orderButton"></div>
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
        <p class="hint">У каждой карточки своя кнопка «Выбрать видео / фото» (с телефона откроется галерея; mp4, mov, webm, jpg, png, webp, gif, до 300 МБ). После загрузки нажмите «Сохранить и опубликовать». Видео играет в колесе само, по клику открывается целиком. Лучше mp4 (H.264) до 30–50 МБ. Минимум 3 карточки.</p>
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
        '<span class="mv"><button class="btn ghost sm" data-a="up" type="button">↑</button><button class="btn ghost sm" data-a="down" type="button">↓</button><button class="btn danger sm" data-a="del" type="button">✕</button></span>'+
        '<div class="mrow"><div class="thumb">нет</div>'+
        '<button class="btn sm" data-a="up_file" type="button">Загрузить видео / фото</button>'+
        '<input type="file" hidden accept="video/*,image/*">'+
        '<input data-k="media" type="hidden" value="'+esc(c.media)+'">'+'<span class="fn" style="flex:1;color:var(--mute);font-size:12px;font-family:var(--fm)">'+(c.media?'Файл загружен':'Файл не выбран')+'</span>'+
        '<button class="btn ghost sm" data-a="clr" type="button">Убрать</button>'+
        '<div class="pg"><i></i></div><div class="pm"></div></div>';
      d.querySelectorAll('input[data-k]').forEach(function(inp){inp.addEventListener('input',function(){c[inp.dataset.k]=inp.value;thumb()})});
      var th=d.querySelector('.thumb'),fi=d.querySelector('input[type=file]'),pg=d.querySelector('.pg'),pb=pg.firstChild,pm=d.querySelector('.pm'),mi=d.querySelector('input[data-k=media]');
      function thumb(){
        var m=c.media||'';th.innerHTML='';th.style.backgroundImage='';
        if(!m){th.textContent='нет';return}
        if(/\.(mp4|mov|m4v|webm)(\?|$)/i.test(m)){var v=document.createElement('video');v.src=m;v.muted=true;v.preload='metadata';v.style.cssText='width:100%;height:100%;object-fit:cover;border-radius:9px';th.appendChild(v)}
        else th.style.backgroundImage='url("'+m.replace(/"/g,'%22')+'")';
      }
      thumb();
      fi.addEventListener('change',function(){
        var f=fi.files[0];if(!f)return;
        var ext=(f.name.split('.').pop()||'').toLowerCase();
        if(['mp4','mov','m4v','webm','jpg','jpeg','png','webp','gif'].indexOf(ext)<0){pm.style.color='#ff7070';pm.textContent='Формат не подходит (HEIC не поддерживается). Нужен mp4, mov, webm, jpg, png, webp или gif.';fi.value='';return}
        if(f.size>300*1024*1024){pm.style.color='#ff7070';pm.textContent='Файл больше 300 МБ';fi.value='';return}
        var x=new XMLHttpRequest();x.open('POST','/dapi/admin/upload?ext='+encodeURIComponent(ext));
        x.withCredentials=true;x.setRequestHeader('x-dapi','1');x.setRequestHeader('content-type','application/octet-stream');
        pg.style.display='block';pb.style.width='0';pm.style.color='';pm.textContent='Загружаю… 0%';
        x.upload.onprogress=function(e){if(e.lengthComputable){var p=Math.round(e.loaded/e.total*100);pb.style.width=p+'%';pm.textContent='Загружаю… '+p+'%'}};
        x.onload=function(){
          pg.style.display='none';fi.value='';
          var j={};try{j=JSON.parse(x.responseText)}catch(e){}
          if(x.status===200&&j.url){c.media=j.url;mi.value=j.url;d.querySelector('.fn').textContent='Файл загружен';thumb();pm.style.color='#3ddc84';pm.textContent='Загружено ('+(j.size/1048576).toFixed(1)+' МБ). Нажмите «Сохранить и опубликовать» внизу.'}
          else if(x.status===401){pm.style.color='#ff7070';pm.textContent='Сессия истекла, войдите заново'}
          else{pm.style.color='#ff7070';pm.textContent=(j&&j.error)||(x.status===413?'Файл слишком большой для сервера':'Ошибка загрузки')}
        };
        x.onerror=function(){pg.style.display='none';fi.value='';pm.style.color='#ff7070';pm.textContent='Сеть оборвалась, попробуйте ещё раз'};
        x.send(f);
      });
      d.querySelectorAll('button').forEach(function(bt){bt.addEventListener('click',function(){
        var a=bt.dataset.a,cs=content.cards;
        if(a==='up_file'){fi.click();return}
        if(a==='clr'){c.media='';mi.value='';d.querySelector('.fn').textContent='Файл не выбран';thumb();pm.textContent='';return}
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
    content.cards.push({title:'Новая карточка',tag:'',c1:'#9a9a9a',c2:'#0d0d0d',media:''});renderCards();
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

echo "== 4. Админка: пароль и запуск =="
NEWPASS=""
if [ ! -f /opt/md-admin/.env ]; then
  NEWPASS=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)
  cat > /opt/md-admin/.env <<EOF
ADMIN_PASSWORD=$NEWPASS
TG_BOT_TOKEN=
TG_CHAT_ID=
EOF
  chmod 600 /opt/md-admin/.env
fi
docker run -d --name md-admin --restart unless-stopped \
  -p 127.0.0.1:3100:3100 \
  --env-file /opt/md-admin/.env \
  -e DATA_DIR=/data -e HOST=0.0.0.0 \
  -v /opt/md-admin/app:/app:ro \
  -v /opt/md-admin/data:/data \
  node:22-alpine node /app/server.js

echo "== 5. Nginx =="
CERT=/etc/letsencrypt/live/002.uz
cat > /etc/nginx/sites-available/md-site <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name 002.uz www.002.uz;
    root /var/www/md-site;
    index index.html;
    location ^~ /media/ { alias /opt/md-admin/data/uploads/; }
    location / { try_files $uri $uri/ =404; }
}
EOF
ln -sf /etc/nginx/sites-available/md-site /etc/nginx/sites-enabled/md-site
nginx -t
systemctl reload nginx 2>/dev/null || systemctl restart nginx

if [ ! -f "$CERT/fullchain.pem" ]; then
  echo "Сертификата HTTPS нет, получаю..."
  apt-get install -y certbot python3-certbot-nginx >/dev/null 2>&1 || true
  certbot certonly --nginx -d 002.uz -d www.002.uz --non-interactive --agree-tos --register-unsafely-without-email || echo "Не удалось получить сертификат (проверьте, что 002.uz указывает на этот сервер)"
fi

ADMIN_ON=0
if [ -f "$CERT/fullchain.pem" ]; then
  SSL_EXTRA=""
  [ -f /etc/letsencrypt/options-ssl-nginx.conf ] && SSL_EXTRA="$SSL_EXTRA
    include /etc/letsencrypt/options-ssl-nginx.conf;"
  [ -f /etc/letsencrypt/ssl-dhparams.pem ] && SSL_EXTRA="$SSL_EXTRA
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;"
  cat > /etc/nginx/sites-available/md-site <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name 002.uz www.002.uz;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name 002.uz www.002.uz;

    ssl_certificate $CERT/fullchain.pem;
    ssl_certificate_key $CERT/privkey.pem;$SSL_EXTRA

    root /var/www/md-site;
    index index.html;

    location ^~ /admin {
        client_max_body_size 1m;
        proxy_pass http://127.0.0.1:3100;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location = /dapi/admin/upload {
        client_max_body_size 320m;
        proxy_request_buffering off;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        proxy_pass http://127.0.0.1:3100;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ^~ /media/ {
        alias /opt/md-admin/data/uploads/;
        types { video/mp4 mp4 m4v; video/quicktime mov; video/webm webm; image/jpeg jpg jpeg; image/png png; image/webp webp; image/gif gif; }
        default_type application/octet-stream;
        add_header Cache-Control "public, max-age=31536000, immutable" always;
        add_header X-Content-Type-Options nosniff always;
    }

    location ^~ /dapi/ {
        client_max_body_size 1m;
        proxy_pass http://127.0.0.1:3100;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        add_header X-Content-Type-Options nosniff always;
        add_header X-Frame-Options SAMEORIGIN always;
        add_header Referrer-Policy strict-origin-when-cross-origin always;
        add_header Strict-Transport-Security "max-age=31536000" always;
        try_files \$uri \$uri/ =404;
    }
}
EOF
  nginx -t
  systemctl reload nginx
  ADMIN_ON=1
fi

echo
echo "================ ГОТОВО ================"
echo "Сайт:    https://002.uz   (код ответа сейчас: $(curl -s -o /dev/null -w '%{http_code}' -H 'Host: 002.uz' http://127.0.0.1/))"
if [ "$ADMIN_ON" = "1" ]; then
  echo "Админка: https://002.uz/admin"
  if [ -n "$NEWPASS" ]; then
    echo "Пароль:  $NEWPASS    (сохраните; сменить можно в админке, вкладка «Настройки»)"
  else
    echo "Пароль:  прежний (файл /opt/md-admin/.env, если не меняли в админке)"
  fi
else
  echo "Админка отключена: нет HTTPS-сертификата. Исправьте DNS/сертификат и запустите скрипт снова."
fi
echo "Заявки в Telegram: впишите TG_BOT_TOKEN и TG_CHAT_ID в /opt/md-admin/.env и выполните: docker restart md-admin"
