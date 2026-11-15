#!/usr/bin/env python3
"""Original vector art for Case 3, "File 12-C". Writes SVG sources to art_src/
and the list of render targets to art_src/targets_case03.json."""
import json, os, random
from make_art import (OUT, PAPER, PAPER_D, INK, AMBER, RED, JADE, SCENE_DEFS, GLASSES, HAIR_A,
                      save, rain, text_lines, bust, room, finish, window, desk_lamp, boxes, icon, sheet)
from make_art_case02 import CAST as CAST2, night, beard

TARGETS = {}


def out(name, path):
    TARGETS[name] = path


# ------------------------------------------------------------------ characters
def scarf(P, s, cx, base):
    return (f'<path d="M{P(-74,-300)} Q{P(-92,-462)} {P(0,-468)} Q{P(92,-462)} {P(74,-300)} Q{P(40,-262)} {P(0,-256)} Q{P(-40,-262)} {P(-74,-300)} Z" fill="#6a5a7a"/>'
            f'<path d="M{P(0,-468)} Q{P(92,-462)} {P(74,-300)} Q{P(40,-262)} {P(0,-256)} Z" fill="#514460"/>'
            f'<path d="M{P(-56,-392)} Q{P(-62,-300)} {P(-26,-282)} Q{P(0,-272)} {P(26,-282)} Q{P(62,-300)} {P(56,-392)} Q{P(0,-430)} {P(-56,-392)} Z" fill="SKIN"/>'
            f'<path d="M{P(-26,-262)} L{P(0,-236)} L{P(26,-262)} L{P(14,-214)} L{P(-14,-214)} Z" fill="#514460"/>')


def face_again(skin, skin_sh, mood=None):
    """Redraws the face over a head covering (brows, eyes, nose, mouth)."""
    def fn(P, s, cx, base):
        t = {"defensive": -8, "shaken": 9}.get(mood, 3)
        ey = {"defensive": 3.2, "shaken": 6.5}.get(mood, 4.5)
        g = scarf(P, s, cx, base).replace("SKIN", skin)
        g += f'<path d="M{P(8,-416)} Q{P(36,-414)} {P(56,-392)} Q{P(62,-300)} {P(26,-282)} Q{P(10,-274)} {P(0,-274)} Q{P(22,-300)} {P(14,-340)} Z" fill="{skin_sh}"/>'
        g += f'<path d="M{P(-48,-372+t)} L{P(-14,-372-t)} L{P(-14,-366-t)} L{P(-48,-365+t)} Z" fill="#3a302a"/><path d="M{P(48,-372+t)} L{P(14,-372-t)} L{P(14,-366-t)} L{P(48,-365+t)} Z" fill="#2a221d"/>'
        g += f'<ellipse cx="{cx-30*s}" cy="{base-352*s}" rx="{7*s}" ry="{ey*s}" fill="#15110f"/><ellipse cx="{cx+30*s}" cy="{base-352*s}" rx="{7*s}" ry="{ey*s}" fill="#15110f"/>'
        g += f'<path d="M{P(-4,-356)} L{P(-12,-318)} L{P(8,-314)} Z" fill="{skin_sh}" opacity="0.8"/>'
        if mood == "shaken":
            g += f'<ellipse cx="{cx}" cy="{base-292*s}" rx="{9*s}" ry="{6*s}" fill="#3a221c"/>'
        else:
            my = -299 if mood == "defensive" else -290
            g += f'<path d="M{P(-18,-294)} Q{P(0,my)} {P(18,-294)}" fill="none" stroke="#5a3a32" stroke-width="{4*s}" stroke-linecap="round"/>'
        return g
    return fn


def hair_cem(P, s, cx, base):
    return (f'<path d="M{P(-66,-366)} Q{P(-80,-456)} {P(0,-460)} Q{P(80,-456)} {P(66,-366)} Q{P(58,-420)} {P(0,-426)} Q{P(-58,-420)} {P(-66,-366)} Z" fill="#241a16"/>'
            f'<path d="M{P(-60,-336)} Q{P(-58,-268)} {P(0,-258)} Q{P(58,-268)} {P(60,-336)} Q{P(40,-300)} {P(0,-306)} Q{P(-40,-300)} {P(-60,-336)} Z" fill="#241a16"/>'
            f'<path d="M{P(0,-258)} Q{P(58,-268)} {P(60,-336)} Q{P(40,-300)} {P(0,-306)} Z" fill="#17100d"/>')


