#!/usr/bin/env python3
"""MuseFlow brand + artwork generator (SVG -> PNG via headless Chrome)."""
import base64
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "images"
COVERS = ASSETS / "covers"
OUT = ROOT / "tool" / "art"
OUT.mkdir(parents=True, exist_ok=True)
COVERS.mkdir(parents=True, exist_ok=True)
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

GRAD = """
<linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#8B5CF6"/>
  <stop offset="0.46" stop-color="#22D3EE"/>
  <stop offset="1" stop-color="#34D399"/>
</linearGradient>
<linearGradient id="g2" x1="1" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#A78BFA"/>
  <stop offset="1" stop-color="#22D3EE"/>
</linearGradient>
<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5">
  <stop offset="0" stop-color="#7C5CFF" stop-opacity="0.55"/>
  <stop offset="1" stop-color="#7C5CFF" stop-opacity="0"/>
</radialGradient>
<filter id="blur40" x="-60%" y="-60%" width="220%" height="220%">
  <feGaussianBlur stdDeviation="40"/>
</filter>
<filter id="blur18" x="-60%" y="-60%" width="220%" height="220%">
  <feGaussianBlur stdDeviation="18"/>
</filter>
"""


def mark(size=512, with_bg=True):
    """The MuseFlow monogram: a fluid M ribbon inside an orbital ring."""
    bg = ""
    if with_bg:
        bg = f"""
  <rect width="{size}" height="{size}" rx="{size*0.235}" fill="#080A13"/>
  <rect width="{size}" height="{size}" rx="{size*0.235}" fill="url(#bgTint)"/>
  <circle cx="{size*0.22}" cy="{size*0.18}" r="{size*0.36}" fill="url(#glow)"/>
  <circle cx="{size*0.82}" cy="{size*0.84}" r="{size*0.34}" fill="url(#glowCyan)" filter="url(#blur40)"/>
  <rect x="1.5" y="1.5" width="{size-3}" height="{size-3}" rx="{size*0.232}" fill="none" stroke="white" stroke-opacity="0.10" stroke-width="2"/>
  <path d="M 0 0 H {size} V {size*0.5} C {size*0.7} {size*0.62}, {size*0.3} {size*0.4}, 0 {size*0.55} Z" fill="white" fill-opacity="0.02"/>
"""
    s = size / 512.0
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 512 512">
<defs>
  {GRAD}
  <linearGradient id="bgTint" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#151A33"/>
    <stop offset="1" stop-color="#070810"/>
  </linearGradient>
  <radialGradient id="glowCyan" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#22D3EE" stop-opacity="0.35"/>
    <stop offset="1" stop-color="#22D3EE" stop-opacity="0"/>
  </radialGradient>
  <linearGradient id="sheen" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="white" stop-opacity="0"/>
    <stop offset="0.5" stop-color="white" stop-opacity="0.55"/>
    <stop offset="1" stop-color="white" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="mGrad" x1="0.1" y1="0" x2="0.9" y2="1">
    <stop offset="0" stop-color="#C4B5FD"/>
    <stop offset="0.38" stop-color="#8B5CF6"/>
    <stop offset="0.7" stop-color="#22D3EE"/>
    <stop offset="1" stop-color="#34D399"/>
  </linearGradient>
  <filter id="markGlow" x="-40%" y="-40%" width="180%" height="180%">
    <feGaussianBlur stdDeviation="14"/>
  </filter>
  <filter id="grain">
    <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" stitchTiles="stitch" result="n"/>
    <feColorMatrix in="n" type="saturate" values="0"/>
    <feComponentTransfer><feFuncA type="linear" slope="0.05"/></feComponentTransfer>
  </filter>
