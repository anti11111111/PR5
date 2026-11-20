"""Render source excerpts as report figures."""

import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "report", "screenshots")
ROOT = os.path.join(os.path.dirname(__file__), "..")
FONT = r"C:\Windows\Fonts\consola.ttf"

SNIPPETS = [
    ("c1_allows.png", "lib/auth/access.dart", "lib/auth/access.dart", 34, 59),
    ("c2_router.png", "lib/router.dart", "lib/router.dart", 20, 58),
    ("c3_refresh.png", "lib/core/api_client.dart", "lib/core/api_client.dart", 60, 81),
    ("c4_password.png", "lib/auth/password_rules.dart", "lib/auth/password_rules.dart", 1, 26),
    ("c5_idle.png", "lib/widgets/inactivity_watcher.dart", "lib/widgets/inactivity_watcher.dart", 61, 79),
    ("c6_tamper.png", "lib/auth/auth_notifier.dart", "lib/auth/auth_notifier.dart", 120, 128),
]


def render(name, path, title, start, end):
    full = os.path.join(ROOT, path.replace("/", os.sep))
    with open(full, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    chosen = lines[start - 1 : end]
    font = ImageFont.truetype(FONT, 18)
    small = ImageFont.truetype(FONT, 16)
    padding = 24
    line_h = 26
    width = 1280
    height = padding * 2 + 36 + line_h * len(chosen)
    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)
    draw.text((padding, 16), title, fill=(20, 40, 80), font=small)
    y = padding + 28
    for offset, line in enumerate(chosen):
        number = f"{start + offset:3}  "
        draw.text((padding, y), number + line.replace("\t", "  "), fill=(20, 20, 20), font=font)
        y += line_h
    target = os.path.join(OUT, name)
    image.save(target)
    print(name, image.size)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for item in SNIPPETS:
        render(*item)
