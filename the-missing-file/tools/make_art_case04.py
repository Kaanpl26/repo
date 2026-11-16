#!/usr/bin/env python3
"""Original vector art for Case 4, "File 103-F". Writes SVG sources to art_src/
and the list of render targets to art_src/targets_case04.json."""
import json, os, random
from make_art import (OUT, PAPER, PAPER_D, INK, AMBER, RED, JADE, GLASSES, HAIR_A,
                      save, rain, text_lines, bust, room, finish, window, desk_lamp, boxes, icon, sheet)
from make_art_case02 import CAST as CAST2
from make_art_case03 import hair_nur

TARGETS = {}


def out(name, path):
    TARGETS[name] = path


def hair_karaca(P, s, cx, base):
    return (f'<path d="M{P(-68,-372)} Q{P(-84,-462)} {P(0,-464)} Q{P(84,-462)} {P(68,-372)} Q{P(56,-430)} {P(-10,-426)} Q{P(-52,-420)} {P(-68,-372)} Z" fill="#c9ccd2"/>'
            f'<path d="M{P(0,-464)} Q{P(84,-462)} {P(68,-372)} Q{P(56,-430)} {P(-10,-426)} Z" fill="#9a9ea6"/>')


def hair_arikan(P, s, cx, base):
    return (f'<path d="M{P(-74,-300)} Q{P(-96,-470)} {P(0,-470)} Q{P(96,-470)} {P(74,-300)} L{P(56,-300)} Q{P(66,-410)} {P(0,-424)} Q{P(-66,-410)} {P(-56,-300)} Z" fill="#1d1614"/>'
            f'<path d="M{P(0,-470)} Q{P(96,-470)} {P(74,-300)} L{P(56,-300)} Q{P(66,-410)} {P(0,-424)} Z" fill="#120d0c"/>')


def arikan_extra(P, s, cx, base):
    return f'<path d="M{P(-70,-236)} L{P(0,-196)} L{P(70,-236)} L{P(60,-214)} L{P(0,-170)} L{P(-60,-214)} Z" fill="#8c2f39"/>'


def yildiz_extra(P, s, cx, base):
    return (f'<path d="M{P(-26,-306)} Q{P(0,-318)} {P(26,-306)} Q{P(0,-296)} {P(-26,-306)} Z" fill="#2b2622"/>'
            f'<rect x="{cx-96*s}" y="{base-206*s}" width="{40*s}" height="{12*s}" fill="{AMBER}"/><rect x="{cx+56*s}" y="{base-206*s}" width="{40*s}" height="{12*s}" fill="{AMBER}"/>'
            f'<circle cx="{cx+76*s}" cy="{base-150*s}" r="{12*s}" fill="#c9cfda"/>')


CAST = {
    "karaca": dict(skin="#d0ab90", skin_sh="#8f6e5a", jacket="#22202a", jacket_l="#383444", shirt="#f1eee6", hair_fn=hair_karaca, extra_fn=GLASSES, tie="#7a2331"),
    "arikan": dict(skin="#cfa588", skin_sh="#90695a", jacket="#15161c", jacket_l="#262832", shirt="#efece4", hair_fn=hair_arikan, extra_fn=arikan_extra),
    "yildiz": dict(skin="#bf9471", skin_sh="#7c5a44", jacket="#3f4b5c", jacket_l="#566579", shirt="#3f4b5c", hair_fn=hair_nur, extra_fn=yildiz_extra, brow_tilt=-2),
}


def figure(who, cx, base, s, mood=None):
    if who == "soykan":
        return bust(cx=cx, base=base, s=s, mood=mood, **CAST2["soykan"])
    if who == "aras":
        return bust("#c79a78", "#7c5a46", "#23262e", "#3a3f4c", "#eef0f2", HAIR_A, None, brow_tilt=-2, tie=AMBER, cx=cx, base=base, s=s, mood=mood)
    return bust(cx=cx, base=base, s=s, mood=mood, **CAST[who])


def portraits():
    for who in CAST:
        for mood in (None, "defensive", "shaken"):
            tag = "" if mood is None else "_" + mood
            save(who + tag, 700, 1000, figure(who, 350, 1010, 2.05, mood))
            out(who + tag, f"assets/portraits/{who}{tag}.png")


