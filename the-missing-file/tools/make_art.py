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
def guard(cx, base, s=1.0, portrait=False, mood=None):
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
    bo, bi = {"defensive": (-382, -363), "shaken": (-364, -377)}.get(mood, (-374, -368))
    g.append(f'<path d="M{P(-48,bo)} L{P(-14,bi)} L{P(-14,bi+7)} L{P(-48,bo+9)} Z" fill="#2a2420"/><path d="M{P(48,bo)} L{P(14,bi)} L{P(14,bi+7)} L{P(48,bo+9)} Z" fill="#1b1714"/>')
    if mood == "shaken":
        g.append(SWEAT(P, s))
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
def SWEAT(P, s):
    return f'<path d="M{P(-52,-398)} q{-9*s},{16*s} 0,{22*s} q{9*s},{-6*s} 0,{-22*s}Z" fill="#bfe3ff" opacity="0.9"/>'


def bust(skin, skin_sh, jacket, jacket_l, shirt, hair_fn, extra_fn=None, brow_tilt=0, tie=None, s=2.05, cx=350, base=1010, mood=None):
    if mood == "defensive":
        brow_tilt = -8
    elif mood == "shaken":
        brow_tilt = 9
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
    ey = {"defensive": 3.2, "shaken": 6.5}.get(mood, 4.5)
    g.append(f'<ellipse cx="{cx-30*s}" cy="{base-352*s}" rx="{7*s}" ry="{ey*s}" fill="#15110f"/><ellipse cx="{cx+30*s}" cy="{base-352*s}" rx="{7*s}" ry="{ey*s}" fill="#15110f"/>')
    g.append(f'<path d="M{P(-4,-356)} L{P(-12,-318)} L{P(8,-314)} Z" fill="{skin_sh}" opacity="0.8"/>')
    if mood == "shaken":
        g.append(f'<ellipse cx="{cx}" cy="{base-292*s}" rx="{9*s}" ry="{6*s}" fill="#3a221c"/>')
    else:
        my = -299 if mood == "defensive" else -290
        g.append(f'<path d="M{P(-18,-294)} Q{P(0,my)} {P(18,-294)}" fill="none" stroke="#5a3a32" stroke-width="{4*s}" stroke-linecap="round"/>')
    g.append(hair_fn(P, s, cx, base))
    if mood == "shaken":
        g.append(SWEAT(P, s))
    if extra_fn:
        g.append(extra_fn(P, s, cx, base))
    g.append(f'<path d="M{P(-150,0)} L{P(-150,-170)} Q{P(-145,-235)} {P(-70,-255)}" fill="none" stroke="{AMBER}" stroke-width="{5*s}" opacity="0.7"/>')
    return "".join(g)


def HAIR_V(P, s, cx, base):
    return (f'<circle cx="{cx+10*s}" cy="{base-452*s}" r="{30*s}" fill="#8e8a86"/>'
            f'<path d="M{P(-70,-360)} Q{P(-84,-450)} {P(0,-452)} Q{P(84,-450)} {P(70,-360)} Q{P(60,-410)} {P(0,-416)} Q{P(-60,-410)} {P(-70,-360)} Z" fill="#a9a5a0"/>'
            f'<path d="M{P(0,-452)} Q{P(84,-450)} {P(70,-360)} Q{P(60,-410)} {P(0,-416)} Z" fill="#7d7975"/>')


def GLASSES(P, s, cx, base):
    return (f'<circle cx="{cx-30*s}" cy="{base-352*s}" r="{19*s}" fill="none" stroke="#1b1714" stroke-width="{4*s}"/>'
            f'<circle cx="{cx+30*s}" cy="{base-352*s}" r="{19*s}" fill="none" stroke="#1b1714" stroke-width="{4*s}"/>'
            f'<path d="M{P(-11,-354)} L{P(11,-354)}" stroke="#1b1714" stroke-width="{4*s}"/>'
            f'<circle cx="{cx}" cy="{base-236*s}" r="{6*s}" fill="{PAPER}"/>')


def HAIR_A(P, s, cx, base):
    return (f'<path d="M{P(-66,-372)} Q{P(-78,-452)} {P(-6,-456)} Q{P(74,-456)} {P(66,-372)} Q{P(58,-418)} {P(10,-420)} Q{P(-40,-424)} {P(-66,-372)} Z" fill="#17151a"/>'
            f'<path d="M{P(-50,-430)} Q{P(0,-450)} {P(50,-430)}" fill="none" stroke="#3a3840" stroke-width="{4*s}"/>')


def HAIR_L(P, s, cx, base):
    return (f'<path d="M{P(-72,-300)} Q{P(-96,-456)} {P(0,-460)} Q{P(96,-456)} {P(72,-300)} L{P(56,-300)} Q{P(64,-396)} {P(20,-412)} Q{P(-30,-420)} {P(-58,-380)} L{P(-56,-300)} Z" fill="#2c1f1a"/>'
            f'<path d="M{P(0,-460)} Q{P(96,-456)} {P(72,-300)} L{P(56,-300)} Q{P(64,-396)} {P(20,-412)} Z" fill="#1c1310"/>')


