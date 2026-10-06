#!/usr/bin/env python3
"""Build a dependency-free, fully translated GitHub Pages site in docs/."""
import html, json, pathlib, shutil, hashlib
ROOT=pathlib.Path(__file__).resolve().parent.parent
SITE=ROOT/'docs';SOURCE=ROOT/'website'
URL='https://kimtoma.github.io/MacAndFiles'
REPO='https://github.com/kimtoma/MacAndFiles'
RELEASE=REPO+'/releases/download/v1.0.0-dev.9/MacAndFiles-macOS-arm64.zip'
LANGUAGES={'en':'English','ko':'한국어','zh-Hans':'简体中文','zh-Hant':'繁體中文','es':'Español','pt-BR':'Português','ja':'日本語','de':'Deutsch','fr':'Français','ru':'Русский','hi':'हिन्दी','id':'Bahasa Indonesia','ar':'العربية'}
ASSET_VERSIONS={name:hashlib.sha256((SOURCE/'assets'/name).read_bytes()).hexdigest()[:12] for name in ['site.css','site.js']}
COPY={language:json.loads((SOURCE/'locales'/f'{language}.json').read_text()) for language in LANGUAGES}
KEYS=set(COPY['en'])
for language,copy in COPY.items():
 assert set(copy)==KEYS and all(isinstance(v,str) and v.strip() for v in copy.values()),language
(SITE/'assets').mkdir(exist_ok=True)
for path in (SOURCE/'assets').iterdir():shutil.copyfile(path,SITE/'assets'/path.name)
shutil.copyfile(ROOT/'Resources/Icon/AppIcon-master.png',SITE/'assets/icon.png')
(SITE/'.nojekyll').touch()

