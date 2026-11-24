# App Store yayın rehberi — Metro Tycoon: Türkiye

Yapımcı: **Efe Arda Arıç** · Paket kimliği: `com.efeardaaric.metrotycoon` · Sürüm: 1.0.0

Projede hazır olanlar:

| Konu | Nerede |
|---|---|
| Uygulama ikonu (1024 + tüm iOS boyutları), açılış ekranı | `assets/icons/` (`python3 tools/gen_icons.py`) |
| iOS dışa aktarma ayarları, gizlilik bildirimi (PrivacyInfo), şifreleme beyanı (`ITSAppUsesNonExemptEncryption=false`), telif satırı | `export_presets.cfg` → *iOS* |
| Mağaza metinleri TR + EN (ad, alt başlık, anahtar kelimeler, açıklama, tanıtım metni, kategori, inceleme notu) | `fastlane/metadata/` |
| Başlıklı ekran görüntüleri, iPhone 6.9" (1290×2796) + iPad 13" (2048×2732), TR + EN | `docs/store/<boyut>/<dil>/` |
| Gizlilik politikası ve destek sayfası | `docs/privacy.html`, `docs/index.html` (GitHub Pages) |
| Mac'te tek komutla arşivle + App Store Connect'e yükle | `tools/ios_release_mac.sh` |
| fastlane şeritleri (metadata / beta / release) | `fastlane/Fastfile` |
| Bulutta (GitHub Actions, macOS) TestFlight derlemesi | `.github/workflows/ios-testflight.yml` |

## 1. Bir kerelik hazırlık (≈30 dk)
1. **Apple Developer Program** üyeliği (yıllık 99 $). developer.apple.com → *Membership* sayfasındaki
   **Team ID**'yi not al.
2. **GitHub Pages**: depo → *Settings → Pages* → *Deploy from a branch* → bu dal, `/docs` klasörü.
   Birkaç dakika sonra şu adresler açılır:
   - Destek: `https://efeardaaric.github.io/MetroGame/`
   - Gizlilik: `https://efeardaaric.github.io/MetroGame/privacy.html`
3. **App Store Connect → Uygulamalar → (+) Yeni Uygulama**
   - Platform: iOS · Ad: `Metro Tycoon: Türkiye` · Birincil dil: Türkçe
   - Paket kimliği: `com.efeardaaric.metrotycoon` (listede yoksa önce developer.apple.com →
     *Identifiers* altında oluştur; Xcode otomatik imzalama da oluşturabilir)
   - SKU: `metrotycoon-tr-001`
4. **Fiyat**: *Fiyatlandırma ve Kullanılabilirlik* → ücretli bir fiyat seç (ör. 99,99 ₺ / 2,99 $).
   Ücretli uygulama için *İş* bölümünde **Ücretli Uygulamalar Sözleşmesi**, banka ve vergi bilgileri tamam olmalı.
5. **Uygulama Gizliliği** → *Veri Toplanmıyor* (Data Not Collected). Gizlilik URL'si: yukarıdaki adres.
6. **Yaş derecelendirmesi**: tüm sorulara *Hayır/Yok* → 4+.
7. **Kategori**: Oyunlar → Simülasyon, Strateji (fastlane de ayarlar).

## 2. Derleme ve yükleme (Mac)
```bash
git pull
./tools/ios_release_mac.sh <TEAM_ID>          # arşivler, imzalar, App Store Connect'e yükler
```
- Xcode'da Apple kimliğinle oturum açık olmalı (*Xcode → Settings → Accounts*).
- Her yüklemede derleme numarası otomatik artar (zaman damgası). İstersen ikinci argümanla ver.
- Yükleme bitince derleme 10–30 dk içinde *TestFlight* sekmesinde görünür; iPhone'da TestFlight
  uygulamasıyla dene.

Alternatif: Mac'e gerek kalmadan **GitHub Actions → iOS TestFlight → Run workflow**
(depo *Secrets*: `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` → App Store Connect →
*Kullanıcılar ve Erişim → Entegrasyonlar → App Store Connect API*, rol: Admin).

## 3. Metinler ve ekran görüntüleri
```bash
bundle install
export ASC_KEY_ID=... ASC_ISSUER_ID=... ASC_KEY_PATH=~/AuthKey_XXXX.p8
bundle exec fastlane ios metadata     # TR + EN metinler ve 32 ekran görüntüsü
```
(Ya da `docs/store/` altındaki görselleri App Store Connect'e sürükle-bırak yap; metinler
`fastlane/metadata/tr/*.txt` dosyalarında.)

## 4. İncelemeye gönder
App Store Connect → sürüm 1.0 → *Derleme* bölümünden TestFlight derlemesini seç →
*İncelemeye Gönder*. Ya da `bundle exec fastlane ios release`.
İnceleme notu hazır (`fastlane/metadata/review_information/notes.txt`): oyun çevrimdışı, hesap gerektirmez.

## Notlar
- **Xcode sürümü**: Apple yeni yüklemeler için güncel Xcode/iOS SDK ister; Mac'te App Store'daki
  en güncel Xcode'u kullan. Godot 4.3 şablonu Xcode'un yeni sürümünde bağlama (link) hatası verirse
  bildir, motor sürümünü yükseltiriz.
- **Game Center** isteğe bağlı: başarım kimlikleri `com.efeardaaric.metrotycoon.<id>` (bkz. `docs/PLATFORM.md`).
- İkonu yeniden üretmek için: `python3 tools/gen_icons.py` · Ekran görüntüleri:
  `tools/store_media.tscn` + `tools/frame_store_shots.py`.
