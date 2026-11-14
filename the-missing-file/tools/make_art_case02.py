#!/usr/bin/env python3
"""Original vector art for Case 2, "File 58-D". Writes SVG sources to art_src/
and the list of render targets to art_src/targets_case02.json.
Run tools/render_art.js afterwards."""
import json, os, random
from make_art import (OUT, NAVY, CHAR, SLATE, PAPER, PAPER_D, INK, AMBER, RED, JADE, SCENE_DEFS,
                      save, rain, text_lines, bust, room, finish, window, desk_lamp, boxes, icon, sheet, SWEAT)

TARGETS = {}


def out(name, path):
    TARGETS[name] = path


# ------------------------------------------------------------------ characters
def no_hair(P, s, cx, base):
    return ""


def hair_soylu(P, s, cx, base):
    return (f'<path d="M{P(-68,-356)} Q{P(-84,-458)} {P(0,-460)} Q{P(84,-458)} {P(68,-356)} Q{P(58,-420)} {P(0,-424)} Q{P(-52,-420)} {P(-68,-356)} Z" fill="#cfc8ba"/>'
            f'<path d="M{P(0,-460)} Q{P(84,-458)} {P(68,-356)} Q{P(58,-420)} {P(0,-424)} Z" fill="#a8a195"/>'
            f'<path d="M{P(-62,-398)} Q{P(-10,-446)} {P(54,-408)} Q{P(0,-418)} {P(-60,-380)} Z" fill="#ded8cc"/>')


def beads(P, s, cx, base):
    return "".join(f'<circle cx="{cx+x*s}" cy="{base+y*s}" r="{5*s}" fill="{RED}"/>' for x, y in ((-24, -248), (-12, -238), (0, -234), (12, -238), (24, -248)))


def hair_guven(P, s, cx, base):
    return (f'<ellipse cx="{cx-60*s}" cy="{base-372*s}" rx="{12*s}" ry="{26*s}" fill="#9a958e"/><ellipse cx="{cx+60*s}" cy="{base-372*s}" rx="{12*s}" ry="{26*s}" fill="#7f7a74"/>')


def beard(P, s, cx, base):
    return (f'<path d="M{P(-60,-336)} Q{P(-58,-268)} {P(0,-258)} Q{P(58,-268)} {P(60,-336)} Q{P(40,-300)} {P(0,-306)} Q{P(-40,-300)} {P(-60,-336)} Z" fill="#9a958e"/>'
            f'<path d="M{P(0,-258)} Q{P(58,-268)} {P(60,-336)} Q{P(40,-300)} {P(0,-306)} Z" fill="#7f7a74"/>')


def hardhat(P, s, cx, base):
    return (f'<path d="M{P(-60,-336)} Q{P(-56,-276)} {P(0,-268)} Q{P(56,-276)} {P(60,-336)} Q{P(40,-316)} {P(0,-322)} Q{P(-40,-316)} {P(-60,-336)} Z" fill="#2a2420" opacity="0.35"/>'
            f'<path d="M{P(-78,-392)} Q{P(-84,-474)} {P(0,-478)} Q{P(84,-474)} {P(78,-392)} Z" fill="#e2b23a"/>'
            f'<path d="M{P(0,-478)} Q{P(84,-474)} {P(78,-392)} L{P(20,-392)} Z" fill="#b98c22"/>'
            f'<path d="M{P(-90,-396)} L{P(90,-396)} L{P(96,-380)} L{P(-96,-380)} Z" fill="#c99a2a"/>'
            f'<path d="M{P(-150,-150)} L{P(150,-150)} L{P(150,-128)} L{P(-150,-128)} Z" fill="#d9dee6" opacity="0.85"/>'
            f'<path d="M{P(-150,-70)} L{P(150,-70)} L{P(150,-48)} L{P(-150,-48)} Z" fill="#d9dee6" opacity="0.85"/>')


def hair_aktas(P, s, cx, base):
    pts = ((-52, -408), (-22, -440), (20, -442), (52, -410), (-66, -366), (66, -366), (0, -452))
    return (f'<circle cx="{cx}" cy="{base-486*s}" r="{28*s}" fill="#2a1c16"/>'
            + "".join(f'<circle cx="{cx+x*s}" cy="{base+y*s}" r="{27*s}" fill="{"#2a1c16" if x <= 0 else "#1c120e"}"/>' for x, y in pts))


def hair_soykan(P, s, cx, base):
    return (f'<ellipse cx="{cx-62*s}" cy="{base-380*s}" rx="{9*s}" ry="{18*s}" fill="#a9a5a0"/><ellipse cx="{cx+62*s}" cy="{base-380*s}" rx="{9*s}" ry="{18*s}" fill="#8a8681"/>')