def paper(x, y, w, h, rot=0, seed=1, fill=PAPER, n=4):
    return sheet(x, y, w, h, rot, fill) + text_lines(x + 12, y + 16, w - 24, n, (h - 24) / max(n, 1), seed=seed, sw=3) + '</g>'


def book(x, y, w=200, h=74, seed=1):
    return (f'<path d="M{x} {y+h} L{x+14} {y} L{x+w/2} {y-6} L{x+w/2} {y+h} Z" fill="{PAPER}"/><path d="M{x+w/2} {y+h} L{x+w/2} {y-6} L{x+w-14} {y} L{x+w} {y+h} Z" fill="#f3ead4"/>'
            + text_lines(x + 24, y + 14, w / 2 - 40, 4, 13, seed=seed, sw=3) + text_lines(x + w / 2 + 12, y + 14, w / 2 - 40, 4, 13, seed=seed + 1, sw=3))


# ------------------------------------------------------------------ prison visiting block
def prison():
    d, b = room("#12161c", "#27303a", "#22262b", "#0a0b0d", lamp="#dfeaff", panels=False)
    b.append('<rect x="0" y="470" width="2880" height="10" fill="#3a4654"/><rect x="0" y="480" width="2880" height="350" fill="#1b2129" opacity="0.6"/>')
    # steel stairs with tape at the foot
    for i in range(7):
        b.append(f'<rect x="{120+i*62}" y="{350+i*68}" width="{500-i*62}" height="18" fill="#56606f"/><rect x="{120+i*62}" y="{368+i*68}" width="{500-i*62}" height="50" fill="#2a323d"/>')
    b.append('<path d="M120 300 L560 780" stroke="#8a93a3" stroke-width="10" fill="none"/>')
    b.append(f'<path d="M430 800 q80 -30 190 4 q40 30 -30 44 q-120 14 -170 -10 q-30 -22 10 -38Z" fill="none" stroke="{PAPER}" stroke-width="6" stroke-dasharray="14 10"/>')
    b.append(f'<rect x="90" y="842" width="640" height="14" fill="{AMBER}"/>' + "".join(f'<rect x="{100+i*60}" y="842" width="30" height="14" fill="#15110f"/>' for i in range(11)))
    # camera above the stairs
    b.append('<rect x="690" y="150" width="14" height="50" fill="#56606f"/><rect x="650" y="196" width="120" height="50" rx="8" fill="#c9cfda"/><circle cx="668" cy="221" r="16" fill="#15110f"/><circle cx="752" cy="210" r="6" fill="#3a3f48"/>')
    # long counter
    b.append('<circle cx="1700" cy="150" r="700" fill="url(#glowA)" opacity="0.35"/>')
    b.append(figure("arikan", 1040, 690, 0.9))
    b.append(figure("yildiz", 2580, 690, 0.9))
    b.append('<rect x="860" y="640" width="1940" height="22" fill="#56606f"/><rect x="880" y="662" width="1900" height="168" fill="#2a323d"/>')
    b.append(book(1290, 566, 210, 74, 51))
    b.append(paper(1560, 560, 130, 84, -5, 53, n=5))
    b.append(f'<rect x="1740" y="250" width="170" height="220" fill="#7a5a3c"/><rect x="1752" y="280" width="146" height="178" fill="{PAPER}"/><rect x="1796" y="240" width="58" height="28" rx="6" fill="#aab2be"/>' + text_lines(1764, 300, 122, 7, 22, seed=54, sw=4) + f'<rect x="1764" y="386" width="122" height="14" fill="{RED}" opacity="0.5"/>')
    b.append('<rect x="1980" y="500" width="220" height="140" rx="8" fill="#15181e"/><rect x="1994" y="512" width="192" height="104" fill="#0c2a2c"/>' + "".join(f'<rect x="{1998+(i%2)*96}" y="{516+(i//2)*52}" width="88" height="46" fill="{"#06090c" if i == 2 else "#1c4a4c"}"/>' for i in range(4)) + f'<circle cx="2176" cy="628" r="5" fill="{RED}"/>')
    b.append(f'<rect x="2260" y="600" width="190" height="40" fill="#8a93a3"/><rect x="2284" y="570" width="100" height="34" fill="#7a2331"/><rect x="2292" y="576" width="60" height="6" fill="{PAPER}"/><rect x="2392" y="584" width="40" height="18" fill="{PAPER_D}"/>')
    finish("prison", d, b)
    out("prison", "assets/scenes/prison.png")


