import pathlib,subprocess,json,os,shutil
mods='game sys input title select credits hiscore eeprim sound tables remote play mkmat blit gpufix playinp td modem readjoy playdata mktp alloc lattice inflate packet art'.split()
base=pathlib.Path('.')
root=pathlib.Path(os.environ.get('JAGSDK', '../jaguar-sdk-linux-x86_64'))/'tools/bin/rmac'
if not root.exists(): root=pathlib.Path(shutil.which('rmac') or 'rmac')
entries=[]
for m in mods:
 p=pathlib.Path('ART.S' if m.lower()=='art' else m.lower()+'.s')
 if not p.exists(): entries.append({'module':m,'error':'missing .S'});continue
 cmd=[str(root),'-dCOMPAT=0','-fb','-u',*(['+o2'] if m in ('mktp','alloc','inflate') else []),'-icompat_include','-o',str(pathlib.Path('build/obj')/(m+'.o')),str(p)]
 result=subprocess.run(cmd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=50)
 entries.append({'module':m,'ok':result.returncode==0,'returncode':result.returncode,'errors':result.stdout[:1200]})
 print(m,result.returncode,result.stdout[:200].replace('\n',' / '),flush=True)
pathlib.Path('build/assembly_results.json').write_text(json.dumps(entries,indent=2))
