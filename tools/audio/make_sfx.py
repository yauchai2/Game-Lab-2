"""用程式合成遊戲音效（全部自製，沒有版權問題）。
風格：低位元、低取樣率的粗糙電子聲（參考影片的重低音與失真質感）。
用法：python3 tools/audio/make_sfx.py  → 輸出到 assets/audio/sfx/*.wav
"""
import os
import wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")
rng = np.random.default_rng(7)


def t(d):
    return np.linspace(0, d, int(SR * d), endpoint=False)


def env(n, attack=0.005, decay=None, power=3.0):
    x = np.arange(n) / SR
    d = decay if decay else n / SR
    e = np.exp(-power * x / d)
    a = int(SR * attack)
    if a > 0:
        e[:a] *= np.linspace(0, 1, a)
    return e


def sine(f, d):
    ph = 2 * np.pi * np.cumsum(np.broadcast_to(f, t(d).shape)) / SR
    return np.sin(ph)


def square(f, d, duty=0.5):
    return np.where((sine(f, d) > np.cos(np.pi * duty)), 1.0, -1.0)


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def lowpass(x, k):
    c = np.cumsum(np.insert(x, 0, 0))
    y = (c[k:] - c[:-k]) / k
    return np.concatenate([np.full(k - 1, y[0]), y])


def sweep(f0, f1, d, curve=2.0):
    x = t(d) / d
    return f0 + (f1 - f0) * x**curve


def crush(x, bits=6, hold=2):
    """粗糙感：降位元＋降取樣（保持取樣）。"""
    x = np.repeat(x[::hold], hold)[: len(x)]
    q = 2 ** (bits - 1)
    return np.round(np.clip(x, -1, 1) * q) / q


def save(name, x, gain=0.8, bits=6, hold=2):
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    x = crush(x, bits, hold)
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


# 普通攻擊：短促的拍擊
d = 0.12
x = noise(d) * env(int(SR * d), decay=0.05) * 0.7 + sine(sweep(260, 90, d), d) * env(int(SR * d), decay=0.06)
save("hit", x)

# 拆場：重低音震擊
d = 0.55
x = sine(sweep(110, 32, d, 0.5), d) * env(int(SR * d), decay=0.3) + lowpass(noise(d), 12) * env(int(SR * d), decay=0.2) * 0.9
save("slam", x, bits=5, hold=3)

# 拆場蓄力（出招前的啟動聲）
d = 0.3
x = square(sweep(120, 380, d, 1.5), d, 0.25) * env(int(SR * d), attack=0.02, decay=0.3, power=1.0) * 0.5
save("windup", x, bits=5)

# 衝刺：掠過的呼嘯
d = 0.25
n = noise(d)
x = (n - lowpass(n, 8)) * np.sin(np.pi * t(d) / d) ** 1.5
save("dash", x, bits=6, hold=2)

# 經驗寶石
d = 0.09
x = square(sweep(700, 1100, d, 1.0), d, 0.5) * env(int(SR * d), decay=0.06)
save("pickup_xp", x, gain=0.5, bits=5)

# 單據（硬幣聲）
x = np.concatenate([square(988, 0.06) * env(int(SR * 0.06), decay=0.05), square(1319, 0.14) * env(int(SR * 0.14), decay=0.1)])
save("pickup_receipt", x, gain=0.55, bits=5)

# 配件：上揚的三音
notes = [523, 659, 784]
x = np.concatenate([square(f, 0.08, 0.25) * env(int(SR * 0.08), decay=0.07) for f in notes] + [square(1046, 0.18, 0.25) * env(int(SR * 0.18), decay=0.14)])
save("pickup_item", x, gain=0.6, bits=5)

# 補血
d = 0.25
x = sine(sweep(330, 660, d, 1.0), d) * env(int(SR * d), decay=0.2)
save("pickup_hp", x, gain=0.5, bits=6)

# 升級
notes = [392, 494, 587, 784, 988]
x = np.concatenate([square(f, 0.09, 0.5) * env(int(SR * 0.09), decay=0.09) for f in notes] + [square(1175, 0.3, 0.25) * env(int(SR * 0.3), decay=0.25)])
save("levelup", x, gain=0.6, bits=5)

# 受傷
d = 0.22
x = square(sweep(220, 70, d, 0.6), d) * env(int(SR * d), decay=0.12) * 0.7 + noise(d) * env(int(SR * d), decay=0.05) * 0.5
save("hurt", x, bits=5, hold=3)

# 敵人倒下
d = 0.3
x = sine(sweep(200, 50, d, 0.5), d) * env(int(SR * d), decay=0.14) + noise(d) * env(int(SR * d), decay=0.07) * 0.6
save("enemy_die", x, bits=5, hold=3)

# 敵人遠程發射
d = 0.15
x = square(sweep(500, 220, d, 1.0), d, 0.25) * env(int(SR * d), decay=0.08)
save("shoot", x, gain=0.5, bits=5)

# 頭目預警（低沉警示）
d = 0.5
x = square(150, d) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 8 * t(d)))) * env(int(SR * d), attack=0.02, decay=0.5, power=1.5)
save("boss_warn", x, bits=4, hold=3)

# 頭目重擊落地
d = 0.7
x = sine(sweep(90, 24, d, 0.4), d) * env(int(SR * d), decay=0.4) * 1.0 + lowpass(noise(d), 20) * env(int(SR * d), decay=0.25) * 0.9
save("boss_slam", x, bits=4, hold=4)

# 死亡
d = 1.0
x = square(sweep(300, 40, d, 0.7), d, 0.5) * env(int(SR * d), decay=0.7, power=2.0)
save("death", x, bits=4, hold=3)

# 通關
notes = [392, 392, 392, 523, 659, 784, 1046]
durs = [0.1, 0.1, 0.1, 0.18, 0.12, 0.12, 0.5]
x = np.concatenate([square(f, dd, 0.25) * env(int(SR * dd), decay=dd) for f, dd in zip(notes, durs)])
save("victory", x, gain=0.6, bits=5)

# 介面（裝上／拆下／失敗）
d = 0.06
save("ui_click", square(sweep(900, 600, d, 1.0), d) * env(int(SR * d), decay=0.04), gain=0.4, bits=5)
d = 0.12
save("ui_error", square(sweep(200, 150, d, 1.0), d) * env(int(SR * d), decay=0.08), gain=0.4, bits=5)
print("done")