def render(language,entry=False):
 c={k:html.escape(v,quote=True) for k,v in COPY[language].items()};base='./' if entry else '../'
 alternates='\n'.join(f'<link rel="alternate" hreflang="{l}" href="{URL}/{l}/">' for l in LANGUAGES)
 options=''.join(f'<option value="{l}"'+(' selected' if l==language else '')+f'>{name}</option>' for l,name in LANGUAGES.items())
 links=' '.join(f'<a href="{base}{l}/" lang="{l}">{name}</a>' for l,name in LANGUAGES.items())
 dir='rtl' if language=='ar' else 'ltr'
 title='MacAndFiles — '+c['intro']
 return f'''<!doctype html>
<html lang="{language}" dir="{dir}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title><meta name="description" content="{c['intro']}">
<meta name="color-scheme" content="light"><meta name="theme-color" content="#f8f9fa">
<meta http-equiv="Content-Security-Policy" content="default-src 'self'; img-src 'self'; style-src 'self'; script-src 'self'; base-uri 'none'; object-src 'none'; form-action 'none'">
<link rel="canonical" href="{URL}/{language}/">{alternates}<link rel="alternate" hreflang="x-default" href="{URL}/en/">
<meta property="og:title" content="{title}"><meta property="og:description" content="{c['intro']}"><meta property="og:type" content="website"><meta property="og:url" content="{URL}/{language}/"><meta property="og:image" content="{URL}/assets/icon.png">
<link rel="icon" type="image/png" href="{base}assets/icon.png"><link rel="stylesheet" href="{base}assets/site.css?v={ASSET_VERSIONS['site.css']}"><script src="{base}assets/site.js?v={ASSET_VERSIONS['site.js']}" defer></script></head>
<body data-base="{base}" data-entry="{'true' if entry else 'false'}"><a class="skip" href="#main">{c['skip']}</a><div class="shell">
<header class="header"><a class="brand" href="{base}{language}/"><img src="{base}assets/icon.png" width="25" height="25" alt="">MacAndFiles</a>
<nav class="nav"><a class="guide-link" href="#guide">{c['guide']}</a><a class="agent-link" href="#agents">{c['agents']}</a><a href="{REPO}">GitHub ↗</a><div class="language"><label for="language">{c['language']}</label><select id="language">{options}</select></div></nav></header>
<noscript><nav class="nojs" aria-label="{c['language']}">{links}</nav></noscript>
<main id="main"><section class="hero"><img class="app-icon" src="{base}assets/icon.png" alt="" width="114" height="114" fetchpriority="high"><h1>{c['hero']}</h1><p class="intro">{c['intro']}</p>
<div class="actions"><a class="download" href="{RELEASE}" aria-describedby="release-status">{c['download']} <span aria-hidden="true">↓</span></a><a class="source" href="{REPO}">GitHub <span aria-hidden="true">↗</span></a></div><p class="release-note">{c['releaseNote']}</p></section>
<figure class="product"><img src="{base}assets/app-preview.png" alt="{c['preview']}" width="1060" height="620" fetchpriority="high"><figcaption>{c['preview']}</figcaption></figure>
<section class="story"><article><span class="feature-symbol" aria-hidden="true"><svg viewBox="0 0 32 32"><path d="M3 9a3 3 0 0 1 3-3h7l3 4h10a3 3 0 0 1 3 3v12a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"/><path d="M3 13h26"/></svg></span><h2>{c['nativeTitle']}</h2><p>{c['nativeBody']}</p></article>
<article><span class="feature-symbol" aria-hidden="true"><svg viewBox="0 0 32 32"><path d="m7 11 4-4 4 4M11 7v14M17 21l4 4 4-4M21 25V11"/><path d="M4 28h24"/></svg></span><h2>{c['progressTitle']}</h2><p>{c['progressBody']}</p></article></section>
<section class="agent" id="agents"><div><h2>{c['cliTitle']}</h2><p>{c['agentBody']}</p><p>{c['cliBody']}</p><a href="{REPO}/blob/main/docs/CLI.md">{c['guide']} <span aria-hidden="true">↗</span></a></div>
<div class="terminal"><div class="terminal-label">maf · CLI</div><pre><code id="commands">maf devices
maf status
maf help</code></pre><div class="terminal-actions"><button class="copy" id="copy" data-copied="{c['copied']}">{c['copy']}</button><span class="copy-status" id="copy-status" role="status" aria-live="polite"></span></div></div></section>
<section class="setup" id="guide"><div><h2>{c['startTitle']}</h2><ol class="steps"><li>{c['step1']}</li><li>{c['step2']}</li><li>{c['step3']}</li></ol></div><div><h2>{c['faqTitle']}</h2><details><summary>{c['searchQ']}</summary><p>{c['searchA']}</p></details><details><summary>{c['privacyQ']}</summary><p>{c['privacyA']}</p></details></div></section>
<aside class="release" id="release-status"><h2>{c['statusTitle']}</h2><p>{c['requirements']}. {c['compatibility']}</p><p>{c['statusBody']}</p><a href="{REPO}#build-and-verify">{c['source']} <span aria-hidden="true">↗</span></a></aside></main>
<footer class="footer"><div class="footer-copy"><p class="creator" lang="en" dir="ltr">made by <a href="https://github.com/kimtoma">kimtoma</a> with love &amp; codex</p><p>{c['license']}</p><p>{c['independent']}</p><p class="legal">The Android robot is reproduced or modified from work created and shared by Google and used according to terms described in the <a href="https://creativecommons.org/licenses/by/3.0/">Creative Commons 3.0 Attribution License</a>.</p></div><div class="footer-links"><a href="{REPO}/blob/main/LICENSE">MIT</a><a href="{REPO}/blob/main/THIRD_PARTY_NOTICES.md">CC BY / LGPL</a><a href="{REPO}">GitHub ↗</a></div></footer></div></body></html>'''

for language in LANGUAGES:
 target=SITE/language;target.mkdir(exist_ok=True);(target/'index.html').write_text(render(language)+'\n')
(SITE/'index.html').write_text(render('en',entry=True)+'\n')
(SITE/'sitemap.xml').write_text('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+''.join(f'<url><loc>{URL}/{l}/</loc></url>' for l in LANGUAGES)+'</urlset>\n')
print('Built 13 complete languages with RTL, language URLs and English fallback.')
