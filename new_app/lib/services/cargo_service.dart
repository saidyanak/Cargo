import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/cargo_helper.dart';

class CargoService {
  // Backend URL - Swagger'dan alındı
  static const String _baseUrl = 'https://67n86mnm-8080.euw.devtunnels.ms';
  
  static final _secureStorage = FlutterSecureStorage();

  // Token'ı header'a eklemek için yardımcı method
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    
    print('=== AUTH HEADERS ===');
    print('Token exists: ${token != null}');
    if (token != null) {
      print('Token preview: ${token.substring(0, math.min(20, token.length))}...');
    }
    print('==================');
    
    if (token == null) {
      throw Exception('Token bulunamadı - Lütfen yeniden giriş yapın');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // HTTP hata yönetimi
  static void _handleHttpError(http.Response response, String operation) {
    print('=== HTTP ERROR ===');
    print('Operation: $operation');
    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');
    print('==================');
    
    switch (response.statusCode) {
      case 401:
        throw Exception('Oturum süresi doldu - Yeniden giriş yapın');
      case 403:
        throw Exception('Bu işlem için yetkiniz yok');
      case 404:
        throw Exception('Endpoint bulunamadı');
      case 500:
        throw Exception('Sunucu hatası');
      default:
        throw Exception('HTTP Hatası: ${response.statusCode}');
    }
  }

  // SWAGGER Response Parsing - Geliştirilmiş ve normalization eklendi
  static Map<String, dynamic> _parseSwaggerResponse(dynamic responseData) {
    print('=== PARSING SWAGGER RESPONSE ===');
    print('Response Type: ${responseData.runtimeType}');
    print('Response Data: $responseData');
    
    Map<String, dynamic> result;
    
    if (responseData is Map<String, dynamic>) {
      // Spring Boot Page format
      if (responseData.containsKey('content') && responseData.containsKey('pageable')) {
        print('Spring Boot Page format detected');
        List<dynamic> content = responseData['content'] ?? [];
        result = {
          'data': _normalizeCargoList(content),
          'meta': {
            'isLast': responseData['last'] ?? true,
            'totalElements': responseData['totalElements'] ?? 0,
            'currentPage': responseData['number'] ?? 0,
            'pageSize': responseData['size'] ?? 10,
            'isFirst': responseData['first'] ?? true,
            'totalPages': responseData['totalPages'] ?? 1,
          }
        };
      } 
      // Custom format kontrol et
      else if (responseData.containsKey('data') && responseData.containsKey('meta')) {
        print('Custom format with data/meta detected');
        List<dynamic> data = responseData['data'] ?? [];
        result = {
          'data': _normalizeCargoList(data),
          'meta': responseData['meta'] ?? {'isLast': true, 'totalElements': 0}
        };
      }
      // Direkt key-value pairs olarak cargo listesi gelebilir
      else {
        print('Direct map format - converting to list');
        List<dynamic> cargoList = [];
        
        // Swagger'daki "additionalProperties": {"type": "object"} formatı
        for (var key in responseData.keys) {
          var value = responseData[key];
          if (value is Map<String, dynamic>) {
            value['id'] = key;
            cargoList.add(value);
          } else if (value is List) {
            cargoList.addAll(value);
          }
        }
        
        result = {
          'data': _normalizeCargoList(cargoList),
          'meta': {'isLast': true, 'totalElements': cargoList.length}
        };
      }
    } 
    // Direkt array gelebilir
    else if (responseData is List) {
      print('Direct array format detected');
      result = {
        'data': _normalizeCargoList(responseData),
        'meta': {'isLast': true, 'totalElements': responseData.length}
      };
    }
    else {
      // Fallback - boş response
      print('Unknown format - returning empty');
      result = {
        'data': [],
        'meta': {'isLast': true, 'totalElements': 0}
      };
    }
    
    print('Parsed result: ${result['data']?.length ?? 0} cargoes');
    return result;
  }

  // Cargo listesini normalize et
  static List<Map<String, dynamic>> _normalizeCargoList(List<dynamic> cargoList) {
    return cargoList.map((cargo) {
      if (cargo is Map<String, dynamic>) {
        Map<String, dynamic> normalizedCargo = CargoHelper.normalizeCargo(cargo);
        
        // Debug için ilk cargo'yu yazdır
        if (cargoList.indexOf(cargo) == 0) {
          CargoHelper.debugPrintCargo(normalizedCargo, prefix: '[NORMALIZED] ');
        }
        
        return normalizedCargo;
      }
      return <String, dynamic>{};
    }).where((cargo) => cargo.isNotEmpty).toList().cast<Map<String, dynamic>>();
  }

  // DISTRIBUTOR İŞLEMLERİ

  // Distributor'ın kargolarını getirme - SWAGGER'A UYGUN
  static Future<Map<String, dynamic>?> getDistributorCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/distributor/getMyCargoes?page=$page&size=$size&sortBy=$sortBy';
      
      print('=== DISTRIBUTOR REQUEST ===');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return _parseSwaggerResponse(responseData);
      } else {
        _handleHttpError(response, 'getDistributorCargoes');
        return null;
      }
    } catch (e) {
      print('Error getting distributor cargoes: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Backend\'e bağlanılamıyor - Bağlantı kontrol edin');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('İstek zaman aşımına uğradı - Backend yavaş');
      }
      rethrow;
    }
  }

  // DRIVER İŞLEMLERİ

  // Driver'ın aldığı kargoları getirme - SWAGGER'A UYGUN
  static Future<Map<String, dynamic>?> getDriverCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/getMyCargoes?page=$page&size=$size&sortBy=$sortBy';
      
      print('=== DRIVER CARGOES REQUEST ===');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return _parseSwaggerResponse(responseData);
      } else {
        _handleHttpError(response, 'getDriverCargoes');
        return null;
      }
    } catch (e) {
      print('Error getting driver cargoes: $e');
      rethrow;
    }
  }

  // Tüm kargoları getirme (Driver için) - SWAGGER'A UYGUN
  static Future<Map<String, dynamic>?> getAllCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/getAllCargoes?page=$page&size=$size&sortBy=$sortBy';
      
      print('=== GET ALL CARGOES REQUEST ===');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return _parseSwaggerResponse(responseData);
      } else {
        _handleHttpError(response, 'getAllCargoes');
        return null;
      }
    } catch (e) {
      print('Error getting all cargoes: $e');
      rethrow;
    }
  }

  // Kargo alma (Driver) - SWAGGER'A UYGUN
  static Future<bool> takeCargo(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/takeCargo/$cargoId';
      
      print('=== TAKE CARGO REQUEST ===');
      print('URL: $url');
      print('Cargo ID: $cargoId');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Take cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result == true || result == 'true';
      } else {
        _handleHttpError(response, 'takeCargo');
        return false;
      }
    } catch (e) {
      print('Error taking cargo: $e');
      rethrow;
    }
  }

  // Kargo teslimi (Driver) - SWAGGER'A UYGUN
  static Future<bool> deliverCargo(int cargoId, String deliveryCode) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/deliverCargo/$cargoId/$deliveryCode';
      
      print('=== DELIVER CARGO REQUEST ===');
      print('URL: $url');
      print('Cargo ID: $cargoId');
      print('Delivery Code: $deliveryCode');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Deliver cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result == true || result == 'true';
      } else {
        _handleHttpError(response, 'deliverCargo');
        return false;
      }
    } catch (e) {
      print('Error delivering cargo: $e');
      rethrow;
    }
  }

  // Kargo ekleme (Distributor) - SWAGGER'A UYGUN
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
    String? selfAddress,
    String? targetAddress,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/distributor/addCargo';
      
      // Swagger'daki CargoRequest formatına tam uygun
      final requestBody = {
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
      };
      
      print('=== ADD CARGO REQUEST ===');
      print('URL: $url');
      print('Body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 20));

      print('Add cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is List) {
          return _normalizeCargoList(responseData);
        } else if (responseData is Map<String, dynamic>) {
          return [CargoHelper.normalizeCargo(responseData)];
        } else {
          print('Unexpected response format for addCargo');
          return [];
        }
      } else {
        _handleHttpError(response, 'addCargo');
        return null;
      }
    } catch (e) {
      print('Error adding cargo: $e');
      rethrow;
    }
  }

  // Kargo güncelleme (Distributor) - SWAGGER'A UYGUN
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
      final url = '$_baseUrl/distributor/updateCargo/$cargoId';
      
      // Swagger'daki CargoRequest formatına tam uygun
      final requestBody = {
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
      };
      
      print('=== UPDATE CARGO REQUEST ===');
      print('URL: $url');
      print('Body: ${json.encode(requestBody)}');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 20));

      print('Update cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return CargoHelper.normalizeCargo(responseData);
      } else {
        _handleHttpError(response, 'updateCargo');
        return null;
      }
    } catch (e) {
      print('Error updating cargo: $e');
      rethrow;
    }
  }

  // Kargo silme - SWAGGER'A UYGUN
  static Future<bool> deleteCargo(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/distributor/deleteCargo/$cargoId';
      
      print('=== DELETE CARGO REQUEST ===');
      print('URL: $url');
      print('Cargo ID: $cargoId');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 15));

      print('Delete cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result == true || result == 'true';
      } else {
        _handleHttpError(response, 'deleteCargo');
        return false;
      }
    } catch (e) {
      print('Error deleting cargo: $e');
      rethrow;
    }
  }

  // Driver güncelleme - SWAGGER'A UYGUN
  static Future<Map<String, dynamic>?> updateDriver({
    required String username,
    required String carType,
    required String phoneNumber,
    required String mail,
    required String password,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/updateDriver';
      
      // Swagger'daki DriverRequest formatına tam uygun
      final requestBody = {
        'username': username,
        'carType': carType,
        'phoneNumber': phoneNumber,
        'mail': mail,
        'password': password,
      };
      
      print('=== UPDATE DRIVER REQUEST ===');
      print('URL: $url');
      print('Body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 20));

      print('Update driver response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _handleHttpError(response, 'updateDriver');
        return null;
      }
    } catch (e) {
      print('Error updating driver: $e');
      rethrow;
    }
  }

  // Distributor güncelleme - SWAGGER'A UYGUN
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
      final url = '$_baseUrl/distributor/updateDistributor';
      
      // Swagger'daki DistributorRequest formatına tam uygun
      final requestBody = {
        'phoneNumber': phoneNumber,
        'address': {
          'city': city,
          'neighbourhood': neighbourhood,
          'street': street,
          'build': build,
        },
        'username': username,
        'mail': mail,
        'password': password,
      };
      
      print('=== UPDATE DISTRIBUTOR REQUEST ===');
      print('URL: $url');
      print('Body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 20));

      print('Update distributor response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _handleHttpError(response, 'updateDistributor');
        return null;
      }
    } catch (e) {
      print('Error updating distributor: $e');
      rethrow;
    }
  }

  // DEBUG: Bağlantı testi
  static Future<bool> testConnection() async {
    try {
      print('=== CONNECTION TEST ===');
      print('Testing URL: $_baseUrl');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/actuator/health'), // Health check endpoint
      ).timeout(Duration(seconds: 10));
      
      print('Connection test result: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Utility method - Kargo durumunu kontrol et
  static bool isCargoAvailable(Map<String, dynamic> cargo) {
    return CargoHelper.canTake(cargo);
  }

  // Utility method - Kargo listesini filtrele (durum bazında)
  static List<Map<String, dynamic>> filterCargosByStatus(
    List<Map<String, dynamic>> cargos, 
    String status
  ) {
    return cargos.where((cargo) => 
      CargoHelper.getCargoSituation(cargo).toUpperCase() == status.toUpperCase()
    ).toList();
  }

  // Utility method - Mesafe bazında kargo filtresi (gelecekte kullanılabilir)
  static List<Map<String, dynamic>> filterCargosByDistance(
    List<Map<String, dynamic>> cargos,
    double userLat,
    double userLng,
    double maxDistanceKm,
  ) {
    return cargos.where((cargo) {
      try {
        Map<String, dynamic> selfLocation = CargoHelper.getSelfLocation(cargo);
        double cargoLat = selfLocation['latitude'] ?? 0.0;
        double cargoLng = selfLocation['longitude'] ?? 0.0;
        
        // Basit mesafe hesaplama (haversine formülü kullanılabilir)
        double distance = _calculateSimpleDistance(userLat, userLng, cargoLat, cargoLng);
        return distance <= maxDistanceKm;
      } catch (e) {
        print('Distance calculation error: $e');
        return false;
      }
    }).toList();
  }

  // Basit mesafe hesaplama (km cinsinden)
  static double _calculateSimpleDistance(double lat1, double lng1, double lat2, double lng2) {
    // Basit euclidean distance (gerçek proje için haversine kullanın)
    double deltaLat = lat1 - lat2;
    double deltaLng = lng1 - lng2;
    double distance = math.sqrt((deltaLat * deltaLat) + (deltaLng * deltaLng));
    return distance * 111; // Yaklaşık km'ye çevir
  }
}