def portraits():
    # One neutral portrait per character plus "defensive" and "shaken" variants.
    for mood in (None, "defensive", "shaken"):
        tag = "" if mood is None else "_" + mood
        # Dr. Selin Vardar: grey hair in a bun, glasses, burgundy blazer. No earrings today.
        save("vardar" + tag, 700, 1000, bust("#c9a48c", "#8a6a5a", "#4a1f2a", "#6b2f3d", "#e6dcc8", HAIR_V, GLASSES, mood=mood))
        # Demir Aras: slick black hair, charcoal suit, amber tie.
        save("aras" + tag, 700, 1000, bust("#c79a78", "#7c5a46", "#23262e", "#3a3f4c", "#eef0f2", HAIR_A, None, brow_tilt=-2, tie=AMBER, mood=mood))
        # Leyla Aydin: dark bob, mustard cardigan, worried brows.
        save("aydin" + tag, 700, 1000, bust("#d2a98c", "#94705c", "#8a6a1e", "#b08a2e", "#f1ece0", HAIR_L, None, brow_tilt=4, mood=mood))
        if mood:
            save("erdem" + tag, 700, 1000, guard(350, 1010, 2.05, portrait=True, mood=mood))
    # card icons for statements and conclusions
    icon("card_testimony", f'<path d="M110 150 h292 a24 24 0 0 1 24 24 v150 a24 24 0 0 1 -24 24 h-150 l-70 60 v-60 h-72 a24 24 0 0 1 -24 -24 v-150 a24 24 0 0 1 24 -24Z" fill="{PAPER}"/>' + text_lines(140, 196, 232, 5, 30, seed=31, sw=8))
    icon("card_insight", f'<circle cx="170" cy="190" r="26" fill="{RED}"/><circle cx="350" cy="330" r="26" fill="{RED}"/><path d="M170 190 Q300 170 350 330" fill="none" stroke="{RED}" stroke-width="10"/>'
         f'<rect x="120" y="230" width="110" height="130" fill="{PAPER}" transform="rotate(-8 175 295)"/><rect x="290" y="130" width="110" height="130" fill="{PAPER}" transform="rotate(7 345 195)"/>'
         f'<circle cx="170" cy="190" r="14" fill="{RED}"/><circle cx="350" cy="330" r="14" fill="{RED}"/>')


# ------------------------------------------------------------------ shared scene pieces
SCENE_DEFS = """
<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{w0}"/><stop offset="1" stop-color="{w1}"/></linearGradient>
<linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{f0}"/><stop offset="1" stop-color="{f1}"/></linearGradient>
<linearGradient id="glass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#31445f"/><stop offset="1" stop-color="#17202f"/></linearGradient>
<linearGradient id="desk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2a1d"/><stop offset="1" stop-color="#17110c"/></linearGradient>
<linearGradient id="cone" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{lamp}" stop-opacity="0.34"/><stop offset="1" stop-color="{lamp}" stop-opacity="0"/></linearGradient>
<radialGradient id="glowA"><stop offset="0" stop-color="#ffd58a" stop-opacity="0.75"/><stop offset="0.35" stop-color="#e3a446" stop-opacity="0.28"/><stop offset="1" stop-color="#e3a446" stop-opacity="0"/></radialGradient>
<radialGradient id="glowB"><stop offset="0" stop-color="#9fd0ff" stop-opacity="0.55"/><stop offset="1" stop-color="#9fd0ff" stop-opacity="0"/></radialGradient>
<radialGradient id="glowM"><stop offset="0" stop-color="#7fd6d0" stop-opacity="0.4"/><stop offset="1" stop-color="#7fd6d0" stop-opacity="0"/></radialGradient>
<radialGradient id="glowW"><stop offset="0" stop-color="#dfeaff" stop-opacity="0.6"/><stop offset="1" stop-color="#dfeaff" stop-opacity="0"/></radialGradient>
<radialGradient id="vig" cx="0.5" cy="0.5" r="0.75"><stop offset="0.45" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.72"/></radialGradient>
"""


def room(w0, w1, f0, f1, lamp=AMBER, W=2880, H=1080, FL=830, panels=True):
    d = SCENE_DEFS.format(w0=w0, w1=w1, f0=f0, f1=f1, lamp=lamp)
    b = [f'<rect width="{W}" height="{FL}" fill="url(#wall)"/>']
    if panels:
        b.append(f'<rect x="0" y="560" width="{W}" height="{FL-560}" fill="#00000030"/><rect x="0" y="556" width="{W}" height="8" fill="#ffffff14"/>')
    b.append(f'<rect x="0" y="{FL-14}" width="{W}" height="14" fill="#00000066"/>')
    b.append(f'<rect x="0" y="{FL}" width="{W}" height="{H-FL}" fill="url(#floor)"/>')
    for i, y in enumerate([850, 880, 925, 990]):
        b.append(f'<line x1="0" y1="{y}" x2="{W}" y2="{y}" stroke="#ffffff" stroke-width="2" opacity="{0.07-i*0.012:.3f}"/>')
    return d, b


