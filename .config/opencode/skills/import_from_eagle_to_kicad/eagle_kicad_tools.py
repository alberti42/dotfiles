#!/usr/bin/env python3
"""eagle_kicad_tools — helpers for importing an Autodesk Eagle design into KiCad.

Stdlib only (xml.etree, re, math, json, argparse). Two kinds of commands:

  ANALYSIS (read-only, safe to run anytime):
    summary <file.sch>                       Eagle version / sheets / parts / libraries
    outline-layer <file.brd>                 find the board-edge layer (Outline vs Dimension trap)
    layer-scan <file.brd>                    every layer carrying graphics -> drives the layer map
    propose-layer-map <file.brd>             populated layers + a suggested KiCad association scheme
                                             (outline->Edge.Cuts, standard layers, leftovers->User.n
                                             with a meaningful name + KiCad layer type) for approval
    refint <file.sch>                        parts whose library/deviceset/device doesn't resolve
    nonascii <file.sch>                      non-ASCII chars + line numbers
    pad-positions <file.kicad_pcb> [--ref R] absolute pad coords (handles footprint rotation)
    solve-transform <file.brd> <file.kicad_pcb>   derive Eagle->KiCad placement transform
    paren-check <file>                       '(' vs ')' balance (sanity after manual edits)

  EDIT (mutate a file IN PLACE — commit/back up first; prints paren balance after):
    bisect <file.sch> <N> <out.sch>          keep only the first N sheets (localize import failure)
    set-pad-net <pcb> --ref R --pad P --net NET     give a blank fine-pitch pad its net
    remove-block <pcb> --head '(segment' --contains S [S ...]   delete matching S-expr block(s)
    ignore-severities <pcb_pro.kicad_pro> --rules a,b,c          set rule_severities -> ignore
    name-user-layers <pcb> --map "User.1|front|Name;User.2|back|Name;User.3|user|Name"
                                             rename/retype the User.n rows in the (layers ...) section
                                             (type = user|front|back = Auxiliary/Off-board front/back)

See SKILL.md for when to use each. Coordinates are mm. KiCad files are S-expressions; the edit
helpers manipulate text and keep parentheses balanced rather than depending on a KiCad install.
"""
import argparse, json, math, re, sys
import xml.etree.ElementTree as ET


# ----------------------------------------------------------------------------- ANALYSIS
def summary(sch_path):
    r = ET.parse(sch_path).getroot()
    sch = r.find('.//schematic')
    libs = [l.get('name') for l in sch.find('libraries').findall('library')]
    sheets = sch.find('sheets').findall('sheet')
    parts = sch.find('parts').findall('part')
    print(f"eagle version : {r.get('version')}")
    print(f"sheets        : {len(sheets)}")
    print(f"parts         : {len(parts)}")
    print(f"libraries     : {libs}")
    for i, sh in enumerate(sheets, 1):
        nets = sh.find('nets'); buss = sh.find('busses')
        print(f"  sheet {i}: nets={len(nets.findall('net')) if nets is not None else 0} "
              f"busses={len(buss.findall('bus')) if buss is not None else 0}")


def outline_layer(brd_path):
    """The board edge is the layer whose <plain> wires span the whole board.
    Often a custom 'Outline' (e.g. 120), NOT 'Dimension' (20). Map IT to Edge.Cuts."""
    r = ET.parse(brd_path).getroot()
    names = {L.get('number'): L.get('name') for L in r.iter('layer')}
    plain = r.find('.//board/plain')
    from collections import Counter, defaultdict
    cnt = Counter(); ext = defaultdict(lambda: [1e9, -1e9, 1e9, -1e9])
    for w in plain.findall('wire'):
        L = w.get('layer'); cnt[L] += 1
        for x in (float(w.get('x1')), float(w.get('x2'))):
            ext[L][0] = min(ext[L][0], x); ext[L][1] = max(ext[L][1], x)
        for y in (float(w.get('y1')), float(w.get('y2'))):
            ext[L][2] = min(ext[L][2], y); ext[L][3] = max(ext[L][3], y)
    rows = []
    for L, n in cnt.items():
        e = ext[L]; rows.append((e[1]-e[0], e[3]-e[2], L, names.get(L, '?'), n))
    rows.sort(key=lambda t: -(t[0]*t[1]))
    print(f"{'layer':>5} {'name':<14} {'wires':>5}  {'W':>7} {'H':>7}")
    for w, h, L, nm, n in rows:
        flag = '  <-- likely BOARD OUTLINE -> Edge.Cuts' if (w, h) == (rows[0][0], rows[0][1]) else ''
        print(f"{L:>5} {nm:<14} {n:>5}  {w:>7.2f} {h:>7.2f}{flag}")


