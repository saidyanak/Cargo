import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CargoService {
  static const String _baseUrl = 'http://localhost:8080';
  static final _secureStorage = FlutterSecureStorage();

  // Token'ı header'a eklemek için yardımcı method
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // DRIVER İŞLEMLERİ

  // Driver'ın aldığı kargoları getirme (Kargolarım)
  static Future<Map<String, dynamic>?> getDriverCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/driver/getMyCargoes?page=$page&size=$size&sortBy=$sortBy'),
        headers: headers,
      );

      print('Get driver cargoes response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting driver cargoes: $e');
      return null;
    }
  }

  // Tüm kargoları getirme (Driver için - Mevcut Kargolar)
  static Future<Map<String, dynamic>?> getAllCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/driver/getAllCargoes?page=$page&size=$size&sortBy=$sortBy'),
        headers: headers,
      );

      print('Get all cargoes response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting all cargoes: $e');
      return null;
    }
  }

  // Kargo alma (Driver)
  static Future<bool> takeCargo(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/takeCargo/$cargoId'),
        headers: headers,
      );

      print('Take cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200 && json.decode(response.body) == true;
    } catch (e) {
      print('Error taking cargo: $e');
      return false;
    }
  }

  // Kargo teslim etme (Driver)
  static Future<bool> deliverCargo(int cargoId, String deliveryCode) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/deliverCargo/$cargoId/$deliveryCode'),
        headers: headers,
      );

      print('Deliver cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response.statusCode == 200 && json.decode(response.body) == true;
    } catch (e) {
      print('Error delivering cargo: $e');
      return false;
    }
  }

  // Driver bilgilerini güncelleme
  static Future<Map<String, dynamic>?> updateDriver({
    required String username,
    required String carType,
    required String phoneNumber,
    required String mail,
    required String password,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/updateDriver'),
        headers: headers,
        body: json.encode({
          'username': username,
          'carType': carType,
          'phoneNumber': phoneNumber,
          'mail': mail,
          'password': password.isEmpty ? null : password,
        }),
      );

      print('Update driver response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error updating driver: $e');
      return null;
    }
  }

  // DISTRIBUTOR İŞLEMLERİ

  // Distributor'ın kargolarını getirme
  static Future<Map<String, dynamic>?> getDistributorCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      print('=== DISTRIBUTOR CARGOES REQUEST ===');
      print('URL: $_baseUrl/distributor/getMyCargoes?page=$page&size=$size&sortBy=$sortBy');
      print('Headers: $headers');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/distributor/getMyCargoes?page=$page&size=$size&sortBy=$sortBy'),
        headers: headers,
      );

      print('Get distributor cargoes response: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed response data: $responseData');
        return responseData;
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting distributor cargoes: $e');
      return null;
    }
  }

  // Kargo ekleme
  static Future<List<Map<String, dynamic>>?> addCargo({
    required String description,
    required double selfLatitude,
    required double selfLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double weight,
    required double height,
    required String size,
    required String phoneNumber,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/distributor/addCargo'),
        headers: headers,
        body: json.encode({
          'description': description,
          'selfLocation': {
            'latitude': selfLatitude,
            'longitude': selfLongitude,
          },
          'targetLocation': {
            'latitude': targetLatitude,
            'longitude': targetLongitude,
          },
          'measure': {
            'weight': weight,
            'height': height,
            'size': size,
          },
          'phoneNumber': phoneNumber,
        }),
      );

      print('Add cargo response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error adding cargo: $e');
      return null;
    }
  }

  // Kargo güncelleme
  static Future<Map<String, dynamic>?> updateCargo({
    required int cargoId,
    required String description,
    required double selfLatitude,
    required double selfLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double weight,
    required double height,
    required String size,
    required String phoneNumber,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/distributor/updateCargo/$cargoId'),
        headers: headers,
        body: json.encode({
          'description': description,
          'selfLocation': {
            'latitude': selfLatitude,
            'longitude': selfLongitude,
          },
          'targetLocation': {
            'latitude': targetLatitude,
            'longitude': targetLongitude,
          },
          'measure': {
            'weight': weight,
            'height': height,
            'size': size,
          },
          'phoneNumber': phoneNumber,
        }),
      );

      print('Update cargo response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error updating cargo: $e');
      return null;
    }
  }

  // Kargo silme
  static Future<bool> deleteCargo(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/distributor/deleteCargo/$cargoId'),
        headers: headers,
      );

      print('Delete cargo response: ${response.statusCode}');
      return response.statusCode == 200 && json.decode(response.body) == true;
    } catch (e) {
      print('Error deleting cargo: $e');
      return false;
    }
  }

  // Distributor bilgilerini güncelleme
  static Future<Map<String, dynamic>?> updateDistributor({
    required String phoneNumber,
    required String city,
    required String neighbourhood,
    required String street,
    required String build,
    required String username,
    required String mail,
    required String password,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/distributor/updateDistributor'),
        headers: headers,
        body: json.encode({
          'phoneNumber': phoneNumber,
          'address': {
            'city': city,
            'neighbourhood': neighbourhood,
            'street': street,
            'build': build,
          },
          'username': username,
          'mail': mail,
          'password': password.isEmpty ? null : password,
        }),
      );

      print('Update distributor response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error updating distributor: $e');
      return null;
    }
  }
}

// Yardımcı metodlar
class CargoHelper {
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
      case 'EXPIRED':
        return 'Süresi Doldu';
      case 'FAILED':
        return 'Başarısız';
      default:
        return status ?? 'Bilinmiyor';
    }
  }

  static String getSizeDisplayName(String? size) {
    switch (size?.toUpperCase()) {
      case 'S':
        return 'Küçük';
      case 'M':
        return 'Orta';
      case 'L':
        return 'Büyük';
      case 'XL':
        return 'Çok Büyük';
      case 'XXL':
        return 'Ekstra Büyük';
      default:
        return size ?? '';
    }
  }

  static String getCarTypeDisplayName(String? carType) {
    switch (carType?.toUpperCase()) {
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
        return 'Treyler';
      default:
        return carType ?? '';
    }
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
      case 'FAILED':
        return Colors.red;
      case 'EXPIRED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  static bool canBeTaken(String? status) => status?.toUpperCase() == 'CREATED';
  static bool canBeDelivered(String? status) => status?.toUpperCase() == 'PICKED_UP';
  static bool isCompleted(String? status) => status?.toUpperCase() == 'DELIVERED';
  static bool isCancelled(String? status) => status?.toUpperCase() == 'CANCELLED';
  static bool isActive(String? status) => ['CREATED', 'ASSIGNED', 'PICKED_UP'].contains(status?.toUpperCase());

  static String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  static String formatWeight(dynamic weight) {
    if (weight == null) return '';
    return '${weight.toString()} kg';
  }

  static String formatHeight(dynamic height) {
    if (height == null) return '';
    return '${height.toString()} cm';
  }

  static bool isValidCoordinate(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    return latitude >= -90 && 
           latitude <= 90 && 
           longitude >= -180 && 
           longitude <= 180;
  }
}