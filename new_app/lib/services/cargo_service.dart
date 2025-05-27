import 'dart:convert';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/cargo_helper.dart';

class CargoService {
  // BACKEND URL'İNİ DEĞİŞTİRİN!
  // Android Emulator için:
  //static const String _baseUrl = 'http://10.0.2.2:8080';
  // Gerçek cihaz için (IP'nizi yazın):
  // static const String _baseUrl = 'http://192.168.1.XXX:8080';
  // Web için:
  static const String _baseUrl = 'https://67n86mnm-8080.euw.devtunnels.ms';
  
  static final _secureStorage = FlutterSecureStorage();

  // Token'ı header'a eklemek için yardımcı method
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    
    print('=== AUTH HEADERS ===');
    print('Token exists: ${token != null}');
    if (token != null) {
      print('Token preview: ${token.substring(0, Math.min(20, token.length))}...');
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
      ).timeout(Duration(seconds: 10));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed Response: $responseData');
        
        // Swagger'a göre backend direkt object döndürüyor
        // Spring Boot Page yapısını kontrol edelim
        if (responseData is Map<String, dynamic>) {
          // Spring Boot Page format: {content: [], pageable: {}, totalElements: 0, ...}
          if (responseData.containsKey('content')) {
            print('Spring Boot Page format detected');
            return {
              'data': responseData['content'],
              'meta': {
                'isLast': responseData['last'] ?? true,
                'totalElements': responseData['totalElements'] ?? 0,
                'currentPage': responseData['number'] ?? 0,
                'pageSize': responseData['size'] ?? size,
                'isFirst': responseData['first'] ?? true,
              }
            };
          }
          // Custom format: {data: [], meta: {}}
          else if (responseData.containsKey('data')) {
            print('Custom format detected');
            return responseData;
          }
          // Direkt array wrapper: responseData contains array directly
          else {
            print('Direct object format - looking for array values');
            // Object içindeki değerleri kontrol et
            final values = responseData.values.toList();
            if (values.isNotEmpty && values.first is List) {
              return {
                'data': values.first,
                'meta': {'isLast': true}
              };
            }
            // Eğer responseData'nın kendisi array benzeri davranıyorsa
            return {
              'data': [],
              'meta': {'isLast': true}
            };
          }
        }
        // Eğer response direkt array ise
        else if (responseData is List) {
          print('Direct array format detected');
          return {
            'data': responseData,
            'meta': {'isLast': true}
          };
        }
        else {
          print('Unknown response format: ${responseData.runtimeType}');
          return {
            'data': [],
            'meta': {'isLast': true}
          };
        }
      } else {
        _handleHttpError(response, 'getDistributorCargoes');
        return null;
      }
    } catch (e) {
      print('Error getting distributor cargoes: $e');
      // Hata tipine göre daha spesifik mesaj
      if (e.toString().contains('SocketException') || e.toString().contains('Connection')) {
        throw Exception('Backend\'e bağlanılamıyor - IP adresini kontrol edin');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('İstek zaman aşımına uğradı - Backend çalışıyor mu?');
      }
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
      
      // Swagger'daki CargoRequest formatına uygun
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
      ).timeout(Duration(seconds: 15));

      print('Update cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Swagger'a göre CargoResponse döndürüyor
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        _handleHttpError(response, 'updateCargo');
        return null;
      }
    } catch (e) {
      print('Error updating cargo: $e');
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
      
      // Swagger'daki DistributorRequest formatına uygun
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
      ).timeout(Duration(seconds: 15));

      print('Update distributor response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Swagger'a göre DistributorResponse döndürüyor
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

  // DRIVER İŞLEMLERİ

  // Driver'ın aldığı kargoları getirme
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
      ).timeout(Duration(seconds: 10));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Aynı parsing mantığını kullan
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('content')) {
            return {
              'data': responseData['content'],
              'meta': {
                'isLast': responseData['last'] ?? true,
                'totalElements': responseData['totalElements'] ?? 0,
              }
            };
          } else if (responseData.containsKey('data')) {
            return responseData;
          } else {
            final values = responseData.values.toList();
            if (values.isNotEmpty && values.first is List) {
              return {
                'data': values.first,
                'meta': {'isLast': true}
              };
            }
            return {
              'data': [],
              'meta': {'isLast': true}
            };
          }
        } else if (responseData is List) {
          return {
            'data': responseData,
            'meta': {'isLast': true}
          };
        }
        
        return {
          'data': [],
          'meta': {'isLast': true}
        };
      } else {
        _handleHttpError(response, 'getDriverCargoes');
        return null;
      }
    } catch (e) {
      print('Error getting driver cargoes: $e');
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
      
      // Swagger'daki DriverRequest formatına uygun
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
      ).timeout(Duration(seconds: 15));

      print('Update driver response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Swagger'a göre DriverResponse döndürüyor
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

  // Tüm kargoları getirme (Driver için)
  static Future<Map<String, dynamic>?> getAllCargoes({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/getAllCargoes?page=$page&size=$size&sortBy=$sortBy';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      print('Get all cargoes response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Aynı parsing mantığı
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('content')) {
            return {
              'data': responseData['content'],
              'meta': {
                'isLast': responseData['last'] ?? true,
                'totalElements': responseData['totalElements'] ?? 0,
              }
            };
          } else if (responseData.containsKey('data')) {
            return responseData;
          } else {
            final values = responseData.values.toList();
            if (values.isNotEmpty && values.first is List) {
              return {
                'data': values.first,
                'meta': {'isLast': true}
              };
            }
            return {
              'data': [],
              'meta': {'isLast': true}
            };
          }
        } else if (responseData is List) {
          return {
            'data': responseData,
            'meta': {'isLast': true}
          };
        }
        
        return {
          'data': [],
          'meta': {'isLast': true}
        };
      } else {
        _handleHttpError(response, 'getAllCargoes');
        return null;
      }
    } catch (e) {
      print('Error getting all cargoes: $e');
      rethrow;
    }
  }

  // Kargo alma (Driver)
  static Future<bool> takeCargo(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/takeCargo/$cargoId';
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      print('Take cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Swagger'a göre boolean döndürüyor
        final result = json.decode(response.body);
        return result == true;
      } else {
        _handleHttpError(response, 'takeCargo');
        return false;
      }
    } catch (e) {
      print('Error taking cargo: $e');
      rethrow;
    }
  }

  // Kargo teslimi (Driver)
  static Future<bool> deliverCargo(int cargoId, String deliveryCode) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/driver/deliverCargo/$cargoId/$deliveryCode';
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      print('Deliver cargo response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result == true;
      } else {
        _handleHttpError(response, 'deliverCargo');
        return false;
      }
    } catch (e) {
      print('Error delivering cargo: $e');
      rethrow;
    }
  }

  // Kargo ekleme (Distributor)
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
      
      // Swagger'daki CargoRequest formatına uygun
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
      ).timeout(Duration(seconds: 15));

      print('Add cargo response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Swagger'a göre array döndürüyor
        final responseData = json.decode(response.body);
        if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else {
          // Tek nesne dönerse array yap
          return [responseData];
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

  // Kargo silme
  static Future<bool> deleteCargo(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$_baseUrl/distributor/deleteCargo/$cargoId';
      
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      print('Delete cargo response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result == true;
      } else {
        _handleHttpError(response, 'deleteCargo');
        return false;
      }
    } catch (e) {
      print('Error deleting cargo: $e');
      rethrow;
    }
  }

  // DEBUG: Bağlantı testi
  static Future<bool> testConnection() async {
    try {
      print('=== CONNECTION TEST ===');
      print('Testing URL: $_baseUrl');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/random'), // Random endpoint swagger'da var
      ).timeout(Duration(seconds: 5));
      
      print('Connection test result: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}

// Math sınıfı eksik olabilir, Math.min yerine:
extension MathUtils on int {
  int min(int other) => this < other ? this : other;
}