def layer_scan(brd_path):
    """Every Eagle layer carrying a drawable element. Map each (or park on User.n) so the
    board import is warning-free (no 'Ignoring a wire ... not mapped')."""
    from collections import Counter
    r = ET.parse(brd_path).getroot()
    names = {L.get('number'): L.get('name') for L in r.iter('layer')}
    use = Counter()
    for tag in ('wire', 'text', 'rectangle', 'polygon', 'circle', 'dimension', 'frame'):
        for e in r.iter(tag):
            if e.get('layer'):
                use[e.get('layer')] += 1
    print(f"{'layer':>5} {'name':<14} {'#elems':>7}")
    for L, c in sorted(use.items(), key=lambda kv: -kv[1]):
        print(f"{L:>5} {names.get(L, '?'):<14} {c:>7}")


# Eagle layer name (lowercased) -> standard KiCad layer (no User.n parking needed)
_STD_MAP = {
    'top': 'F.Cu', 'bottom': 'B.Cu',
    'tstop': 'F.Mask', 'bstop': 'B.Mask',
    'tcream': 'F.Paste', 'bcream': 'B.Paste',
    'tnames': 'F.Silkscreen', 'bnames': 'B.Silkscreen',
    'tplace': 'F.Silkscreen', 'bplace': 'B.Silkscreen',
    'tvalues': 'F.Fab', 'bvalues': 'B.Fab',
    'tdocu': 'F.Fab', 'bdocu': 'B.Fab',
    'tglue': 'F.Adhesive', 'bglue': 'B.Adhesive',
    'tkeepout': 'F.Courtyard', 'bkeepout': 'B.Courtyard',
    'unrouted': 'User.Drawings',
    'dxf': 'User.Comments', 'reference': 'User.Comments', 'document': 'User.Comments',
}


def _detect_outline(root):
    """Layer number whose <plain> wires have the largest bounding box (the real board edge)."""
    from collections import defaultdict
    plain = root.find('.//board/plain')
    if plain is None:
        return None
    ext = defaultdict(lambda: [1e9, -1e9, 1e9, -1e9])
    for w in plain.findall('wire'):
        L = w.get('layer')
        for x in (float(w.get('x1')), float(w.get('x2'))):
            ext[L][0] = min(ext[L][0], x); ext[L][1] = max(ext[L][1], x)
        for y in (float(w.get('y1')), float(w.get('y2'))):
            ext[L][2] = min(ext[L][2], y); ext[L][3] = max(ext[L][3], y)
    if not ext:
        return None
    return max(ext.items(), key=lambda kv: (kv[1][1]-kv[1][0]) * (kv[1][3]-kv[1][2]))[0]


def _classify_leftover(en):
    """Suggest (kicad_type, descriptive_name) for an Eagle layer with no standard KiCad equivalent.
    type is 'user' (Auxiliary, no side), 'front' (Off-board front) or 'back' (Off-board back)."""
    low = en.lower()
    side = 'front' if low.startswith('t') else 'back' if low.startswith('b') else 'user'
    if 'restrict' in low:                       # copper keepout
        return side, f'{en}.Keepout'
    if 'nocream' in low or 'nopaste' in low or 'nostop' in low:   # no-paste / no-mask region
        return side, en
    if 'measure' in low:
        return 'user', 'Measures.Dims'
    if 'descript' in low or 'docu' in low:
        return 'user', 'Descript.Text'
    return 'user', re.sub(r'[^A-Za-z0-9._]', '_', en) or 'Aux'


