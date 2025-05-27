Api Diagram
![diagram](https://github.com/user-attachments/assets/f9b78d18-e016-4438-974e-265df6b433e7)

📦 Uygulama Amacı:
İstanbul gibi büyük şehirlerde, şehirler arası seyahat eden sürücüler (driver), kendi rotalarına uygun olan kargoları alarak taşıyabilir. Kargo göndermek isteyenler (distributor) ilan verir. Sürücüler uygun kargoları alıp teslim eder.

👤 Kullanıcı Rolleri:
Distributor (Kargo Veren)

Kargo ilanı verir (başlangıç ve varış konumu, ağırlık, açıklama).

Kargoları güncelleyebilir/silebilir.

Hangi kargoların alındığını veya teslim edildiğini görebilir.

Driver (Sürücü)

Yakınındaki veya gideceği yöne uygun kargoları görür.

Uygun bir kargoyu seçip "alır".

Teslim ettiğinde sistemde bunu bildirir.

Harita üzerinden kargonun konumunu görebilir.

Admin (Web Panel üzerinden)

Tüm kargoları, kullanıcıları ve sistem istatistiklerini görür.

Gerekirse kullanıcıları yönetir (gelecekte eklenecek).

🔧 Teknolojiler:
Backend: Spring Boot (JWT Authentication, MySQL)

Mobil Uygulama: Flutter (veya FlutterFlow)

Web Admin Paneli: Basit Spring Boot + Thymeleaf veya React panel (opsiyonel)

Veritabanı:

Cargo

Distributor (User'dan türetilmiş)

Driver (User'dan türetilmiş)


EskiKargolar (teslim edilenler için)

🔁 Akış:
Kullanıcı kayıt olur ve giriş yapar.

Rolüne göre (Driver / Distributor) farklı bir anasayfaya yönlendirilir.

Distributor → Kargo ekler.

Driver → Yakınındaki veya rotasındaki kargoları görür.

Driver → Uygun kargoyu alır → teslim eder.

Sistem → Teslim edilen kargoyu EskiKargolar tablosuna kaydeder.

📱 Mobil Uygulama Özellikleri (Flutter):
Login / Register

Rol bazlı yönlendirme

Harita gösterimi (konum bazlı kargo seçimi)

Bildirim (yakın kargo varsa gösterilebilir)

Kargo detay ekranları

Profil yönetimi
Flutter Diagram
![diagram](https://github.com/user-attachments/assets/0dc2f728-896e-40c6-a305-59aa456cd65a)
