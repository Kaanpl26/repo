#!/usr/bin/env python3
"""Generates the game's original vector art as SVG files in art_src/.
Run tools/render_art.js afterwards to turn them into the PNGs the game uses.
All artwork here is original to this project."""
import os, random, math

OUT = os.path.join(os.path.dirname(__file__), "..", "art_src")
os.makedirs(OUT, exist_ok=True)

NAVY, CHAR, SLATE = "#0e1420", "#1b2230", "#2a3446"
PAPER, PAPER_D, INK = "#e8dfc8", "#cfc3a4", "#1d1a16"
AMBER, RED, JADE = "#e3a446", "#b8413a", "#4fa58a"

GRAIN = """<filter id="grain" x="0" y="0" width="100%" height="100%">
<feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="7" result="n"/>
<feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.07 0"/></filter>
<filter id="blur8"><feGaussianBlur stdDeviation="8"/></filter>
<filter id="blur20"><feGaussianBlur stdDeviation="20"/></filter>
<filter id="blur3"><feGaussianBlur stdDeviation="3"/></filter>"""


def save(name, w, h, body, defs=""):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{GRAIN}{defs}</defs>{body}</svg>'
    with open(os.path.join(OUT, name + ".svg"), "w") as f:
        f.write(svg)


def rain(x, y, w, h, n, seed, op=0.22):
    r = random.Random(seed)
    out = []
    for _ in range(n):
        px, py, ln = x + r.random() * w, y + r.random() * h, 20 + r.random() * 60
        out.append(f'<line x1="{px:.0f}" y1="{py:.0f}" x2="{px-ln*0.18:.0f}" y2="{min(py+ln, y+h):.0f}" stroke="#cfe0ff" stroke-width="{1+r.random()*1.5:.1f}" opacity="{op*(0.4+r.random()):.2f}"/>')
    return "".join(out)


def text_lines(x, y, w, n, gap=14, color=INK, op=0.55, seed=1, sw=4):
    r = random.Random(seed)
    return "".join(f'<line x1="{x}" y1="{y+i*gap}" x2="{x+w*(0.55+0.45*r.random()):.0f}" y2="{y+i*gap}" stroke="{color}" stroke-width="{sw}" opacity="{op}" stroke-linecap="round"/>' for i in range(n))


# ------------------------------------------------------------------ guard figure
def guard(cx, base, s=1.0, portrait=False):
    """Veysel Erdem: night guard, cap, heavy moustache. cx = centre x, base = bottom y."""
    def P(x, y):
        return f"{cx + x*s:.1f},{base + y*s:.1f}"
    skin, skin_sh = "#b98d6f", "#6e5343"
    uni, uni_l = "#1f2a3d", "#34435e"
    g = []
    # torso
    g.append(f'<path d="M{P(-150,0)} L{P(-150,-170)} Q{P(-145,-235)} {P(-70,-255)} L{P(70,-255)} Q{P(145,-235)} {P(150,-170)} L{P(150,0)} Z" fill="{uni}"/>')
    g.append(f'<path d="M{P(-150,0)} L{P(-150,-170)} Q{P(-145,-235)} {P(-70,-255)} L{P(-40,-255)} Q{P(-110,-220)} {P(-112,-160)} L{P(-112,0)} Z" fill="{uni_l}"/>')
    # shirt + tie
    g.append(f'<path d="M{P(-38,-258)} L{P(0,-190)} L{P(38,-258)} Z" fill="#c9cfda"/>')
    g.append(f'<path d="M{P(-11,-240)} L{P(11,-240)} L{P(15,-150)} L{P(0,-128)} L{P(-15,-150)} Z" fill="#11161f"/>')
    g.append(f'<path d="M{P(-38,-258)} L{P(-62,-236)} L{P(-12,-200)} Z" fill="{uni_l}"/><path d="M{P(38,-258)} L{P(62,-236)} L{P(12,-200)} Z" fill="#182132"/>')
    # badge + pocket
    g.append(f'<path d="M{P(62,-178)} l{16*s},{-8*s} l{16*s},{8*s} l0,{20*s} q{-16*s},{16*s} {-32*s},0 Z" fill="{AMBER}"/>')
    g.append(f'<rect x="{cx-100*s}" y="{base-150*s}" width="{56*s}" height="{6*s}" fill="#141c2a"/>')
    # neck
    g.append(f'<path d="M{P(-34,-262)} L{P(-30,-300)} L{P(30,-300)} L{P(34,-262)} L{P(0,-232)} Z" fill="{skin_sh}"/>')
    # head
    g.append(f'<path d="M{P(-62,-395)} Q{P(-66,-300)} {P(-28,-278)} Q{P(0,-266)} {P(28,-278)} Q{P(66,-300)} {P(62,-395)} Z" fill="{skin}"/>')
    g.append(f'<path d="M{P(8,-395)} L{P(62,-395)} Q{P(66,-300)} {P(28,-278)} Q{P(10,-270)} {P(0,-270)} Q{P(22,-300)} {P(14,-340)} Z" fill="{skin_sh}"/>')
    # ears
    g.append(f'<ellipse cx="{cx-64*s}" cy="{base-352*s}" rx="{9*s}" ry="{17*s}" fill="{skin}"/><ellipse cx="{cx+64*s}" cy="{base-352*s}" rx="{9*s}" ry="{17*s}" fill="{skin_sh}"/>')
    # brows, eyes, nose
    g.append(f'<path d="M{P(-48,-374)} L{P(-14,-368)} L{P(-14,-361)} L{P(-48,-365)} Z" fill="#2a2420"/><path d="M{P(48,-374)} L{P(14,-368)} L{P(14,-361)} L{P(48,-365)} Z" fill="#1b1714"/>')
    g.append(f'<ellipse cx="{cx-30*s}" cy="{base-352*s}" rx="{7*s}" ry="{4*s}" fill="#15110f"/><ellipse cx="{cx+30*s}" cy="{base-352*s}" rx="{7*s}" ry="{4*s}" fill="#15110f"/>')
    g.append(f'<path d="M{P(-4,-356)} L{P(-12,-318)} L{P(8,-314)} Z" fill="{skin_sh}" opacity="0.8"/>')
    # moustache + mouth
    g.append(f'<path d="M{P(-40,-300)} Q{P(-20,-318)} {P(0,-310)} Q{P(20,-318)} {P(40,-300)} Q{P(20,-296)} {P(0,-300)} Q{P(-20,-296)} {P(-40,-300)} Z" fill="#8f8a83"/>')
    g.append(f'<path d="M{P(-16,-290)} L{P(16,-290)}" stroke="#4a372d" stroke-width="{3*s}" />')
    # cap
    g.append(f'<path d="M{P(-70,-398)} Q{P(-78,-452)} {P(0,-460)} Q{P(78,-452)} {P(70,-398)} Z" fill="{uni}"/>')
    g.append(f'<path d="M{P(-70,-398)} Q{P(-78,-452)} {P(0,-460)} Q{P(-40,-440)} {P(-36,-398)} Z" fill="{uni_l}"/>')
    g.append(f'<path d="M{P(-76,-398)} L{P(76,-398)} L{P(88,-384)} Q{P(0,-372)} {P(-88,-384)} Z" fill="#0c1018"/>')
    g.append(f'<circle cx="{cx}" cy="{base-424*s}" r="{11*s}" fill="{AMBER}"/>')
    if portrait:
        # amber rim light from the desk lamp side
        g.append(f'<path d="M{P(-150,0)} L{P(-150,-170)} Q{P(-145,-235)} {P(-70,-255)}" fill="none" stroke="{AMBER}" stroke-width="{5*s}" opacity="0.7"/>')
        g.append(f'<path d="M{P(-62,-395)} Q{P(-66,-300)} {P(-28,-278)}" fill="none" stroke="{AMBER}" stroke-width="{4*s}" opacity="0.6"/>')
    return "".join(g)


