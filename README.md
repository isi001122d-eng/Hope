# Hope: Retro Terminal Racer

Tamamilə **HTML-siz**, birbaşa **Node.js Terminalında (Konsolda)** rəngli ANSI/ASCII qrafika ilə çalışan arkada maşın oyunu.

## Xüsusiyyətlər

- **100% Təmiz JavaScript (Node.js):** Heç bir HTML, CSS, brauzer və ya xarici kitabxana (`npm install`) tələb etmir.
- **Canlı 4 Zolaqlı Şose:** Fərqli sürətlərdə hərəkət edən minik maşınları və yük maşınları (Truck).
- **Bonuslar və Yanacaq Sistemi:**
  - `$` **Sikkə (Coin):** +100 əlavə xal qazandırır.
  - `F` **Yanacaq (Fuel):** Yanacaq çənini +35% doldurur.
  - `N` **Nitro Balonu:** Nitro ehtiyatını +40% artırır.
- **Nitro Turbo (`SPACE`):** Sürəti maksimuma qaldırır, eqzoz alovu aktivləşdirir və **3x Xal Çarpanı** verir.
- **Yaxın Keçid Bonusu (Near Miss):** Rəqib maşının tam yanından keçdikdə **+35 Bonus Xal** verir.
- **4 Rəng Teması (`T`):** `NEON SYNTH`, `CLASSIC ARCADE`, `MATRIX GRID`, `NIGHT FURY`.
- **Yaddaşda Rekord (`highscore.json`):** Ən yüksək nəticə avtomatik saxlanılır.

## Oyun Rejimləri

### 1. 3D Turbo Highway Racer (Real 3D Qrafika)
Brauzerdə dərhal açılan Three.js əsaslı 3D arkada yarışı (asqı fizikası, gecə/gündüz işıqları, nitro və spidometr):

```bash
npm run 3d
```
*(və ya birbaşa `racer3d.html` faylını iki dəfə klikləyib açın)*

---

### 2. Retro Terminal Racer (HTML-siz Konsol Oyunu)
Tamamilə terminal daxilində çalışan 2D ANSI/ASCII arkada yarışı:

```bash
npm start
# və ya: node game.js
```

---

## Unreal Engine 5 Bələdçisi
Unreal Engine 5 quraşdırmaq və AAA səviyyəsində avtomobil layihəsi başlatmaq üçün ətraflı bələdçi:
👉 [UNREAL_ENGINE_GUIDE.md](file:///c:/Users/isi00/Documents/antigravity/resilient-oppenheimer/UNREAL_ENGINE_GUIDE.md)

## İdarəetmə Düymələri (Controls)

| Düymə | Funksiya |
| :--- | :--- |
| `A` / `D` və ya `◄` / `►` | Sol / Sağ zolağa keçid |
| `W` / `S` və ya `▲` / `▼` | Qaz (Sürətlənmə) / Tormoz |
| `SPACE` | Oyunu başlatmaq / Nitro Turbo aktivləşdirmək |
| `P` | Oyunu dayandırmaq (Pause / Resume) |
| `T` | Rəng temasını dəyişmək |
| `R` | Qəzadan sonra yenidən başlamaq |
| `Q` və ya `Ctrl+C` | Oyundan çıxış |

## Test və Yoxlama

Avtomatlaşdırılmış özünü-yoxlama testlərini işə salmaq üçün:

```bash
npm test
```
