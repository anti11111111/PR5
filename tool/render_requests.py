"""Снимок журнала запросов сервера для отчёта."""

import json
import os
from urllib.parse import unquote
from urllib.request import Request, urlopen

from PIL import Image, ImageDraw, ImageFont

BASE = "http://127.0.0.1:8080"
OUT = os.path.join(os.path.dirname(__file__), "..", "report", "screenshots", "10_requests.png")
FONT = r"C:\Windows\Fonts\consola.ttf"


def call(path, method="GET", body=None, token=None):
    data = None if body is None else json.dumps(body).encode("utf-8")
    headers = {"Content-Type": "application/json", "Origin": "http://127.0.0.1:5559"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = Request(BASE + path, data=data, headers=headers, method=method)
    with urlopen(request) as response:
        return json.load(response)


def main():
    login = call(
        "/api/auth/login",
        "POST",
        {"email": "admin@salon.local", "password": "admin"},
    )
    token = login["token"]
    rows = call("/api/__requests", token=token)
    lines = ["GET /api/__requests"]
    for row in rows:
        lines.append(f"{row['method']:6} {row['status']:3}  {unquote(row['path'])}")
    font = ImageFont.truetype(FONT, 20)
    padding = 28
    line_h = 32
    width = 1280
    height = padding * 2 + line_h * len(lines)
    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)
    y = padding
    for line in lines:
        draw.text((padding, y), line, fill=(20, 20, 20), font=font)
        y += line_h
    image.save(OUT)
    print("\n".join(lines))
    print("saved", OUT)


if __name__ == "__main__":
    main()