def hair_nur(P, s, cx, base):
    return (f'<path d="M{P(-66,-370)} Q{P(-80,-456)} {P(0,-460)} Q{P(80,-456)} {P(66,-370)} Q{P(60,-424)} {P(0,-428)} Q{P(-60,-424)} {P(-66,-370)} Z" fill="#2b2622"/>'
            f'<path d="M{P(0,-460)} Q{P(80,-456)} {P(66,-370)} Q{P(60,-424)} {P(0,-428)} Z" fill="#1c1815"/>')


def nur_extra(P, s, cx, base):
    return GLASSES(P, s, cx, base) + f'<rect x="{cx+70*s}" y="{base-190*s}" width="{44*s}" height="{58*s}" fill="#c9cfda"/><rect x="{cx+78*s}" y="{base-206*s}" width="{6*s}" height="{24*s}" fill="{RED}"/><rect x="{cx+92*s}" y="{base-206*s}" width="{6*s}" height="{24*s}" fill="#23324a"/>'


def no_hair(P, s, cx, base):
    return ""


def bulut_extra(P, s, cx, base):
    return (f'<path d="M{P(-60,-336)} Q{P(-56,-276)} {P(0,-268)} Q{P(56,-276)} {P(60,-336)} Q{P(40,-312)} {P(0,-318)} Q{P(-40,-312)} {P(-60,-336)} Z" fill="#e8e4dc" opacity="0.55"/>'
            f'<path d="M{P(-78,-396)} Q{P(-84,-448)} {P(-10,-456)} Q{P(70,-456)} {P(80,-400)} Z" fill="#5d6470"/>'
            f'<path d="M{P(-10,-456)} Q{P(70,-456)} {P(80,-400)} L{P(20,-398)} Z" fill="#464c57"/>'
            f'<path d="M{P(-84,-398)} L{P(40,-398)} L{P(96,-384)} Q{P(10,-376)} {P(-92,-384)} Z" fill="#3a3f48"/>'
            f'<path d="M{P(-46,-262)} Q{P(0,-236)} {P(46,-262)} L{P(50,-232)} Q{P(0,-206)} {P(-50,-232)} Z" fill="#1b2b44"/>')


CAST = {
    "hatice": dict(skin="#d2aa8e", skin_sh="#96735e", jacket="#5a4a52", jacket_l="#77646e", shirt="#e9e2d6", hair_fn=None),
    "cem": dict(skin="#c69a78", skin_sh="#7f5c47", jacket="#2d3a2e", jacket_l="#42543f", shirt="#efece4", hair_fn=hair_cem, brow_tilt=-2),
    "nur": dict(skin="#cfa98b", skin_sh="#8f6c58", jacket="#dfe5ee", jacket_l="#f4f6fa", shirt="#7f9db0", hair_fn=hair_nur, extra_fn=nur_extra),
    "bulut": dict(skin="#b78a66", skin_sh="#75553e", jacket="#1b2b44", jacket_l="#2c4264", shirt="#1b2b44", hair_fn=no_hair, extra_fn=bulut_extra, brow_tilt=-3),
}


def figure(who, cx, base, s, mood=None):
    if who == "soykan":
        return bust(cx=cx, base=base, s=s, mood=mood, **CAST2["soykan"])
    spec = dict(CAST[who])
    if who == "hatice":
        spec["hair_fn"] = face_again(spec["skin"], spec["skin_sh"], mood)
    return bust(cx=cx, base=base, s=s, mood=mood, **spec)


def portraits():
    for who in CAST:
        for mood in (None, "defensive", "shaken"):
            tag = "" if mood is None else "_" + mood
            save(who + tag, 700, 1000, figure(who, 350, 1010, 2.05, mood))
            out(who + tag, f"assets/portraits/{who}{tag}.png")