def propose_layer_map(brd_path):
    """List every populated Eagle layer and propose a KiCad association scheme:
    outline -> Edge.Cuts, standard layers by _STD_MAP, and every leftover parked on a User.n layer
    with a suggested name + type. Prints a ready-to-apply `name-user-layers --map` string.
    The user must approve (and may rename) the scheme before the import / before applying."""
    from collections import Counter
    r = ET.parse(brd_path).getroot()
    names = {L.get('number'): L.get('name') for L in r.iter('layer')}
    use = Counter()
    for tag in ('wire', 'text', 'rectangle', 'polygon', 'circle', 'dimension', 'frame'):
        for e in r.iter(tag):
            if e.get('layer'):
                use[e.get('layer')] += 1
    outline = _detect_outline(r)
    print(f"{'#':>4} {'eagle':<14} {'elems':>5}  -> proposed KiCad target")
    user_idx = 0
    entries = []
    for L, c in sorted(use.items(), key=lambda kv: int(kv[0])):
        en = names.get(L, '?'); low = en.lower()
        if L == outline:
            target = 'Edge.Cuts   (detected board outline)'
        elif low in _STD_MAP:
            target = _STD_MAP[low]
        elif low == 'dimension':
            target = 'Edge.Cuts   (VERIFY: may be connector body marks, not the edge)'
        else:
            user_idx += 1
            typ, nm = _classify_leftover(en)
            ul = f'User.{user_idx}'
            target = f'{ul}   type={typ}  name="{nm}"'
            entries.append(f'{ul}|{typ}|{nm}')
        print(f"{L:>4} {en:<14} {c:>5}  -> {target}")
    print("\nLeftover layers have no standard KiCad equivalent and are parked on User.n.")
    print("Get the user's approval of names + types, then AFTER the import apply them with:")
    print(f'  name-user-layers <f.kicad_pcb> --map "{";".join(entries) or "(none)"}"')


def refint(sch_path):
    """Parts whose library/deviceset/device cannot be resolved — a dangling ref can crash the
    schematic converter (a likely culprit when the import silently produces no .kicad_sch)."""
    r = ET.parse(sch_path).getroot(); sch = r.find('.//schematic')
    libs = {l.get('name'): l for l in sch.find('libraries').findall('library')}
    bad = []
    for p in sch.find('parts').findall('part'):
        L = libs.get(p.get('library'))
        ds = None
        if L is not None:
            ds = next((d for d in L.find('devicesets').findall('deviceset')
                       if d.get('name') == p.get('deviceset')), None)
        devs = [x.get('name') for x in ds.find('devices').findall('device')] if ds is not None else None
        if ds is None or (p.get('device') or '') not in (devs or []):
            bad.append((p.get('name'), p.get('library'), p.get('deviceset'), p.get('device')))
    print(f"unresolved parts: {len(bad)}")
    for b in bad:
        print("  ", b)


def nonascii(sch_path):
    n = 0
    for i, line in enumerate(open(sch_path, encoding='utf-8'), 1):
        if any(ord(c) > 127 for c in line):
            n += 1
            print(f"{i}: {line.rstrip()}")
    print(f"--- {n} line(s) with non-ASCII ---")


def _rot(px, py, deg):
    a = math.radians(deg)
    return (px*math.cos(a) - py*math.sin(a), px*math.sin(a) + py*math.cos(a))


