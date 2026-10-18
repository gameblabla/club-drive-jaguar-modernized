from pathlib import Path
import subprocess,json,os,shutil
mods='adjblack uncomp lighten cross fade gpunzip comp precomp ren preren casbeg racbeg tagbeg casend racend tagend 3d gpustud gpuhouse gpugara gpucity'.split()
res=[]
for m in mods:
 p=Path(m.lower()+'.gas')
 if not p.exists(): continue
 rmac=os.path.join(os.environ.get('JAGSDK', '../jaguar-sdk-linux-x86_64'),'tools/bin/rmac')
 if not os.path.exists(rmac):rmac=shutil.which('rmac') or 'rmac'
 c=[rmac,'-dCOMPAT=0','-mtom','-fr','-icompat_include','-o',f'build/gpu/{m}.bin',str(p)]
 r=subprocess.run(c,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=60)
 result=dict(module=m,ok=r.returncode==0,returncode=r.returncode,errors=r.stdout[:3000]);res.append(result)
 print(m,r.returncode,(Path(f'build/gpu/{m}.bin').stat().st_size if result['ok'] else 0),r.stdout.replace('\n',' / ')[:230],flush=True)
Path('build/gpu_results.json').write_text(json.dumps(res,indent=2))
