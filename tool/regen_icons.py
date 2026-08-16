#!/usr/bin/env python3
"""Regenerate every app icon PNG/ICO at its correct size and validate it.

Some launcher icons in the repo were generated with inconsistent
IHDR/pixel-data sizes, which makes aapt2 (Android resource compiler)
fail during `flutter build apk`. This script rebuilds all of them.
"""
import math
import os
import struct
import zlib

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')

BG = (76, 110, 245)
FG = (255, 255, 255)


def make_png(size, path):
    """Solid rounded-rect with a bold checkmark, supersampled 3x."""
    SS = 3
    n = size * SS
    r = int(size * 0.22 * SS)

    def seg_dist(px, py, x1, y1, x2, y2):
        dx, dy = x2 - x1, y2 - y1
        l2 = dx * dx + dy * dy
        t = 0 if l2 == 0 else max(0, min(1, ((px - x1) * dx + (py - y1) * dy) / l2))
        cx, cy = x1 + t * dx, y1 + t * dy
        return math.hypot(px - cx, py - cy)

    def in_rect(x, y):
        return (r <= x <= n - r) and (r <= y <= n - r)

    p1 = (0.30 * n, 0.53 * n)
    p2 = (0.45 * n, 0.68 * n)
    p3 = (0.73 * n, 0.34 * n)
    th = 0.075 * n
    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            acc = [0.0, 0.0, 0.0, 0.0]
            for sy in range(SS):
                for sx in range(SS):
                    px = x * SS + sx + 0.5
                    py = y * SS + sy + 0.5
                    if not in_rect(px, py):
                        continue
                    d = min(seg_dist(px, py, *p1, *p2), seg_dist(px, py, *p2, *p3))
                    if d <= th - SS:
                        c = FG
                    elif d <= th + SS:
                        t = (d - (th - SS)) / (2 * SS)
                        c = tuple(int(FG[i] * (1 - t) + BG[i] * t) for i in range(3))
                    else:
                        c = BG
                    acc[0] += c[0]
                    acc[1] += c[1]
                    acc[2] += c[2]
                    acc[3] += 255.0
            k = SS * SS
            row += bytes((int(acc[0] / k), int(acc[1] / k), int(acc[2] / k), int(acc[3] / k)))
        rows.append(bytes(row))
    raw = b''.join(b'\x00' + r for r in rows)

    def chunk(tag, data):
        return (struct.pack('>I', len(data)) + tag + data +
                struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff))

    ihdr = struct.pack('>IIBBBBB', size, size, 8, 6, 0, 0, 0)
    png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) +
           chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(png)


def make_ico(path):
    sizes = [16, 24, 32, 48, 64, 128, 256]
    pngs = []
    for s in sizes:
        tmp = f'/tmp/taskflow_ico_{s}.png'
        make_png(s, tmp)
        pngs.append((s, open(tmp, 'rb').read()))
    header = struct.pack('<HHH', 0, 1, len(pngs))
    entries = b''
    blobs = b''
    offset = 6 + 16 * len(pngs)
    for s, data in pngs:
        entries += struct.pack('<BBBBHHII', (0 if s >= 256 else s),
                               (0 if s >= 256 else s), 0, 0, 1, 32, len(data), offset)
        blobs += data
        offset += len(data)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(header + entries + blobs)


def validate_png(path, expected):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', 'bad signature'
    off = 8
    idat = b''
    w = h = None
    while off < len(data):
        ln = struct.unpack('>I', data[off:off + 4])[0]
        typ = data[off + 4:off + 8]
        chunk = data[off + 8:off + 8 + ln]
        crc = struct.unpack('>I', data[off + 8 + ln:off + 12 + ln])[0]
        assert crc == zlib.crc32(typ + chunk) & 0xffffffff, f'bad crc {typ}'
        if typ == b'IHDR':
            w, h = struct.unpack('>II', chunk[:8])
        if typ == b'IDAT':
            idat += chunk
        if typ == b'IEND':
            break
        off += 12 + ln
    raw = zlib.decompress(idat)
    assert len(raw) == h * (1 + w * 4), f'data/header mismatch'
    if expected:
        assert (w, h) == (expected, expected), f'expected {expected}x{expected}, got {w}x{h}'
    return w, h


ANDROID = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
}

WEB = {
    'web/favicon.png': 32,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
}

IOS = {
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png': 64,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png': 128,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png': 192,
}

MACOS = {
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
}

ok = bad = 0
for mapping in (ANDROID, WEB, IOS, MACOS):
    for rel, size in mapping.items():
        path = os.path.join(ROOT, rel)
        make_png(size, path)
        try:
            w, h = validate_png(path, size)
            ok += 1
            print(f'OK   {rel} ({w}x{h})')
        except AssertionError as e:
            bad += 1
            print(f'FAIL {rel}: {e}')

# Windows ICO
ico_path = os.path.join(ROOT, 'windows/runner/resources/app_icon.ico')
make_ico(ico_path)
with open(ico_path, 'rb') as f:
    head = f.read(4)
assert head == b'\x00\x00\x01\x00', 'bad ico'
print(f'OK   windows/runner/resources/app_icon.ico ({os.path.getsize(ico_path)}B)')

print(f'\n{ok} PNGs regenerated and validated, {bad} failures')
raise SystemExit(1 if bad else 0)