</defs>
{bg}
<g>
  <circle cx="256" cy="256" r="196" fill="none" stroke="white" stroke-opacity="0.05" stroke-width="1"/>
  <circle cx="256" cy="256" r="170" fill="none" stroke="url(#g)" stroke-opacity="0.22" stroke-width="1.5" stroke-dasharray="2 9"/>
  <path d="M 112 384 V 196 Q 112 126 178 176 L 256 268 L 334 176 Q 400 126 400 196 V 384"
        fill="none" stroke="#7C5CFF" stroke-opacity="0.55" stroke-width="56"
        stroke-linecap="round" stroke-linejoin="round" filter="url(#markGlow)"/>
  <path d="M 112 384 V 196 Q 112 126 178 176 L 256 268 L 334 176 Q 400 126 400 196 V 384"
        fill="none" stroke="url(#mGrad)" stroke-width="46"
        stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M 112 384 V 196 Q 112 126 178 176 L 256 268 L 334 176 Q 400 126 400 196 V 384"
        fill="none" stroke="url(#sheen)" stroke-opacity="0.35" stroke-width="2"
        stroke-linecap="round" stroke-linejoin="round" transform="translate(-4,-6)"/>
  <circle cx="400" cy="196" r="9" fill="#34D399"/>
  <circle cx="400" cy="196" r="18" fill="#34D399" fill-opacity="0.18"/>
  <circle cx="112" cy="384" r="4" fill="white" fill-opacity="0.5"/>
</g>
</svg>"""


def wordmark(): 
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="480" viewBox="0 0 1600 480">
<defs>
  <linearGradient id="wg" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="0.55" stop-color="#E9E6FF"/>
    <stop offset="1" stop-color="#9FC7FF"/>
  </linearGradient>
  <linearGradient id="mg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#C4B5FD"/>
    <stop offset="0.5" stop-color="#22D3EE"/>
    <stop offset="1" stop-color="#34D399"/>
  </linearGradient>
</defs>
<g transform="translate(60 90) scale(0.586)">
  <circle cx="256" cy="256" r="196" fill="none" stroke="white" stroke-opacity="0.08" stroke-width="2"/>
  <path d="M 112 384 V 196 Q 112 126 178 176 L 256 268 L 334 176 Q 400 126 400 196 V 384"
        fill="none" stroke="url(#mg)" stroke-width="46" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="400" cy="196" r="9" fill="#34D399"/>
</g>
<text x="412" y="252" font-family="InterDisplay, Helvetica Neue, Arial" font-weight="700"
      font-size="128" letter-spacing="-3" fill="url(#wg)">MuseFlow</text>
<text x="416" y="316" font-family="Inter, Helvetica Neue, Arial" font-size="32"
      letter-spacing="10" fill="#8B93B5">沐声 · EVERY SOUND, YOUR FLOW</text>
</svg>"""


COVER_PALETTES = [
    ("#031A22", "#0E4C5C", "#22D3EE", "#34D399", "01"),
    ("#0B0B2A", "#2A1B5E", "#8B5CF6", "#F472B6", "02"),
    ("#08131F", "#1E4C5B", "#7DD3FC", "#A7F3D0", "03"),
    ("#04130F", "#123B32", "#34D399", "#A78BFA", "04"),
    ("#170615", "#4A0F3C", "#F472B6", "#A78BFA", "05"),
    ("#1A0E05", "#4A2A10", "#FBBF24", "#FB7185", "06"),
    ("#0D1411", "#2C3B31", "#D9E8DD", "#A3B18A", "07"),
    ("#040916", "#0B2350", "#38BDF8", "#818CF8", "08"),
]

TRACKS = [
    ("Tides", "LUMA", "潮汐", "Chillwave"),
    ("Night Flight", "ASTER", "夜航", "Dream Pop"),
    ("Glass Sea", "NOVA", "玻璃海", "Ambient"),
    ("Aurora Letters", "KISARAGI", "极光信笺", "Downtempo"),
    ("Neon Rain", "MONO", "霓虹雨", "Synthwave"),
    ("Slow Planet", "LUMA", "慢速星球", "Lo-Fi"),
    ("Morning Mist", "ASTER", "晨雾", "Acoustic"),
    ("Zero-G", "NOVA", "失重", "Electronic"),
]