# ------------------------------------------------------------------ Karaca's law office
def lawoffice():
    d, b = room("#1a1410", "#3a2a1e", "#2a1f16", "#0c0906")
    b.append(window(150, 160, 360, 420, 61, "w41"))
    b.append(rain(150, 160, 360, 420, 40, 62, 0.25))
    # brass plate and key board
    b.append(f'<rect x="640" y="270" width="210" height="110" rx="6" fill="#b08a3a"/><rect x="650" y="280" width="190" height="90" rx="4" fill="#c9a24a"/><rect x="672" y="304" width="146" height="10" fill="#3a2a10"/><rect x="690" y="328" width="110" height="8" fill="#3a2a10" opacity="0.7"/><path d="M735 346 l10 -14 l10 14Z" fill="#3a2a10"/>')
    b.append('<rect x="900" y="300" width="150" height="110" fill="#3b2b1e"/>' + "".join(f'<circle cx="{925+i*34}" cy="322" r="5" fill="#c9cfda"/>' + (f'<rect x="{922+i*34}" y="326" width="6" height="34" fill="#c9a24a"/><circle cx="{925+i*34}" cy="366" r="9" fill="#c9a24a"/>' if i != 2 else f'<rect x="{915+i*34}" y="330" width="22" height="30" fill="{PAPER}"/>') for i in range(4)))
    b.append(desk_lamp(1160, 640))
    b.append(figure("karaca", 1420, 700, 0.9))
    b.append('<rect x="1080" y="640" width="860" height="22" fill="#5a3d26"/><rect x="1100" y="662" width="820" height="168" fill="url(#desk)"/>')
    b.append(book(1560, 568, 190, 72, 63))
    b.append(f'<rect x="1780" y="600" width="130" height="40" fill="#7a2331"/><rect x="1790" y="590" width="110" height="14" fill="{PAPER}"/>')
    # bookcase
    b.append('<rect x="2010" y="150" width="400" height="680" fill="#2a1f16"/>')
    r = random.Random(64)
    for row in range(4):
        y = 180 + row * 160
        b.append(f'<rect x="2022" y="{y+130}" width="376" height="12" fill="#4a3625"/>' + "".join(f'<rect x="{2030+i*30}" y="{y+r.randint(0,20)}" width="26" height="{130-r.randint(0,20)}" fill="{r.choice(["#5a2a22","#23324a","#2d3a2e","#4a3625","#3a2a4a"])}"/>' for i in range(12)))
    b.append(figure("aras", 2640, 700, 0.9))
    b.append('<rect x="2500" y="690" width="300" height="18" fill="#5a3d26"/><rect x="2520" y="708" width="260" height="122" fill="#2a1f16"/>')
    finish("lawoffice", d, b)
    out("lawoffice", "assets/scenes/lawoffice.png")