# ------------------------------------------------------------------ lobby
def lobby():
    W, H, FL = 2880, 1080, 830
    d = f"""
<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c111b"/><stop offset="1" stop-color="#1a2233"/></linearGradient>
<linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1b2231"/><stop offset="1" stop-color="#080b12"/></linearGradient>
<linearGradient id="glass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#31445f"/><stop offset="1" stop-color="#17202f"/></linearGradient>
<linearGradient id="desk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2a1d"/><stop offset="1" stop-color="#17110c"/></linearGradient>
<linearGradient id="cone" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{AMBER}" stop-opacity="0.34"/><stop offset="1" stop-color="{AMBER}" stop-opacity="0"/></linearGradient>
<radialGradient id="glowA"><stop offset="0" stop-color="#ffd58a" stop-opacity="0.75"/><stop offset="0.35" stop-color="{AMBER}" stop-opacity="0.28"/><stop offset="1" stop-color="{AMBER}" stop-opacity="0"/></radialGradient>
<radialGradient id="glowB"><stop offset="0" stop-color="#9fd0ff" stop-opacity="0.55"/><stop offset="1" stop-color="#9fd0ff" stop-opacity="0"/></radialGradient>
<radialGradient id="glowM"><stop offset="0" stop-color="#7fd6d0" stop-opacity="0.4"/><stop offset="1" stop-color="#7fd6d0" stop-opacity="0"/></radialGradient>
<radialGradient id="vig" cx="0.55" cy="0.5" r="0.75"><stop offset="0.45" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.72"/></radialGradient>
<clipPath id="doorclip"><rect x="110" y="220" width="390" height="610"/></clipPath>
"""
    b = []
    b.append(f'<rect width="{W}" height="{FL}" fill="url(#wall)"/>')
    # wall panelling
    b.append(f'<rect x="0" y="560" width="{W}" height="{FL-560}" fill="#121926"/><rect x="0" y="556" width="{W}" height="8" fill="#273247"/>')
    for x in range(40, W, 240):
        b.append(f'<rect x="{x}" y="590" width="200" height="210" fill="none" stroke="#1f293b" stroke-width="4"/>')
    b.append(f'<rect x="0" y="{FL-14}" width="{W}" height="14" fill="#0a0e16"/>')
    # floor
    b.append(f'<rect x="0" y="{FL}" width="{W}" height="{H-FL}" fill="url(#floor)"/>')
    for i, y in enumerate([850, 880, 925, 990]):
        b.append(f'<line x1="0" y1="{y}" x2="{W}" y2="{y}" stroke="#2a3446" stroke-width="2" opacity="{0.5-i*0.1}"/>')
    for x in range(-600, W + 600, 180):
        x2 = 1440 + (x - 1440) * 1.9
        b.append(f'<line x1="{x}" y1="{FL}" x2="{x2:.0f}" y2="{H}" stroke="#2a3446" stroke-width="2" opacity="0.28"/>')

    # ---- entrance doors (left)
    b.append('<rect x="80" y="190" width="450" height="640" fill="#080b12"/>')
    b.append('<rect x="110" y="220" width="390" height="610" fill="url(#glass)"/>')
    b.append('<g clip-path="url(#doorclip)">')
    b.append('<circle cx="390" cy="330" r="230" fill="url(#glowB)"/><circle cx="390" cy="330" r="16" fill="#e6f2ff"/>')
    b.append('<rect x="382" y="340" width="14" height="500" fill="#0c111b" opacity="0.8"/>')
    b.append('<path d="M110 700 L190 640 L250 690 L330 610 L420 680 L500 650 L500 830 L110 830 Z" fill="#0c121d" opacity="0.85"/>')
    b.append(rain(110, 220, 390, 610, 150, 3))
    b.append('</g>')
    b.append('<rect x="298" y="220" width="14" height="610" fill="#080b12"/>')
    b.append(f'<rect x="270" y="500" width="14" height="110" rx="6" fill="{AMBER}" opacity="0.8"/><rect x="326" y="500" width="14" height="110" rx="6" fill="{AMBER}" opacity="0.8"/>')
    b.append('<path d="M110 830 L500 830 L760 1080 L-140 1080 Z" fill="#9fd0ff" opacity="0.07"/>')

    # ---- newspaper rack
    b.append('<path d="M600 830 L600 560 L770 560 L770 830" fill="none" stroke="#3a4558" stroke-width="10"/>')
    b.append('<rect x="596" y="690" width="178" height="10" fill="#3a4558"/>')
    b.append(f'<path d="M612 600 L758 590 L762 686 L610 690 Z" fill="{PAPER}"/><rect x="622" y="606" width="126" height="16" fill="{INK}" opacity="0.85" transform="rotate(-3 622 606)"/>')
    b.append(f'<rect x="626" y="634" width="56" height="42" fill="#59616e" transform="rotate(-3 626 634)"/>' + text_lines(692, 634, 58, 4, 11, seed=4, sw=3))
    b.append(f'<path d="M612 724 L760 720 L762 800 L610 802 Z" fill="{PAPER_D}"/>' + text_lines(622, 736, 126, 5, 12, seed=5, sw=3))

    # ---- staff portrait board
    b.append('<rect x="880" y="190" width="400" height="280" fill="#3b2b1e"/><rect x="896" y="206" width="368" height="248" fill="#1f3a34"/>')
    b.append(f'<rect x="1010" y="216" width="140" height="18" fill="{AMBER}" opacity="0.85"/>')
    hair = ["#2a2420", "#a9a39a", "#3a2a22", "#1c1c22"]
    for i in range(4):
        x = 912 + i * 88
        b.append(f'<rect x="{x}" y="252" width="76" height="104" fill="{PAPER}"/>')
        b.append(f'<circle cx="{x+38}" cy="290" r="17" fill="#8b6f5c"/><path d="M{x+21} 286 q17 -30 34 0 q-17 -12 -34 0Z" fill="{hair[i]}"/><path d="M{x+10} 356 q4 -40 28 -42 q24 2 28 42 Z" fill="#2c3648"/>')
        b.append(f'<rect x="{x+10}" y="364" width="56" height="6" fill="{PAPER}" opacity="0.6"/><rect x="{x+18}" y="376" width="40" height="5" fill="{PAPER}" opacity="0.4"/>')
    # director: jade earrings (first portrait), longer hair
    b.append(f'<path d="M933 286 q-6 26 2 40 l6 -30Z M967 286 q6 26 -2 40 l-6 -30Z" fill="{hair[0]}"/><circle cx="932" cy="302" r="4" fill="{JADE}"/><circle cx="968" cy="302" r="4" fill="{JADE}"/>')
    # ---- wall clock (08:14)
    b.append(f'<circle cx="1420" cy="210" r="62" fill="#2a2018"/><circle cx="1420" cy="210" r="52" fill="{PAPER}"/>')
    for k in range(12):
        a = k * math.pi / 6
        b.append(f'<line x1="{1420+44*math.sin(a):.1f}" y1="{210-44*math.cos(a):.1f}" x2="{1420+50*math.sin(a):.1f}" y2="{210-50*math.cos(a):.1f}" stroke="{INK}" stroke-width="3"/>')
    ah, am = (8 + 14 / 60) * math.pi / 6, 14 * math.pi / 30
    b.append(f'<line x1="1420" y1="210" x2="{1420+26*math.sin(ah):.1f}" y2="{210-26*math.cos(ah):.1f}" stroke="{INK}" stroke-width="6" stroke-linecap="round"/><line x1="1420" y1="210" x2="{1420+40*math.sin(am):.1f}" y2="{210-40*math.cos(am):.1f}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>')

    # ---- pendant lamp + light cone over the desk
    b.append('<rect x="1746" y="0" width="6" height="110" fill="#05070b"/><path d="M1690 150 Q1749 70 1808 150 Z" fill="#0a0d14"/>')
    b.append('<path d="M1700 150 L1798 150 L2140 640 L1360 640 Z" fill="url(#cone)"/>')
    b.append('<ellipse cx="1749" cy="152" rx="46" ry="8" fill="#ffe2a8"/>')

    # ---- guard behind desk
    b.append(guard(1680, 660, 0.92))

    # ---- security desk
    b.append('<rect x="1240" y="606" width="1020" height="36" fill="#4a3625"/><rect x="1240" y="606" width="1020" height="6" fill="#7a5a3c"/>')
    b.append('<rect x="1260" y="642" width="980" height="262" fill="url(#desk)"/>')
    for x in (1290, 1610, 1930):
        b.append(f'<rect x="{x}" y="672" width="280" height="200" fill="none" stroke="#0f0b08" stroke-width="5"/><rect x="{x+6}" y="678" width="268" height="188" fill="none" stroke="#4a3625" stroke-width="2" opacity="0.6"/>')
    b.append(f'<circle cx="1750" cy="772" r="34" fill="none" stroke="{AMBER}" stroke-width="5" opacity="0.7"/><path d="M1750 748 v48 M1734 762 h32 M1730 786 q20 18 40 0" fill="none" stroke="{AMBER}" stroke-width="5" opacity="0.7"/>')
    b.append('<ellipse cx="1750" cy="930" rx="560" ry="40" fill="#000" opacity="0.45" filter="url(#blur8)"/>')
    # desk lamp
    b.append('<circle cx="1545" cy="560" r="330" fill="url(#glowA)" opacity="0.8"/>')
    b.append(f'<rect x="1520" y="596" width="56" height="10" rx="4" fill="#0a0d14"/><rect x="1544" y="530" width="8" height="70" fill="#0a0d14"/><path d="M1494 536 Q1548 478 1602 536 Z" fill="#7a5320"/><path d="M1500 536 L1596 536 L1590 546 L1506 546 Z" fill="#ffe2a8"/>')
    # visitor log (open ledger)
    b.append(f'<path d="M1300 606 L1316 566 L1406 560 L1408 606 Z" fill="{PAPER}"/><path d="M1408 606 L1406 560 L1496 566 L1512 606 Z" fill="#f3ead4"/><path d="M1300 606 L1512 606 L1512 612 L1300 612 Z" fill="#5a2a22"/>')
    b.append(text_lines(1326, 574, 70, 3, 9, seed=8, sw=2) + text_lines(1418, 574, 70, 3, 9, seed=9, sw=2))
    b.append('<rect x="1440" y="594" width="62" height="6" rx="3" fill="#0a0d14" transform="rotate(-14 1440 594)"/>')
    # patrol clipboard, leaning
    b.append(f'<g transform="rotate(8 1900 610)"><rect x="1850" y="508" width="100" height="104" rx="4" fill="#6a4a2c"/><rect x="1858" y="522" width="84" height="84" fill="{PAPER}"/><rect x="1880" y="502" width="40" height="16" rx="3" fill="#aab2be"/>' + text_lines(1866, 536, 68, 6, 11, seed=11, sw=3) + '</g>')
    # monitor
    b.append('<circle cx="2100" cy="520" r="210" fill="url(#glowM)"/>')
    b.append('<rect x="2010" y="450" width="180" height="128" rx="6" fill="#0a0d14"/><rect x="2020" y="460" width="160" height="108" fill="#28505a"/>')
    b.append(text_lines(2030, 474, 136, 7, 13, color="#a8f0e6", op=0.7, seed=12, sw=3))
    b.append('<rect x="2088" y="578" width="24" height="20" fill="#0a0d14"/><rect x="2060" y="596" width="80" height="10" rx="3" fill="#0a0d14"/>')
    # ---- waste bin
    b.append('<path d="M2290 770 L2400 770 L2388 900 L2302 900 Z" fill="#232b3a"/><rect x="2284" y="762" width="122" height="12" rx="4" fill="#3a4558"/>')
    for i in range(5):
        b.append(f'<line x1="{2304+i*21}" y1="776" x2="{2310+i*18}" y2="898" stroke="#121823" stroke-width="3"/>')
    b.append(f'<path d="M2306 764 l16 -22 l22 10 l14 -16 l24 14 l10 14 Z" fill="{PAPER_D}"/><path d="M2330 764 l10 -30 l26 6 l-4 24 Z" fill="{PAPER}"/><rect x="2338" y="742" width="18" height="3" fill="{RED}" transform="rotate(12 2338 742)"/>')
    b.append('<ellipse cx="2345" cy="904" rx="70" ry="10" fill="#000" opacity="0.5" filter="url(#blur3)"/>')

    # ---- key-card reader
    b.append('<circle cx="2535" cy="450" r="70" fill="#ff5a4a" opacity="0.10" filter="url(#blur8)"/>')
    b.append('<rect x="2500" y="430" width="70" height="130" rx="8" fill="#39424f"/><rect x="2510" y="442" width="50" height="34" fill="#0d1218"/><circle cx="2535" cy="494" r="6" fill="#ff5a4a"/><rect x="2514" y="520" width="42" height="6" fill="#0d1218"/><rect x="2514" y="534" width="42" height="6" fill="#0d1218"/>')
    # ---- inner door to the stacks
    b.append('<rect x="2610" y="220" width="240" height="610" fill="#070a10"/><rect x="2626" y="236" width="208" height="594" fill="#202a3a"/>')
    b.append('<rect x="2690" y="290" width="80" height="150" fill="#0e141e"/>')
    for i in range(1, 4):
        b.append(f'<line x1="{2690+i*20}" y1="290" x2="{2690+i*20}" y2="440" stroke="#2a3446" stroke-width="2"/><line x1="2690" y1="{290+i*37}" x2="2770" y2="{290+i*37}" stroke="#2a3446" stroke-width="2"/>')
    b.append(f'<rect x="2644" y="520" width="16" height="70" rx="6" fill="{AMBER}" opacity="0.7"/>')
    b.append(f'<rect x="2680" y="160" width="100" height="44" fill="#1f3a34"/><path d="M2700 192 h14 v-8 h14 v-8 h14 v-8 h18" fill="none" stroke="{PAPER}" stroke-width="4"/>')

    # atmosphere
    b.append(f'<rect width="{W}" height="{H}" fill="url(#vig)"/>')
    b.append(f'<rect width="{W}" height="{H}" filter="url(#grain)"/>')
    save("lobby", W, H, "".join(b), d)


