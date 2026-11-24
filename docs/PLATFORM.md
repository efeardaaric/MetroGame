# Platform servisleri kurulumu

Oyun, Game Center / Google Play Games / native paylaşım için **hazır köprü kodu** içerir
(`scripts/autoload/platform.gd`). Eklenti yüklü değilse her şey sessizce devre dışı kalır
(masaüstünde ve eklentisiz derlemelerde oyun aynen çalışır). Aşağıdaki adımlar bu servisleri açar.

## 1. Game Center (iOS)
1. App Store Connect → uygulama → *Game Center* bölümünü aç.
2. Başarımları oluştur: kimlikler `com.efeardaaric.metrotycoon.<id>` biçiminde olmalı. `<id>` listesi
   `scripts/core/achievements.gd` içindeki `LIST` (ör. `com.efeardaaric.metrotycoon.first_line`).
3. Liderlik tablosu: `com.efeardaaric.metrotycoon.best_riders` (tamsayı, yüksek daha iyi).
4. Eklenti: [godot-ios-plugins](https://github.com/godot-sdk-integrations/godot-ios-plugins)
   içindeki **gamecenter** eklentisini derleyip `ios/plugins/` klasörüne koy,
   *Project → Export → iOS → Plugins* altında `GameCenter`'ı işaretle.

## 2. Google Play Games (Android)
1. Play Console → *Play Games Services* → yapılandırma oluştur, başarımları ekle.
2. Konsolun verdiği kimlikleri (`CgkI...`) `platform.gd` içindeki `ANDROID_IDS` sözlüğüne yaz:
   `{"first_line": "CgkI...", ..., "best_riders": "CgkI..."}`.
3. Eklenti: [godot-play-game-services](https://github.com/godot-sdk-integrations/godot-play-game-services)
   → `addons/` klasörüne kopyala, eklentiyi etkinleştir; Android dışa aktarma ön ayarında
   **Gradle build** açık olmalı (`Android Play Store (AAB)` ön ayarı zaten öyle).

## 3. Native paylaşım (poster)
Poster `user://raya_<şehir>_<yıl>.png` olarak kaydedilir. `share_image` veya `shareImage`
fonksiyonu sunan herhangi bir paylaşım eklentisi (singleton adı `GodotShare` ya da `Share`)
yüklenirse sistem paylaşım menüsü açılır. Eklenti yoksa poster Resimler klasörüne kopyalanır,
paylaşım metni panoya kopyalanır.

## 4. Bulut kaydı
Hesap gerektirmeyen bir yöntem hazır: **Ayarlar → Kayıt aktarımı → Kaydı kopyala/yapıştır**
(tüm ilerleme sıkıştırılmış tek bir metin koduna dönüşür). iCloud / Google Drive senkronizasyonu
için `SaveManager.export_code()` ve `import_code()` çağrıları ilgili eklentiyle (ör. iCloud
key-value store) bağlanabilir.

## 5. Gerçek cihaz testi kontrol listesi
- [ ] Düşük seviye Android (2 GB RAM, Mali GPU) ve eski iPhone (A12) üzerinde İstanbul açılış süresi
- [ ] 30 dakikalık oyunda FPS (Ayarlar → FPS göster) ve pil/ısınma
- [ ] Otomatik kalite düşürme tetikleniyor mu (FPS < 38 olunca 6 sn)
- [ ] Çentikli ekranlarda üst çubuk ve alt menü güvenli alanda mı
- [ ] Yatay/dikey dönüş, tablet düzeni
- [ ] Geri tuşu (Android), uygulama arka plana alınınca otomatik kayıt
- [ ] Ses: martılar, vapur düdüğü, müzik geçişleri, titreşim