# ------------------------------------------------------------------ the chief's office
def chief():
    d, b = room("#0f1420", "#232c40", "#1c1a1c", "#08080a")
    b.append('<rect x="180" y="150" width="20" height="680" fill="#8a7a4a"/><path d="M200 170 L470 190 L450 300 L470 400 L200 420 Z" fill="#8c2f39"/><circle cx="310" cy="296" r="40" fill="none" stroke="#f1eee6" stroke-width="10"/>')
    # framed photograph
    b.append(f'<rect x="560" y="200" width="250" height="190" fill="#b08a3a"/><rect x="574" y="214" width="222" height="162" fill="#59616e"/><path d="M574 330 L640 250 L700 330 Z" fill="#3a4250"/><rect x="664" y="236" width="18" height="100" fill="{PAPER}"/><path d="M656 236 l26 0 l-13 -26Z" fill="{RED}"/>' + "".join(f'<circle cx="{620+i*56}" cy="330" r="13" fill="#c8a087"/><rect x="{606+i*56}" y="343" width="28" height="33" fill="#15181e"/>' for i in range(3)))
    b.append(desk_lamp(1010, 640))
    b.append(figure("soykan", 1440, 700, 0.9))
    b.append('<rect x="900" y="640" width="1060" height="22" fill="#4a3625"/><rect x="920" y="662" width="1020" height="168" fill="url(#desk)"/>')
    b.append(book(1100, 570, 190, 70, 71))
    b.append(paper(1700, 556, 130, 90, 6, 73, n=5) + f'<rect x="1716" y="622" width="60" height="10" fill="#23324a" transform="rotate(6 1765 600)"/>')
    b.append('<rect x="1860" y="596" width="70" height="44" rx="6" fill="#15181e"/><rect x="1866" y="586" width="58" height="14" rx="6" fill="#262e3f"/>')
    b.append(window(2260, 150, 440, 440, 72, "w42"))
    b.append(rain(2260, 150, 440, 440, 50, 74, 0.25))
    b.append('<rect x="2100" y="560" width="110" height="270" fill="#262e3f"/>' + "".join(f'<rect x="2110" y="{575+i*84}" width="90" height="70" fill="#1a2030"/><rect x="2140" y="{604+i*84}" width="30" height="8" fill="#8a93a3"/>' for i in range(3)))
    finish("chief", d, b)
    out("chief", "assets/scenes/chief.png")


# ------------------------------------------------------------------ the lamp room of the old lighthouse
def lighthouse():
    d, b = room("#0c1018", "#1e2632", "#221c16", "#090706", lamp="#ffe9b0", panels=False)
    for i, x in enumerate((140, 760, 1960, 2520)):
        b.append(window(x, 180, 240, 420, 80 + i, f"w5{i}") + rain(x, 180, 240, 420, 30, 85 + i, 0.25))
    # the lamp
    b.append('<circle cx="1500" cy="430" r="620" fill="url(#glowA)" opacity="0.55"/>')
    b.append('<rect x="1380" y="640" width="240" height="190" fill="#3a3f48"/><rect x="1350" y="620" width="300" height="26" fill="#56606f"/>')
    b.append('<path d="M1400 620 Q1360 430 1500 240 Q1640 430 1600 620 Z" fill="#dfeaff" opacity="0.28" stroke="#c9a24a" stroke-width="10"/>' + "".join(f'<path d="M{1410+i*18} 600 Q{1500} {330+i*30} {1590-i*18} 600" fill="none" stroke="#f4f8ff" stroke-width="4" opacity="0.5"/>' for i in range(4)) + '<ellipse cx="1500" cy="470" rx="34" ry="60" fill="#ffe9b0" opacity="0.9"/>')
    b.append(f'<rect x="1430" y="690" width="140" height="90" fill="#262b33"/><rect x="1470" y="700" width="70" height="56" fill="{PAPER_D}" transform="rotate(-8 1505 728)"/>')
    # tin box, crate with the ledger
    b.append('<rect x="430" y="720" width="260" height="110" fill="#5d6a5a" stroke="#2a332a" stroke-width="6"/><rect x="420" y="700" width="280" height="26" fill="#74826f"/><rect x="540" y="752" width="40" height="30" fill="#c9a24a"/>')
    b.append('<rect x="1000" y="700" width="260" height="130" fill="#5a4636" stroke="#2a2018" stroke-width="6"/>')
    b.append(f'<g transform="rotate(-4 1130 660)"><rect x="1030" y="630" width="200" height="70" fill="#1d3a2e"/><rect x="1030" y="630" width="200" height="12" fill="#2f5a47"/><rect x="1060" y="654" width="110" height="26" fill="{PAPER}"/><rect x="1070" y="662" width="80" height="8" fill="{INK}"/></g>')
    # petrol can and matches, hatch
    b.append(f'<rect x="2230" y="690" width="150" height="140" rx="10" fill="#8c2f39"/><rect x="2260" y="660" width="50" height="34" fill="#6a222b"/><path d="M2310 668 l60 -24 l10 18 l-60 26Z" fill="#6a222b"/><rect x="2256" y="730" width="98" height="50" fill="#a8414c"/><rect x="2410" y="800" width="60" height="30" fill="{PAPER_D}"/><rect x="2410" y="800" width="60" height="8" fill="{RED}"/>')
    b.append('<rect x="2620" y="790" width="220" height="40" fill="#070605"/><rect x="2610" y="780" width="240" height="14" fill="#4a3625"/><path d="M2640 780 L2640 640 M2820 780 L2820 640" stroke="#56606f" stroke-width="10"/>')
    finish("lighthouse", d, b)
    out("lighthouse", "assets/scenes/lighthouse.png")