def cap_soykan(P, s, cx, base):
    return (f'<path d="M{P(-76,-398)} Q{P(-90,-470)} {P(0,-478)} Q{P(90,-470)} {P(76,-398)} Z" fill="#161b26"/>'
            f'<path d="M{P(-76,-398)} Q{P(-90,-470)} {P(0,-478)} Q{P(-44,-452)} {P(-40,-398)} Z" fill="#262e3f"/>'
            f'<path d="M{P(-76,-412)} L{P(76,-412)} L{P(76,-398)} L{P(-76,-398)} Z" fill="{AMBER}"/>'
            f'<path d="M{P(-80,-398)} L{P(80,-398)} L{P(92,-382)} Q{P(0,-370)} {P(-92,-382)} Z" fill="#05070b"/>'
            f'<path d="M{P(0,-462)} l{9*s},{18*s} l{-18*s},{-11*s} l{18*s},0 l{-18*s},{11*s} Z" fill="{AMBER}"/>'
            f'<path d="M{P(-132,-246)} L{P(-84,-258)} L{P(-80,-244)} L{P(-128,-230)} Z" fill="{AMBER}"/><path d="M{P(132,-246)} L{P(84,-258)} L{P(80,-244)} L{P(128,-230)} Z" fill="#b98228"/>')


CAST = {
    "soylu": dict(skin="#d0aa90", skin_sh="#93705e", jacket="#1f3d3f", jacket_l="#2f5a5c", shirt="#efe7d6", hair_fn=hair_soylu, extra_fn=beads),
    "guven": dict(skin="#c9a182", skin_sh="#86654f", jacket="#4a3a2a", jacket_l="#6a543c", shirt="#cfdbe6", hair_fn=hair_guven, extra_fn=beard, brow_tilt=3),
    "kaplan": dict(skin="#b9875f", skin_sh="#7a563b", jacket="#c8641a", jacket_l="#e58a2e", shirt="#1d2330", hair_fn=no_hair, extra_fn=hardhat, brow_tilt=-3),
    "aktas": dict(skin="#d6ad8e", skin_sh="#9a745c", jacket="#2f4a6b", jacket_l="#44668f", shirt="#f4f1ea", hair_fn=hair_aktas),
    "soykan": dict(skin="#c8a087", skin_sh="#84624f", jacket="#161b26", jacket_l="#262e3f", shirt="#eef0f2", hair_fn=hair_soykan, extra_fn=cap_soykan, tie="#05070b"),
}


def figure(who, cx, base, s, mood=None):
    return bust(cx=cx, base=base, s=s, mood=mood, **CAST[who])


def portraits():
    for who in CAST:
        for mood in (None, "defensive", "shaken"):
            tag = "" if mood is None else "_" + mood
            save(who + tag, 700, 1000, figure(who, 350, 1010, 2.05, mood))
            out(who + tag, f"assets/portraits/{who}{tag}.png")


# ------------------------------------------------------------------ outdoor night base
def night(sky0, sky1, ground0, ground1, horizon=700, W=2880, H=1080):
    d = SCENE_DEFS.format(w0=sky0, w1=sky1, f0=ground0, f1=ground1, lamp="#dfeaff")
    b = [f'<rect width="{W}" height="{horizon}" fill="url(#wall)"/><rect x="0" y="{horizon}" width="{W}" height="{H-horizon}" fill="url(#floor)"/>']
    return d, b