# ------------------------------------------------------------------ Erol's house
def house():
    d, b = room("#17130f", "#2c241c", "#261d16", "#0b0806")
    # kitchen corner: fridge, counter, dish rack
    b.append('<rect x="120" y="300" width="250" height="530" rx="10" fill="#c9cfda"/><rect x="120" y="300" width="250" height="180" rx="10" fill="#dfe5ee"/><rect x="340" y="350" width="12" height="90" rx="6" fill="#8a93a3"/><rect x="340" y="520" width="12" height="150" rx="6" fill="#8a93a3"/>')
    b.append(f'<rect x="160" y="340" width="120" height="70" fill="{PAPER}" transform="rotate(-4 220 375)"/>' + text_lines(172, 356, 96, 3, 14, seed=3, sw=3))
    b.append('<rect x="400" y="650" width="640" height="180" fill="#3a2a1d"/><rect x="390" y="636" width="660" height="18" fill="#7a5a3c"/>')
    b.append('<rect x="440" y="560" width="290" height="78" fill="none" stroke="#aab2be" stroke-width="6"/>' + "".join(f'<line x1="{470+i*42}" y1="560" x2="{470+i*42}" y2="638" stroke="#aab2be" stroke-width="4"/>' for i in range(6)))
    b.append('<path d="M560 572 l44 0 l-6 62 l-32 0Z" fill="#dfeaff" opacity="0.55"/><ellipse cx="582" cy="572" rx="22" ry="5" fill="#f4f8ff" opacity="0.7"/><circle cx="640" cy="604" r="30" fill="none" stroke="#e8ecf2" stroke-width="6"/>')
    # Hatice behind the counter
    b.append(figure("hatice", 910, 648, 0.86))
    b.append('<rect x="790" y="636" width="260" height="18" fill="#7a5a3c"/><rect x="790" y="654" width="250" height="176" fill="#3a2a1d"/>')
    b.append(window(520, 180, 230, 250, 31, "h1"))
    # the doctor's note on a stand, the empty armchair, the tray
    b.append('<rect x="1160" y="700" width="12" height="130" fill="#2a2018"/><path d="M1110 830 h112 l-16 -16 h-80Z" fill="#2a2018"/>')
    b.append(f'<g transform="rotate(-6 1166 640)"><rect x="1104" y="566" width="124" height="150" rx="5" fill="#39424f"/><rect x="1114" y="586" width="104" height="122" fill="{PAPER}"/><rect x="1140" y="558" width="52" height="18" rx="4" fill="#aab2be"/>' + text_lines(1124, 604, 84, 6, 15, seed=4, sw=3) + '</g>')
    b.append('<path d="M1270 830 L1270 520 Q1270 420 1370 410 L1490 410 Q1590 420 1590 520 L1590 830 Z" fill="#4a2f2a"/><path d="M1270 830 L1270 520 Q1270 420 1370 410 L1410 410 Q1320 430 1320 530 L1320 830 Z" fill="#623d36"/>')
    b.append('<path d="M1300 640 L1560 640 L1590 720 L1270 720 Z" fill="#3a231f"/><path d="M1330 520 q100 40 200 -6 l20 140 q-120 30 -240 0Z" fill="#7f8f6a" opacity="0.8"/>')
    b.append('<rect x="1250" y="620" width="50" height="210" rx="20" fill="#623d36"/><rect x="1560" y="620" width="50" height="210" rx="20" fill="#3a231f"/>')
    b.append('<circle cx="1720" cy="560" r="300" fill="url(#glowA)" opacity="0.6"/>')
    b.append('<rect x="1630" y="640" width="200" height="14" fill="#4a3625"/><rect x="1722" y="654" width="16" height="176" fill="#2a2018"/><path d="M1660 830 h140 l-20 -16 h-100Z" fill="#2a2018"/>')
    b.append(f'<rect x="1640" y="624" width="180" height="16" rx="6" fill="#aab2be"/><rect x="1668" y="520" width="42" height="104" rx="8" fill="#dfeaff" opacity="0.75"/><rect x="1678" y="494" width="22" height="30" fill="#dfeaff" opacity="0.75"/><rect x="1672" y="560" width="34" height="40" fill="{PAPER}"/>'
             '<path d="M1750 566 l40 0 l-5 58 l-30 0Z" fill="#f4f8ff" opacity="0.6"/><rect x="1756" y="596" width="28" height="26" fill="#f4f8ff" opacity="0.5"/>')
    # desk: pills, diary, telephone, envelope
    b.append('<rect x="1920" y="640" width="720" height="18" fill="#4a3625"/><rect x="1940" y="658" width="680" height="172" fill="url(#desk)"/>')
    b.append(desk_lamp(2590, 640))
    b.append("".join(f'<rect x="{1956+i*24}" y="604" width="22" height="34" rx="3" fill="{["#7fa8c9","#c9a27f","#9fc98f","#c98f9f","#c9c27f","#8f9fc9","#aab2be"][i]}"/>' for i in range(7)) + '<rect x="1952" y="634" width="176" height="8" fill="#39424f"/>')
    b.append(f'<rect x="2136" y="578" width="42" height="62" rx="6" fill="#b06a2a"/><rect x="2136" y="570" width="42" height="14" rx="4" fill="{PAPER}"/><rect x="2140" y="598" width="34" height="24" fill="{PAPER}"/>')
    b.append(f'<path d="M2196 640 L2208 590 L2278 586 L2280 640 Z" fill="{PAPER}"/><path d="M2280 640 L2278 586 L2348 590 L2360 640 Z" fill="#f3ead4"/>' + text_lines(2216, 600, 50, 3, 11, seed=5, sw=3) + text_lines(2290, 600, 50, 3, 11, seed=6, sw=3) + f'<rect x="2290" y="620" width="50" height="6" fill="{RED}" opacity="0.7"/>')
    b.append('<rect x="2384" y="596" width="110" height="44" rx="8" fill="#17110c"/><rect x="2394" y="578" width="90" height="22" rx="10" fill="#2a2018"/><circle cx="2440" cy="620" r="13" fill="#39424f"/>')
    b.append(f'<g transform="rotate(5 2540 628)"><rect x="2500" y="612" width="96" height="30" fill="{PAPER_D}"/><path d="M2500 612 L2548 630 L2596 612" fill="none" stroke="#8a7a5a" stroke-width="3"/></g>')
    # Cem beside the desk, behind a low cabinet
    b.append(figure("cem", 2760, 672, 0.86))
    b.append('<rect x="2650" y="660" width="220" height="170" fill="#3a2a1d"/><rect x="2640" y="648" width="240" height="16" fill="#7a5a3c"/>')
    # bookshelf wall
    r = random.Random(12)
    b.append('<rect x="1940" y="170" width="660" height="330" fill="#2a1f16"/>')
    for row in range(2):
        y = 190 + row * 160
        b.append(f'<rect x="1954" y="{y+130}" width="632" height="12" fill="#17110c"/>')
        x = 1962
        while x < 2570:
            w = 18 + r.random() * 24
            hh = 96 + r.random() * 30
            b.append(f'<rect x="{x:.0f}" y="{y+130-hh:.0f}" width="{w:.0f}" height="{hh:.0f}" fill="{r.choice(["#5a2a22","#2c3d4f","#4a4a32","#3a2f45","#6a5a3c","#24413a"])}"/>')
            x += w + 3
    finish("house", d, b)
    out("house", "assets/scenes/house.png")


