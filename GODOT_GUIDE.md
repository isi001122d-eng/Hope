# Godot 4 — 3D Avtomobil Oyunu Layihəsi (Hope 3D Racing)

Bu layihə **Godot Engine 4** üçün xüsusi olaraq hazırlanmış tam 3D avtomobil oyunudur. Daxilində hazır **VehicleBody3D** asqı fizikası, 4 təkərli idarəetmə, Nitro gücləndiricisi və dinamik izləyən 3D kamera mövcuddur.

---

## 1. Godot 4-ün Yüklənməsi (Cəmi 50 MB, Quraşdırma Tələb Etmir!)

Godot Engine-in ən böyük üstünlüyü heç bir quraşdırma (installer) tələb etməməsidir:

1. Rəsmi saytdan yükləyin: **[godotengine.org/download](https://godotengine.org/download/)**
2. **"Godot Engine - Standard version (64-bit)"** seçin (cəmi ~50 MB).
3. Yüklənən `.zip` faylını açın və içindəki `Godot_v4.x...exe` faylını istədiyiniz yerə (məsələn, Masaüstünə) çıxarın.

---

## 2. Layihəni Godot-da Açmaq (2 Sadə Addım)

1. **Godot proqramını işə salın.**
2. Açılan pəncərədə sağ tərəfdəki **"Import" (İdxal et)** düyməsinə klikləyin:
   - **Project Path:** `Browse` düyməsinə basıb bu qovluğu seçin:
     `c:\Users\isi00\Documents\antigravity\resilient-oppenheimer\godot_project`
   - İçindəki `project.godot` faylını seçin.
3. **"Import & Edit"** düyməsinə klikləyin. Layihə dərhal açılacaq!

---

## 3. Oyunu Başlatmaq

* Yuxarı sağ küncdəki **"Play" (F5)** düyməsinə basın və ya klaviaturada **`F5`** düyməsini sıxın.
* Oyun dərhal 60+ FPS sürətlə pəncərədə açılacaq!

---

## 4. İdarəetmə Düymələri (Controls)

| Düymə | Təyinatı |
| :--- | :--- |
| **W** və ya **▲** | Qaz (Sürətlənmə) |
| **S** və ya **▼** | Əyləc / Geri ötürmə |
| **A / D** və ya **◄ / ►** | Sükan (Sola / Sağa dönmə) |
| **SPACE** | **⚡ Nitro Turbo Boost** |
| **SHIFT** | **Əl Əyləci (Drift)** |
| **R** | Maşını yenidən yola qaytarmaq (Aşdıqda bərpa) |

---

## 5. Layihənin Strukturu

```
godot_project/
├── project.godot           # Layihə konfiqurasiyası və idarəetmə xəritəsi
├── scenes/
│   ├── main.tscn           # Əsas 3D dünya, asfalt trek, tramplin, işıqlar və səma
│   ├── car.tscn            # VehicleBody3D maşın modeli, faralar, 4 təkər və alov
│   └── hud.tscn            # Rəqəmsal spidometr (KM/H) və Nitro çubuğu
└── scripts/
    ├── car.gd              # Avtomobilin mühərrik gücü, asqısı və drift fizikası
    ├── camera_follow.gd    # Arxadan izləyən dinamik 3D kamera (Nitro FOV effekti)
    └── hud.gd              # Spidometr və nitro dəyərlərinin ekranda göstərilməsi
```

---

## 6. Maşının Parametrlərini Necə Dəyişmək Olar?

`godot_project/scripts/car.gd` faylını açaraq istədiyiniz parametrləri dərhal tənzimləyə bilərsiniz:
- `max_engine_force = 380.0` (Mühərrikin gücü)
- `nitro_boost_force = 550.0` (Nitro turbo gücü)
- `max_steer_angle = 0.42` (Sükanın maksimum dönmə bucağı)
- `steer_speed = 6.0` (Sükanın həssaslığı)
