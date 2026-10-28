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

## İşə Salmaq (Run)

Terminalda aşağıdakı əmri yazın:

```bash
node game.js
```

və ya:

```bash
npm start
```

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