def finish(name, d, b, W=2880, H=1080):
    b.append(f'<rect width="{W}" height="{H}" fill="url(#vig)"/><rect width="{W}" height="{H}" filter="url(#grain)"/>')
    save(name, W, H, "".join(b), d)


def window(x, y, w, h, seed, cid):
    return (f'<clipPath id="{cid}"><rect x="{x}" y="{y}" width="{w}" height="{h}"/></clipPath>'
            f'<rect x="{x-26}" y="{y-26}" width="{w+52}" height="{h+52}" fill="#080b12"/><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#glass)"/>'
            f'<g clip-path="url(#{cid})"><circle cx="{x+w*0.7}" cy="{y+h*0.3}" r="{h*0.5}" fill="url(#glowB)"/>'
            f'<path d="M{x} {y+h*0.75} l{w*0.2} {-h*0.12} l{w*0.15} {h*0.08} l{w*0.2} {-h*0.2} l{w*0.2} {h*0.14} l{w*0.25} {-h*0.05} V{y+h} H{x} Z" fill="#0c121d" opacity="0.85"/>'
            + rain(x, y, w, h, int(w * h / 1600), seed) + '</g>'
            f'<rect x="{x+w/2-7}" y="{y}" width="14" height="{h}" fill="#080b12"/><rect x="{x}" y="{y+h/2-6}" width="{w}" height="12" fill="#080b12"/>')


def desk_lamp(x, y):
    """Lamp whose base sits at (x, y)."""
    return (f'<circle cx="{x}" cy="{y-50}" r="330" fill="url(#glowA)" opacity="0.8"/>'
            f'<rect x="{x-28}" y="{y-10}" width="56" height="10" rx="4" fill="#0a0d14"/><rect x="{x-4}" y="{y-76}" width="8" height="70" fill="#0a0d14"/>'
            f'<path d="M{x-54} {y-70} Q{x} {y-128} {x+54} {y-70} Z" fill="#7a5320"/><path d="M{x-48} {y-70} L{x+48} {y-70} L{x+42} {y-60} L{x-42} {y-60} Z" fill="#ffe2a8"/>')


def boxes(x, y, w, n, seed, label=None, missing=None, h=110):
    """A row of archive boxes on a shelf whose top surface is at y+h."""
    r = random.Random(seed)
    out, bw = [], w / n
    for i in range(n):
        bx = x + i * bw + 5
        if i == missing:
            out.append(f'<rect x="{bx}" y="{y}" width="{bw-10}" height="{h}" fill="#05070b"/>')
            continue
        col = r.choice(["#6b5a44", "#7a6850", "#5d4e3c", "#84705a"])
        out.append(f'<rect x="{bx}" y="{y}" width="{bw-10}" height="{h}" fill="{col}"/><rect x="{bx+10}" y="{y+18}" width="{bw-30}" height="34" fill="{PAPER_D}"/>'
                   f'<rect x="{bx+16}" y="{y+28}" width="{(bw-42)*(0.5+0.5*r.random()):.0f}" height="6" fill="{INK}" opacity="0.6"/><circle cx="{bx+bw/2-5}" cy="{y+82}" r="9" fill="#00000055"/>')
    return "".join(out)