# ------------------------------------------------------------------ harbour road
def road():
    d, b = night("#070b14", "#141e30", "#1a1f29", "#07090d", horizon=690)
    d += ('<radialGradient id="glowP"><stop offset="0" stop-color="#5a8cff" stop-opacity="0.7"/><stop offset="1" stop-color="#5a8cff" stop-opacity="0"/></radialGradient>'
          '<radialGradient id="glowR"><stop offset="0" stop-color="#ff5a4a" stop-opacity="0.6"/><stop offset="1" stop-color="#ff5a4a" stop-opacity="0"/></radialGradient>')
    r = random.Random(4)
    # sea and far harbour lights
    b.append('<rect x="0" y="470" width="2880" height="220" fill="#0a1220"/>')
    for _ in range(46):
        x, y = r.random() * 2880, 440 + r.random() * 60
        col = r.choice([AMBER, "#9fd0ff", "#ffd58a"])
        b.append(f'<rect x="{x:.0f}" y="{y:.0f}" width="6" height="6" fill="{col}" opacity="{0.3+r.random()*0.5:.2f}"/><rect x="{x:.0f}" y="{y+40:.0f}" width="6" height="{30+r.random()*60:.0f}" fill="{col}" opacity="0.08"/>')
    # guardrail with a gap on the right
    for x0, x1 in ((0, 2110), (2520, 2880)):
        b.append(f'<rect x="{x0}" y="600" width="{x1-x0}" height="26" fill="#56606f"/><rect x="{x0}" y="606" width="{x1-x0}" height="6" fill="#8a93a3"/>')
        for x in range(x0 + 40, x1, 150):
            b.append(f'<rect x="{x}" y="600" width="14" height="96" fill="#39424f"/>')
    b.append('<path d="M2110 600 L2190 640 L2230 700" fill="none" stroke="#56606f" stroke-width="24"/><path d="M2520 600 L2470 650 L2450 706" fill="none" stroke="#56606f" stroke-width="24"/>')
    # road markings, skid marks
    b.append('<rect x="0" y="690" width="2880" height="10" fill="#0b0e14"/>')
    for x in range(0, 2880, 260):
        b.append(f'<rect x="{x}" y="900" width="140" height="12" fill="#c9cfda" opacity="0.25"/>')
    b.append('<path d="M1500 1010 Q1960 960 2260 720" fill="none" stroke="#05070b" stroke-width="16" opacity="0.8"/><path d="M1560 1050 Q2040 990 2330 724" fill="none" stroke="#05070b" stroke-width="16" opacity="0.8"/>')
    b.append('<path d="M1380 980 Q1900 900 2200 716" fill="none" stroke="#3a1414" stroke-width="12" opacity="0.7" stroke-dasharray="60 26"/>')
    # police car with blue light
    b.append('<circle cx="430" cy="470" r="420" fill="url(#glowP)"/>')
    b.append('<path d="M110 800 L110 660 Q110 630 150 628 L250 624 L330 540 Q340 530 360 530 L560 530 Q580 530 592 544 L660 624 L760 634 Q790 640 790 670 L790 800 Z" fill="#e8ecf2"/>')
    b.append('<path d="M110 720 L790 720 L790 800 L110 800 Z" fill="#1d2f52"/><path d="M350 548 L560 548 L620 624 L290 624 Z" fill="#17202f"/><rect x="452" y="548" width="10" height="76" fill="#e8ecf2"/>')
    b.append('<rect x="390" y="506" width="130" height="26" rx="8" fill="#2f6bff"/><rect x="390" y="506" width="64" height="26" rx="8" fill="#9fc0ff"/>')
    for x in (230, 660):
        b.append(f'<circle cx="{x}" cy="806" r="58" fill="#05070b"/><circle cx="{x}" cy="806" r="26" fill="#39424f"/>')
    b.append(f'<g transform="rotate(-12 630 560)"><rect x="574" y="498" width="112" height="128" rx="5" fill="#6a4a2c"/><rect x="584" y="516" width="92" height="102" fill="{PAPER}"/><rect x="606" y="490" width="48" height="18" rx="4" fill="#aab2be"/>' + text_lines(594, 532, 72, 6, 13, seed=21, sw=3) + '</g>')
    # work light + folding table with bagged evidence
    b.append('<circle cx="1250" cy="430" r="430" fill="url(#glowW)" opacity="0.5"/><rect x="1244" y="330" width="12" height="320" fill="#05070b"/><rect x="1200" y="296" width="100" height="56" rx="8" fill="#0a0d14"/><rect x="1208" y="304" width="84" height="40" fill="#f4f8ff"/>')
    b.append('<rect x="980" y="644" width="540" height="18" fill="#aab2be"/><path d="M1010 662 L990 830 M1490 662 L1510 830 M1010 662 L1060 830 M1490 662 L1440 830" stroke="#56606f" stroke-width="8"/>')
    b.append('<rect x="1004" y="588" width="104" height="56" rx="6" fill="#dfe5ee" opacity="0.5"/><rect x="1030" y="596" width="46" height="42" rx="6" fill="#0a0d14"/><rect x="1035" y="601" width="36" height="28" fill="#28505a"/>')
    b.append(f'<rect x="1128" y="596" width="104" height="48" rx="6" fill="#dfe5ee" opacity="0.5"/><circle cx="1160" cy="620" r="13" fill="none" stroke="{AMBER}" stroke-width="5"/><rect x="1172" y="616" width="34" height="7" fill="{AMBER}"/><rect x="1196" y="606" width="28" height="22" rx="3" fill="{PAPER}"/>')
    b.append(f'<rect x="1252" y="590" width="104" height="54" rx="6" fill="#dfe5ee" opacity="0.5"/><rect x="1270" y="598" width="68" height="40" rx="4" fill="{PAPER}"/><rect x="1270" y="598" width="68" height="12" rx="4" fill="{RED}"/>' + text_lines(1278, 620, 50, 2, 9, seed=22, sw=3))
    b.append('<rect x="1380" y="584" width="118" height="60" rx="6" fill="#0a0d14"/><rect x="1388" y="592" width="102" height="44" fill="#28505a"/>' + text_lines(1396, 602, 84, 3, 11, color="#a8f0e6", op=0.8, seed=23, sw=3))
    # police tape and the chief under an umbrella
    b.append('<path d="M1700 250 Q1900 130 2100 250 Z" fill="#0a0d14"/><rect x="1896" y="250" width="8" height="360" fill="#05070b"/>')
    b.append(figure("soykan", 1790, 752, 0.9))
    b.append(f'<rect x="1560" y="716" width="480" height="30" fill="{AMBER}"/>' + "".join(f'<rect x="{x}" y="716" width="26" height="30" fill="{INK}" transform="skewX(-24)" opacity="0.85"/>' for x in range(1900, 2380, 70)))
    b.append('<rect x="1560" y="700" width="14" height="130" fill="#39424f"/><rect x="2030" y="700" width="14" height="130" fill="#39424f"/>')
    for x in (1640, 2070):
        b.append(f'<path d="M{x} 1000 l34 -96 l34 96Z" fill="#e2622a"/><rect x="{x+14}" y="950" width="40" height="14" fill="{PAPER}"/>')
    # the wreck: rear of the car over the edge, with a scrape of dark red paint
    b.append('<circle cx="2330" cy="640" r="240" fill="url(#glowR)" opacity="0.5"/>')
    b.append('<g transform="rotate(14 2330 640)"><path d="M2190 720 L2190 600 Q2196 560 2240 554 L2420 554 Q2466 560 2470 600 L2470 720 Z" fill="#8a93a3"/>'
             '<path d="M2216 600 Q2222 574 2250 572 L2410 572 Q2440 574 2444 600 Z" fill="#17202f"/>'
             '<rect x="2196" y="622" width="62" height="24" rx="6" fill="#ff5a4a"/><rect x="2402" y="622" width="62" height="24" rx="6" fill="#ff5a4a"/>'
             '<rect x="2184" y="662" width="292" height="34" rx="8" fill="#56606f"/><rect x="2290" y="640" width="80" height="22" fill="#e8ecf2"/>'
             '<path d="M2184 640 l70 10 l-6 44 l-66 -10Z" fill="#6a1f22"/><path d="M2190 652 l54 8 M2188 672 l50 8" stroke="#3a0d10" stroke-width="5"/></g>')
    b.append(rain(0, 0, 2880, 1080, 520, 9, 0.16))
    finish("road", d, b)
    out("road", "assets/scenes/road.png")


