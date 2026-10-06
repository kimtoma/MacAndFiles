#!/usr/bin/env python3
import html.parser, json, pathlib, re, subprocess
ROOT=pathlib.Path(__file__).resolve().parent.parent
subprocess.run(['python3',str(ROOT/'scripts/build-site.py')],check=True)
class Page(html.parser.HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=[];self.lang=None;self.dir=None;self.headings=0;self.options=0
 def handle_starttag(self,tag,attributes):
  attrs=dict(attributes)
  if tag=='html':self.lang=attrs.get('lang');self.dir=attrs.get('dir')
  if tag=='h1':self.headings+=1
  if tag=='option':self.options+=1
  if 'id' in attrs:self.ids.append(attrs['id'])
  if tag in ['link','a','script','img']:
   target=attrs.get('href',attrs.get('src'))
   if target:self.links.append(target)
reference=json.loads((ROOT/'website/locales/en.json').read_text())
for source in (ROOT/'website/locales').glob('*.json'):
 language=source.stem;translated=json.loads(source.read_text());assert set(translated)==set(reference)
 for key,value in translated.items():assert value.strip() and '<script' not in value
 target=ROOT/'docs'/language/'index.html';page=Page();page.feed(target.read_text())
 assert page.lang==language and page.dir==('rtl' if language=='ar' else 'ltr')
 assert page.headings==1 and page.options==13 and len(page.ids)==len(set(page.ids))
 for link in page.links:
  if link.startswith(('https://','http://','#')):continue
  destination=target.parent/link.split('#')[0]
  assert destination.exists(),(language,link)
 assert target.read_text().count('rel="alternate"')==14
 print('PASS',language,'complete copy, language links, assets, canonical and RTL')
assert (ROOT/'docs/.nojekyll').exists()
print('13 site language scenarios passed')
