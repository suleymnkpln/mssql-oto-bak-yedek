# MSSQL Otomatik Yedekleme (Auto Backup)

**Windows Batch Script** ile MSSQL Server üzerindeki tüm kullanıcı veritabanlarını belirli aralıklarla otomatik olarak yedekleyen ve ZIP arşivine sıkıştıran araç.

---

## Özellikler

- Tüm kullanıcı veritabanlarını otomatik algılar (`master`, `tempdb`, `model`, `msdb` hariç)
- Her yedekleme turunu `yyyy-MM-dd_HH-mm-ss.zip` formatında arşivler
- Sıkıştırılmış yedekleme (`WITH COMPRESSION`) ile disk alanı tasarrufu
- ZIP oluşturulduktan sonra `.bak` dosyaları otomatik temizlenir
- Başarılı / başarısız yedekleme sayısını raporlar
- Sonsuz döngü ile kesintisiz çalışır (CTRL+C ile çıkış)
- Bölgesel ayarlardan bağımsız tarih formatı (PowerShell ile)

## Gereksinimler

| Gereksinim | Açıklama |
|---|---|
| **İşletim Sistemi** | Windows 10 / 11 / Server 2016+ |
| **SQL Server** | MSSQL 2012 ve üzeri |
| **sqlcmd** | SQL Server komut satırı aracı (SQL Server ile birlikte gelir) |
| **PowerShell** | 5.0+ (ZIP arşivleme ve tarih formatı için) |
| **Yetki** | Windows Authentication ile SQL Server'a erişim |

## Kurulum ve Kullanım

### 1. Ayarları Düzenle

`MSSQL_OtomatikYedek.bat` dosyasını bir metin editörü ile açın ve aşağıdaki değişkenleri kendi ortamınıza göre düzenleyin:

```bat
set Sunucu=localhost\SQLEXPRESS   &:: SQL Server instance adı
set HedefKlasor=D:\SQL_Yedekler   &:: Yedeklerin kaydedileceği klasör
set BeklemeSaniye=3600             &:: Yedekleme aralığı (saniye cinsinden)
```

#### Sunucu Örnekleri

| Tür | Örnek |
|---|---|
| Varsayılan Instance | `localhost` veya `.` |
| Named Instance | `localhost\SQLEXPRESS` |
| Uzak Sunucu | `192.168.1.100\SQLEXPRESS` |

### 2. Çalıştır

Dosyaya çift tıklayın veya komut satırından çalıştırın:

```cmd
MSSQL_OtomatikYedek.bat
```

> **Not:** Script, SQL Server'a **Windows Authentication** ile bağlanır. Çalıştıran kullanıcının SQL Server'da yedekleme yetkisi olmalıdır.

### 3. Çıkış

Çalışan scripti durdurmak için: `CTRL + C`

## Çıktı Yapısı

Yedeklemeler hedef klasörde aşağıdaki yapıda oluşturulur:

```
HedefKlasor/
├── 2025-06-10_14-30-05.zip    ← Her ZIP bir yedekleme turunu içerir
├── 2025-06-10_15-30-05.zip
└── ...
```

Her ZIP dosyasının içeriği:

```
2025-06-10_14-30-05.zip
├── Veritabani1_2025-06-10_14-30-05.bak
├── Veritabani2_2025-06-10_14-30-05.bak
└── ...
```

## Ekran Görüntüsü

```
============================================================
      MSSQL OTOMATIK YEDEKLEME SISTEMI - AKTIF
  Format: 2025-06-10_14-30-05.zip
============================================================
 Sunucu  : localhost\SQLEXPRESS
 Hedef   : D:\SQL_Yedekler
 Aralik  : Her 3600 saniyede bir
 Cikis   : CTRL+C
============================================================

 YEDEKLEME BASLADI : 2025-06-10_14-30-05
 [-->] Yedekleniyor : AdventureWorks
       [OK]   Basarili : AdventureWorks_2025-06-10_14-30-05.bak
 [-->] Yedekleniyor : Northwind
       [OK]   Basarili : Northwind_2025-06-10_14-30-05.bak

 Sonuc  > Basarili: 2  /  Hatali: 0

 [ZIP] Arsiv olusturuluyor: 2025-06-10_14-30-05.zip
 [ZIP] Tamamlandi : 2025-06-10_14-30-05.zip  (45 MB)
```

## Sık Sorulan Sorular

**S: "SQL Server'a bağlanamadı" hatası alıyorum.**
C: `Sunucu` değişkeninin doğru ayarlandığından ve SQL Server servisinin çalıştığından emin olun. `sqlcmd` komutunun PATH'te olduğunu kontrol edin.

**S: Yedekleme yetkisi hatası alıyorum.**
C: Scripti çalıştıran Windows kullanıcısının SQL Server'da `db_backupoperator` veya `sysadmin` rolüne sahip olması gerekir.

**S: Belirli veritabanlarını hariç tutabilir miyim?**
C: `sqlcmd` sorgusundaki `WHERE name NOT IN (...)` kısmına hariç tutmak istediğiniz veritabanı adlarını ekleyebilirsiniz.

## Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır.
