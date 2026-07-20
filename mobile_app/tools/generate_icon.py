"""Generates the app launcher icon (background + foreground) for
Uzhavanin Nanban (உழவனின் நண்பன் — "Farmer's Friend"). Run once with
`python tools/generate_icon.py`; output feeds flutter_launcher_icons
(see pubspec.yaml).

Design: a bold Tamil "உ" (first letter of "Uzhavan"/farmer) as the primary
wordmark — the standard single-letter monogram approach for app icons,
chosen because the full name isn't legible at launcher-icon sizes — with
a small leaf accent for the agriculture identity, on a deep-green field.
"""

import os
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
DEEP_GREEN = (17, 66, 32, 255)      # #114220 background
LEAF_GREEN = (139, 195, 74, 255)    # #8BC34A leaf accent
LEAF_GREEN_DARK = (76, 145, 65, 255)
SPARK_GOLD = (255, 193, 7, 255)     # #FFC107 accent
WHITE = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

TAMIL_FONT_PATH = "C:/Windows/Fonts/Nirmala.ttc"
TAMIL_FONT_BOLD_INDEX = 1
MONOGRAM_LETTER = "உ"


def rounded_square(size, radius, fill):
    img = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=radius, fill=fill)
    return img


def draw_leaf_accent(draw, cx, cy, scale):
    """Small leaf silhouette used as an accent near the monogram, echoing
    the original leaf mark without competing with the letterform."""
    length = 130 * scale
    width = 110 * scale
    angle = -40

    import math

    def rotate(x, y):
        a = math.radians(angle)
        rx = x * math.cos(a) - y * math.sin(a)
        ry = x * math.sin(a) + y * math.cos(a)
        return cx + rx, cy + ry

    def bezier(p0, p1, p2, t):
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        return x, y

    base, tip = (0, 0), (length, 0)
    ctrl_top, ctrl_bottom = (length * 0.5, -width / 2), (length * 0.5, width / 2)
    steps = 40
    top_edge = [bezier(base, ctrl_top, tip, i / steps) for i in range(steps + 1)]
    bottom_edge = [bezier(tip, ctrl_bottom, base, i / steps) for i in range(steps + 1)]
    pts = [rotate(x, y) for x, y in top_edge + bottom_edge]
    draw.polygon(pts, fill=SPARK_GOLD)

    x2, y2 = rotate(length * 0.92, 0)
    draw.line([(cx, cy), (x2, y2)], fill=LEAF_GREEN_DARK, width=int(6 * scale))


def build_monogram_layer(size, letter_color, include_leaf=True):
    layer = Image.new("RGBA", (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(layer)

    font_size = int(size * 0.62)
    font = ImageFont.truetype(TAMIL_FONT_PATH, font_size, index=TAMIL_FONT_BOLD_INDEX)

    bbox = draw.textbbox((0, 0), MONOGRAM_LETTER, font=font)
    text_w, text_h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = size / 2 - text_w / 2 - bbox[0]
    y = size / 2 - text_h / 2 - bbox[1]
    draw.text((x, y), MONOGRAM_LETTER, font=font, fill=letter_color)

    if include_leaf:
        draw_leaf_accent(draw, size * 0.76, size * 0.28, scale=size / 1024)

    return layer


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
    os.makedirs(out_dir, exist_ok=True)

    # Foreground-only (transparent bg) for Android adaptive icons — letter
    # sized conservatively since adaptive icons crop ~a third of the canvas.
    foreground = build_monogram_layer(SIZE, WHITE)
    foreground.save(os.path.join(out_dir, "app_icon_foreground.png"))

    # Full icon with background field, for iOS / generic launcher icon.
    bg = rounded_square(SIZE, radius=int(SIZE * 0.22), fill=DEEP_GREEN)
    monogram = build_monogram_layer(SIZE, WHITE)
    full = Image.alpha_composite(bg, monogram)
    full.save(os.path.join(out_dir, "app_icon.png"))

    # In-app logo (circular field) for splash/login screens.
    logo_bg = Image.new("RGBA", (SIZE, SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(logo_bg)
    draw.ellipse([(0, 0), (SIZE - 1, SIZE - 1)], fill=DEEP_GREEN)
    logo = Image.alpha_composite(logo_bg, monogram)
    logo.save(os.path.join(out_dir, "app_logo.png"))

    print("Generated: app_icon.png, app_icon_foreground.png, app_logo.png")


if __name__ == "__main__":
    main()
