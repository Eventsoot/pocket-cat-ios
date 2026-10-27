"""Generate original pixel app art and six soft synthesized cat sounds."""
from pathlib import Path
import json, math, random, struct, wave, zlib

root = Path(__file__).resolve().parent.parent / 'Resources'
root.mkdir(exist_ok=True)
rate = 22050
random.seed(17)
def sound(name, duration, generate):
    values = []
    for i in range(int(duration * rate)):
        t = i / rate
        envelope = min(1, t / .025) * min(1, (duration - t) / .07)
        values.append(int(max(-.92, min(.92, generate(t) * envelope)) * 32767))
    with wave.open(str(root / (name + '.wav')), 'wb') as output:
        output.setnchannels(1); output.setsampwidth(2); output.setframerate(rate)
        output.writeframes(struct.pack('<' + 'h' * len(values), *values))
tau = math.tau
sound('purr', 1.2, lambda t: .23 * (.55 + .45 * math.sin(tau * 27 * t)) * (math.sin(tau * 95 * t) + .3 * math.sin(tau * 190 * t)))
sound('meow', .62, lambda t: .23 * math.sin(math.pi * t / .62) * (math.sin(tau * (590 * t - 220 * t * t)) + .35 * math.sin(tau * (1180 * t - 440 * t * t))))
sound('crunch', .48, lambda t: .18 * random.uniform(-1, 1) * max(0, math.sin(tau * 8 * t)) ** 4)
sound('sparkle', .32, lambda t: .18 * math.exp(-8 * t) * (math.sin(tau * 1046 * t) + .5 * math.sin(tau * 1568 * t)))
sound('sleep', .8, lambda t: .14 * math.exp(-3 * t) * (math.sin(tau * 330 * t) + .5 * math.sin(tau * 440 * t) + .3 * math.sin(tau * 660 * t)))
sound('water', .55, lambda t: .13 * math.sin(tau * (700 * t + 100 * math.sin(tau * 4 * t) / 25)) * max(0, math.sin(tau * 6 * t)))
sound('jump', .16, lambda t: .12 * math.sin(tau * (340 * t + 1300 * t * t)))
sound('pickup', .20, lambda t: .12 * math.exp(-8 * t) * math.sin(tau * (880 if t < .09 else 1320) * t))
sound('bump', .22, lambda t: .14 * math.exp(-12 * t) * math.sin(tau * (180 * t - 160 * t * t)))
sound('victory', .9, lambda t: .11 * math.sin(math.pi * (t % .18) / .18) * math.sin(tau * [523, 659, 784, 1046, 1318][min(4, int(t / .18))] * t))
catalog = root / 'Assets.xcassets'
icon = catalog / 'AppIcon.appiconset'
icon.mkdir(parents=True, exist_ok=True)
(catalog / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}))
(icon / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}))
size = 1024
pixels = bytearray(bytes.fromhex('F2DDD3') * size * size)
def block(x, y, w, h, color):
    row = bytes.fromhex(color) * w
    for py in range(y, min(y + h, size)):
        offset = (py * size + x) * 3
        pixels[offset:offset + w * 3] = row
block(243, 358, 538, 410, '694D50'); block(265, 336, 494, 410, 'E6AB79')
block(243, 215, 132, 230, '694D50'); block(649, 215, 132, 230, '694D50')
block(265, 237, 110, 208, 'E6AB79'); block(649, 237, 110, 208, 'E6AB79')
block(296, 268, 48, 85, 'CC8B90'); block(680, 268, 48, 85, 'CC8B90')
block(365, 467, 51, 68, '493846'); block(608, 467, 51, 68, '493846')
block(365, 467, 15, 17, 'FFF2D5'); block(608, 467, 15, 17, 'FFF2D5')
block(486, 574, 52, 25, 'B66D83'); block(504, 599, 16, 29, '694D50')
block(452, 628, 52, 16, '694D50'); block(520, 628, 52, 16, '694D50')
block(173, 568, 126, 14, '694D50'); block(725, 568, 126, 14, '694D50')
block(198, 631, 106, 14, '694D50'); block(720, 631, 106, 14, '694D50')
block(473, 349, 22, 81, 'CD8E65'); block(531, 349, 22, 81, 'CD8E65')
block(794, 238, 24, 70, 'B7768C'); block(771, 261, 70, 24, 'B7768C')
def chunk(name, data):
    return struct.pack('!I', len(data)) + name + data + struct.pack('!I', zlib.crc32(name + data) & 0xffffffff)
raw = b''.join(b'\0' + pixels[y * size * 3:(y + 1) * size * 3] for y in range(size))
data = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', size, size, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
(icon / 'AppIcon.png').write_bytes(data)
print('Created app icon and ten original synthesized WAV sounds.')
