# Synology NAS için otomatik çalıştırma paketi
DSM 7.x ile bir Synology NAS üzerinde harici depolar (USB / eSATA) bağlanırken komut dosyalarını yürütür. Tipik kullanım bazı dosyaları kopyalamak veya yedeklemektir.
Synologies Görev Zamanlayıcı'da tetiklenen görevler oluşturma olanağı vardır. Ancak tetikleme olayı için yalnızca Önyükleme ve Kapatma kullanılabilir. USB olayları mevcut değildir. Bu açık bu araçla telafi edilir.

## [Lisans](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_trk.html)

## Sorumluluk Reddi ve Sorun İzleyici
Buradaki her şeyi kendi sorumluluğunuzda kullanıyorsunuz.
Sorunlar için lütfen [issue tracker] (https://github.com/schmidhorst/synology-autorun/issues) adresini Almanca veya İngilizce olarak kullanın

# Kurulum
*.spk dosyasını ["Sürümler"](https://github.com/schmidhorst/synology-autorun/releases), "Varlıklar" adresinden bilgisayarınıza indirin ve Paket Merkezinde "Manuel Yükleme "yi kullanın.

Üçüncü Taraf paketleri DSM 7'de Synology tarafından kısıtlanmıştır. Otomatik çalıştırma root gerektirdiğinden
görevini yerine getirmesi için kurulumdan sonra ek bir manuel adım gereklidir.

NAS'ınıza SSH ile bağlanın (yönetici kullanıcı olarak) ve aşağıdaki komutu çalıştırın:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
SSH'a alternatif:
Denetim Masası => Görev Zamanlayıcı => Oluştur => Zamanlanmış Görev => Kullanıcı Tanımlı Komut Dosyası'na gidin. "Genel" sekmesinde herhangi bir görev adı belirleyin, kullanıcı olarak 'root' seçin. "Görev Ayarları" sekmesinde şunları girin
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
"Komutu çalıştır" olarak seçin. Tamam ile bitirin. Paket kurulumu sırasında bu komutu şimdi çalıştırmanız istendiğinde, görev zamanlayıcısına gidin, bu görevi seçin ve "Çalıştırın".

Paket Merkezindeki https://www.cphub.net/ altında eski DSM sürümleri için [eski sürümler] (https://github.com/reidemei/synology-autorun) mevcuttur:
* DSM 7: aslında hala sadece 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Krediler ve Referanslar
- Jan Reidemeister](https://github.com/reidemei)'a [Sürüm 1.8](https://github.com/reidemei/synology-autorun) ve [Lisans](https://github.com/reidemei/synology-autorun/blob/main/LICENSE) için teşekkürler
- Bu otomatik çalıştırma paketi hakkındaki [Synology Forum Konusu](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/) sayesinde
- toafez Tommes](https://github.com/toafez) ve onun [Demo Paketi](https://github.com/toafez/DSM7DemoSPK) sayesinde
- geimist Stephan Geisler](https://github.com/geimist)'e teşekkürler ve diğer dillere çeviriler için [DeepL API](https://www.deepl.com/docs-api)'yi kullanma tavsiyesinde bulundu.

