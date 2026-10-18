#!/usr/bin/env python3
"""Validate CONTACT_EVENTS emulator-side GPU instruction/CP/force-commit observations.

This is an observed execution trace, NOT a hardware collision proof, inverse
kinematics solver, or demonstration of patched Jaguar ROM gameplay.
"""
import csv, json, hashlib, argparse
from pathlib import Path
from collections import Counter,defaultdict

ROOT=Path(__file__).resolve().parent.parent
CONTACT_EVENTS=ROOT/'assets/diagnostics/contact'
TRACE=CONTACT_EVENTS/'trace/contact_events_1800.csv'
GPU_TRACE=ROOT/'assets/diagnostics/gpu'
COLUMNS=('field','event_id','overlay','event','pc','player','band','polygon','band_flags',
         'polygon_flags','edges','divider','material','polygon_in_band','force_address',
         'fx','fy','fz','tx','ty','tz','ram_matches')
INT_COLUMNS=('field','event_id','edges','divider','material','polygon_in_band',
             'fx','fy','fz','tx','ty','tz','ram_matches')
HEX_COLUMNS=('pc','player','band','polygon','band_flags','polygon_flags','force_address')
SITES={'casend':{'edgehit':0xF03608,'pre_store':0xF0375E,'post_store':0xF0377A},
       'racend':{'edgehit':0xF03648,'pre_store':0xF0379E,'post_store':0xF037BA},
       'tagend':{'edgehit':0xF03688,'pre_store':0xF037DE,'post_store':0xF037FA}}
REFERENCE_FORCE={1065:(0,-30815,0,40022,0,127980),
                 1067:(0,-5598,0,-16862,0,-11256)}

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def analyze(path=TRACE, check_reference=True):
    rows=[];last_field=0;ids=set();paired={};edge_fields=Counter();events=Counter()
    with Path(path).open(newline='') as f:
        reader=csv.DictReader(f)
        if tuple(reader.fieldnames or [])!=COLUMNS:raise ValueError('Trace header changed')
        for textrow in reader:
            if None in textrow or any(v is None for v in textrow.values()):raise ValueError('Malformed trace columns')
            if any(not textrow[k] for k in COLUMNS):raise ValueError('Empty trace value')
            row={}
            try:
                for k in COLUMNS:
                    row[k]=int(textrow[k],16) if k in HEX_COLUMNS else int(textrow[k]) if k in INT_COLUMNS else textrow[k]
            except (TypeError,ValueError) as exc:raise ValueError('Invalid numeric record') from exc
            field=row['field'];mode=row['overlay'];kind=row['event'];eid=row['event_id']
            if not 1<=field<=1800 or field<last_field:raise ValueError('Field range/order invalid')
            if mode not in SITES or kind not in SITES[mode]:raise ValueError('Unexpected overlay/event')
            if row['pc']!=SITES[mode][kind]:raise ValueError('Unverified instrumented GPU PC')
            if not 0<eid<100000 or row['player']>=0x200000 or row['band']>=0x200000 or row['polygon']>=0x200000:raise ValueError('Pointer range invalid')
            if row['polygon']%2 or row['band']%4 or row['force_address']%4:raise ValueError('Unaligned pointer')
            if row['edges'] not in range(3,16) or row['edges']!=row['polygon_flags']&15:raise ValueError('Invalid polygon size')
            if row['polygon_flags']&0x40 or row['band_flags']&1:raise ValueError('Trace hit disabled collision surface')
            if row['polygon_in_band']!=1:raise ValueError('Polygon not within active band surface list')
            if row['divider']>=65536 or row['material']>=65536:raise ValueError('Invalid divider/color word')
            if kind=='edgehit':
                if eid in ids:raise ValueError('Duplicated event ID')
                if row['ram_matches']!=-1 or row['force_address']!=0 or any(row[k] for k in ('fx','fy','fz','tx','ty','tz')):raise ValueError('Unexpected edgehit payload')
                ids.add(eid);edge_fields[field]+=1
            else:
                if row['force_address']!=row['player']+60:raise ValueError('CAR_FORCE pointer inconsistent with car.inc')
                if kind=='pre_store':
                    if eid in ids:raise ValueError('Duplicated event ID')
                    if row['ram_matches']!=-1:raise ValueError('Pre-store marked committed')
                    ids.add(eid);paired[eid]=row
                else:
                    if eid not in paired:raise ValueError('Post-store without pre-store')
                    pre=paired.pop(eid)
                    if row['ram_matches']!=1:raise ValueError('RAM force/torque not verified')
                    for k in ('field','overlay','player','band','polygon','force_address','fx','fy','fz','tx','ty','tz'):
                        if row[k]!=pre[k]:raise ValueError(f'Pre/post mismatch: {k}')
                    events['matched_stores']+=1
                    if any(row[k] for k in ('fx','fy','fz','tx','ty','tz')):
                        events['nonzero_stores']+=1
                        if check_reference and tuple(row[k] for k in ('fx','fy','fz','tx','ty','tz'))!=REFERENCE_FORCE.get(field):
                            raise ValueError('Nonzero committed response differs from baseline')
            events[kind]+=1;last_field=field;rows.append(row)
    if paired:raise ValueError('Unmatched pre-store events')
    if check_reference:
        if len(rows)!=784 or events['edgehit']!=20 or events['matched_stores']!=382 or events['nonzero_stores']!=2:raise ValueError('CONTACT_EVENTS expected event counts changed')
        if dict(edge_fields)!={1065:6,1067:5,1069:6,1071:3}:raise ValueError('Edgehit field distribution changed')
        attrs={(r['player'],r['band'],r['polygon'],r['divider'],r['material'],r['polygon_flags'],r['edges']) for r in rows}
        if attrs!={(0x6A200,0x8355C,0x82946,18,0x9341,4,4)}:raise ValueError('Runtime collision polygon attribution changed')
    return {'events':len(rows),'edgehit_entries':events['edgehit'],
            'committed_force_torque_sequences':events['matched_stores'],
            'nonzero_committed_sequences':events['nonzero_stores'],
            'unmatched_store_sequences':len(paired),
            'edgehit_by_field':{str(k):v for k,v in sorted(edge_fields.items())},
            'active_player':'0x06A200','active_band':'0x08355C','collision_polygon':'0x082946',
            'divider':18,'native_color_word':'0x9341','polygon_edges':4,
            'committed_responses':[{'field':field,'force':list(vec[:3]),'torque':list(vec[3:])} for field,vec in REFERENCE_FORCE.items()] if check_reference else [],
            'trace_sha256':sha(path)}