def icons():
    def ic(name, inner):
        icon("c4_" + name, inner)
        out("c4_" + name, f"assets/evidence/c4_{name}.png")
    ic("ledger", f'<g transform="rotate(-6 256 256)"><rect x="130" y="110" width="252" height="300" rx="8" fill="#1d3a2e"/><rect x="130" y="110" width="34" height="300" fill="#2f5a47"/><rect x="190" y="170" width="160" height="70" fill="{PAPER}"/><rect x="204" y="190" width="130" height="12" fill="{INK}"/><rect x="204" y="212" width="90" height="10" fill="{INK}" opacity="0.6"/></g>')
    ic("camera", f'<rect x="240" y="96" width="24" height="90" fill="#56606f"/><rect x="140" y="180" width="240" height="110" rx="14" fill="#c9cfda"/><circle cx="182" cy="235" r="34" fill="#15110f"/><circle cx="182" cy="235" r="14" fill="#23324a"/><line x1="120" y1="150" x2="400" y2="390" stroke="{RED}" stroke-width="18"/>')
    ic("key", f'<circle cx="190" cy="200" r="60" fill="none" stroke="#c9a24a" stroke-width="26"/><rect x="236" y="236" width="170" height="26" fill="#c9a24a" transform="rotate(38 236 236)"/><rect x="330" y="330" width="26" height="50" fill="#c9a24a" transform="rotate(38 330 330)"/><rect x="250" y="110" width="150" height="80" fill="{PAPER}" transform="rotate(12 325 150)"/><rect x="270" y="140" width="100" height="12" fill="{INK}" transform="rotate(12 325 150)"/>')
    ic("photo", f'<rect x="100" y="130" width="312" height="250" fill="#b08a3a"/><rect x="120" y="150" width="272" height="210" fill="#59616e"/><rect x="244" y="170" width="24" height="130" fill="{PAPER}"/><path d="M232 170 l48 0 l-24 -40Z" fill="{RED}"/>' + "".join(f'<circle cx="{180+i*76}" cy="300" r="20" fill="#c8a087"/><rect x="{158+i*76}" y="320" width="44" height="40" fill="#15181e"/>' for i in range(3)))
    ic("can", f'<rect x="150" y="190" width="212" height="220" rx="16" fill="#8c2f39"/><rect x="190" y="140" width="70" height="54" fill="#6a222b"/><path d="M260 150 l90 -40 l16 28 l-90 44Z" fill="#6a222b"/><rect x="186" y="250" width="140" height="80" fill="#a8414c"/><path d="M380 400 l20 -50 l18 30 l14 -44 l20 64Z" fill="#e2622a"/>')
    ic("stairs", "".join(f'<rect x="{110+i*50}" y="{150+i*50}" width="{300-i*50}" height="18" fill="#aab2be"/><rect x="{110+i*50}" y="{168+i*50}" width="{300-i*50}" height="32" fill="#39424f"/>' for i in range(5)) + f'<path d="M300 420 q50 -20 100 0 q14 20 -20 26 q-60 6 -84 -6Z" fill="none" stroke="{PAPER}" stroke-width="7" stroke-dasharray="12 8"/>')


if __name__ == "__main__":
    portraits(); prison(); lawoffice(); chief(); lighthouse(); icons()
    with open(os.path.join(OUT, "targets_case04.json"), "w") as f:
        json.dump(TARGETS, f, indent=1)
    print("Case 4 SVG sources written:", len(TARGETS))