def cover_svg(idx):
    bg, mid, a, b, num = COVER_PALETTES[idx]
    title, artist, cn, genre = TRACKS[idx]
    seed = idx + 1
    shapes = ""
    if idx % 4 == 0:
        shapes = f"""
  <g opacity="0.85">
    <circle cx="590" cy="300" r="250" fill="url(#orb)" opacity="0.55"/>
    <path d="M -80 560 C 140 430, 300 650, 520 520 S 820 430, 900 540" fill="none" stroke="{a}" stroke-opacity="0.5" stroke-width="1.4"/>
    <path d="M -80 600 C 140 470, 300 690, 520 560 S 820 470, 900 580" fill="none" stroke="{b}" stroke-opacity="0.38" stroke-width="1.4"/>
    <path d="M -80 640 C 140 510, 300 730, 520 600 S 820 510, 900 620" fill="none" stroke="{a}" stroke-opacity="0.25" stroke-width="1.4"/>
    <path d="M -80 680 C 140 550, 300 770, 520 640 S 820 550, 900 660" fill="none" stroke="{b}" stroke-opacity="0.16" stroke-width="1.4"/>
  </g>"""
    elif idx % 4 == 1:
        shapes = f"""
  <g>
    <circle cx="400" cy="330" r="190" fill="none" stroke="{a}" stroke-opacity="0.55" stroke-width="1.6"/>
    <circle cx="400" cy="330" r="240" fill="none" stroke="{b}" stroke-opacity="0.3" stroke-width="1.2"/>
    <circle cx="400" cy="330" r="300" fill="none" stroke="{a}" stroke-opacity="0.16" stroke-width="1.2"/>
    <circle cx="400" cy="330" r="120" fill="url(#orb)" opacity="0.65"/>
    <path d="M 60 760 L 400 330 L 740 760 Z" fill="none" stroke="{a}" stroke-opacity="0.12"/>
    {''.join(f'<circle cx="{120+seed*63}" cy="{180+((seed*97+i*131) % 430)}" r="{1.2+i%3}" fill="{b}" opacity="{0.7-i*0.1}"/>' for i in range(9))}
  </g>"""
    elif idx % 4 == 2:
        shapes = f"""
  <g>
    <rect x="170" y="120" width="470" height="470" rx="60" fill="url(#orb)" opacity="0.5"/>
    <rect x="250" y="200" width="310" height="310" rx="40" fill="none" stroke="{a}" stroke-opacity="0.55" stroke-width="1.4"/>
    <rect x="310" y="260" width="190" height="190" rx="26" fill="none" stroke="{b}" stroke-opacity="0.45" stroke-width="1.2"/>
    <line x1="170" y1="600" x2="640" y2="120" stroke="{b}" stroke-opacity="0.25"/>
    <line x1="240" y1="700" x2="710" y2="220" stroke="{a}" stroke-opacity="0.18"/>
  </g>"""
    else:
        shapes = f"""
  <g>
    <path d="M 80 600 Q 220 470 360 540 T 720 430" fill="none" stroke="{a}" stroke-opacity="0.5" stroke-width="2"/>
    <path d="M 80 640 Q 220 510 360 580 T 720 470" fill="none" stroke="{b}" stroke-opacity="0.3" stroke-width="1.4"/>
    <path d="M 80 680 Q 220 550 360 620 T 720 510" fill="none" stroke="{a}" stroke-opacity="0.16" stroke-width="1.4"/>
    <circle cx="640" cy="230" r="120" fill="url(#orb)" opacity="0.5"/>
    <circle cx="640" cy="230" r="170" fill="none" stroke="{b}" stroke-opacity="0.3"/>
    <circle cx="640" cy="230" r="215" fill="none" stroke="{a}" stroke-opacity="0.18"/>
  </g>"""
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="{bg}"/><stop offset="0.55" stop-color="{mid}"/><stop offset="1" stop-color="{bg}"/>
  </linearGradient>
  <radialGradient id="orb" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="{a}" stop-opacity="0.85"/>
    <stop offset="0.55" stop-color="{b}" stop-opacity="0.28"/>
    <stop offset="1" stop-color="{b}" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="vig" cx="0.5" cy="0.42" r="0.75">
    <stop offset="0" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#000" stop-opacity="0.62"/>
  </radialGradient>
  <filter id="grain">
    <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" stitchTiles="stitch"/>
    <feColorMatrix type="saturate" values="0"/>
    <feComponentTransfer><feFuncA type="linear" slope="0.08"/></feComponentTransfer>
  </filter>
  <filter id="soft"><feGaussianBlur stdDeviation="70"/></filter>