# ------------------------------------------------------------------ forensic institute
def institute():
    d, b = room("#0e1418", "#1c2a30", "#1a2226", "#080b0c", lamp="#dfeaff", panels=False)
    for x in range(0, 2880, 240):
        b.append(f'<rect x="{x}" y="0" width="236" height="826" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.04"/>')
    # steel table with a sheet
    b.append('<circle cx="520" cy="300" r="460" fill="url(#glowW)" opacity="0.4"/><rect x="430" y="0" width="12" height="140" fill="#05070b"/><path d="M340 180 Q436 110 532 180 Z" fill="#0a0d14"/><ellipse cx="436" cy="182" rx="80" ry="10" fill="#f4f8ff"/>')
    b.append('<rect x="140" y="640" width="720" height="20" fill="#aab2be"/><rect x="170" y="660" width="16" height="170" fill="#8a93a3"/><rect x="810" y="660" width="16" height="170" fill="#8a93a3"/>')
    b.append('<path d="M160 640 Q200 560 320 570 L700 570 Q820 560 850 640 Z" fill="#dfe5ee"/><path d="M160 640 L850 640 L880 720 L130 720 Z" fill="#c9cfda" opacity="0.7"/>')
    # specimen fridge with the stock log on its door
    b.append('<rect x="980" y="300" width="260" height="530" rx="8" fill="#c9cfda"/><rect x="996" y="316" width="228" height="250" fill="#28505a" opacity="0.5"/><rect x="1206" y="600" width="12" height="130" rx="6" fill="#8a93a3"/>')
    b.append(f'<rect x="1020" y="610" width="150" height="180" fill="{PAPER}"/><rect x="1070" y="602" width="50" height="16" rx="4" fill="{RED}"/>' + text_lines(1034, 636, 122, 8, 17, seed=21, sw=4))
    # Nur at the bench
    b.append(figure("nur", 1560, 662, 0.88))
    b.append('<rect x="1330" y="650" width="900" height="18" fill="#8a93a3"/><rect x="1350" y="668" width="860" height="162" fill="#2f3743"/>')
    b.append('<circle cx="1900" cy="560" r="170" fill="url(#glowM)"/><rect x="1820" y="520" width="170" height="130" rx="8" fill="#39424f"/><rect x="1834" y="534" width="100" height="62" fill="#28505a"/>' + text_lines(1842, 546, 84, 3, 15, color="#a8f0e6", op=0.8, seed=22, sw=3) + f'<circle cx="1962" cy="552" r="8" fill="{JADE}"/><circle cx="1962" cy="580" r="8" fill="{RED}"/>')
    b.append("".join(f'<rect x="{2030+i*26}" y="{590}" width="16" height="60" rx="6" fill="#dfeaff" opacity="0.7"/><rect x="{2030+i*26}" y="{620}" width="16" height="30" rx="6" fill="{["#b06a2a","#7fa8c9","#b06a2a","#9fc98f","#b06a2a"][i]}"/>' for i in range(5)) + '<rect x="2022" y="640" width="140" height="10" fill="#56606f"/>')
    b.append(f'<g transform="rotate(-5 1410 620)"><rect x="1360" y="588" width="110" height="64" fill="{PAPER}"/>' + text_lines(1370, 602, 90, 3, 14, seed=23, sw=3) + f'<rect x="1370" y="640" width="60" height="6" fill="{RED}"/></g>')
    b.append(f'<g transform="rotate(4 1720 624)"><rect x="1670" y="596" width="104" height="58" fill="#f3ead4"/>' + text_lines(1680, 608, 84, 3, 13, seed=24, sw=3) + '</g>')
    # shelf with the old registers
    b.append('<rect x="2330" y="260" width="460" height="16" fill="#56606f"/><rect x="2330" y="470" width="460" height="16" fill="#56606f"/>')
    r = random.Random(7)
    for (y0, n) in ((276 - 150, 9), (486 - 160, 8)):
        x = 2344
        for i in range(n):
            w = 40 + r.random() * 12
            b.append(f'<rect x="{x:.0f}" y="{y0+r.random()*14:.0f}" width="{w:.0f}" height="150" fill="{r.choice(["#24413a","#5a2a22","#23324a","#4a4a32"])}"/><rect x="{x+8:.0f}" y="{y0+40:.0f}" width="{w-16:.0f}" height="26" fill="{PAPER_D}"/>')
            x += w + 5
    b.append(f'<g transform="rotate(-10 2560 660)"><path d="M2450 700 L2470 590 L2560 582 L2562 700 Z" fill="{PAPER}"/><path d="M2562 700 L2560 582 L2650 590 L2670 700 Z" fill="#f3ead4"/><path d="M2450 700 L2670 700 L2670 712 L2450 712 Z" fill="#24413a"/>' + text_lines(2482, 606, 66, 6, 14, seed=25, sw=3) + text_lines(2574, 606, 66, 6, 14, seed=26, sw=3) + f'<rect x="2574" y="646" width="76" height="12" fill="{AMBER}" opacity="0.6"/></g>')
    b.append('<rect x="2420" y="712" width="280" height="118" fill="#2f3743"/>')
    finish("institute", d, b)
    out("institute", "assets/scenes/institute.png")