# ------------------------------------------------------------------ Vural's office
def office():
    d, b = room("#141018", "#2a2028", "#241c1c", "#0a0808")
    b.append(window(140, 190, 380, 400, 31, "w1"))
    b.append('<path d="M114 830 L546 830 L780 1080 L-120 1080 Z" fill="#9fd0ff" opacity="0.05"/>')
    # wall shelf with binders
    b.append('<rect x="1640" y="330" width="640" height="16" fill="#3b2b1e"/>')
    r = random.Random(5)
    x = 1656
    while x < 2250:
        w = 30 + r.random() * 26
        b.append(f'<rect x="{x:.0f}" y="{330-150-r.random()*30:.0f}" width="{w:.0f}" height="{150+r.random()*30:.0f}" fill="{r.choice(["#5a2a22","#2c3d4f","#4a4a32","#3a2f45","#6a5a3c"])}"/>')
        x += w + 4
    # Leyla on a chair behind the scanner table
    b.append('<rect x="700" y="470" width="250" height="280" rx="16" fill="#1a1414"/>')
    b.append(bust("#d2a98c", "#94705c", "#8a6a1e", "#b08a2e", "#f1ece0", HAIR_L, None, brow_tilt=4, s=0.82, cx=825, base=742))
    b.append('<rect x="620" y="716" width="430" height="22" fill="#4a3625"/><rect x="640" y="738" width="16" height="92" fill="#2a2018"/><rect x="1014" y="738" width="16" height="92" fill="#2a2018"/>')
    b.append('<rect x="900" y="668" width="130" height="50" rx="6" fill="#c9cfda"/><rect x="900" y="668" width="130" height="14" rx="6" fill="#8a93a3"/><circle cx="1012" cy="700" r="5" fill="#4fa58a"/>')
    # desk
    b.append('<rect x="1150" y="600" width="1110" height="36" fill="#4a3625"/><rect x="1150" y="600" width="1110" height="6" fill="#7a5a3c"/>')
    b.append('<rect x="1170" y="636" width="1070" height="264" fill="url(#desk)"/><rect x="1500" y="636" width="390" height="264" fill="#0c0806"/>')
    b.append('<ellipse cx="1700" cy="928" rx="600" ry="40" fill="#000" opacity="0.45" filter="url(#blur8)"/>')
    b.append(desk_lamp(1260, 600))
    # monitor (email)
    b.append('<circle cx="1490" cy="510" r="210" fill="url(#glowM)"/><rect x="1380" y="436" width="220" height="140" rx="6" fill="#0a0d14"/><rect x="1390" y="446" width="200" height="120" fill="#28505a"/>')
    b.append(f'<rect x="1404" y="458" width="172" height="20" fill="#a8f0e6" opacity="0.5"/>' + text_lines(1404, 492, 170, 5, 14, color="#a8f0e6", op=0.7, seed=41, sw=3))
    b.append('<rect x="1478" y="576" width="24" height="18" fill="#0a0d14"/><rect x="1450" y="592" width="80" height="8" rx="3" fill="#0a0d14"/>')
    # notebook
    b.append(f'<g transform="rotate(-4 1730 590)"><rect x="1660" y="572" width="150" height="28" fill="#23324a"/><rect x="1664" y="566" width="142" height="10" fill="{PAPER}"/><rect x="1790" y="560" width="6" height="42" fill="{RED}"/></g>')
    # desk calendar
    b.append(f'<path d="M1856 600 L1872 524 L1948 524 L1964 600 Z" fill="{PAPER}"/><rect x="1870" y="518" width="80" height="14" fill="{RED}"/>' + text_lines(1882, 548, 56, 3, 13, seed=42, sw=3)
             + f'<rect x="1880" y="580" width="60" height="5" fill="{RED}" opacity="0.8"/>')
    # letter tray
    b.append(f'<rect x="2030" y="574" width="170" height="26" fill="#39424f"/><g transform="rotate(-5 2110 566)"><rect x="2044" y="556" width="140" height="22" fill="{PAPER}"/><rect x="2056" y="563" width="70" height="4" fill="{INK}" opacity="0.6"/></g>')
    # forced drawers
    for i in range(3):
        off = 14 if i < 2 else 0
        b.append(f'<rect x="{1910+off}" y="{660+i*76}" width="300" height="66" fill="#2c2016" stroke="#0f0b08" stroke-width="4"/><rect x="{2030+off}" y="{684+i*76}" width="60" height="10" rx="5" fill="{AMBER}" opacity="0.7"/>')
    b.append('<path d="M2204 676 l14 10 l-10 12 l12 8" fill="none" stroke="#c9b08a" stroke-width="4"/><path d="M2208 752 l12 8 l-8 12" fill="none" stroke="#c9b08a" stroke-width="4"/>')
    b.append(f'<g transform="rotate(24 2300 930)"><rect x="2260" y="924" width="120" height="8" fill="#c9cfda"/><rect x="2360" y="918" width="50" height="20" rx="6" fill="#5a2a22"/></g>')
    b.append(f'<path d="M1960 690 l40 -8 l30 12 l-44 10Z" fill="{PAPER}"/><path d="M2100 912 l60 -10 l40 16 l-64 12Z" fill="{PAPER_D}"/>')
    # coat rack
    b.append('<rect x="2562" y="210" width="12" height="620" fill="#1a1210"/><path d="M2520 830 h96 l-16 -16 h-64Z" fill="#1a1210"/><path d="M2530 236 q38 -40 76 0" fill="none" stroke="#1a1210" stroke-width="10"/>')
    b.append('<path d="M2500 260 q68 -30 136 0 l26 330 q-94 30 -188 0 Z" fill="#3a3a44"/><path d="M2500 260 q30 -14 60 -16 l-10 360 q-40 -4 -76 -14 Z" fill="#4a4a56"/>')
    b.append('<rect x="2660" y="420" width="8" height="380" fill="#0a0d14"/><path d="M2640 420 q24 -30 48 0Z" fill="#0a0d14"/>')
    # filing cabinet
    b.append('<rect x="2710" y="380" width="150" height="450" fill="#2f3743"/>')
    for i in range(3):
        b.append(f'<rect x="2722" y="{396+i*144}" width="126" height="128" fill="#39424f"/><rect x="2760" y="{440+i*144}" width="50" height="10" fill="#0d1218"/>')
    finish("office", d, b)


