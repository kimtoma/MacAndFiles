#!/usr/bin/env python3
"""Explicit-device tests. Writes only UUID fixtures. Raw evidence remains in dist/.
Run with --keep-fixture if a manual cable test will follow; then use --case cleanup.
"""
import argparse, hashlib, json, os, pathlib, selectors, signal, subprocess, time, uuid

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--cli',default='dist/MacAndFiles.app/Contents/MacOS/maf')
parser.add_argument('--device',required=True)
parser.add_argument('--storage',required=True,type=int)
parser.add_argument('--case',choices=['all','basic','large','many','cancel','cable','cleanup'],default='all')
parser.add_argument('--fixture')
parser.add_argument('--keep-fixture',action='store_true')
args=parser.parse_args()
cli=str(pathlib.Path(args.cli).resolve()); base=['--device',args.device,'--storage',str(args.storage)]
fixture=args.fixture or 'AndroidBridge-Test-'+str(uuid.uuid4()).upper()
assert fixture.startswith('AndroidBridge-Test-')
uuid.UUID(fixture.removeprefix('AndroidBridge-Test-'))
root=pathlib.Path('dist/hardware')/fixture;root.mkdir(parents=True,exist_ok=True)
report=json.loads((root/'report.json').read_text()) if (root/'report.json').exists() else {'fixture':fixture,'results':[],'cleanup':'PENDING'}
assert report['fixture']==fixture
report['case']=args.case
report.pop('error',None)

