import 'dart:convert';
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

  // DISTRIBUTOR İŞLEMLERİ
  
  // Kargo ekleme
  static Future<List<Map<String, dynamic>>?> addCargo({
    required String description,
    required double selfLatitude,
    required double selfLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double weight,
    required double height,
    required String size, // S, M, L, XL, XXL
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

  // Distributor'ın kargolarını getirme
  static Future<Map<String, dynamic>?> getDistributorCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/distributor/getMyCargoes?page=$page&size=$size&sortBy=$sortBy'),
        headers: headers,
      );

      print('Get distributor cargoes response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting distributor cargoes: $e');
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
      return response.statusCode == 200;
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
          'password': password.isEmpty ? null : password, // Boşsa gönderme
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

  // DRIVER İŞLEMLERİ

  // Tüm kargoları getirme (Driver için)
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
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting all cargoes: $e');
      return null;
    }
  }

  // Driver'ın aldığı kargoları getirme
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
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting driver cargoes: $e');
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
      return response.statusCode == 200;
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
      return response.statusCode == 200;
    } catch (e) {
      print('Error delivering cargo: $e');
      return false;
    }
  }

  // Driver bilgilerini güncelleme
  static Future<Map<String, dynamic>?> updateDriver({
    required String username,
    required String carType, // SEDAN, HATCHBACK, SUV, vs.
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
          'password': password.isEmpty ? null : password, // Boşsa gönderme
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

  // GENEL İŞLEMLER

  // Kargo detayını getirme
  static Future<Map<String, dynamic>?> getCargoDetails(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cargo/$cargoId'),
        headers: headers,
      );

      print('Get cargo details response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting cargo details: $e');
      return null;
    }
  }

  // Kargo durumunu güncelleme
  static Future<bool> updateCargoStatus(int cargoId, String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/cargo/$cargoId/status'),
        headers: headers,
        body: json.encode({'status': status}),
      );

      print('Update cargo status response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating cargo status: $e');
      return false;
    }
  }

  // Kargo geçmişini getirme
  static Future<List<Map<String, dynamic>>?> getCargoHistory(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cargo/$cargoId/history'),
        headers: headers,
      );

      print('Get cargo history response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error getting cargo history: $e');
      return null;
    }
  }

  // Yakındaki kargoları getirme (konum bazlı)
  static Future<List<Map<String, dynamic>>?> getNearbyCargoesLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/cargo/nearby?lat=$latitude&lng=$longitude&radius=$radiusKm&limit=$limit'),
        headers: headers,
      );

      print('Get nearby cargoes response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error getting nearby cargoes: $e');
      return null;
    }
  }

  // Kargo arama
  static Future<List<Map<String, dynamic>>?> searchCargoes({
    String? query,
    String? status,
    String? size,
    double? minWeight,
    double? maxWeight,
    int page = 0,
    int size_param = 10,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      // Query parametrelerini oluştur
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size_param.toString(),
      };
      
      if (query != null && query.isNotEmpty) queryParams['q'] = query;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (size != null && size.isNotEmpty) queryParams['size_filter'] = size;
      if (minWeight != null) queryParams['minWeight'] = minWeight.toString();
      if (maxWeight != null) queryParams['maxWeight'] = maxWeight.toString();
      
      final uri = Uri.parse('$_baseUrl/api/cargo/search').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      print('Search cargoes response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['content'] != null) {
          return List<Map<String, dynamic>>.from(data['content']);
        }
        return [];
      }
      return null;
    } catch (e) {
      print('Error searching cargoes: $e');
      return null;
    }
  }
}