# ------------------------------------------------------------------ stack B2
def stacks():
    d, b = room("#0a0f18", "#151d2b", "#161c26", "#06080c", lamp="#dfeaff", panels=False)
    # concrete wall seams
    for x in range(0, 2880, 360):
        b.append(f'<line x1="{x}" y1="0" x2="{x}" y2="830" stroke="#ffffff" stroke-width="2" opacity="0.04"/>')
    # spiral staircase
    b.append('<rect x="380" y="0" width="22" height="830" fill="#05070b"/>')
    for i in range(11):
        y = 60 + i * 72
        side = 1 if i % 2 == 0 else -1
        x0 = 391
        b.append(f'<path d="M{x0} {y} L{x0+side*250} {y-18} L{x0+side*250} {y+6} L{x0} {y+16} Z" fill="#2a3446"/><line x1="{x0+side*250}" y1="{y-18}" x2="{x0+side*250}" y2="{y-150}" stroke="#1b2230" stroke-width="6"/>')
    b.append('<path d="M141 -100 Q100 300 141 692" fill="none" stroke="#3a4558" stroke-width="8"/><path d="M641 -30 Q690 400 641 764" fill="none" stroke="#3a4558" stroke-width="8"/>')
    # work lamp on tripod
    b.append('<circle cx="1150" cy="330" r="520" fill="url(#glowW)" opacity="0.55"/><path d="M1150 330 L720 1080 L1500 1080 Z" fill="url(#cone)" opacity="0.6"/>')
    b.append('<rect x="1144" y="330" width="12" height="500" fill="#05070b"/><path d="M1150 700 L1090 830 M1150 700 L1210 830" stroke="#05070b" stroke-width="8"/><rect x="1100" y="296" width="100" height="60" rx="8" fill="#0a0d14"/><rect x="1108" y="304" width="84" height="44" fill="#f4f8ff"/>')
    # tape outline where he was found + markers
    b.append('<path d="M470 900 q-50 30 -20 70 q80 40 220 30 q150 0 190 -40 q30 -50 -60 -70 q-170 -30 -330 10Z" fill="none" stroke="#f4f8ff" stroke-width="7" stroke-dasharray="26 16" opacity="0.8"/>')
    for (mx, my, n) in ((720, 1010, 1), (960, 830, 2)):
        b.append(f'<path d="M{mx} {my} l22 -56 l22 56Z" fill="{AMBER}"/><rect x="{mx+16}" y="{my-30}" width="12" height="14" fill="{INK}"/>')
    # low shelf unit beside the stairs (earring underneath)
    b.append('<rect x="820" y="330" width="14" height="500" fill="#2a3446"/><rect x="1056" y="330" width="14" height="500" fill="#2a3446"/>')
    for i, y in enumerate((440, 600, 760)):
        b.append(f'<rect x="820" y="{y}" width="250" height="12" fill="#3a4558"/>' + boxes(838, y - 110, 216, 2, 60 + i))
    b.append('<rect x="834" y="772" width="222" height="58" fill="#04060a"/>')
    b.append(f'<circle cx="952" cy="816" r="20" fill="{JADE}" opacity="0.25" filter="url(#blur3)"/><path d="M946 800 q8 -8 12 2" fill="none" stroke="#c9cfda" stroke-width="3"/><ellipse cx="952" cy="816" rx="7" ry="10" fill="{JADE}"/><circle cx="949" cy="812" r="2" fill="#e8fff6"/>')
    # forensic trolley: effects tray + coroner's clipboard
    b.append('<rect x="1290" y="690" width="260" height="12" fill="#aab2be"/><rect x="1290" y="790" width="260" height="10" fill="#8a93a3"/><rect x="1296" y="690" width="8" height="130" fill="#8a93a3"/><rect x="1536" y="690" width="8" height="130" fill="#8a93a3"/><circle cx="1306" cy="824" r="10" fill="#05070b"/><circle cx="1534" cy="824" r="10" fill="#05070b"/>')
    b.append(f'<rect x="1312" y="662" width="150" height="28" rx="4" fill="#dfe5ee"/><circle cx="1352" cy="672" r="13" fill="#3b2b1e"/><circle cx="1352" cy="672" r="8" fill="{PAPER}"/><rect x="1380" y="668" width="60" height="6" fill="{AMBER}"/><circle cx="1444" cy="672" r="8" fill="none" stroke="{AMBER}" stroke-width="4"/>')
    b.append(f'<g transform="rotate(-8 1600 740)"><rect x="1566" y="660" width="92" height="130" rx="4" fill="#39424f"/><rect x="1574" y="678" width="76" height="104" fill="{PAPER}"/><rect x="1592" y="652" width="40" height="16" rx="3" fill="#aab2be"/>' + text_lines(1582, 692, 60, 6, 13, seed=71, sw=3) + f'<path d="M1600 760 h24 M1612 748 v24" stroke="{RED}" stroke-width="5"/></g>')
    # tall shelving A (47-B missing) and B (74-B)
    for (sx, seed, miss_row, miss_i) in ((1720, 80, 1, 1), (2330, 90, None, None)):
        b.append(f'<rect x="{sx}" y="120" width="16" height="710" fill="#2a3446"/><rect x="{sx+484}" y="120" width="16" height="710" fill="#2a3446"/>')
        for row, y in enumerate((250, 400, 550, 700)):
            b.append(f'<rect x="{sx}" y="{y}" width="500" height="14" fill="#3a4558"/>' + boxes(sx + 20, y - 110, 460, 4, seed + row, missing=miss_i if row == miss_row else None))
        b.append(f'<rect x="{sx+16}" y="714" width="468" height="116" fill="#04060a" opacity="0.6"/>')
    # empty slot 47-B: box pulled forward, lid off
    b.append(f'<g transform="rotate(-6 1900 380)"><rect x="1846" y="318" width="110" height="80" fill="#7a6850"/><rect x="1856" y="330" width="90" height="56" fill="#05070b"/><rect x="1854" y="402" width="110" height="14" fill="#84705a"/></g>')
    b.append(f'<rect x="1846" y="404" width="96" height="26" fill="{PAPER}"/><rect x="1854" y="413" width="50" height="7" fill="{INK}"/>')
    # 74-B box, slightly out of line
    b.append(f'<rect x="2562" y="434" width="110" height="116" fill="#84705a"/><rect x="2572" y="454" width="90" height="34" fill="{PAPER}"/><rect x="2580" y="464" width="56" height="7" fill="{INK}"/><circle cx="2617" cy="520" r="9" fill="#00000055"/>')
    finish("stacks", d, b)