# ------------------------------------------------------------------ old harbour
def harbour():
    d, b = night("#080d16", "#16233a", "#1c1a17", "#080706", horizon=700)
    r = random.Random(14)
    b.append('<rect x="0" y="520" width="2880" height="180" fill="#0b1422"/>')
    for _ in range(40):
        x, y = r.random() * 2880, 500 + r.random() * 40
        b.append(f'<rect x="{x:.0f}" y="{y:.0f}" width="6" height="6" fill="{r.choice([AMBER, "#9fd0ff"])}" opacity="{0.3+r.random()*0.5:.2f}"/><rect x="{x:.0f}" y="{y+30:.0f}" width="6" height="{30+r.random()*70:.0f}" fill="{AMBER}" opacity="0.07"/>')
    # a boat at the quay
    b.append('<path d="M120 640 L620 640 L560 720 L190 720 Z" fill="#23324a"/><rect x="330" y="560" width="120" height="80" fill="#e8ecf2"/><rect x="350" y="576" width="34" height="30" fill="#17202f"/><rect x="384" y="430" width="8" height="130" fill="#39424f"/>')
    b.append('<rect x="0" y="700" width="2880" height="14" fill="#3a3a3a"/>')
    for x in (700, 760):
        b.append(f'<rect x="{x}" y="640" width="26" height="70" rx="6" fill="#39424f"/>')
    # café table: backgammon and the tally slate, Bulut behind it
    b.append('<circle cx="1180" cy="330" r="430" fill="url(#glowA)" opacity="0.55"/><rect x="1174" y="120" width="10" height="150" fill="#05070b"/><path d="M1110 300 Q1179 230 1248 300 Z" fill="#7a5320"/><ellipse cx="1179" cy="302" rx="56" ry="8" fill="#ffe2a8"/>')
    b.append(figure("bulut", 1180, 672, 0.9))
    b.append('<rect x="930" y="660" width="560" height="18" fill="#7a5a3c"/><rect x="960" y="678" width="14" height="152" fill="#2a2018"/><rect x="1446" y="678" width="14" height="152" fill="#2a2018"/>')
    b.append(f'<rect x="960" y="612" width="210" height="48" fill="#5a3a22"/><rect x="968" y="618" width="194" height="36" fill="#7a5a3c"/>' + "".join(f'<path d="M{976+i*18} 618 l8 30 l8 -30Z" fill="{PAPER if i % 2 else "#2a2018"}"/>' for i in range(10)))
    b.append(f'<g transform="rotate(8 1380 610)"><rect x="1320" y="560" width="120" height="100" fill="#17202f" stroke="#7a5a3c" stroke-width="8"/>' + "".join(f'<line x1="{1338+i*14}" y1="580" x2="{1338+i*14}" y2="612" stroke="{PAPER}" stroke-width="4"/>' for i in range(6)) + f'<line x1="1334" y1="630" x2="1420" y2="630" stroke="{PAPER}" stroke-width="4"/></g>')
    # shed No. 7: door plate, newspapers, stove, pinned slips
    b.append('<rect x="1700" y="300" width="900" height="530" fill="#2f4660"/>' + "".join(f'<rect x="{x}" y="300" width="6" height="530" fill="#22354a"/>' for x in range(1740, 2600, 60)))
    b.append('<path d="M1660 300 L2150 190 L2640 300 Z" fill="#1b2b3d"/><rect x="2010" y="470" width="230" height="360" fill="#141c26"/>')
    b.append(f'<rect x="2060" y="390" width="130" height="60" rx="6" fill="{PAPER}"/><rect x="2076" y="404" width="40" height="32" fill="{INK}"/><rect x="2124" y="408" width="54" height="8" fill="{INK}" opacity="0.7"/><rect x="2124" y="424" width="40" height="8" fill="{INK}" opacity="0.5"/>')
    b.append("".join(f'<rect x="{1790+(i%2)*6}" y="{790-i*16}" width="170" height="16" fill="{[PAPER, PAPER_D][i % 2]}"/>' for i in range(6)) + f'<rect x="1800" y="704" width="80" height="8" fill="{INK}" opacity="0.7"/>')
    b.append('<rect x="2330" y="640" width="170" height="190" rx="10" fill="#17110c"/><rect x="2390" y="430" width="30" height="210" fill="#17110c"/><rect x="2350" y="700" width="130" height="80" rx="6" fill="#0a0806"/>')
    b.append(f'<circle cx="2415" cy="745" r="60" fill="{AMBER}" opacity="0.18" filter="url(#blur8)"/><path d="M2370 770 l20 -30 l16 18 l18 -34 l22 46Z" fill="#e2622a" opacity="0.8"/><rect x="2376" y="756" width="46" height="14" fill="#c9cfda" transform="rotate(-14 2376 756)"/><rect x="2420" y="762" width="40" height="12" fill="#aab2be" transform="rotate(10 2420 762)"/>')
    b.append('<rect x="1740" y="350" width="230" height="200" fill="#3b2b1e"/><rect x="1752" y="362" width="206" height="176" fill="#2b2018"/>' + "".join(f'<rect x="{1764+(i%3)*64}" y="{374+(i//3)*80}" width="56" height="66" fill="{[PAPER, "#f3ead4", PAPER_D][i % 3]}" transform="rotate({[-5, 3, -2, 4, -4, 2][i]} {1792+(i%3)*64} {407+(i//3)*80})"/><circle cx="{1792+(i%3)*64}" cy="{378+(i//3)*80}" r="5" fill="{RED}"/>' for i in range(6)))
    # fish crates
    for i, x in enumerate((2660, 2700)):
        b.append(f'<rect x="{x}" y="{760-i*70}" width="170" height="70" fill="#5a4636" stroke="#2a2018" stroke-width="5"/>')
    b.append('<ellipse cx="2760" cy="690" rx="60" ry="14" fill="#aab2be"/><ellipse cx="2800" cy="688" rx="40" ry="10" fill="#8a93a3"/>')
    b.append(rain(0, 0, 2880, 1080, 300, 15, 0.12))
    finish("harbour", d, b)
    out("harbour", "assets/scenes/harbour.png")


