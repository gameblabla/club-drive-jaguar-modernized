#!/usr/bin/env python3
"""Independent RMAC/word-offset proof for bnd Car2 BND quad-fan probe."""
from asset_paths import asset_file
import argparse, hashlib, json, struct, subprocess, tempfile
from pathlib import Path
import native_bnd as bnd

def offsets(d):
    data=d['sizes'];s={'dividers':12}
    s['edges']=s['dividers']+data['divider']*4
    s['points']=s['edges']+data['edge']*4
    s['normals']=s['points']+data['point']*6
    s['colors']=s['normals']+data['vector']*6
    s['tris']=s['colors']+data['color']*8
    return s

def check(rmac):
    p=Path(rmac).resolve()
    if not p.is_file():raise FileNotFoundError(p)
    stats=bnd.probe();rel=bnd.MODELS[0]
    old=asset_file(rel);new=bnd.BASE/'probes/CAR2_edited.BND'
    a=bnd.decode(old.read_bytes().decode('latin1'));c=bnd.decode(new.read_bytes().decode('latin1'))
    first=offsets(a);second=offsets(c)
    with tempfile.TemporaryDirectory(prefix='club_bnd_') as dirname:
        folder=Path(dirname);binaries=[]
        for i,source in enumerate((old,new)):
            target=folder/f'{i}.bin'
            r=subprocess.run([str(p),'-fb','-u','-o',str(target),str(source)],cwd=bnd.ROOT,capture_output=True,text=True,timeout=45)
            if r.returncode or not target.is_file():raise RuntimeError('RMAC .BND assembly failure: '+r.stdout+r.stderr)
            binaries.append(target.read_bytes())
    orig,edited=binaries
    if orig[32:44]!=edited[32:44]:raise ValueError('Original 12-byte model origin changed')
    # RMAC -fb adds a 32-byte object wrapper containing the binary length;
    # strip it before comparing native word array offsets.
    # BSD object text section length is stored at bytes 4..7. Symbol tables
    # follow text and legitimately rebase after table growth.
    orig,edited=orig[32:32+struct.unpack_from('>I',orig,4)[0]],edited[32:32+struct.unpack_from('>I',edited,4)[0]]
    if len(orig)!=2638 or len(edited)!=2704:raise ValueError('Unexpected isolated BND assembly sizes')
    if orig[:12]!=edited[:12]:raise ValueError('Original origin data changed')
    for key,end in [('dividers','edges'),('edges','points'),('points','normals'),('normals','colors')]:
        start,endpos=first[key],first[end]
        newstart=second[key]
        if orig[start:endpos]!=edited[newstart:newstart+(endpos-start)]:
            raise ValueError('Original '+key+' native records changed')
    if edited[second['edges']-4:second['edges']]!=struct.pack('>HH',94,31):
        raise ValueError('Appended native divider wrong')
    if edited[second['normals']-6:second['normals']]!=struct.pack('>hhh',0,20,36):
        raise ValueError('Appended native BND point wrong')
    if edited[second['colors']-6:second['colors']]!=struct.pack('>hhh',0,32767,0):
        raise ValueError('Appended native normal wrong')
    if edited[second['points']-16:second['points']]!=struct.pack('>HHHHHHHH',8,95,95,5,7,95,6,95):
        raise ValueError('Appended BND directed edge records wrong')
    if orig[first['colors']:first['tris']]!=edited[second['colors']:second['tris']]:
        raise ValueError('32 original color entries changed')
    oldtris=orig[first['tris']:];newtris=edited[second['tris']:]
    # Both have empty CP0; first CP1 quad is fourteen bytes, the fan 48.
    if oldtris[:2]!=newtris[:2] or oldtris[16:]!=newtris[50:]:
        raise ValueError('BND remaining collision polygons or CP boundaries changed')
    if len(newtris)-len(oldtris)!=34:raise ValueError('BND CP surface growth incorrect')
    if len(edited)-len(orig)!=66:raise ValueError('Expected +66 native bytes')
    report={'scope':'Standalone BND intermediate only. Not linked into ROM; no collision runtime parity claim.',
        'assembler_pass':True,'original_size_bytes':len(orig),'edited_size_bytes':len(edited),
        'size_delta_bytes':66,'native_table_offsets_original':first,'native_table_offsets_edited':second,
        'retained_original_points':len(a['points']),'retained_original_normals':len(a['normals']),
        'retained_color_bytes':first['tris']-first['colors'],'added_edges':4,
        'changed_cp_surface_bytes':34,'plane_area_error':stats['area_difference'],
        'original_sha256':hashlib.sha256(orig).hexdigest(),'edited_sha256':hashlib.sha256(edited).hexdigest()}
    (bnd.BASE/'probes/assembly_validation.json').write_text(json.dumps(report,indent=2)+'\n')
    return report
if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--rmac',required=True)
    args=ap.parse_args();print(json.dumps(check(args.rmac),indent=2))
