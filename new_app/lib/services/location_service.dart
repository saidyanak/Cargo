import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Konum izni isteme
  static Future<bool> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      return permission.isGranted;
    } catch (e) {
      print('Konum izni hatası: $e');
      return false;
    }
  }

  // Konum servislerinin açık olup olmadığını kontrol et
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Konum servisi kontrol hatası: $e');
      return false;
    }
  }

  // Mevcut konumu al
  static Future<Position?> getCurrentLocation() async {
    try {
      // İzin kontrolü
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Konum izni verilmedi');
      }

      // Konum servislerinin açık olup olmadığını kontrol et
      final isLocationEnabled = await isLocationServiceEnabled();
      if (!isLocationEnabled) {
        throw Exception('Konum servisleri kapalı');
      }

      // Konum al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      print('Konum alındı: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Konum alma hatası: $e');
      return null;
    }
  }

  // Son bilinen konumu al
  static Future<Position?> getLastKnownLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        print('Son bilinen konum: ${position.latitude}, ${position.longitude}');
      }
      return position;
    } catch (e) {
      print('Son bilinen konum hatası: $e');
      return null;
    }
  }

  // Koordinatlardan adres al
static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
  try {
    print('Adres çevirme başlatılıyor: $latitude, $longitude');
    
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    print('Placemark sayısı: ${placemarks.length}');
    
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      print('Placemark detayları: ${place.toString()}');
      
      // Güvenli adres oluşturma
      List<String> addressParts = [];
      
      if (place.name != null && place.name!.isNotEmpty) {
        addressParts.add(place.name!);
      }
      if (place.street != null && place.street!.isNotEmpty) {
        addressParts.add(place.street!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }
      
      if (addressParts.isNotEmpty) {
        String address = addressParts.join(', ');
        print('Oluşturulan adres: $address');
        return address;
      }
    }
    
    // Fallback
    String fallbackAddress = 'Konum: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    print('Fallback adres kullanılıyor: $fallbackAddress');
    return fallbackAddress;
    
  } catch (e) {
    print('Adres çevirme hatası detayı: $e');
    print('Hata tipi: ${e.runtimeType}');
    
    // Güvenli fallback
    return 'Konum: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}

  // Adresten koordinatlar al
  static Future<List<Location>> getCoordinatesFromAddress(String address) async {
    try {
      if (address.trim().isEmpty) {
        throw Exception('Adres boş olamaz');
      }
      
      final locations = await locationFromAddress(address);
      print('Adres koordinatları bulundu: ${locations.length} sonuç');
      return locations;
    } catch (e) {
      print('Koordinat alma hatası: $e');
      return [];
    }
  }

  // İki nokta arasındaki mesafeyi hesapla
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      final distance = Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
      return distance;
    } catch (e) {
      print('Mesafe hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Mesafeyi okunabilir formata çevir
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else if (distanceInMeters < 100000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    } else {
      return '${(distanceInMeters / 1000).round()} km';
    }
  }

  // İki nokta arasındaki yön hesapla (bearing)
  static double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      final bearing = Geolocator.bearingBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
      return bearing;
    } catch (e) {
      print('Yön hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Konum güncellemelerini dinle
  static Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 10,
    int timeIntervalMs = 5000,
  }) {
    try {
      final locationSettings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterMeters,
        timeLimit: Duration(milliseconds: timeIntervalMs),
      );

      return Geolocator.getPositionStream(locationSettings: locationSettings);
    } catch (e) {
      print('Konum stream hatası: $e');
      return Stream.empty();
    }
  }

  // Belirli bir noktanın yakınında mı kontrol et
  static bool isNearby(
    double currentLat,
    double currentLng,
    double targetLat,
    double targetLng,
    double radiusInMeters,
  ) {
    try {
      final distance = calculateDistance(currentLat, currentLng, targetLat, targetLng);
      return distance <= radiusInMeters;
    } catch (e) {
      print('Yakınlık kontrol hatası: $e');
      return false;
    }
  }

  // Koordinatların geçerli olup olmadığını kontrol et
  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    
    return latitude >= -90 && 
           latitude <= 90 && 
           longitude >= -180 && 
           longitude <= 180;
  }

  // Adres bilgilerini detaylı şekilde al
  static Future<Map<String, String>> getDetailedAddressInfo(
    double latitude, 
    double longitude
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        return {
          'street': place.street ?? '',
          'subLocality': place.subLocality ?? '',
          'locality': place.locality ?? '',
          'postalCode': place.postalCode ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'country': place.country ?? '',
          'isoCountryCode': place.isoCountryCode ?? '',
          'thoroughfare': place.thoroughfare ?? '',
          'subThoroughfare': place.subThoroughfare ?? '',
        };
      }
      return {};
    } catch (e) {
      print('Detaylı adres bilgisi hatası: $e');
      return {};
    }
  }

  // Konum permisson durumunu kontrol et
  static Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      print('Permission kontrol hatası: $e');
      return LocationPermission.denied;
    }
  }

  // Konum ayarlarını aç
  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      print('Ayarları açma hatası: $e');
      return false;
    }
  }

  // Coğrafi sınırlar içinde mi kontrol et (geofencing)
  static bool isInsideBounds({
    required double latitude,
    required double longitude,
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
  }) {
    return latitude <= northEastLat &&
           latitude >= southWestLat &&
           longitude <= northEastLng &&
           longitude >= southWestLng;
  }

  // Koordinatları DMS (Derece, Dakika, Saniye) formatına çevir
  static String convertToDMS(double coordinate, bool isLatitude) {
    try {
      final direction = isLatitude 
          ? (coordinate >= 0 ? 'K' : 'G') 
          : (coordinate >= 0 ? 'D' : 'B');
      
      final absCoordinate = coordinate.abs();
      final degrees = absCoordinate.floor();
      final minutes = ((absCoordinate - degrees) * 60).floor();
      final seconds = ((absCoordinate - degrees - minutes / 60) * 3600);
      
      return '$degrees°${minutes}\'${seconds.toStringAsFixed(2)}"$direction';
    } catch (e) {
      print('DMS çevirme hatası: $e');
      return '';
    }
  }

  // Hız hesaplama (iki konum arasında)
  static double calculateSpeed(
    Position previousPosition,
    Position currentPosition,
  ) {
    try {
      final distance = calculateDistance(
        previousPosition.latitude,
        previousPosition.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );
      
      final timeDifference = currentPosition.timestamp!
          .difference(previousPosition.timestamp!)
          .inSeconds;
      
      if (timeDifference == 0) return 0.0;
      
      // m/s cinsinden hız
      final speedMps = distance / timeDifference;
      
      // km/h cinsinden döndür
      return speedMps * 3.6;
    } catch (e) {
      print('Hız hesaplama hatası: $e');
      return 0.0;
    }
  }

  // Tahmini varış süresini hesapla
  static Duration estimateArrivalTime(
    double distanceInMeters,
    double averageSpeedKmh,
  ) {
    try {
      if (averageSpeedKmh <= 0) return Duration.zero;
      
      final distanceInKm = distanceInMeters / 1000;
      final timeInHours = distanceInKm / averageSpeedKmh;
      final timeInMinutes = (timeInHours * 60).round();
      
      return Duration(minutes: timeInMinutes);
    } catch (e) {
      print('Varış süresi hesaplama hatası: $e');
      return Duration.zero;
    }
  }

  // Şehir bilgisini al
  static Future<String> getCityName(double latitude, double longitude) async {
    try {
      final addressInfo = await getDetailedAddressInfo(latitude, longitude);
      return addressInfo['locality'] ?? 
             addressInfo['administrativeArea'] ?? 
             'Bilinmeyen Şehir';
    } catch (e) {
      print('Şehir adı alma hatası: $e');
      return 'Bilinmeyen Şehir';
    }
  }

  // Ülke bilgisini al
  static Future<String> getCountryName(double latitude, double longitude) async {
    try {
      final addressInfo = await getDetailedAddressInfo(latitude, longitude);
      return addressInfo['country'] ?? 'Bilinmeyen Ülke';
    } catch (e) {
      print('Ülke adı alma hatası: $e');
      return 'Bilinmeyen Ülke';
    }
  }
}