# ------------------------------------------------------------------ police records room
def records():
    d, b = room("#101216", "#20242c", "#1c1e22", "#08090b", panels=False)
    # the flood line: ankle-high
    b.append('<path d="M0 786 Q360 780 720 788 T1440 784 T2160 790 T2880 784 L2880 830 L0 830 Z" fill="#3a3a30" opacity="0.5"/>')
    # shelving with binders
    for sx in (120, 760):
        b.append(f'<rect x="{sx}" y="130" width="16" height="700" fill="#2a3446"/><rect x="{sx+544}" y="130" width="16" height="700" fill="#2a3446"/>')
        for row, y in enumerate((260, 420, 580, 740)):
            b.append(f'<rect x="{sx}" y="{y}" width="560" height="14" fill="#3a4558"/>' + boxes(sx + 22, y - 116, 516, 5, 40 + row + sx, missing=(2 if (sx, row) == (760, 0) else None), h=116))
    # counter with the register and the card index
    b.append('<rect x="1440" y="640" width="900" height="20" fill="#4a3625"/><rect x="1460" y="660" width="860" height="170" fill="url(#desk)"/>')
    b.append(desk_lamp(1520, 640))
    b.append(f'<g transform="rotate(-3 1700 610)"><path d="M1600 640 L1616 566 L1706 560 L1708 640 Z" fill="{PAPER}"/><path d="M1708 640 L1706 560 L1796 566 L1812 640 Z" fill="#f3ead4"/>' + text_lines(1626, 578, 66, 4, 13, seed=31, sw=3) + text_lines(1718, 578, 66, 4, 13, seed=32, sw=3) + f'<rect x="1718" y="602" width="78" height="12" fill="{RED}" opacity="0.5"/></g>')
    b.append('<rect x="1900" y="560" width="230" height="80" fill="#39424f"/><rect x="1900" y="540" width="230" height="26" fill="#56606f"/>' + "".join(f'<rect x="{1912+i*18}" y="{518-(i%3)*6}" width="14" height="44" fill="{[PAPER, PAPER_D, "#f3ead4"][i % 3]}"/>' for i in range(12)) + f'<rect x="1966" y="500" width="14" height="60" fill="{AMBER}"/>')
    # the chief
    b.append(figure("soykan", 2500, 700, 0.9))
    b.append('<rect x="2360" y="690" width="300" height="140" fill="#2a2018"/><rect x="2350" y="676" width="320" height="18" fill="#4a3625"/>')
    b.append('<rect x="2740" y="210" width="60" height="620" fill="#070a10"/>')
    finish("records", d, b)
    out("records", "assets/scenes/records.png")


