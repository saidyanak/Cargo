import 'package:flutter/material.dart';

class CargoHelper {
  // Kargo durumu display isimleri - Backend enum'larına göre güncellenmiş
  static String getStatusDisplayName(String? status) {
    if (status == null) return 'Bilinmeyen';
    
    switch (status.toUpperCase()) {
      case 'CREATED':
        return 'Oluşturuldu';
      case 'ASSIGNED':
        return 'Atandı';
      case 'PICKED_UP':
        return 'Alındı';
      case 'DELIVERED':
        return 'Teslim Edildi';
      case 'CANCELLED':
        return 'İptal Edildi';
      case 'EXPIRED':
        return 'Süresi Doldu';
      case 'FAILED':
        return 'Teslimat Başarısız';
      default:
        return status;
    }
  }

  // Kargo durumu renkleri - Yeni durumlar eklendi
  static Color getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toUpperCase()) {
      case 'CREATED':
        return Colors.blue;
      case 'ASSIGNED':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'EXPIRED':
        return Colors.grey;
      case 'FAILED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // Kargo durumu ikonları - Yeni durumlar eklendi
  static IconData getStatusIcon(String? status) {
    if (status == null) return Icons.help_outline;
    
    switch (status.toUpperCase()) {
      case 'CREATED':
        return Icons.fiber_new;
      case 'ASSIGNED':
        return Icons.assignment;
      case 'PICKED_UP':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'EXPIRED':
        return Icons.schedule;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  // Araba tipi display isimleri - Backend CarType enum'una göre
  static String getCarTypeDisplayName(String? carType) {
    if (carType == null) return 'Belirtilmemiş';
    
    switch (carType.toUpperCase()) {
      case 'SEDAN':
        return 'Sedan';
      case 'HATCHBACK':
        return 'Hatchback';
      case 'SUV':
        return 'SUV';
      case 'MINIVAN':
        return 'Minivan';
      case 'PICKUP':
        return 'Pickup';
      case 'PANELVAN':
        return 'Panel Van';
      case 'MOTORCYCLE':
        return 'Motosiklet';
      case 'TRUCK':
        return 'Kamyon';
      case 'TRAILER':
        return 'Tır';
      default:
        return carType;
    }
  }

  // Araba tipi ikonları
  static IconData getCarTypeIcon(String? carType) {
    if (carType == null) return Icons.directions_car;
    
    switch (carType.toUpperCase()) {
      case 'SEDAN':
      case 'HATCHBACK':
        return Icons.directions_car;
      case 'SUV':
        return Icons.directions_car_filled;
      case 'MINIVAN':
        return Icons.airport_shuttle;
      case 'PICKUP':
        return Icons.local_shipping;
      case 'PANELVAN':
        return Icons.rv_hookup;
      case 'MOTORCYCLE':
        return Icons.two_wheeler;
      case 'TRUCK':
        return Icons.local_shipping;
      case 'TRAILER':
        return Icons.fire_truck;
      default:
        return Icons.directions_car;
    }
  }

  // Boyut display isimleri - Backend Size enum'una göre
  static String getSizeDisplayName(String? size) {
    if (size == null) return 'Bilinmeyen';
    
    switch (size.toUpperCase()) {
      case 'S':
        return 'Küçük (S)';
      case 'M':
        return 'Orta (M)';
      case 'L':
        return 'Büyük (L)';
      case 'XL':
        return 'Çok Büyük (XL)';
      case 'XXL':
        return 'Ekstra Büyük (XXL)';
      default:
        return size;
    }
  }

  // Ağırlık formatı - güvenli erişim
  static String formatWeight(dynamic weight) {
    if (weight == null) return '0 kg';
    
    try {
      double weightValue = weight is double ? weight : double.parse(weight.toString());
      if (weightValue == 0) return '0 kg';
      return '${weightValue.toStringAsFixed(1)} kg';
    } catch (e) {
      return '0 kg';
    }
  }

  // Yükseklik formatı - güvenli erişim
  static String formatHeight(dynamic height) {
    if (height == null) return '0 cm';
    
    try {
      double heightValue = height is double ? height : double.parse(height.toString());
      if (heightValue == 0) return '0 cm';
      return '${heightValue.toStringAsFixed(0)} cm';
    } catch (e) {
      return '0 cm';
    }
  }

  // Tarih formatı - güvenli erişim
  static String formatDate(dynamic dateTime) {
    if (dateTime == null) return 'Bilinmeyen';
    
    try {
      DateTime date;
      if (dateTime is String) {
        date = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        date = dateTime;
      } else {
        return 'Geçersiz tarih';
      }
      
      return '${date.day.toString().padLeft(2, '0')}/'
             '${date.month.toString().padLeft(2, '0')}/'
             '${date.year} '
             '${date.hour.toString().padLeft(2, '0')}:'
             '${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }

  // Kısa tarih formatı
  static String formatDateShort(dynamic dateTime) {
    if (dateTime == null) return 'Bilinmeyen';
    
    try {
      DateTime date;
      if (dateTime is String) {
        date = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        date = dateTime;
      } else {
        return 'Geçersiz';
      }
      
      return '${date.day.toString().padLeft(2, '0')}.'
             '${date.month.toString().padLeft(2, '0')}.'
             '${date.year}';
    } catch (e) {
      return 'Geçersiz';
    }
  }

  // Kargo açıklaması - güvenli erişim ve varsayılan değer
  static String getDescription(Map<String, dynamic> cargo) {
    String? description = cargo['description'];
    
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }
    
    // Varsayılan açıklama oluştur
    String size = getSizeDisplayName(getMeasure(cargo)['size']);
    String weight = formatWeight(getMeasure(cargo)['weight']);
    
    return 'Kargo #${cargo['id'] ?? 'N/A'} - $size, $weight';
  }

  // Measure objesi - güvenli erişim (responseMeasure veya measure)
  static Map<String, dynamic> getMeasure(Map<String, dynamic> cargo) {
    // Önce measure'ı kontrol et
    if (cargo['measure'] != null && cargo['measure'] is Map) {
      return Map<String, dynamic>.from(cargo['measure']);
    }
    
    // Sonra responseMeasure'ı kontrol et
    if (cargo['responseMeasure'] != null && cargo['responseMeasure'] is Map) {
      return Map<String, dynamic>.from(cargo['responseMeasure']);
    }
    
    // Hiçbiri yoksa boş map döndür
    return <String, dynamic>{
      'weight': 0.0,
      'height': 0.0,
      'size': 'M'
    };
  }

  // SelfLocation - güvenli erişim
  static Map<String, dynamic> getSelfLocation(Map<String, dynamic> cargo) {
    if (cargo['selfLocation'] != null && cargo['selfLocation'] is Map) {
      Map<String, dynamic> location = Map<String, dynamic>.from(cargo['selfLocation']);
      // Koordinatları double'a çevir
      if (location['latitude'] != null) {
        location['latitude'] = _parseDouble(location['latitude']);
      }
      if (location['longitude'] != null) {
        location['longitude'] = _parseDouble(location['longitude']);
      }
      return location;
    }
    
    // Fallback olarak boş koordinatlar
    return {'latitude': 0.0, 'longitude': 0.0};
  }

  // TargetLocation - güvenli erişim
  static Map<String, dynamic> getTargetLocation(Map<String, dynamic> cargo) {
    if (cargo['targetLocation'] != null && cargo['targetLocation'] is Map) {
      Map<String, dynamic> location = Map<String, dynamic>.from(cargo['targetLocation']);
      // Koordinatları double'a çevir
      if (location['latitude'] != null) {
        location['latitude'] = _parseDouble(location['latitude']);
      }
      if (location['longitude'] != null) {
        location['longitude'] = _parseDouble(location['longitude']);
      }
      return location;
    }
    
    // Fallback olarak boş koordinatlar
    return {'latitude': 0.0, 'longitude': 0.0};
  }

  // Double parsing helper
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Telefon numarası - güvenli erişim
  static String getPhoneNumber(Map<String, dynamic> cargo) {
    String? phone = cargo['phoneNumber'];
    return phone?.isNotEmpty == true ? phone! : 'Telefon bilgisi yok';
  }

  // Distributor telefon numarası - güvenli erişim
  static String getDistributorPhone(Map<String, dynamic> cargo) {
    String? distPhone = cargo['distPhoneNumber'];
    return distPhone?.isNotEmpty == true ? distPhone! : 'Bilgi yok';
  }

  // Kargo durumu - güvenli erişim
  static String getCargoSituation(Map<String, dynamic> cargo) {
    String? situation = cargo['cargoSituation'];
    return situation ?? 'CREATED';
  }

  // Kargo ID - güvenli erişim
  static String getCargoId(Map<String, dynamic> cargo) {
    dynamic id = cargo['id'];
    return id?.toString() ?? 'N/A';
  }

  // Doğrulama kodu - güvenli erişim
  static String? getVerificationCode(Map<String, dynamic> cargo) {
    return cargo['verificationCode'];
  }

  // Cargo normalization - backend response'ları standartlaştır
  static Map<String, dynamic> normalizeCargo(Map<String, dynamic> cargo) {
    Map<String, dynamic> normalized = Map<String, dynamic>.from(cargo);
    
    // responseMeasure -> measure mapping
    if (normalized['responseMeasure'] != null && normalized['measure'] == null) {
      normalized['measure'] = normalized['responseMeasure'];
    }
    
    // Eksik description için varsayılan değer
    if (normalized['description'] == null || normalized['description'].toString().trim().isEmpty) {
      normalized['description'] = getDescription(normalized);
    }
    
    // CreatedAt kontrolü - eğer yoksa şu anki zamanı ekle
    if (normalized['createdAt'] == null) {
      normalized['createdAt'] = DateTime.now().toIso8601String();
    }

    // UpdatedAt kontrolü
    if (normalized['updatedAt'] == null) {
      normalized['updatedAt'] = normalized['createdAt'];
    }
    
    return normalized;
  }

  // Duruma göre yapılabilir aksiyonları kontrol et
  static bool canEdit(Map<String, dynamic> cargo) {
    String status = getCargoSituation(cargo);
    return status.toUpperCase() == 'CREATED';
  }

  static bool canDelete(Map<String, dynamic> cargo) {
    String status = getCargoSituation(cargo);
    return status.toUpperCase() == 'CREATED';
  }

  static bool canTake(Map<String, dynamic> cargo) {
    String status = getCargoSituation(cargo);
    return status.toUpperCase() == 'CREATED';
  }

  static bool canDeliver(Map<String, dynamic> cargo) {
    String status = getCargoSituation(cargo);
    return status.toUpperCase() == 'PICKED_UP';
  }

  static bool isCompleted(Map<String, dynamic> cargo) {
    String status = getCargoSituation(cargo);
    return status.toUpperCase() == 'DELIVERED';
  }

  static bool isCancelled(Map<String, dynamic> cargo) {
    String status = getCargoSituation(cargo);
    return ['CANCELLED', 'EXPIRED', 'FAILED'].contains(status.toUpperCase());
  }

  // Duruma göre renk tonları
  static Color getStatusColorLight(String? status) {
    return getStatusColor(status).withOpacity(0.1);
  }

  static Color getStatusColorMedium(String? status) {
    return getStatusColor(status).withOpacity(0.3);
  }

  // Koordinat formatı
  static String formatCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Koordinat bilgisi yok';
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  // Debug için kargo bilgilerini yazdır
  static void debugPrintCargo(Map<String, dynamic> cargo, {String prefix = ''}) {
    print('$prefix=== CARGO DEBUG ===');
    print('$prefix ID: ${getCargoId(cargo)}');
    print('$prefix Description: ${getDescription(cargo)}');
    print('$prefix Status: ${getCargoSituation(cargo)}');
    print('$prefix Phone: ${getPhoneNumber(cargo)}');
    print('$prefix Measure: ${getMeasure(cargo)}');
    print('$prefix Self Location: ${getSelfLocation(cargo)}');
    print('$prefix Target Location: ${getTargetLocation(cargo)}');
    print('$prefix==================');
  }
}