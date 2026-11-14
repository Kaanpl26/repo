#!/usr/bin/env python3
"""Original vector art for the detective's office (the hub between cases).
Writes SVG sources to art_src/ and render targets to art_src/targets_office.json."""
import json, os, random
from make_art import (OUT, PAPER, PAPER_D, INK, AMBER, RED, JADE, save, text_lines, room, finish, window, desk_lamp, sheet)

TARGETS = {}


def out(name, path):
    TARGETS[name] = path


def office():
    d, b = room("#13151b", "#262a35", "#221c18", "#0a0807")
    b.append(window(150, 190, 440, 420, 55, "wo"))
    b.append('<path d="M124 830 L616 830 L860 1080 L-120 1080 Z" fill="#9fd0ff" opacity="0.05"/>')
    # the Ledger wall: a big cork board
    b.append('<rect x="760" y="140" width="760" height="440" fill="#3b2b1e"/><rect x="776" y="156" width="728" height="408" fill="#2b2018"/>')
    r = random.Random(17)
    pins = [(860, 230), (1010, 210), (1180, 250), (1380, 220), (900, 400), (1080, 430), (1250, 400), (1420, 450), (1140, 330)]
    for (x, y) in pins:
        w, h = r.choice([(92, 70), (76, 96), (104, 62)])
        b.append(f'<rect x="{x-w/2}" y="{y-h/2+10}" width="{w}" height="{h}" fill="{r.choice([PAPER, PAPER_D, "#f3ead4"])}" transform="rotate({r.randint(-7, 7)} {x} {y})"/>')
    b.append(f'<path d="M860 230 L1140 330 L1380 220 M1010 210 L1140 330 L1250 400 M900 400 L1140 330 L1420 450 M1080 430 L1250 400" fill="none" stroke="{RED}" stroke-width="4" opacity="0.9"/>')
    b.append("".join(f'<circle cx="{x}" cy="{y}" r="8" fill="{RED}"/>' for x, y in pins))
    b.append(f'<rect x="1100" y="300" width="80" height="60" fill="{INK}"/><text x="1140" y="342" font-size="40" font-family="serif" fill="{PAPER}" text-anchor="middle">?</text>')
    # shelves for mementos
    for y in (300, 470):
        b.append(f'<rect x="1610" y="{y}" width="560" height="16" fill="#4a3625"/><rect x="1610" y="{y+16}" width="560" height="6" fill="#17110c"/>')
    # frame for the rank certificate and commendations
    b.append(f'<rect x="2260" y="170" width="230" height="290" fill="#3b2b1e"/><rect x="2276" y="186" width="198" height="258" fill="{PAPER}"/>' + text_lines(2296, 226, 158, 6, 26, seed=71, sw=5)
             + f'<circle cx="2375" cy="404" r="22" fill="{AMBER}"/><path d="M2363 420 l-8 30 l20 -12 l20 12 l-8 -30" fill="{AMBER}"/>')
    # desk with the case folders
    b.append('<rect x="1480" y="640" width="1060" height="36" fill="#4a3625"/><rect x="1480" y="640" width="1060" height="6" fill="#7a5a3c"/><rect x="1500" y="676" width="1020" height="224" fill="url(#desk)"/>')
    for x in (1530, 1870, 2210):
        b.append(f'<rect x="{x}" y="704" width="280" height="170" fill="none" stroke="#0f0b08" stroke-width="5"/>')
    b.append('<ellipse cx="2010" cy="930" rx="600" ry="40" fill="#000" opacity="0.45" filter="url(#blur8)"/>')
    b.append(desk_lamp(1590, 640))
    for i, col in enumerate(["#9a7a3e", "#b8924e", "#d2ab62"]):
        b.append(f'<g transform="rotate({[-5, 3, -2][i]} 1920 {620-i*16})"><path d="M1760 {604-i*16} L1860 {604-i*16} L1876 {618-i*16} L2080 {618-i*16} L2080 {642-i*16} L1760 {642-i*16} Z" fill="{col}"/></g>')
    b.append(f'<rect x="1800" y="578" width="120" height="26" fill="{PAPER}" transform="rotate(-2 1800 578)"/><rect x="1812" y="586" width="70" height="7" fill="{INK}" transform="rotate(-2 1800 578)"/>')
    b.append('<rect x="2200" y="596" width="110" height="44" rx="8" fill="#0a0d14"/><rect x="2212" y="580" width="86" height="22" rx="10" fill="#17202f"/>')
    b.append(f'<rect x="2380" y="586" width="54" height="54" rx="6" fill="{PAPER_D}"/><path d="M2434 600 q24 4 0 30" fill="none" stroke="{PAPER_D}" stroke-width="8"/>')
    # filing cabinet of closed cases
    b.append('<rect x="2640" y="360" width="190" height="470" fill="#2f3743"/>')
    for i in range(3):
        b.append(f'<rect x="2654" y="{376+i*150}" width="162" height="134" fill="#39424f"/><rect x="2706" y="{424+i*150}" width="58" height="10" fill="#0d1218"/><rect x="2690" y="{392+i*150}" width="90" height="22" fill="{PAPER_D}"/>')
    finish("office_hub", d, b)
    out("office_hub", "assets/scenes/office_hub.png")


