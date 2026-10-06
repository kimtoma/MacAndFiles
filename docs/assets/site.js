'use strict';
const language=document.querySelector('#language');
const base=document.body.dataset.base;
const supported=[...language.options].map(option=>option.value);
language.addEventListener('change',()=>{
  const value=language.value;
  if(!supported.includes(value))return;
  try{localStorage.setItem('maf-language',value)}catch{}
  location.assign(new URL(`${base}${value}/`,location.href));
});
if(document.body.dataset.entry==='true'){
  let preferred;
  try{preferred=localStorage.getItem('maf-language')}catch{}
  if(!supported.includes(preferred)){
    const choices=navigator.languages||[navigator.language];
    preferred=choices.map(value=>{
      if(/^zh-(TW|HK|MO|Hant)/i.test(value))return 'zh-Hant';
      if(/^zh/i.test(value))return 'zh-Hans';
      if(/^pt/i.test(value))return 'pt-BR';
      return value.split('-')[0];
    }).find(value=>supported.includes(value))||'en';
  }
  location.replace(new URL(`${base}${preferred}/`,location.href));
}
const copy=document.querySelector('#copy');
if(!navigator.clipboard){copy.hidden=true}else{
  copy.addEventListener('click',async()=>{
    try{
      await navigator.clipboard.writeText(document.querySelector('#commands').textContent);
      document.querySelector('#copy-status').textContent=copy.dataset.copied;
    }catch{copy.hidden=true}
  });
}
