import 'package:flutter/material.dart';

class CargoHelper {
  static String getSizeDisplayName(String? size) {
    final Map<String, String> sizeNames = {
      'S': 'Küçük',
      'M': 'Orta',
      'L': 'Büyük',
      'XL': 'Çok Büyük',
      'XXL': 'Ekstra Büyük',
    };
    return sizeNames[size] ?? size ?? 'M';
  }

  static String formatWeight(dynamic weight) {
    if (weight == null) return '0 kg';
    return '${weight.toString()} kg';
  }

  static String formatHeight(dynamic height) {
    if (height == null) return '0 cm';
    return '${height.toString()} cm';
  }

  static Color getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
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
      case 'FAILED':
        return Colors.red;
      case 'EXPIRED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static String getStatusDisplayName(String? status) {
    switch (status?.toUpperCase()) {
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
      case 'FAILED':
        return 'Başarısız';
      case 'EXPIRED':
        return 'Süresi Doldu';
      default:
        return 'Bilinmiyor';
    }
  }

  static IconData getStatusIcon(String? status) {
    switch (status?.toUpperCase()) {
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
      case 'FAILED':
        return Icons.error;
      case 'EXPIRED':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }

  static String formatDate(String? dateString) {
    if (dateString == null) return 'Tarih yok';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}