# ------------------------------------------------------------------ Director's office
def director():
    d, b = room("#10171a", "#1f2c2c", "#1c2220", "#080a0a")
    # bookcase
    b.append('<rect x="70" y="150" width="330" height="680" fill="#2a1f16"/>')
    r = random.Random(9)
    for row in range(4):
        y = 180 + row * 160
        b.append(f'<rect x="84" y="{y+130}" width="302" height="12" fill="#17110c"/>')
        x = 92
        while x < 370:
            w = 18 + r.random() * 22
            hh = 96 + r.random() * 30
            b.append(f'<rect x="{x:.0f}" y="{y+130-hh:.0f}" width="{w:.0f}" height="{hh:.0f}" fill="{r.choice(["#5a2a22","#2c3d4f","#4a4a32","#3a2f45","#6a5a3c","#24413a"])}"/>')
            x += w + 3
    # diploma + long-service certificate
    b.append(f'<rect x="520" y="200" width="200" height="150" fill="#3b2b1e"/><rect x="534" y="214" width="172" height="122" fill="{PAPER}"/>' + text_lines(552, 240, 136, 4, 16, seed=51, sw=4) + f'<circle cx="676" cy="312" r="14" fill="{RED}"/>')
    b.append(f'<rect x="740" y="250" width="150" height="190" fill="#3b2b1e"/><rect x="752" y="262" width="126" height="166" fill="#f3ead4"/>' + text_lines(766, 290, 98, 6, 16, seed=52, sw=4) + f'<rect x="790" y="396" width="50" height="14" fill="{AMBER}"/>')
    # key cabinet + register
    b.append('<rect x="1660" y="220" width="200" height="190" fill="#39424f"/><rect x="1668" y="228" width="184" height="174" fill="#1b2230"/>')
    for i in range(2):
        for j in range(4):
            kx, ky = 1694 + j * 44, 256 + i * 74
            b.append(f'<circle cx="{kx}" cy="{ky}" r="4" fill="#8a93a3"/>')
            if not (i == 0 and j < 2):
                b.append(f'<circle cx="{kx}" cy="{ky+14}" r="8" fill="none" stroke="{AMBER}" stroke-width="4"/><rect x="{kx-2}" y="{ky+22}" width="4" height="22" fill="{AMBER}"/>')
    b.append(f'<rect x="1680" y="430" width="160" height="14" fill="#3b2b1e"/><g transform="rotate(-3 1760 420)"><rect x="1700" y="396" width="124" height="34" fill="#24413a"/><rect x="1708" y="402" width="108" height="8" fill="{PAPER}"/></g>')
    # window with Aras beside it, behind an armchair
    b.append(window(2140, 170, 560, 440, 77, "w2"))
    b.append('<path d="M2114 830 L2726 830 L2980 1080 L1900 1080 Z" fill="#9fd0ff" opacity="0.05"/>')
    b.append(bust("#c79a78", "#7c5a46", "#23262e", "#3a3f4c", "#eef0f2", HAIR_A, None, brow_tilt=-2, tie=AMBER, s=0.9, cx=2040, base=700))
    b.append('<path d="M1890 830 L1890 640 Q1890 590 1950 590 L2130 590 Q2190 590 2190 640 L2190 830 Z" fill="#3a1f1a"/><path d="M1890 830 L1890 640 Q1890 590 1950 590 L1990 590 Q1930 600 1930 650 L1930 830 Z" fill="#522a22"/>')
    for i in range(3):
        b.append(f'<circle cx="{1980+i*60}" cy="660" r="6" fill="#1a0e0c"/><circle cx="{1980+i*60}" cy="740" r="6" fill="#1a0e0c"/>')
    # Vardar behind her desk
    b.append('<rect x="1120" y="380" width="280" height="300" rx="20" fill="#24130f"/>')
    b.append(bust("#c9a48c", "#8a6a5a", "#4a1f2a", "#6b2f3d", "#e6dcc8", HAIR_V, GLASSES, s=0.9, cx=1260, base=668))
    b.append('<rect x="900" y="640" width="720" height="34" fill="#4a3625"/><rect x="900" y="640" width="720" height="6" fill="#7a5a3c"/><rect x="920" y="674" width="680" height="226" fill="url(#desk)"/>')
    for x in (950, 1280):
        b.append(f'<rect x="{x}" y="700" width="290" height="170" fill="none" stroke="#0f0b08" stroke-width="5"/>')
    b.append('<ellipse cx="1260" cy="928" rx="420" ry="36" fill="#000" opacity="0.45" filter="url(#blur8)"/>')
    b.append(desk_lamp(1010, 640))
    b.append(f'<rect x="1470" y="566" width="90" height="74" fill="#3b2b1e"/><rect x="1478" y="574" width="74" height="58" fill="#59616e"/><circle cx="1500" cy="598" r="9" fill="#8b6f5c"/><circle cx="1530" cy="598" r="9" fill="#8b6f5c"/><path d="M1486 632 q14 -24 28 0Z M1516 632 q14 -24 28 0Z" fill="#1d2330"/>')
    b.append(f'<rect x="1140" y="626" width="130" height="14" fill="{PAPER}" transform="rotate(-2 1140 626)"/><rect x="1330" y="622" width="70" height="8" rx="3" fill="#0a0d14" transform="rotate(8 1330 622)"/>')
    finish("director", d, b)