def prop(name, w, h, body):
    save(name, w, h, body)
    out(name, f"assets/props/{name}.png")


def props():
    # jade earring in a small frame (after File 47-B)
    prop("prop_earring", 120, 150, f'<rect width="120" height="150" fill="#3b2b1e"/><rect x="10" y="10" width="100" height="130" fill="#1f3a34"/>'
         f'<path d="M60 44 q-14 -22 6 -28" fill="none" stroke="#c9cfda" stroke-width="5"/><circle cx="60" cy="50" r="6" fill="#c9cfda"/><path d="M60 56 q-30 40 0 74 q30 -34 0 -74Z" fill="{JADE}"/>')
    # the front page that was finally printed (after File 58-D, solved)
    prop("prop_frontpage", 150, 190, f'<rect width="150" height="190" fill="#3b2b1e"/><rect x="10" y="10" width="130" height="170" fill="{PAPER}"/><rect x="18" y="20" width="114" height="18" fill="{INK}"/>'
         f'<rect x="18" y="48" width="114" height="10" fill="{INK}" opacity="0.7"/><rect x="18" y="66" width="56" height="46" fill="#59616e"/>' + text_lines(82, 70, 50, 4, 11, seed=81, sw=3) + text_lines(18, 124, 114, 5, 11, seed=82, sw=3))
    # the small brass key with tag 117 (after File 58-D)
    prop("prop_key", 100, 150, f'<rect x="46" y="0" width="8" height="24" fill="#39424f"/><circle cx="50" cy="44" r="18" fill="none" stroke="{AMBER}" stroke-width="8"/><rect x="46" y="60" width="8" height="54" fill="{AMBER}"/><rect x="54" y="92" width="14" height="8" fill="{AMBER}"/><rect x="54" y="106" width="10" height="8" fill="{AMBER}"/>'
         f'<rect x="10" y="100" width="34" height="46" rx="4" fill="{PAPER}" transform="rotate(-12 27 123)"/><rect x="16" y="118" width="22" height="6" fill="{INK}" transform="rotate(-12 27 123)"/>')
    # commendation plaque (first promotion)
    prop("prop_plaque", 190, 130, f'<rect width="190" height="130" rx="8" fill="#3b2b1e"/><rect x="12" y="12" width="166" height="106" rx="4" fill="{AMBER}"/><path d="M95 26 l10 22 l24 2 l-18 16 l6 24 l-22 -13 l-22 13 l6 -24 l-18 -16 l24 -2Z" fill="#7a5320"/><rect x="40" y="96" width="110" height="8" fill="#7a5320"/>')


if __name__ == "__main__":
    os.makedirs(os.path.join(OUT, "..", "assets", "props"), exist_ok=True)
    office(); props()
    with open(os.path.join(OUT, "targets_office.json"), "w") as f:
        json.dump(TARGETS, f, indent=1)
    print("office art written:", len(TARGETS))