def pad_abs_positions(pcb_text, ref_filter=None):
    out = []
    for m in re.finditer(r'\(footprint "[^"]+"\n((?:(?!\n\t\(footprint ).)*?)\n\t\)\n', pcb_text, re.S):
        blk = m.group(0)
        fat = re.search(r'\n\t\t\(at ([\-0-9.]+) ([\-0-9.]+)(?: ([\-0-9.]+))?\)', blk)
        ref = re.search(r'\(property "Reference" "([^"]+)"', blk)
        if not fat or not ref:
            continue
        r = ref.group(1)
        if ref_filter and r != ref_filter:
            continue
        fx, fy, fr = float(fat.group(1)), float(fat.group(2)), float(fat.group(3) or 0)
        for ch in re.split(r'\n\t\t\(pad ', blk)[1:]:
            nm = ch.split('"')[1]
            at = re.search(r'\(at ([\-0-9.]+) ([\-0-9.]+)', ch)
            net = re.search(r'\(net "([^"]*)"\)', ch)
            if not at:
                continue
            rx, ry = _rot(float(at.group(1)), float(at.group(2)), fr)
            out.append((r, nm, fx+rx, fy+ry, net.group(1) if net else None))
    return out


def pad_positions(pcb_path, ref=None):
    for r, nm, x, y, net in pad_abs_positions(open(pcb_path).read(), ref):
        print(f"{r}.{nm:<4} ({x:.4f}, {y:.4f}) net={net}")


def solve_transform(brd_path, pcb_path):
    """Match component placements between the .brd and the imported .kicad_pcb to derive
    kx = ex + dx, ky = OY - ey (Eagle Y is flipped). Useful only if the importer DROPPED the
    outline and you must rebuild it; with a correct Outline->Edge.Cuts mapping you won't need it."""
    bel = {e.get('name'): (float(e.get('x')), float(e.get('y')))
           for e in ET.parse(brd_path).getroot().iter('element')}
    kpos = {}
    for m in re.finditer(r'\(footprint "[^"]+"\n((?:(?!\n\t\(footprint ).)*?)\n\t\)\n',
                         open(pcb_path).read(), re.S):
        blk = m.group(0)
        ref = re.search(r'\(property "Reference" "([^"]+)"', blk)
        at = re.search(r'\n\t\t\(at ([\-0-9.]+) ([\-0-9.]+)', blk)
        if ref and at:
            kpos[ref.group(1)] = (float(at.group(1)), float(at.group(2)))
    common = sorted(set(bel) & set(kpos))
    if not common:
        print("no shared references"); return
    dxs = [kpos[r][0] - bel[r][0] for r in common]
    oys = [kpos[r][1] + bel[r][1] for r in common]
    dx = sum(dxs)/len(dxs); oy = sum(oys)/len(oys)
    print(f"matched {len(common)} refs")
    print(f"kx = ex + {dx:.4f}")
    print(f"ky = {oy:.4f} - ey   (Eagle Y flipped)")
    print(f"residuals: dx range [{min(dxs):.4f},{max(dxs):.4f}]  OY range [{min(oys):.4f},{max(oys):.4f}]")


def paren_check(path):
    t = open(path).read()
    bal = t.count('(') - t.count(')')
    print(f"paren balance: {bal}" + ("  OK" if bal == 0 else "  !!! UNBALANCED"))
    return bal


# ----------------------------------------------------------------------------- EDIT
def _report(path, text):
    open(path, 'w').write(text)
    bal = text.count('(') - text.count(')')
    print(f"wrote {path}  (paren balance {bal}{' OK' if bal == 0 else ' !!! UNBALANCED'})")


def bisect(sch_path, keep_n, out_path):
    root = ET.parse(sch_path).getroot()
    sheets_el = root.find('.//schematic/sheets')
    sheets = sheets_el.findall('sheet')
    for s in sheets[keep_n:]:
        sheets_el.remove(s)
    ET.ElementTree(root).write(out_path, encoding='utf-8', xml_declaration=True)
    data = open(out_path, encoding='utf-8').read()
    if '<!DOCTYPE' not in data:
        data = data.replace('<eagle', '<!DOCTYPE eagle SYSTEM "eagle.dtd">\n<eagle', 1)
        open(out_path, 'w', encoding='utf-8').write(data)
    print(f"wrote {out_path} with {keep_n} sheet(s)")


