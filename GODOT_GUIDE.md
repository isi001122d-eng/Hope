# Godot 4.7 — Hope 3D Racing (Tam Yenilənmiş Buraxılış)

Bu layihə **Godot Engine 4.7 (v4.7.2)** üçün sıfırdan tam yenilənmiş, Intel UHD və bütün müasir GPU-larda 60 FPS sürətlə işləyən 3D arkada şose yarışıdır.

---

## Yenilənmiş Xüsusiyyətlər (Godot 4.7 Edition)

1. **Təkmil 3D Superkar Fizikası (`scripts/car.gd`):**
   - **3D Asqı (Suspension) Dinamikası:** Qaz verdikdə və Nitro basdıqda maşının önü yuxarı qalxır, əyləc basdıqda önə əyilir, döngələrdə və drift zamanı kuzov yana yatır.
   - **6 Pilləli Avtomatik Ötürmə (`G1`–`G6`)** və mühərrik dövriyyəsi (RPM).
   - **Fırlanan və Dönən 3D Təkərlər:** Ön təkərlər sükana uyğun sağa-sola dönür, hər 4 təkər sürətə uyğun fırlanır.
   - **5 Superkar Rəngi (`V` düyməsi):** Oyun zamanı maşının rəngini canlı dəyişmək imkanı (*Cyber Cyan, Ferrari Red, Lambo Gold, Venom Green, Midnight Violet*).
2. **Sonsuz 3D Şose və Ətraf Mühit (`scripts/world_manager.gd`):**
   - 4 zolaqlı asfalt şose, parlayan neon bordürlər, metal qoruyucu sədlər, küçə fənərləri və yol kənarı şam ağacları.
   - **3 İşıqlandırma Rejimi (`L` düyməsi):** *Neon Gecə*, *Qürub Üfüqü (Sunset)* və *Gündüz Sürüşü*.
   - **Canlı Trafik Sistemi:** Minik maşınları və yük maşınları (uzaqdan seçilən parlaq LED arxa stoplarla).
   - **Yaxın Keçid Bonusu (Near-Miss):** Yüksək sürətlə maşınların yanından keçdikdə **+60 Bonus Xal**.
   - **Tramplin Tullanışı (Air Jump):** Yoldakı narıncı tramplinlərdən uçaraq maşınların üzərindən tullanmaq və **+200 Bonus Xal** qazanmaq.
   - **Zireh (Armor) və Bonuslar:** 100% Zireh sistemi (toqquşmada dərhal uduzmursunuz, 3 zərbəyə davam gətirir), yolda Qızıl Sikkələr (`+150 Xal`), Mavi Nitro Balonları (`+40% Nitro`) və Yaşıl Təmir Kürələri (`+35% Zireh`).
3. **Yüksək Görünüşlü 3D Kamera (`scripts/camera_follow.gd`):**
   - **3 Kamera Rejimi (`C` düyməsi):** *Yüksək Arxa Kamera*, *Helikopter Kamerası* və *Kapot (FPV) Kamerası*.
   - Nitro zamanı dinamik FOV genişlənməsi və toqquşma zamanı kamera titrəməsi (Screen Shake).
4. **Daxili Sintezator Səs Mühərriki:**
   - Xarici səs faylı tələb etmədən `AudioStreamGenerator` ilə sikkə, nitro, səviyyə artımı və qəza səsləri.

---

## İdarəetmə Düymələri (Controls)

| Düymə | Funksiya |
| :--- | :--- |
| **`W` / `S`** və ya **`▲` / `▼`** | Qaz (Sürətlənmə) / Əyləc |
| **`A` / `D`** və ya **`◄` / `►`** | Sükan (Sol / Sağ zolaq) |
| **`SPACE`** | **⚡ Nitro Turbo Boost (3x Xal Çarpanı)** |
| **`SHIFT`** | **Drift / Kəskin Dönüş** |
| **`C`** | Kamera bucağını dəyişmək (3 rejim) |
| **`V`** | Maşının boya rəngini dəyişmək (5 rəng) |
| **`L`** | Gecə / Qürub / Gündüz rejimini dəyişmək |
| **`R`** | Oyunu yenidən başlatmaq (Restart) |

---

## Necə İşə Salmaq Olar?

Godot 4.7 pəncərəsində sadəcə sağ yuxarıdakı **Play (`▶`)** düyməsinə və ya klaviaturada **`F5`** düyməsinə basın!