# ------------------------------------------------------------------ icons
def icons():
    def ic(name, inner):
        icon("c3_" + name, inner)
        out("c3_" + name, f"assets/evidence/c3_{name}.png")
    ic("pills", "".join(f'<rect x="{96+i*46}" y="200" width="40" height="110" rx="6" fill="{["#7fa8c9","#c9a27f","#9fc98f","#c98f9f","#c9c27f","#8f9fc9","#aab2be"][i]}"/>' for i in range(7))
       + '<rect x="88" y="300" width="336" height="18" fill="#39424f"/>' + f'<rect x="210" y="336" width="90" height="84" rx="10" fill="#b06a2a"/><rect x="210" y="326" width="90" height="22" rx="6" fill="{PAPER}"/><rect x="220" y="366" width="70" height="34" fill="{PAPER}"/>')
    ic("raki", f'<rect x="180" y="150" width="90" height="250" rx="16" fill="#dfeaff" opacity="0.85"/><rect x="204" y="96" width="42" height="64" fill="#dfeaff" opacity="0.85"/><rect x="190" y="240" width="70" height="90" fill="{PAPER}"/><rect x="200" y="262" width="50" height="10" fill="{INK}"/>'
       '<path d="M300 250 l92 0 l-12 150 l-68 0Z" fill="#f4f8ff" opacity="0.7"/><rect x="312" y="330" width="68" height="66" fill="#f4f8ff" opacity="0.6"/>')
    ic("glass", '<rect x="96" y="330" width="320" height="20" fill="#aab2be"/>' + "".join(f'<line x1="{130+i*52}" y1="210" x2="{130+i*52}" y2="330" stroke="#aab2be" stroke-width="8"/>' for i in range(6))
       + '<path d="M216 180 l96 0 l-14 150 l-68 0Z" fill="#dfeaff" opacity="0.75"/><ellipse cx="264" cy="180" rx="48" ry="10" fill="#f4f8ff"/><path d="M236 250 q-6 20 0 40 M292 240 q8 24 0 50" stroke="#9fd0ff" stroke-width="6" fill="none"/>')
    ic("fish", sheet(110, 190, 300, 160, -6) + text_lines(126, 210, 120, 5, 22, seed=41, sw=6) + f'<rect x="270" y="206" width="120" height="50" fill="#fff"/><rect x="280" y="218" width="80" height="8" fill="{INK}"/><rect x="280" y="234" width="60" height="8" fill="{INK}" opacity="0.6"/></g>'
       + '<path d="M150 250 q110 -70 220 0 q-110 70 -220 0Z" fill="#aab2be"/><path d="M370 250 l56 -36 l0 72Z" fill="#8a93a3"/><circle cx="196" cy="244" r="9" fill="#17202f"/>')
    ic("blister", "".join(f'<g transform="rotate({[-10, 8][j]} 256 {200+j*110})"><rect x="130" y="{160+j*110}" width="252" height="86" rx="10" fill="#c9cfda"/>' + "".join(f'<circle cx="{166+i*46}" cy="{203+j*110}" r="16" fill="{"#39424f" if (i + j) % 3 else "#f3ead4"}"/>' for i in range(5)) + '</g>' for j in range(2))
       + '<path d="M120 380 l40 -50 l30 30 l34 -60 l40 80Z" fill="#e2622a" opacity="0.75"/>')
    ic("ampoule", f'<rect x="150" y="100" width="212" height="310" fill="{PAPER}"/><rect x="230" y="88" width="52" height="24" rx="6" fill="{RED}"/>' + text_lines(170, 140, 172, 6, 26, seed=42, sw=7)
       + '<path d="M300 300 l40 0 l0 70 q-20 24 -40 0Z" fill="#dfeaff" stroke="#39424f" stroke-width="5"/><rect x="310" y="280" width="20" height="24" fill="#dfeaff" stroke="#39424f" stroke-width="5"/>')
    ic("tally", f'<rect x="110" y="120" width="292" height="272" fill="#17202f" stroke="#7a5a3c" stroke-width="16"/>' + "".join(f'<line x1="{150+i*26}" y1="170" x2="{150+i*26}" y2="240" stroke="{PAPER}" stroke-width="8"/>' for i in range(8))
       + f'<line x1="140" y1="290" x2="372" y2="290" stroke="{PAPER}" stroke-width="8"/><line x1="150" y1="330" x2="250" y2="330" stroke="{AMBER}" stroke-width="8"/>')
    ic("slips", "".join(sheet(130 + i * 60, 130 + (i % 2) * 70, 130, 160, [-6, 5, -3][i], [PAPER, "#f3ead4", PAPER_D][i]) + text_lines(144 + i * 60, 160 + (i % 2) * 70, 100, 4, 24, seed=43 + i, sw=6) + f'</g><circle cx="{195+i*60}" cy="{140+(i%2)*70}" r="10" fill="{RED}"/>' for i in range(3)))
    ic("papers", "".join(f'<rect x="{110+(i%2)*10}" y="{340-i*34}" width="290" height="34" fill="{[PAPER, PAPER_D][i % 2]}"/>' for i in range(6)) + f'<rect x="130" y="176" width="150" height="14" fill="{INK}"/><rect x="290" y="166" width="100" height="40" fill="#fff"/><rect x="298" y="176" width="70" height="8" fill="{INK}"/><rect x="298" y="190" width="50" height="8" fill="{INK}" opacity="0.6"/>')
    ic("card", f'<rect x="90" y="150" width="332" height="220" rx="8" fill="{PAPER}"/><rect x="90" y="150" width="332" height="44" rx="8" fill="#23324a"/><rect x="112" y="214" width="96" height="120" fill="#59616e"/><circle cx="160" cy="258" r="24" fill="#8b6f5c"/><path d="M124 334 q6 -44 36 -46 q30 2 36 46Z" fill="#1d2330"/>' + text_lines(228, 226, 170, 5, 24, seed=46, sw=6))
    ic("parking", f'<rect x="150" y="96" width="212" height="320" fill="{PAPER}" transform="rotate(5 256 256)"/><rect x="170" y="120" width="172" height="46" fill="{RED}" transform="rotate(5 256 256)"/>' + f'<g transform="rotate(5 256 256)">' + text_lines(174, 196, 164, 6, 28, seed=47, sw=7) + f'<rect x="174" y="370" width="110" height="24" fill="{INK}"/></g>')


if __name__ == "__main__":
    portraits(); house(); institute(); harbour(); records(); icons()
    with open(os.path.join(OUT, "targets_case03.json"), "w") as f:
        json.dump(TARGETS, f, indent=1)
    print("Case 3 SVG sources written:", len(TARGETS))