def remove_blocks(text, head, must_contain):
    """Indentation-proof removal of S-expr blocks starting with `head` (e.g. '(segment',
    '(fp_line', '(gr_line') whose body contains every string in `must_contain`. Paren-depth based."""
    lines = text.split('\n'); out = []; i = 0; removed = 0
    while i < len(lines):
        if lines[i].lstrip().startswith(head):
            depth = 0; j = i; block = []
            while j < len(lines):
                block.append(lines[j]); depth += lines[j].count('(') - lines[j].count(')')
                if depth <= 0 and j > i:
                    break
                j += 1
            if all(s in '\n'.join(block) for s in must_contain):
                removed += 1; i = j + 1; continue
            out.extend(block); i = j + 1; continue
        out.append(lines[i]); i += 1
    return '\n'.join(out), removed


def _footprint_block(text, ref):
    for m in re.finditer(r'\(footprint "[^"]+"\n(?:(?!\n\t\(footprint ).)*?\n\t\)\n', text, re.S):
        if f'(property "Reference" "{ref}"' in m.group(0):
            return m.group(0)
    return None


def set_pad_net(pcb_path, ref, pad, net):
    text = open(pcb_path).read()
    blk = _footprint_block(text, ref)
    if blk is None:
        sys.exit(f"footprint {ref} not found")
    lines = blk.split('\n'); out = []; i = 0; done = False
    while i < len(lines):
        if lines[i].lstrip().startswith(f'(pad "{pad}"'):
            depth = 0; j = i; pb = []
            while j < len(lines):
                pb.append(lines[j]); depth += lines[j].count('(') - lines[j].count(')')
                if depth <= 0 and j > i:
                    break
                j += 1
            if '(net "' in '\n'.join(pb):
                print(f"pad {ref}.{pad} already has a net; leaving unchanged")
            else:
                indent = '\t' * ((len(pb[0]) - len(pb[0].lstrip())) + 1)
                pb.insert(len(pb) - 1, f'{indent}(net "{net}")')
                done = True
            out.extend(pb); i = j + 1; continue
        out.append(lines[i]); i += 1
    if not done:
        print(f"no insertion made for pad {ref}.{pad}")
        return
    newblk = '\n'.join(out)
    _report(pcb_path, text.replace(blk, newblk))
    print(f"  set {ref}.{pad} -> net {net}")


def cmd_remove_block(pcb_path, head, contains):
    text = open(pcb_path).read()
    new, n = remove_blocks(text, head, contains)
    print(f"removed {n} block(s) matching head={head!r} contains={contains}")
    _report(pcb_path, new)


def ignore_severities(pro_path, rules):
    lines = open(pro_path).read().split('\n'); changed = []
    for i, l in enumerate(lines):
        for k in rules:
            if f'"{k}":' in l:
                ind = l[:len(l) - len(l.lstrip())]
                comma = ',' if l.rstrip().endswith(',') else ''
                lines[i] = f'{ind}"{k}": "ignore"{comma}'; changed.append(k)
    out = '\n'.join(lines)
    json.loads(out)  # validate
    open(pro_path, 'w').write(out)
    print(f"set ignore: {sorted(set(changed))}  (JSON valid)")