# ------------------------------------------------------------------ portrait
def portrait_erdem():
    W, H = 700, 1000
    save("erdem", W, H, guard(350, 1010, 2.05, portrait=True))


# ------------------------------------------------------------------ menu background
def menu_bg():
    W, H = 2560, 1080
    d = f"""
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0a0f1a"/><stop offset="1" stop-color="#1d2b44"/></linearGradient>
<radialGradient id="lamp"><stop offset="0" stop-color="#ffd58a" stop-opacity="0.8"/><stop offset="0.4" stop-color="{AMBER}" stop-opacity="0.25"/><stop offset="1" stop-color="{AMBER}" stop-opacity="0"/></radialGradient>
<linearGradient id="shade" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#05070c" stop-opacity="0.95"/><stop offset="0.5" stop-color="#05070c" stop-opacity="0.55"/><stop offset="1" stop-color="#05070c" stop-opacity="0"/></linearGradient>
<radialGradient id="vig" cx="0.6" cy="0.5" r="0.8"><stop offset="0.5" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.75"/></radialGradient>
<clipPath id="win"><rect x="1180" y="90" width="1240" height="640"/></clipPath>"""
    r = random.Random(21)
    b = [f'<rect width="{W}" height="{H}" fill="#0b1019"/>']
    b.append('<rect x="1180" y="90" width="1240" height="640" fill="url(#sky)"/><g clip-path="url(#win)">')
    # skyline
    x = 1160
    while x < 2440:
        w, h = 60 + r.random() * 120, 120 + r.random() * 300
        b.append(f'<rect x="{x:.0f}" y="{730-h:.0f}" width="{w:.0f}" height="{h:.0f}" fill="#0c1320"/>')
        for _ in range(int(h / 40)):
            if r.random() < 0.55:
                b.append(f'<rect x="{x+8+r.random()*(w-24):.0f}" y="{730-h+12+r.random()*(h-30):.0f}" width="10" height="14" fill="{AMBER}" opacity="{0.25+r.random()*0.5:.2f}"/>')
        x += w + 6
    for _ in range(26):
        cx, cy, rad = 1180 + r.random() * 1240, 380 + r.random() * 340, 14 + r.random() * 30
        col = r.choice([AMBER, "#9fd0ff", "#ffd58a", RED])
        b.append(f'<circle cx="{cx:.0f}" cy="{cy:.0f}" r="{rad:.0f}" fill="{col}" opacity="{0.08+r.random()*0.14:.2f}" filter="url(#blur8)"/>')
    b.append(rain(1180, 90, 1240, 640, 420, 5, 0.3))
    b.append('</g>')
    # window frame
    b.append('<rect x="1160" y="70" width="1280" height="680" fill="none" stroke="#05070c" stroke-width="40"/><rect x="1785" y="90" width="30" height="640" fill="#05070c"/><rect x="1180" y="395" width="1240" height="24" fill="#05070c"/>')
    b.append('<rect x="1120" y="740" width="1360" height="30" fill="#141a26"/>')
    # desk
    b.append('<rect x="0" y="860" width="2560" height="220" fill="#1c140e"/><rect x="0" y="860" width="2560" height="10" fill="#4a3625"/>')
    b.append('<circle cx="2160" cy="700" r="520" fill="url(#lamp)"/>')
    b.append(f'<rect x="2120" y="846" width="110" height="16" rx="6" fill="#05070c"/><rect x="2170" y="700" width="12" height="150" fill="#05070c"/><path d="M2070 712 Q2176 600 2282 712 Z" fill="#7a5320"/><path d="M2080 712 L2272 712 L2262 728 L2090 728 Z" fill="#ffe2a8"/>')
    # manila folder with missing-file gap + red thread
    b.append('<g transform="rotate(-6 1700 900)"><path d="M1480 838 L1620 838 L1640 858 L1930 858 L1930 1010 L1480 1010 Z" fill="#b8924e"/><path d="M1480 870 L1930 870 L1930 1010 L1480 1010 Z" fill="#d2ab62"/>')
    b.append(f'<rect x="1520" y="900" width="170" height="44" fill="{PAPER}"/><rect x="1532" y="912" width="120" height="6" fill="{INK}" opacity="0.7"/><rect x="1532" y="926" width="80" height="6" fill="{INK}" opacity="0.5"/>')
    b.append(f'<rect x="1740" y="950" width="150" height="40" fill="none" stroke="{RED}" stroke-width="6" transform="rotate(-8 1740 950)"/><rect x="1756" y="964" width="118" height="10" fill="{RED}" transform="rotate(-8 1740 950)"/></g>')
    b.append(f'<circle cx="1420" cy="930" r="12" fill="{RED}"/><path d="M1420 930 Q1900 760 2380 950" fill="none" stroke="{RED}" stroke-width="4" opacity="0.8"/><circle cx="2380" cy="950" r="12" fill="{RED}"/>')
    b.append(f'<rect width="1500" height="{H}" fill="url(#shade)"/><rect width="{W}" height="{H}" fill="url(#vig)"/><rect width="{W}" height="{H}" filter="url(#grain)"/>')
    save("menu_bg", W, H, "".join(b), d)