</defs>
<rect width="800" height="800" fill="url(#bg)"/>
<ellipse cx="220" cy="180" rx="300" ry="240" fill="{a}" opacity="0.16" filter="url(#soft)"/>
<ellipse cx="660" cy="620" rx="300" ry="260" fill="{b}" opacity="0.14" filter="url(#soft)"/>
{shapes}
<rect width="800" height="800" fill="url(#vig)"/>
<rect width="800" height="800" filter="url(#grain)" opacity="0.5"/>
<rect x="1" y="1" width="798" height="798" fill="none" stroke="white" stroke-opacity="0.08"/>
<g font-family="Inter, Helvetica Neue, Arial" fill="white">
  <text x="54" y="70" font-size="15" letter-spacing="6" opacity="0.62">MUSEFLOW SESSIONS</text>
  <text x="746" y="70" font-size="15" letter-spacing="2" text-anchor="end" opacity="0.45">NO. {num}</text>
  <text x="54" y="650" font-family="InterDisplay, Helvetica Neue, Arial" font-weight="700"
        font-size="74" letter-spacing="-2">{title}</text>
  <text x="56" y="700" font-size="22" letter-spacing="5" opacity="0.72">{artist}</text>
  <text x="56" y="746" font-size="17" letter-spacing="3" opacity="0.4">{genre} · {cn}</text>
</g>
<g transform="translate(746 730)" opacity="0.6">
  <circle r="3" fill="{a}"/><circle r="9" fill="none" stroke="{a}" stroke-opacity="0.5"/>
</g>
</svg>"""


def render(svg_path: Path, png_path: Path, width: int, height: int = None, transparent=False):
    height = height or width
    cmd = [
        CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--no-sandbox", "--force-device-scale-factor=1",
        f"--window-size={width},{height}",
        f"--screenshot={png_path}", f"file://{svg_path}",
    ]
    if transparent:
        cmd.insert(-1, "--default-background-color=00000000")
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def full_bleed_icon():
    inner = mark(1024, False)
    # strip the outer transparent canvas and place mark on a full-bleed aurora field
    return inner.replace(
        "</defs>",
        """  <radialGradient id="bgA" cx="0.2" cy="0.1" r="0.9">
    <stop offset="0" stop-color="#242A54"/>
    <stop offset="0.55" stop-color="#0C1022"/>
    <stop offset="1" stop-color="#05060C"/>
  </radialGradient>
  <radialGradient id="bgB" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#7C5CFF" stop-opacity="0.38"/>
    <stop offset="1" stop-color="#7C5CFF" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="bgC" cx="0.5" cy="0.5" r="0.5">
    <stop offset="0" stop-color="#22D3EE" stop-opacity="0.3"/>
    <stop offset="1" stop-color="#22D3EE" stop-opacity="0"/>
  </radialGradient>
</defs>""", 1
    ).replace(
        "<g>",
        """<rect width="512" height="512" fill="url(#bgA)"/>
<circle cx="130" cy="110" r="260" fill="url(#bgB)"/>
<circle cx="420" cy="430" r="240" fill="url(#bgC)"/>
<g>""", 1
    )


def wordmark_dark():
    return wordmark().replace("<svg ", '<svg style="background:#0A0C16" ', 1)


def main():
    (OUT / "logo_wordmark_dark.svg").write_text(wordmark_dark())
    render(OUT / "logo_wordmark_dark.svg", ASSETS / "logo_wordmark_dark.png", 1600, 480)
    (OUT / "logo_app.svg").write_text(mark(1024, True))
    (OUT / "app_icon.svg").write_text(full_bleed_icon())
    render(OUT / "app_icon.svg", ASSETS / "app_icon.png", 1024)
    (OUT / "logo_mark.svg").write_text(mark(512, False))
    (OUT / "logo_wordmark.svg").write_text(wordmark())
    render(OUT / "logo_app.svg", ASSETS / "logo_app.png", 1024)
    render(OUT / "logo_mark.svg", ASSETS / "logo_mark.png", 512, transparent=True)
    render(OUT / "logo_wordmark.svg", ASSETS / "logo_wordmark.png", 1600, 480, transparent=True)
    subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "90", str(OUT / "logo_app.png"), "--out", str(OUT / "logo_app.jpg")], check=True, stdout=subprocess.DEVNULL)
    for i in range(8):
        p = OUT / f"cover_{i+1:02d}.svg"
        p.write_text(cover_svg(i))
        raw = OUT / f"cover_{i+1:02d}.png"
        render(p, raw, 800)
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "88", str(raw), "--out", str(COVERS / f"cover_{i+1:02d}.jpg")], check=True, stdout=subprocess.DEVNULL)
    print("done")


if __name__ == "__main__":
    main()