# ------------------------------------------------------------------ newsroom
def newsroom():
    d, b = room("#12141a", "#242833", "#1e2026", "#090a0d")
    # door and sign-in sheet
    b.append('<rect x="20" y="210" width="60" height="620" fill="#070a10"/>')
    b.append(f'<rect x="124" y="392" width="124" height="170" rx="5" fill="#6a4a2c"/><rect x="134" y="414" width="104" height="140" fill="{PAPER}"/><rect x="160" y="384" width="52" height="18" rx="4" fill="#aab2be"/>' + text_lines(144, 432, 84, 8, 14, seed=31, sw=3) + f'<rect x="144" y="430" width="84" height="12" fill="{AMBER}" opacity="0.5"/>')
    # reception desk with the switchboard
    b.append('<rect x="280" y="712" width="380" height="118" fill="url(#desk)"/><rect x="270" y="700" width="400" height="16" fill="#4a3625"/>')
    b.append('<path d="M330 700 L350 590 L590 590 L610 700 Z" fill="#2f3743"/><rect x="362" y="604" width="216" height="44" fill="#0a0d14"/>' + text_lines(372, 616, 190, 2, 14, color="#a8f0e6", op=0.8, seed=32, sw=3))
    for i in range(12):
        b.append(f'<rect x="{366+(i%6)*36}" y="{658+(i//6)*20}" width="26" height="12" rx="3" fill="{AMBER if i in (3, 8) else "#56606f"}"/>')
    # Tunç's desk: no laptop, a clean rectangle in the dust, charger still plugged in
    b.append('<rect x="790" y="210" width="380" height="270" fill="#3b2b1e"/><rect x="802" y="222" width="356" height="246" fill="#2b2018"/>')
    r = random.Random(6)
    pins = [(840, 260), (960, 250), (1090, 270), (870, 380), (1010, 400), (1110, 370)]
    for (x, y) in pins:
        b.append(f'<rect x="{x-34}" y="{y-24}" width="68" height="52" fill="{r.choice([PAPER, PAPER_D, "#f3ead4"])}" transform="rotate({r.randint(-8, 8)} {x} {y})"/>')
    b.append(f'<path d="M840 260 L960 250 L1010 400 L1110 370 L1090 270 M870 380 L1010 400" fill="none" stroke="{RED}" stroke-width="4"/>' + "".join(f'<circle cx="{x}" cy="{y}" r="7" fill="{RED}"/>' for x, y in pins))
    b.append('<rect x="760" y="640" width="460" height="18" fill="#4a3625"/><rect x="780" y="658" width="420" height="172" fill="url(#desk)"/>')
    b.append('<rect x="850" y="600" width="250" height="38" fill="#5a4636" opacity="0.5"/><rect x="876" y="606" width="198" height="28" fill="#6f5846"/>')
    b.append('<path d="M1100 626 q40 -30 70 10 l10 196" fill="none" stroke="#0a0d14" stroke-width="6"/><rect x="1088" y="618" width="22" height="16" rx="3" fill="#0a0d14"/>')
    b.append(f'<rect x="790" y="590" width="44" height="50" fill="#39424f"/><rect x="796" y="584" width="8" height="26" fill="{RED}"/><rect x="810" y="580" width="8" height="30" fill="{AMBER}"/>')
    # Deniz at the next desk
    b.append('<rect x="1380" y="400" width="240" height="250" rx="16" fill="#15171c"/>')
    b.append(figure("aktas", 1500, 652, 0.85))
    b.append('<rect x="1290" y="640" width="440" height="18" fill="#4a3625"/><rect x="1310" y="658" width="400" height="172" fill="url(#desk)"/>')
    b.append('<circle cx="1660" cy="560" r="150" fill="url(#glowM)"/><rect x="1600" y="520" width="130" height="92" rx="5" fill="#0a0d14"/><rect x="1608" y="528" width="114" height="76" fill="#28505a"/><rect x="1654" y="612" width="22" height="28" fill="#0a0d14"/>' + text_lines(1616, 540, 96, 4, 14, color="#a8f0e6", op=0.7, seed=33, sw=3))
    # editor's glass office
    b.append('<rect x="1850" y="150" width="660" height="680" fill="#9fd0ff" opacity="0.05"/>')
    b.append(f'<rect x="1890" y="240" width="130" height="180" fill="{PAPER}"/>' + text_lines(1902, 262, 104, 8, 17, seed=34, sw=4) + f'<rect x="1902" y="296" width="104" height="14" fill="{RED}" opacity="0.5"/><circle cx="1955" cy="240" r="7" fill="{RED}"/>')
    b.append('<rect x="2060" y="390" width="250" height="260" rx="16" fill="#1a1414"/>')
    b.append(figure("soylu", 2185, 652, 0.86))
    b.append('<rect x="1960" y="640" width="470" height="18" fill="#4a3625"/><rect x="1980" y="658" width="430" height="172" fill="url(#desk)"/>')
    b.append(desk_lamp(2370, 640))
    b.append('<rect x="1844" y="150" width="12" height="680" fill="#39424f"/><rect x="2504" y="150" width="12" height="680" fill="#39424f"/><rect x="1844" y="150" width="672" height="12" fill="#39424f"/>')
    # the morgue: drawers of clippings
    b.append('<rect x="2550" y="270" width="300" height="560" fill="#2f3743"/>')
    b.append(f'<rect x="2550" y="190" width="300" height="70" fill="#3b2b1e"/><rect x="2562" y="200" width="276" height="50" fill="{PAPER}"/>' + text_lines(2574, 214, 240, 3, 12, seed=35, sw=3))
    for row in range(6):
        for col in range(3):
            x, y = 2562 + col * 96, 282 + row * 90
            special = (row, col) == (3, 1)
            b.append(f'<rect x="{x}" y="{y}" width="86" height="80" fill="{"#46526a" if special else "#39424f"}"/><rect x="{x+16}" y="{y+14}" width="54" height="20" fill="{PAPER if special else PAPER_D}"/><rect x="{x+28}" y="{y+52}" width="30" height="8" rx="4" fill="#0d1218"/>')
    finish("newsroom", d, b)
    out("newsroom", "assets/scenes/newsroom.png")