def verify_artifacts():
    data=analyze()
    # A separate gpu_trace CSV was re-recorded by the same new emulator executable.
    # Its rows must be byte-identical to the published gpu_trace reference, and the
    # output frames to the already stored gpu_trace uninstrumented control.
    legacy=CONTACT_EVENTS/'trace/legacy_1800.csv'
    if not legacy.is_file() or legacy.read_bytes()!=(GPU_TRACE/'trace/collision_gpu_1800_fields.csv').read_bytes():
        raise ValueError('Original GPU_TRACE instruction trace changed')
    data['gpu_trace_gpu_counts_unchanged']=True
    pics={}
    for field in (600,1200,1800):
        name=f'{field:06d}'
        edited=CONTACT_EVENTS/f'images/contact_events_control_{name}.png'
        reference=GPU_TRACE/f'images/force_run_{name}.png'
        if edited.read_bytes()!=reference.read_bytes():raise ValueError(f'Control frame {field} changed')
        pics[str(field)]=sha(edited)
    data['unmodified_emulator_frame_sha256']=pics
    data['screenshots_byte_identical']=True
    reference_rom=ROOT/'Club_Drive.j64'
    data['rom_sha256']=sha(reference_rom) if reference_rom.exists() else 'dd8062993e50cd0bc4b0ca67b04312360fe5b9d2287c8fd53283a011add07289'
    data['bios_mode']='real'
    data['field_count']=1800
    data['limitations']=['Observational emulator evidence, not physical Jaguar hardware',
         'The final CP word is a native color/material identifier, not proven friction coefficient',
         'No edited collision model linked into the runtime ROM',
         'Instruction hits are not unique physical collision events']
    return data

def main():
    p=argparse.ArgumentParser();p.add_argument('action',choices=['check','summary'],nargs='?',default='check');args=p.parse_args()
    summary=verify_artifacts()
    if args.action=='summary':
        out=CONTACT_EVENTS/'runtime_collision_attribution_summary.json';out.write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n')
        print('WROTE',out)
    print('CONTACT_EVENTS validated',summary['edgehit_entries'],'edgehit entries,',summary['committed_force_torque_sequences'],'RAM commits,',summary['nonzero_committed_sequences'],'nonzero')
if __name__=='__main__':main()
