# autorun
Bir Synology NAS üzerinde harici depolama (USB / eSATA) bağlarken komut dosyalarını çalıştırın. Tipik kullanım bazı dosyaları kopyalamak veya yedeklemektir. 
Synologies Görev Zamanlayıcı'da Tetiklenen görevler oluşturma olanağı vardır, ancak tetikleme olayı için yalnızca Önyükleme ve Kapatma kullanılabilir. USB olayları mevcut değildir. Bu açık bu araç ile telafi edilir.  

# yükleyin
* Github'daki "Sürümler", "Varlıklar" bölümünden *.spk dosyasını indirin ve Paket Merkezindeki "Manuel Kurulum" seçeneğini kullanın.

Paket Merkezindeki https://www.cphub.net/ altında eski DSM sürümleri için eski sürümler mevcuttur:
* DSM 7: aslında hala sadece 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

Üçüncü Taraf paketleri DSM 7'de Synology tarafından kısıtlanmıştır. Otomatik çalıştırma root gerektirdiğinden 
görevini yerine getirmesi için kurulumdan sonra ek bir manuel adım gereklidir.

NAS'ınıza SSH ile bağlanın (yönetici kullanıcı olarak) ve aşağıdaki komutu çalıştırın:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
SSH'a alternatif: 
Denetim Paneli => Görev Zamanlayıcı => Oluştur => Zamanlanmış Görev => Kullanıcı Tanımlı Komut Dosyasına gidin. "Genel" sekmesinde herhangi bir görev adı belirleyin, kullanıcı olarak 'root' seçin. "Görev Ayarları" sekmesinde şunları girin  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
"Komutu çalıştır" olarak seçin. Tamam ile bitirin. Pckage kurulumu sırasında bu komutu şimdi çalıştırmanız istendiğinde, görev zamanlayıcısına gidin, bu görevi seçin ve "Çalıştırın". 