# ------------------------------------------------------------------ tower site
def site():
    d, b = night("#06090f", "#131a26", "#1f1c18", "#080706", horizon=830)
    # concrete frame of the tower and a crane
    for floor in range(6):
        y = 120 + floor * 100
        b.append(f'<rect x="1260" y="{y}" width="620" height="14" fill="#2a3140"/>')
    for x in (1260, 1460, 1670, 1866):
        b.append(f'<rect x="{x}" y="120" width="14" height="710" fill="#2a3140"/>')
    b.append('<rect x="2140" y="0" width="16" height="830" fill="#1b2230"/><rect x="1500" y="40" width="900" height="12" fill="#1b2230"/><path d="M2148 0 L1560 46 M2148 0 L2380 46" stroke="#1b2230" stroke-width="5"/><rect x="1680" y="52" width="4" height="150" fill="#1b2230"/>')
    b.append('<circle cx="1000" cy="250" r="520" fill="url(#glowW)" opacity="0.45"/><rect x="994" y="250" width="12" height="580" fill="#05070b"/><rect x="940" y="206" width="120" height="60" rx="8" fill="#0a0d14"/><rect x="950" y="214" width="100" height="44" fill="#f4f8ff"/>')
    # gate hut: visitor log and camera monitor
    b.append('<rect x="150" y="380" width="480" height="450" fill="#2f3743"/><rect x="130" y="360" width="520" height="30" fill="#1b2230"/>')
    b.append('<rect x="190" y="440" width="420" height="250" fill="#0d1218"/><circle cx="400" cy="560" r="230" fill="url(#glowA)" opacity="0.5"/>')
    b.append(f'<path d="M206 690 L226 600 L306 594 L308 690 Z" fill="{PAPER}"/><path d="M308 690 L306 594 L386 600 L402 690 Z" fill="#f3ead4"/>' + text_lines(234, 612, 60, 5, 14, seed=41, sw=3) + text_lines(318, 612, 60, 5, 14, seed=42, sw=3))
    b.append('<rect x="430" y="480" width="170" height="124" rx="6" fill="#0a0d14"/><rect x="440" y="490" width="150" height="104" fill="#1c2b33"/><rect x="470" y="536" width="78" height="34" rx="8" fill="#6a1f22"/><circle cx="486" cy="572" r="9" fill="#05070b"/><circle cx="532" cy="572" r="9" fill="#05070b"/><rect x="440" y="490" width="150" height="14" fill="#a8f0e6" opacity="0.25"/>')
    b.append(f'<rect x="650" y="640" width="16" height="190" fill="#39424f"/><rect x="650" y="640" width="330" height="14" fill="{RED}"/>' + "".join(f'<rect x="{x}" y="640" width="40" height="14" fill="{PAPER}"/>' for x in range(700, 980, 90)))
    # white pickup, rear corner dented
    b.append('<path d="M820 800 L820 640 L1130 640 L1130 600 Q1134 560 1180 556 L1340 556 Q1380 560 1400 600 L1440 680 L1500 690 Q1530 696 1530 730 L1530 800 Z" fill="#e8ecf2"/>')
    b.append('<path d="M1160 600 Q1164 578 1190 576 L1330 576 Q1356 580 1370 604 L1410 680 L1160 680 Z" fill="#17202f"/><rect x="820" y="640" width="310" height="14" fill="#c9cfda"/>')
    b.append('<path d="M820 640 l44 14 l-12 60 l22 46 l-54 40Z" fill="#aab2be"/><path d="M830 668 l30 30 M826 716 l34 26" stroke="#56606f" stroke-width="6"/><rect x="820" y="690" width="26" height="30" fill="#ff5a4a" opacity="0.6"/>')
    for x in (950, 1410):
        b.append(f'<circle cx="{x}" cy="806" r="62" fill="#05070b"/><circle cx="{x}" cy="806" r="28" fill="#39424f"/>')
    # Kaplan behind a stack of cement bags
    b.append(figure("kaplan", 1700, 742, 0.88))
    for i, (x, y) in enumerate(((1560, 770), (1700, 770), (1630, 712), (1770, 712), (1840, 770))):
        b.append(f'<rect x="{x}" y="{y}" width="150" height="62" rx="12" fill="{"#9a917f" if i % 2 else "#857c6b"}"/><rect x="{x+20}" y="{y+22}" width="70" height="12" fill="#5d5648"/>')
    # site office board: incident book and delivery tickets
    b.append('<rect x="1950" y="400" width="450" height="430" fill="#3a4a5c"/>' + "".join(f'<rect x="{x}" y="400" width="6" height="430" fill="#2a3644"/>' for x in range(1990, 2400, 50)))
    b.append(f'<g transform="rotate(-3 2070 550)"><rect x="1990" y="480" width="160" height="150" rx="6" fill="#5a2a22"/><rect x="2000" y="490" width="140" height="130" fill="{PAPER}"/>' + text_lines(2012, 510, 110, 6, 17, seed=43, sw=4) + '</g>')
    b.append('<rect x="2268" y="470" width="6" height="150" fill="#aab2be"/>' + "".join(f'<rect x="{2214+i*4}" y="{500+i*22}" width="116" height="40" fill="{[PAPER, "#f3ead4", PAPER_D, PAPER][i]}" transform="rotate({[-6, 4, -3, 7][i]} 2270 {520+i*22})"/>' for i in range(4)))
    # concrete mixer
    b.append('<path d="M2450 800 L2450 640 L2560 640 L2600 560 L2700 560 L2700 800 Z" fill="#c8641a"/><ellipse cx="2760" cy="610" rx="150" ry="110" fill="#aab2be" transform="rotate(-18 2760 610)"/><path d="M2670 560 l160 100 M2700 520 l150 96" stroke="#56606f" stroke-width="10"/>')
    for x in (2520, 2760):
        b.append(f'<circle cx="{x}" cy="806" r="60" fill="#05070b"/><circle cx="{x}" cy="806" r="26" fill="#39424f"/>')
    b.append(rain(0, 0, 2880, 1080, 380, 12, 0.13))
    finish("site", d, b)
    out("site", "assets/scenes/site.png")