def save(): (root/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
def record(name,**values):
 report['results'].append(dict(case=name,**values));save();print(json.dumps(report['results'][-1],ensure_ascii=False),flush=True)
def call(command,options,*,progress=False,timeout=900):
 label=f'{len(list(root.glob("*.stdout.json"))):03d}-{command}'
 begin=time.monotonic()
 result=subprocess.run([cli,command,*options,*(['--progress'] if progress else [])],capture_output=True,timeout=timeout)
 (root/(label+'.stdout.json')).write_bytes(result.stdout);(root/(label+'.stderr.log')).write_bytes(result.stderr)
 data=json.loads(result.stdout)
 if result.returncode or not data['ok']: raise RuntimeError(f'{command}: {data.get("error")}')
 return data,time.monotonic()-begin

def digest(path):
 h=hashlib.sha256()
 with path.open('rb') as stream:
  for block in iter(lambda:stream.read(8*1024*1024),b''):h.update(block)
 return h.hexdigest()
def local_file(name,size):
 p=root/name
 with p.open('wb') as out:
  out.truncate(size)
  if size:
   out.seek(0);out.write(bytes(range(256))*min(16,size//256))
   out.seek(size-1);out.write(b'\x7f')
 return p

def cleanup():
 helper=pathlib.Path('dist/hardware-cleanup')
 sources=['Sources/MacAndFiles/'+name+'.swift' for name in ['Localization','Types','TransferProgress','DeviceAccess','MTPTransport']]
 subprocess.run(['swiftc','-I','Sources/CLibMTP','-L'+str(pathlib.Path('.build/libraries/prefix/lib').resolve()),*sources,'Tests/HardwareCleanup.swift','-o',str(helper)],check=True)
 result=subprocess.run([str(helper.resolve()),args.device,str(args.storage),fixture],capture_output=True,timeout=900)
 (root/'cleanup.log').write_bytes(result.stdout+result.stderr)
 if result.returncode: raise RuntimeError('Cleanup failed; inspect the isolated fixture and cleanup.log')
 report['cleanup']='PASS';save();print('PASS cleanup confirmed',flush=True)

def basic():
 source=root/'basic';source.mkdir(exist_ok=True)
 (source/'한글 문서.txt').write_text('UTF-8 문서 · MacAndFiles\n')
 (source/'empty.bin').write_bytes(b'')
 nested=source/'한글 폴더';nested.mkdir(exist_ok=True)
 (nested/'binary-5MiB.bin').write_bytes(bytes(range(256))*20480)
 options=base+['--to','/'+fixture]
 for p in [source/'한글 문서.txt',source/'empty.bin',nested]:options+=['--from',str(p.resolve())]
 r,elapsed=call('upload',options,progress=True)
 assert r['result']['transfer']['completedFiles']==3
 destination=root/'basic-received';destination.mkdir(exist_ok=True)
 r,_=call('download',base+['--path','/'+fixture,'--to',str(destination.resolve())],progress=True)
 for relative in ['한글 문서.txt','empty.bin','한글 폴더/binary-5MiB.bin']:
  assert digest(source/relative)==digest(destination/fixture/relative)
 record('basic',result='PASS',files=3,unicode=True,zeroByte=True,sha256Match=True,uploadSeconds=round(elapsed,2))

def large():
 size=4*1024**3+1024**2;p=local_file('large-4GiB-plus.bin',size)
 r,upload=call('upload',base+['--from',str(p.resolve()),'--to','/'+fixture],progress=True)
 assert r['result']['transfer']['totalBytes']==size and r['result']['transfer']['completedFiles']==1
 destination=root/'large-received';destination.mkdir(exist_ok=True)
 r,download=call('download',base+['--path','/'+fixture+'/'+p.name,'--to',str(destination.resolve())],progress=True)
 q=destination/p.name;assert q.stat().st_size==size and digest(p)==digest(q)
 record('large',result='PASS',bytes=size,sha256=digest(q),uploadSeconds=round(upload,2),downloadSeconds=round(download,2))

def many():
 source=root/'small-files';source.mkdir(exist_ok=True)
 for index in range(2000):(source/f'tiny-{index:04d}.bin').write_bytes(f'{index}: 파일\n'.encode()*16)
 r,upload=call('upload',base+['--from',str(source.resolve()),'--to','/'+fixture],progress=True)
 assert r['result']['transfer']['completedFiles']==2000
 destination=root/'many-received';destination.mkdir(exist_ok=True)
 r,download=call('download',base+['--path','/'+fixture+'/small-files','--to',str(destination.resolve())],progress=True)
 assert r['result']['transfer']['completedFiles']==2000
 for p in source.iterdir():assert digest(p)==digest(destination/'small-files'/p.name)
 record('many',result='PASS',files=2000,allHashesMatch=True,uploadSeconds=round(upload,2),downloadSeconds=round(download,2))

def interrupted(command,options,*,cancel):
 label=f'{len(list(root.glob("*.stdout.json"))):03d}-{command}-interrupted'
 log=root/(label+'.stderr.log');stdout=root/(label+'.stdout.json')
 with stdout.open('wb') as out,log.open('wb') as err:
  process=subprocess.Popen([cli,command,*options,'--progress'],stdout=out,stderr=subprocess.PIPE)
  reader=selectors.DefaultSelector();reader.register(process.stderr,selectors.EVENT_READ)
  started=False;sent=False;deadline=time.monotonic()+180
  try:
   while process.poll() is None:
    if time.monotonic()>deadline:process.send_signal(signal.SIGINT);raise RuntimeError('Interrupted test timed out')
    for key,_ in reader.select(timeout=.5):
     line=key.fileobj.readline()
     if not line:continue
     err.write(line);err.flush()
     try:event=json.loads(line)
     except (ValueError,UnicodeDecodeError):continue
     if event.get('transferredBytes',0)>=1024**2:
      started=True
      if cancel and not sent:process.send_signal(signal.SIGINT);sent=True
      elif not cancel and not sent:print('CABLE_DISCONNECT_READY: active bytes observed; unplug the USB cable now.',flush=True);sent=True
   remainder=process.stderr.read();err.write(remainder);process.wait(timeout=30)
  finally:
   reader.close()
   if process.poll() is None:process.send_signal(signal.SIGINT);process.wait(timeout=60)
 data=json.loads(stdout.read_bytes())
 assert started,'No actual streaming bytes observed; not a mid-transfer test'
 assert not data['ok'] and process.returncode!=0,(command,data)
 if cancel:assert process.returncode==130 and data['error']['code']=='cancelled'
 assert data.get('transfer',{}).get('completedFiles',0)==0
 return data

def cancel():
 p=local_file('cancel.bin',1024**3)
 r=interrupted('upload',base+['--from',str(p.resolve()),'--to','/'+fixture],cancel=True)
 record('cancel-upload',result='PASS',exitCode=r['error']['exitCode'],partialAndroidFilePossible=r['androidPartialFilesPossible'])
 destination=root/'cancel-received';destination.mkdir(exist_ok=True)
 r=interrupted('download',base+['--path','/'+fixture+'/large-4GiB-plus.bin','--to',str(destination.resolve())],cancel=True)
 assert list(destination.iterdir())==[]
 record('cancel-download',result='PASS',exitCode=r['error']['exitCode'],temporaryCleaned=True)

def cable():
 destination=root/'cable-received';destination.mkdir(exist_ok=True)
 r=interrupted('download',base+['--path','/'+fixture+'/large-4GiB-plus.bin','--to',str(destination.resolve())],cancel=False)
 assert list(destination.iterdir())==[]
 record('cable-disconnect-download',result='PASS',code=r['error']['code'],temporaryCleaned=True)

created=False
try:
 if args.case=='cleanup':cleanup()
 else:
  r,_=call('storages',['--device',args.device]);report['deviceModel']=r['result']['device']['name']
  selected=next(s for s in r['result']['storages'] if s['id']==args.storage)
  if args.case in ['all','large']:assert selected['freeBytes']>6*1024**3,'At least 6 GiB free space required'
  if not args.fixture:call('mkdir',base+['--path','/'+fixture]);created=True;save()
  for name in (['basic','large','many','cancel'] if args.case=='all' else [args.case]):globals()[name]()
except BaseException as error:
 report['error']=str(error);save();raise
finally:
 if args.case!='cleanup' and not args.keep_fixture and (created or args.fixture):
  try:cleanup()
  except Exception as error:report['cleanup']=str(error);save();print('Fixture may remain:',fixture,flush=True)
print('Evidence:',root/'report.json',flush=True)