# ------------------------------------------------------------------ evidence icons + app icon
def icon(name, inner, bg=True):
    base = f'<circle cx="256" cy="256" r="236" fill="{CHAR}" stroke="{SLATE}" stroke-width="6"/>' if bg else ""
    save(name, 512, 512, base + inner)


def sheet(x, y, w, h, rot=0, fill=PAPER):
    return f'<g transform="rotate({rot} {x+w/2} {y+h/2})"><rect x="{x+6}" y="{y+8}" width="{w}" height="{h}" fill="#000" opacity="0.35"/><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}"/>'


def icons():
    # E01 visitor log
    icon("e01", f'<path d="M96 180 L256 160 L256 380 L96 400 Z" fill="{PAPER}"/><path d="M416 180 L256 160 L256 380 L416 400 Z" fill="#f3ead4"/><path d="M96 400 L256 380 L416 400 L416 414 L256 394 L96 414 Z" fill="#5a2a22"/>'
         + text_lines(118, 206, 110, 9, 18, seed=1) + text_lines(282, 206, 110, 9, 18, seed=2)
         + f'<rect x="282" y="276" width="112" height="14" fill="{AMBER}" opacity="0.5"/>')
    # E02 key-card log printout
    icon("e02", sheet(150, 96, 212, 320, -4) + text_lines(170, 130, 170, 12, 22, seed=3)
         + f'<rect x="170" y="258" width="172" height="16" fill="{AMBER}" opacity="0.5"/></g>'
         + f'<g transform="rotate(14 360 360)"><rect x="300" y="320" width="130" height="84" rx="10" fill="#39424f"/><rect x="312" y="334" width="40" height="30" fill="{AMBER}"/><rect x="312" y="376" width="104" height="8" fill="#0d1218"/></g>')
    # E03 staff portraits
    faces = ""
    for i, hc in enumerate(["#2a2420", "#a9a39a", "#3a2a22", "#1c1c22"]):
        x, y = 128 + (i % 2) * 136, 120 + (i // 2) * 146
        faces += f'<rect x="{x}" y="{y}" width="120" height="130" fill="{PAPER}"/><circle cx="{x+60}" cy="{y+50}" r="26" fill="#8b6f5c"/><path d="M{x+34} {y+44} q26 -44 52 0 q-26 -18 -52 0Z" fill="{hc}"/><path d="M{x+16} {y+130} q6 -48 44 -50 q38 2 44 50 Z" fill="#2c3648"/>'
    faces += f'<path d="M162 164 q-8 40 4 58 l8 -44Z M214 164 q8 40 -4 58 l-8 -44Z" fill="#2a2420"/><circle cx="160" cy="190" r="8" fill="{JADE}"/><circle cx="216" cy="190" r="8" fill="{JADE}"/>'
    icon("e03", '<rect x="104" y="96" width="304" height="320" fill="#3b2b1e"/><rect x="116" y="108" width="280" height="296" fill="#1f3a34"/>' + faces)
    # E04 patrol log clipboard
    icon("e04", f'<g transform="rotate(5 256 256)"><rect x="140" y="96" width="232" height="330" rx="10" fill="#6a4a2c"/><rect x="158" y="130" width="196" height="278" fill="{PAPER}"/><rect x="206" y="82" width="100" height="40" rx="8" fill="#aab2be"/>'
         + text_lines(176, 160, 160, 10, 24, seed=4) + f'<rect x="176" y="250" width="160" height="16" fill="{RED}" opacity="0.4"/></g>')
    # E05 betting slip
    icon("e05", sheet(166, 90, 180, 330, 9, "#f3ead4")
         + f'<circle cx="256" cy="156" r="34" fill="none" stroke="{RED}" stroke-width="7"/><path d="M256 134 v48 M240 148 h32 M236 170 q20 18 40 0" fill="none" stroke="{RED}" stroke-width="7"/>'
         + text_lines(186, 220, 140, 6, 22, seed=5) + f'<rect x="186" y="360" width="140" height="26" fill="{INK}" opacity="0.8"/><path d="M166 420 l15 -12 l15 12 l15 -12 l15 12 l15 -12 l15 12 l15 -12 l15 12 l15 -12 l15 12 l15 -12 l15 12 v6 h-180 Z" fill="{CHAR}"/></g>')
    # E06 car park barrier terminal
    icon("e06", '<rect x="96" y="120" width="320" height="220" rx="12" fill="#0a0d14"/><rect x="112" y="136" width="288" height="188" fill="#28505a"/>'
         + text_lines(128, 160, 160, 5, 26, color="#a8f0e6", op=0.8, seed=6, sw=6)
         + f'<rect x="306" y="250" width="14" height="60" fill="{PAPER}"/><rect x="250" y="250" width="70" height="12" fill="{RED}" transform="rotate(-24 320 256)"/>'
         + '<rect x="232" y="340" width="48" height="36" fill="#0a0d14"/><rect x="176" y="372" width="160" height="18" rx="6" fill="#0a0d14"/>')
    # E15 newspaper
    icon("e15", sheet(112, 110, 288, 300, -5) + f'<rect x="130" y="128" width="252" height="34" fill="{INK}" opacity="0.9"/><rect x="130" y="180" width="130" height="100" fill="#59616e"/><circle cx="196" cy="216" r="18" fill="#8b6f5c"/><path d="M168 280 q6 -40 28 -42 q22 2 28 42Z" fill="#1d2330"/><circle cx="236" cy="198" r="10" fill="{PAPER}"/>'
         + text_lines(276, 186, 104, 6, 17, seed=7) + text_lines(130, 300, 252, 6, 17, seed=8) + '</g>')
    # app icon
    save("icon", 432, 432, f'<rect width="432" height="432" fill="{NAVY}"/><circle cx="216" cy="200" r="190" fill="{AMBER}" opacity="0.10"/>'
         f'<g transform="rotate(-6 216 216)"><path d="M84 132 L186 132 L204 154 L348 154 L348 318 L84 318 Z" fill="#b8924e"/><path d="M84 168 L348 168 L348 318 L84 318 Z" fill="#d2ab62"/>'
         f'<rect x="112" y="196" width="120" height="34" fill="{PAPER}"/><rect x="122" y="208" width="84" height="8" fill="{INK}" opacity="0.7"/>'
         f'<rect x="196" y="252" width="130" height="40" fill="none" stroke="{RED}" stroke-width="8" transform="rotate(-8 196 252)"/><rect x="212" y="266" width="98" height="12" fill="{RED}" transform="rotate(-8 196 252)"/></g>')


# ------------------------------------------------------------------ generic suspect bust
def bust(skin, skin_sh, jacket, jacket_l, shirt, hair_fn, extra_fn=None, brow_tilt=0, tie=None, s=2.05, cx=350, base=1010):
    def P(x, y):
        return f"{cx + x*s:.1f},{base + y*s:.1f}"
    g = []
    g.append(f'<path d="M{P(-150,0)} L{P(-150,-170)} Q{P(-145,-235)} {P(-70,-255)} L{P(70,-255)} Q{P(145,-235)} {P(150,-170)} L{P(150,0)} Z" fill="{jacket}"/>')
    g.append(f'<path d="M{P(-150,0)} L{P(-150,-170)} Q{P(-145,-235)} {P(-70,-255)} L{P(-40,-255)} Q{P(-110,-220)} {P(-112,-160)} L{P(-112,0)} Z" fill="{jacket_l}"/>')
    g.append(f'<path d="M{P(-40,-258)} L{P(0,-150)} L{P(40,-258)} Z" fill="{shirt}"/>')
    if tie:
        g.append(f'<path d="M{P(-11,-240)} L{P(11,-240)} L{P(14,-165)} L{P(0,-148)} L{P(-14,-165)} Z" fill="{tie}"/>')
    g.append(f'<path d="M{P(-40,-258)} L{P(-66,-232)} L{P(-6,-150)} Z" fill="{jacket_l}"/><path d="M{P(40,-258)} L{P(66,-232)} L{P(6,-150)} Z" fill="{jacket}" stroke="#00000055" stroke-width="2"/>')
    g.append(f'<path d="M{P(-34,-262)} L{P(-30,-300)} L{P(30,-300)} L{P(34,-262)} L{P(0,-232)} Z" fill="{skin_sh}"/>')
    g.append(f'<path d="M{P(-62,-400)} Q{P(-66,-300)} {P(-28,-278)} Q{P(0,-266)} {P(28,-278)} Q{P(66,-300)} {P(62,-400)} Q{P(0,-440)} {P(-62,-400)} Z" fill="{skin}"/>')
    g.append(f'<path d="M{P(8,-420)} Q{P(40,-420)} {P(62,-400)} Q{P(66,-300)} {P(28,-278)} Q{P(10,-270)} {P(0,-270)} Q{P(22,-300)} {P(14,-340)} Z" fill="{skin_sh}"/>')
    g.append(f'<ellipse cx="{cx-64*s}" cy="{base-352*s}" rx="{9*s}" ry="{17*s}" fill="{skin}"/><ellipse cx="{cx+64*s}" cy="{base-352*s}" rx="{9*s}" ry="{17*s}" fill="{skin_sh}"/>')
    t = brow_tilt
    g.append(f'<path d="M{P(-48,-372+t)} L{P(-14,-372-t)} L{P(-14,-366-t)} L{P(-48,-365+t)} Z" fill="#2a2420"/><path d="M{P(48,-372+t)} L{P(14,-372-t)} L{P(14,-366-t)} L{P(48,-365+t)} Z" fill="#1b1714"/>')
    g.append(f'<ellipse cx="{cx-30*s}" cy="{base-352*s}" rx="{7*s}" ry="{4.5*s}" fill="#15110f"/><ellipse cx="{cx+30*s}" cy="{base-352*s}" rx="{7*s}" ry="{4.5*s}" fill="#15110f"/>')
    g.append(f'<path d="M{P(-4,-356)} L{P(-12,-318)} L{P(8,-314)} Z" fill="{skin_sh}" opacity="0.8"/>')
    g.append(f'<path d="M{P(-18,-294)} Q{P(0,-290)} {P(18,-294)}" fill="none" stroke="#5a3a32" stroke-width="{4*s}" stroke-linecap="round"/>')
    g.append(hair_fn(P, s, cx, base))
    if extra_fn:
        g.append(extra_fn(P, s, cx, base))
    g.append(f'<path d="M{P(-150,0)} L{P(-150,-170)} Q{P(-145,-235)} {P(-70,-255)}" fill="none" stroke="{AMBER}" stroke-width="{5*s}" opacity="0.7"/>')
    return "".join(g)


def portraits():
    # Dr. Selin Vardar: grey hair in a bun, glasses, burgundy blazer. No earrings today.
    def hair_v(P, s, cx, base):
        return (f'<circle cx="{cx+10*s}" cy="{base-452*s}" r="{30*s}" fill="#8e8a86"/>'
                f'<path d="M{P(-70,-360)} Q{P(-84,-450)} {P(0,-452)} Q{P(84,-450)} {P(70,-360)} Q{P(60,-410)} {P(0,-416)} Q{P(-60,-410)} {P(-70,-360)} Z" fill="#a9a5a0"/>'
                f'<path d="M{P(0,-452)} Q{P(84,-450)} {P(70,-360)} Q{P(60,-410)} {P(0,-416)} Z" fill="#7d7975"/>')
    def glasses(P, s, cx, base):
        return (f'<circle cx="{cx-30*s}" cy="{base-352*s}" r="{19*s}" fill="none" stroke="#1b1714" stroke-width="{4*s}"/>'
                f'<circle cx="{cx+30*s}" cy="{base-352*s}" r="{19*s}" fill="none" stroke="#1b1714" stroke-width="{4*s}"/>'
                f'<path d="M{P(-11,-354)} L{P(11,-354)}" stroke="#1b1714" stroke-width="{4*s}"/>'
                f'<circle cx="{cx}" cy="{base-236*s}" r="{6*s}" fill="{PAPER}"/>')
    save("vardar", 700, 1000, bust("#c9a48c", "#8a6a5a", "#4a1f2a", "#6b2f3d", "#e6dcc8", hair_v, glasses))
    # Demir Aras: slick black hair, charcoal suit, amber tie.
    def hair_a(P, s, cx, base):
        return (f'<path d="M{P(-66,-372)} Q{P(-78,-452)} {P(-6,-456)} Q{P(74,-456)} {P(66,-372)} Q{P(58,-418)} {P(10,-420)} Q{P(-40,-424)} {P(-66,-372)} Z" fill="#17151a"/>'
                f'<path d="M{P(-50,-430)} Q{P(0,-450)} {P(50,-430)}" fill="none" stroke="#3a3840" stroke-width="{4*s}"/>')
    save("aras", 700, 1000, bust("#c79a78", "#7c5a46", "#23262e", "#3a3f4c", "#eef0f2", hair_a, None, brow_tilt=-2, tie=AMBER))
    # Leyla Aydin: dark bob, mustard cardigan, worried brows.
    def hair_l(P, s, cx, base):
        return (f'<path d="M{P(-72,-300)} Q{P(-96,-456)} {P(0,-460)} Q{P(96,-456)} {P(72,-300)} L{P(56,-300)} Q{P(64,-396)} {P(20,-412)} Q{P(-30,-420)} {P(-58,-380)} L{P(-56,-300)} Z" fill="#2c1f1a"/>'
                f'<path d="M{P(0,-460)} Q{P(96,-456)} {P(72,-300)} L{P(56,-300)} Q{P(64,-396)} {P(20,-412)} Z" fill="#1c1310"/>')
    save("aydin", 700, 1000, bust("#d2a98c", "#94705c", "#8a6a1e", "#b08a2e", "#f1ece0", hair_l, None, brow_tilt=4))
    # card icons for statements and conclusions
    icon("card_testimony", f'<path d="M110 150 h292 a24 24 0 0 1 24 24 v150 a24 24 0 0 1 -24 24 h-150 l-70 60 v-60 h-72 a24 24 0 0 1 -24 -24 v-150 a24 24 0 0 1 24 -24Z" fill="{PAPER}"/>' + text_lines(140, 196, 232, 5, 30, seed=31, sw=8))
    icon("card_insight", f'<circle cx="170" cy="190" r="26" fill="{RED}"/><circle cx="350" cy="330" r="26" fill="{RED}"/><path d="M170 190 Q300 170 350 330" fill="none" stroke="{RED}" stroke-width="10"/>'
         f'<rect x="120" y="230" width="110" height="130" fill="{PAPER}" transform="rotate(-8 175 295)"/><rect x="290" y="130" width="110" height="130" fill="{PAPER}" transform="rotate(7 345 195)"/>'
         f'<circle cx="170" cy="190" r="14" fill="{RED}"/><circle cx="350" cy="330" r="14" fill="{RED}"/>')


if __name__ == "__main__":
    lobby(); portrait_erdem(); menu_bg(); icons(); portraits()
    print("SVG sources written to art_src/")