def more_icons():
    icon("e07", '<rect x="96" y="120" width="320" height="220" rx="12" fill="#0a0d14"/><rect x="112" y="136" width="288" height="188" fill="#28505a"/>'
         f'<rect x="170" y="176" width="172" height="112" fill="{PAPER}"/><path d="M170 176 L256 244 L342 176" fill="none" stroke="{INK}" stroke-width="7"/>'
         '<rect x="232" y="340" width="48" height="36" fill="#0a0d14"/><rect x="176" y="372" width="160" height="18" rx="6" fill="#0a0d14"/>')
    icon("e08", f'<g transform="rotate(-6 256 256)"><rect x="140" y="100" width="232" height="320" rx="8" fill="#23324a"/><rect x="160" y="118" width="204" height="296" fill="{PAPER}"/>' + text_lines(180, 156, 160, 9, 26, seed=11)
         + f'<rect x="180" y="258" width="150" height="18" fill="{AMBER}" opacity="0.55"/><rect x="330" y="92" width="14" height="336" fill="{RED}"/></g>')
    icon("e09", f'<path d="M120 400 L160 150 L352 150 L392 400 Z" fill="{PAPER}"/><rect x="156" y="130" width="200" height="44" fill="{RED}"/>' + text_lines(180, 220, 150, 4, 30, seed=12, sw=7)
         + f'<path d="M176 350 q40 -22 80 0 t80 0" fill="none" stroke="{RED}" stroke-width="8"/>')
    icon("e10", f'<g transform="rotate(-8 256 256)"><rect x="106" y="150" width="300" height="200" fill="{PAPER}"/><path d="M106 150 L256 262 L406 150" fill="none" stroke="{PAPER_D}" stroke-width="8"/></g>'
         + sheet(190, 100, 190, 230, 7, "#f3ead4") + text_lines(210, 140, 150, 6, 26, seed=13) + f'<rect x="210" y="290" width="90" height="12" fill="{INK}"/></g>')
    icon("e11", '<rect x="110" y="120" width="292" height="290" fill="#3a2a1d"/>'
         + "".join(f'<rect x="{126+(26 if i<2 else 0)}" y="{136+i*90}" width="260" height="78" fill="#2c2016" stroke="#0f0b08" stroke-width="5"/><rect x="{226+(26 if i<2 else 0)}" y="{166+i*90}" width="60" height="14" rx="6" fill="{AMBER}"/>' for i in range(3))
         + '<path d="M380 150 l18 12 l-14 16 l16 10" fill="none" stroke="#e8dfc8" stroke-width="7"/>' + f'<g transform="rotate(30 300 400)"><rect x="230" y="394" width="150" height="10" fill="#c9cfda"/><rect x="360" y="386" width="60" height="26" rx="8" fill="#5a2a22"/></g>')
    hands = '<line x1="256" y1="256" x2="296" y2="236" stroke="#1d1a16" stroke-width="9" stroke-linecap="round"/><line x1="256" y1="256" x2="226" y2="210" stroke="#1d1a16" stroke-width="7" stroke-linecap="round"/>'
    icon("e12", f'<rect x="216" y="80" width="80" height="352" rx="14" fill="#3b2b1e"/><circle cx="256" cy="256" r="104" fill="#aab2be"/><circle cx="256" cy="256" r="86" fill="{PAPER}"/>' + hands
         + '<path d="M214 196 L262 250 L240 300 M262 250 L318 232" fill="none" stroke="#39424f" stroke-width="5"/>')
    icon("e13", f'<circle cx="256" cy="290" r="110" fill="{JADE}" opacity="0.18" filter="url(#blur20)"/><path d="M256 190 q-34 -70 20 -84 q40 0 26 40" fill="none" stroke="#c9cfda" stroke-width="9" stroke-linecap="round"/>'
         f'<circle cx="256" cy="206" r="12" fill="#c9cfda"/><path d="M256 218 q-56 80 0 150 q56 -70 0 -150Z" fill="{JADE}"/><path d="M244 250 q-18 44 6 84" fill="none" stroke="#bdf3de" stroke-width="7" stroke-linecap="round"/>')
    icon("e14", f'<path d="M110 200 L402 200 L402 410 L110 410 Z" fill="#7a6850"/><path d="M130 220 L382 220 L382 300 L130 300 Z" fill="#05070b"/><rect x="150" y="330" width="130" height="50" fill="{PAPER}"/><rect x="162" y="346" width="80" height="10" fill="{INK}"/>'
         f'<path d="M96 150 L416 150 L402 200 L110 200 Z" fill="#84705a" transform="rotate(-10 256 175) translate(20 -36)"/><circle cx="340" cy="356" r="14" fill="#00000066"/>')
    icon("e16", f'<g transform="rotate(4 256 256)"><rect x="140" y="96" width="232" height="330" rx="10" fill="#39424f"/><rect x="158" y="130" width="196" height="278" fill="{PAPER}"/><rect x="206" y="82" width="100" height="40" rx="8" fill="#aab2be"/>'
         + text_lines(176, 164, 160, 5, 24, seed=16) + f'<path d="M256 300 v80 M216 340 h80" stroke="{RED}" stroke-width="14"/></g>')
    icon("e17", f'<g transform="rotate(-5 256 256)"><path d="M96 150 L210 150 L232 176 L416 176 L416 392 L96 392 Z" fill="#b8924e"/>' + f'<rect x="130" y="166" width="230" height="200" fill="{PAPER}" transform="rotate(4 245 266)"/>'
         + f'<path d="M96 210 L416 210 L416 392 L96 392 Z" fill="#d2ab62"/><rect x="130" y="246" width="150" height="50" fill="{PAPER}"/><rect x="144" y="262" width="100" height="12" fill="{INK}"/></g>')
    icon("e18", f'<rect x="96" y="120" width="320" height="272" fill="#3b2b1e"/><rect x="116" y="140" width="280" height="232" fill="{PAPER}"/><rect x="176" y="170" width="160" height="16" fill="{INK}" opacity="0.8"/>' + text_lines(156, 214, 200, 4, 26, seed=18)
         + f'<circle cx="340" cy="326" r="26" fill="{RED}"/><path d="M326 344 l-8 34 l22 -14 l22 14 l-8 -34" fill="{RED}"/>')
    icon("e19", f'<circle cx="190" cy="200" r="64" fill="none" stroke="{AMBER}" stroke-width="26"/><rect x="236" y="236" width="190" height="26" fill="{AMBER}" transform="rotate(40 236 236)"/><rect x="330" y="318" width="26" height="54" fill="{AMBER}" transform="rotate(40 330 318)"/><rect x="370" y="352" width="26" height="40" fill="{AMBER}" transform="rotate(40 370 352)"/>'
         f'<rect x="150" y="330" width="120" height="70" rx="8" fill="{PAPER}"/><rect x="166" y="352" width="60" height="12" fill="{INK}"/>')


if __name__ == "__main__":
    lobby(); portrait_erdem(); menu_bg(); icons(); portraits(); office(); stacks(); director(); more_icons()
    print("SVG sources written to art_src/")
