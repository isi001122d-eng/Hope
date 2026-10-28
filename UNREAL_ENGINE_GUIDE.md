# Unreal Engine 5 (UE5) Quraşdırma və Avtomobil Layihəsi Bələdçisi

Bu sənəd kompüterinizdə Unreal Engine 5-i sıfırdan quraşdırmaq və AAA səviyyəsində qrafikalı 3D avtomobil oyunu layihəsi başlatmaq üçün addım-addım təlimatdır.

---

## 1. Tələb Olunan Sistem Parametrləri (Minimum & Tövsiyə)

| Komponent | Minimum | Tövsiyə Olunan |
| :--- | :--- | :--- |
| **Əməliyyat Sistemi** | Windows 10 (64-bit) | Windows 11 (64-bit) |
| **Prosessor (CPU)** | 4-nüvəli Intel / AMD (2.5 GHz) | 8-nüvəli Intel i7/i9 və ya AMD Ryzen 7/9 |
| **Video Kart (GPU)** | DirectX 11 dəstəkli (GTX 1060) | NVIDIA RTX 3060 / 4060 və ya daha yüksək (DirectX 12 / Lumen üçün) |
| **RAM** | 16 GB | 32 GB |
| **Boş Disk Yeri** | ~60 GB SSD | 100+ GB NVMe SSD (Məsələn, C: və ya G: diskinizdə) |

---

## 2. Addım-Addım Quraşdırma

### Addım 1: Epic Games Launcher Yüklənməsi
1. Rəsmi veb-sayta daxil olun: [unrealengine.com](https://www.unrealengine.com) və ya [epicgames.com](https://store.epicgames.com)
2. Sağ yuxarı küncdəki **"Download"** düyməsinə klikləyərək **Epic Games Launcher** quraşdırıcısını yükləyin və quraşdırın.
3. Epic Games hesabı ilə daxil olun (və ya pulsuz yeni hesab yaradın).

### Addım 2: Unreal Engine 5 Quraşdırılması
1. Epic Games Launcher proqramını açın.
2. Sol menyudan **"Unreal Engine"** bölməsinə keçin.
3. Yuxarıdakı tablardan **"Library" (Kitabxana)** seçin.
4. **"Engine Versions"** yanındakı **`+`** sarı düyməsinə klikləyin.
5. Ən son sabit versiyanı (məsələn, **UE 5.4** və ya **UE 5.5**) seçin və **"Install"** düyməsinə basın.
   > **Qeyd:** Kompüterinizdə `G:\` diskində 109 GB boş yer var, quraşdırma qovluğu kimi `G:\Epic Games\UE_5.x` seçməyiniz məsləhətdir.

### Addım 3: Visual Studio 2022 (C++ üçün - Əgər C++ istifadə edəcəksinizsə)
1. [Visual Studio Community 2022](https://visualstudio.microsoft.com/vs/community/) yükləyin (tamamilə pulsuzdur).
2. Quraşdırma zamanı **"Workloads"** siyahısından:
   - **"Game development with C++"** (C++ ilə oyun inkişafı) iş qrafını işarələyin.
   - Sağ paneldə **"Unreal Engine installer"** və **"C++ profiling tools"** seçilmiş olsun.

---

## 3. İlk 3D Avtomobil Layihəsinin Yaradılması (Hazır Şablon)

Unreal Engine 5 daxilində hazır və peşəkar fizikalı avtomobil şablonu gəlir:

1. Unreal Engine 5-i işə salın.
2. Açılan pəncərədə sol menyudan **"Games"** seçin.
3. Şablonlar arasından **"Vehicle" (Avtomobil)** şablonunu seçin.
4. Sağ tərəfdə seçimləri edin:
   - **Project Type:** `Blueprint` (daha asan vizual proqramlaşdırma) və ya `C++` (maksimum performans üçün).
   - **Target Platform:** `Desktop`.
   - **Quality Preset:** `Maximum`.
   - **Starter Content:** İşarələyin (hazır materiallar və səslər üçün).
5. Layihə adını daxil edin (məsələn, `HopeRacing3D`) və **"Create"** düyməsinə basın.

---

## 4. Oyunu Başlatmaq və Sürmək

1. Layihə açıldıqda qarşınıza böyük bir asfalt sınaq treki çıxacaq.
2. Yuxarıdakı **"Play" (Yaşıl Üçbucaq)** düyməsinə və ya klaviaturada `Alt + P` basın.
3. `W`, `A`, `S`, `D` və ya ox düymələri ilə idarə edin:
   - `W`: Qaz
   - `S`: Əyləc / Geri
   - `A/D`: Sükan
   - `Space`: Əl əyləci (Drift)
   - `Tab`: Kamera dəyişmək

---

## 5. Növbəti Addımlar və İnkişaf
Layihəni quraşdırdıqdan sonra Unreal Engine daxilində istədiyiniz vaxt:
- Avtomobilin kütləsi, asqı sərtliyi və mühərrik gücünü (Torque curve) tənzimləmək,
- Nitro effekti (Niagara Particle System) əlavə etmək,
- Real şəhər və ya dağ trekləri import etmək üçün xüsusi C++ / Blueprint kodlarını birgə yaza bilərik.