# ------------------------------------------------------------------ planning office
def planning():
    d, b = room("#14160f", "#27291c", "#22201a", "#0a0908")
    # plan chest
    b.append('<rect x="130" y="470" width="330" height="360" fill="#3a2a1d"/>')
    for i in range(6):
        b.append(f'<rect x="144" y="{484+i*57}" width="302" height="48" fill="#2c2016" stroke="#0f0b08" stroke-width="3"/><rect x="270" y="{502+i*57}" width="50" height="8" rx="4" fill="{AMBER}" opacity="0.7"/>')
    b.append(f'<path d="M150 470 L170 430 L420 420 L440 470 Z" fill="{PAPER_D}"/><path d="M190 440 l200 -8" stroke="{RED}" stroke-width="4"/>')
    # the file register on a stand
    b.append('<rect x="620" y="650" width="16" height="180" fill="#2a2018"/><path d="M560 830 h136 l-20 -18 h-96Z" fill="#2a2018"/>')
    b.append(f'<g transform="rotate(-8 630 590)"><path d="M520 650 L540 530 L630 522 L632 650 Z" fill="{PAPER}"/><path d="M632 650 L630 522 L720 530 L740 650 Z" fill="#f3ead4"/><path d="M520 650 L740 650 L740 662 L520 662 Z" fill="#24413a"/>' + text_lines(552, 546, 66, 7, 14, seed=51, sw=3) + text_lines(644, 546, 66, 7, 14, seed=52, sw=3) + f'<rect x="644" y="586" width="80" height="12" fill="{AMBER}" opacity="0.6"/></g>')
    # Güven at his desk
    b.append('<rect x="1380" y="390" width="250" height="270" rx="16" fill="#1a1611"/>')
    b.append(figure("guven", 1505, 662, 0.88))
    b.append('<rect x="1150" y="650" width="760" height="18" fill="#4a3625"/><rect x="1170" y="668" width="720" height="162" fill="url(#desk)"/>')
    b.append('<ellipse cx="1530" cy="930" rx="460" ry="36" fill="#000" opacity="0.45" filter="url(#blur8)"/>')
    b.append(desk_lamp(1250, 650))
    b.append(f'<path d="M1716 650 L1732 574 L1808 574 L1824 650 Z" fill="{PAPER}"/><rect x="1730" y="568" width="80" height="14" fill="{RED}"/>' + text_lines(1742, 598, 56, 3, 13, seed=53, sw=3) + f'<rect x="1742" y="630" width="56" height="5" fill="{RED}"/>')
    b.append('<rect x="1290" y="596" width="96" height="54" fill="#3b2b1e"/><rect x="1298" y="604" width="80" height="38" fill="#59616e"/><circle cx="1324" cy="620" r="8" fill="#8b6f5c"/><circle cx="1352" cy="620" r="8" fill="#8b6f5c"/>')
    # the zoning map
    b.append('<rect x="1990" y="150" width="760" height="460" fill="#3b2b1e"/><rect x="2006" y="166" width="728" height="428" fill="#d8d2bd"/>')
    r = random.Random(8)
    cols = ["#c9b98f", "#a8b89a", "#b9a6a0", "#9fb1bd", "#d0c7a2"]
    for i in range(7):
        for j in range(4):
            b.append(f'<rect x="{2016+i*102}" y="{176+j*72}" width="96" height="66" fill="{r.choice(cols)}"/>')
    b.append('<path d="M2006 468 Q2200 440 2380 486 T2734 470 L2734 594 L2006 594 Z" fill="#7f9db0"/>')
    b.append(f'<rect x="2420" y="392" width="198" height="66" fill="none" stroke="{RED}" stroke-width="7"/><circle cx="2520" cy="392" r="9" fill="{RED}"/>')
    b.append(window(2790, 220, 70, 330, 91, "w3"))
    finish("planning", d, b)
    out("planning", "assets/scenes/planning.png")