def name_user_layers(pcb_path, map_str):
    """Rewrite the User.n rows in the (layers ...) section, e.g. (39 "User.1" user) ->
    (39 "User.1" front "tRestrict.Keepout.Top"). map_str = 'User.1|front|Name;User.2|back|Name;...'
    type is user (Auxiliary) | front (Off-board front) | back (Off-board back).
    NOTE: front/back is a documentation label only — it has no fab effect; real paste/copper layers
    are F.Paste/B.Paste/F.Cu/B.Cu."""
    entries = []
    for part in map_str.split(';'):
        part = part.strip()
        if not part:
            continue
        bits = [b.strip() for b in part.split('|')]
        if len(bits) != 3:
            sys.exit(f"bad map entry {part!r} — want 'User.N|type|name'")
        entries.append(bits)
    text = open(pcb_path).read()
    if '(layers' not in text:
        sys.exit("no (layers ...) section found")
    applied = []
    for label, typ, name in entries:
        if typ not in ('user', 'front', 'back'):
            sys.exit(f"bad type {typ!r} for {label} — use user|front|back")
        pat = re.compile(r'(\(\d+ "%s" )(?:user|front|back|signal|power|mixed|jumper)(?: "[^"]*")?\)'
                         % re.escape(label))
        text, n = pat.subn(lambda m, t=typ, nm=name: f'{m.group(1)}{t} "{nm}")', text, count=1)
        if n == 0:
            sys.exit(f"layer row for {label} not found in (layers ...) section")
        applied.append((label, typ, name))
    _report(pcb_path, text)
    for label, typ, name in applied:
        print(f'  {label} -> {typ} "{name}"')


# ----------------------------------------------------------------------------- CLI
def main():
    ap = argparse.ArgumentParser(description="Eagle->KiCad import helpers")
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('summary').add_argument('sch')
    sub.add_parser('outline-layer').add_argument('brd')
    sub.add_parser('layer-scan').add_argument('brd')
    sub.add_parser('propose-layer-map').add_argument('brd')
    sub.add_parser('refint').add_argument('sch')
    sub.add_parser('nonascii').add_argument('sch')
    p = sub.add_parser('pad-positions'); p.add_argument('pcb'); p.add_argument('--ref')
    p = sub.add_parser('solve-transform'); p.add_argument('brd'); p.add_argument('pcb')
    sub.add_parser('paren-check').add_argument('file')
    p = sub.add_parser('bisect'); p.add_argument('sch'); p.add_argument('n', type=int); p.add_argument('out')
    p = sub.add_parser('set-pad-net'); p.add_argument('pcb')
    p.add_argument('--ref', required=True); p.add_argument('--pad', required=True); p.add_argument('--net', required=True)
    p = sub.add_parser('remove-block'); p.add_argument('pcb')
    p.add_argument('--head', required=True); p.add_argument('--contains', required=True, nargs='+')
    p = sub.add_parser('ignore-severities'); p.add_argument('pro')
    p.add_argument('--rules', required=True, help='comma-separated rule names')
    p = sub.add_parser('name-user-layers'); p.add_argument('pcb')
    p.add_argument('--map', required=True, help="'User.1|front|Name;User.2|back|Name;User.3|user|Name'")
    a = ap.parse_args()

    if a.cmd == 'summary': summary(a.sch)
    elif a.cmd == 'outline-layer': outline_layer(a.brd)
    elif a.cmd == 'layer-scan': layer_scan(a.brd)
    elif a.cmd == 'propose-layer-map': propose_layer_map(a.brd)
    elif a.cmd == 'refint': refint(a.sch)
    elif a.cmd == 'nonascii': nonascii(a.sch)
    elif a.cmd == 'pad-positions': pad_positions(a.pcb, a.ref)
    elif a.cmd == 'solve-transform': solve_transform(a.brd, a.pcb)
    elif a.cmd == 'paren-check': paren_check(a.file)
    elif a.cmd == 'bisect': bisect(a.sch, a.n, a.out)
    elif a.cmd == 'set-pad-net': set_pad_net(a.pcb, a.ref, a.pad, a.net)
    elif a.cmd == 'remove-block': cmd_remove_block(a.pcb, a.head, a.contains)
    elif a.cmd == 'ignore-severities': ignore_severities(a.pro, [r.strip() for r in a.rules.split(',')])
    elif a.cmd == 'name-user-layers': name_user_layers(a.pcb, a.map)


if __name__ == '__main__':
    main()