# ------------------------------------------------------------------ icons
def icons():
    def ic(name, inner):
        icon("c2_" + name, inner)
        out("c2_" + name, f"assets/evidence/c2_{name}.png")
    ic("phone", '<rect x="170" y="80" width="172" height="352" rx="26" fill="#0a0d14"/><rect x="184" y="112" width="144" height="270" fill="#28505a"/>'
       + text_lines(198, 140, 116, 6, 34, color="#a8f0e6", op=0.8, seed=61, sw=8) + f'<rect x="198" y="232" width="116" height="24" fill="{AMBER}" opacity="0.6"/><circle cx="256" cy="406" r="12" fill="#39424f"/>')
    ic("paint", f'<rect x="80" y="210" width="352" height="96" rx="20" fill="#8a93a3"/><rect x="80" y="286" width="352" height="46" rx="16" fill="#56606f"/><rect x="330" y="226" width="86" height="40" rx="8" fill="#ff5a4a"/>'
       f'<path d="M92 222 l150 16 l-10 62 l-144 -18Z" fill="#6a1f22"/><path d="M104 244 l120 14 M100 270 l116 14" stroke="#3a0d10" stroke-width="8"/>')
    ic("pass", f'<rect x="246" y="60" width="20" height="90" fill="{RED}"/><rect x="136" y="140" width="240" height="290" rx="14" fill="{PAPER}"/><rect x="136" y="140" width="240" height="62" rx="14" fill="{RED}"/>'
       + text_lines(160, 240, 190, 4, 30, seed=62, sw=8) + f'<rect x="160" y="370" width="120" height="30" fill="{INK}" opacity="0.8"/>')
    ic("ecall", '<rect x="90" y="130" width="332" height="230" rx="18" fill="#0a0d14"/><rect x="108" y="148" width="296" height="194" fill="#28505a"/>'
       f'<path d="M124 290 l50 0 l20 -90 l30 130 l24 -70 l20 30 h120" fill="none" stroke="#a8f0e6" stroke-width="9"/><circle cx="360" cy="190" r="22" fill="{RED}"/>')
    ic("camera", '<rect x="90" y="120" width="332" height="240" rx="12" fill="#0a0d14"/><rect x="106" y="136" width="300" height="208" fill="#1c2b33"/>'
       '<rect x="170" y="216" width="170" height="70" rx="16" fill="#6a1f22"/><path d="M200 216 q10 -40 50 -40 h30 q40 0 50 40Z" fill="#6a1f22"/><circle cx="204" cy="292" r="20" fill="#05070b"/><circle cx="306" cy="292" r="20" fill="#05070b"/>'
       f'<rect x="106" y="136" width="300" height="26" fill="#a8f0e6" opacity="0.25"/><circle cx="380" cy="150" r="8" fill="{RED}"/>')
    ic("pickup", '<path d="M70 330 L70 220 L250 220 L250 190 Q254 160 286 158 L370 158 Q396 162 408 190 L428 250 L450 256 Q466 262 466 284 L466 330 Z" fill="#e8ecf2"/>'
       '<path d="M270 190 Q274 176 290 176 L364 176 Q380 178 388 194 L408 246 L270 246 Z" fill="#17202f"/>'
       '<path d="M70 220 l34 12 l-10 44 l18 32 l-42 22Z" fill="#aab2be"/><circle cx="150" cy="336" r="42" fill="#05070b"/><circle cx="390" cy="336" r="42" fill="#05070b"/><circle cx="150" cy="336" r="18" fill="#39424f"/><circle cx="390" cy="336" r="18" fill="#39424f"/>')
    ic("ticket", "".join(sheet(140 + i * 14, 110 + i * 40, 220, 150, [-8, 5, -3][i], [PAPER_D, "#f3ead4", PAPER][i]) + text_lines(160 + i * 14, 140 + i * 40, 170, 3, 26, seed=63 + i, sw=7) + "</g>" for i in range(3))
       + '<rect x="250" y="70" width="12" height="180" fill="#aab2be"/>')
    ic("car", f'<rect x="96" y="110" width="320" height="300" rx="12" fill="{PAPER}"/><rect x="96" y="110" width="320" height="56" rx="12" fill="#23324a"/>'
       f'<rect x="126" y="196" width="170" height="46" rx="6" fill="{INK}"/><rect x="134" y="204" width="24" height="30" fill="#2f6bff"/>' + text_lines(126, 276, 250, 4, 28, seed=66, sw=7)
       + f'<circle cx="360" cy="220" r="26" fill="{RED}" opacity="0.8"/>')
    ic("laptop", '<path d="M130 130 h252 a12 12 0 0 1 12 12 v170 h-276 v-170 a12 12 0 0 1 12 -12Z" fill="#0a0d14"/><rect x="138" y="148" width="236" height="150" fill="#28505a"/>'
       + text_lines(154, 172, 200, 5, 24, color="#a8f0e6", op=0.8, seed=67, sw=6) + '<path d="M80 320 h352 l30 50 h-412Z" fill="#aab2be"/><rect x="216" y="336" width="80" height="14" fill="#56606f"/>')
    ic("desk", '<rect x="70" y="250" width="372" height="26" fill="#7a5a3c"/><rect x="90" y="276" width="332" height="140" fill="#3a2a1d"/>'
       f'<rect x="150" y="200" width="212" height="50" fill="none" stroke="{PAPER}" stroke-width="6" stroke-dasharray="18 12"/>'
       '<path d="M362 236 q50 -40 70 20 l6 160" fill="none" stroke="#0a0d14" stroke-width="9"/><rect x="350" y="226" width="26" height="20" rx="4" fill="#0a0d14"/>')
    ic("index", f'<rect x="110" y="150" width="292" height="220" fill="#39424f"/><rect x="130" y="170" width="252" height="76" fill="{PAPER}"/><rect x="150" y="196" width="120" height="14" fill="{INK}"/>'
       f'<rect x="216" y="290" width="80" height="22" rx="10" fill="#0d1218"/><rect x="300" y="186" width="66" height="44" fill="none" stroke="{RED}" stroke-width="7"/>')
    ic("person", f'<rect x="80" y="140" width="352" height="232" rx="16" fill="{PAPER}"/><rect x="104" y="166" width="120" height="150" fill="#59616e"/><circle cx="164" cy="222" r="30" fill="#8b6f5c"/><path d="M118 316 q8 -56 46 -58 q38 2 46 58Z" fill="#1d2330"/>'
       + text_lines(250, 184, 150, 5, 28, seed=68, sw=7) + f'<rect x="250" y="322" width="150" height="26" fill="{RED}" opacity="0.6"/>')


if __name__ == "__main__":
    portraits(); road(); newsroom(); site(); planning(); icons()
    with open(os.path.join(OUT, "targets_case02.json"), "w") as f:
        json.dump(TARGETS, f, indent=1)
    print("Case 2 SVG sources written:", len(TARGETS))
