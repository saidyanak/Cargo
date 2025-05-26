import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8080/auth';
  static const String _randomUrl = 'http://localhost:8080/random';
  static final _secureStorage = FlutterSecureStorage();

  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'username': username, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String token = data['token'];
        
        // Backend'den role bilgisi gelirse al
        String? role = data['role'];
        
        // Token'ı kaydet
        await _secureStorage.write(key: 'auth_token', value: token);
        
        // Role bilgisi varsa kaydet
        if (role != null) {
          role = role.toUpperCase(); // Standardize et
          await _secureStorage.write(key: 'user_role', value: role);
          print('Role backend\'den alındı ve kaydedildi: $role');
        } else {
          print('Backend\'den role bilgisi gelmedi');
        }
        
        // Kullanıcı bilgilerini de kaydet
        if (data['userId'] != null) {
          await _secureStorage.write(key: 'user_id', value: data['userId'].toString());
        }
        if (data['username'] != null) {
          await _secureStorage.write(key: 'username', value: data['username']);
        }
        
        return token;
      } else {
        print('Login failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      // Token'ı al
      final token = await _secureStorage.read(key: 'auth_token');
      
      // Backend'e logout isteği gönder
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
      
      // Tüm local verileri temizle
      await _secureStorage.deleteAll();
      print("Logout başarılı");
    } catch (e) {
      print("Logout hatası: $e");
      // Hata olsa bile local verileri temizle
      await _secureStorage.deleteAll();
    }
  }

  static Future<bool> register(String tcOrVkn, String mail, String username, String password, String phoneNumber, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tcOrVkn': tcOrVkn,
          'mail': mail,
          'username': username,
          'password': password,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );
      
      print('Register response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Register response body: ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // Kullanıcı bilgilerini getir
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return null;

      // Önce /random endpoint'ini dene
      var response = await http.get(
        Uri.parse(_randomUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Random endpoint response: ${response.statusCode}');
      print('Random endpoint body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Eğer role bilgisi varsa döndür
        if (data['role'] != null) {
          return {
            'name': data['name'],
            'role': data['role'],
            'userId': data['userId'],
            'username': data['username'],
          };
        }
      }

      // Alternatif: /auth/me endpoint'ini dene
      response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Auth/me endpoint response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      return null;
    } catch (e) {
      print('Get user info error: $e');
      return null;
    }
  }

  static Future<String?> getNameFromToken(String? token) async {
    try {
      final String? actualToken = token ?? await _secureStorage.read(key: 'auth_token');
      if (actualToken == null) {
        print("Token bulunamadı");
        return null;
      }

      final response = await http.get(
        Uri.parse(_randomUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $actualToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'];
      } else {
        print('Get name error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Get name from token error: $e');
      return null;
    }
  }

  // Mevcut kullanıcının rolünü al
  static Future<String?> getCurrentUserRole() async {
    try {
      // Önce secure storage'dan bak
      String? role = await _secureStorage.read(key: 'user_role');
      
      if (role != null) {
        print('Role secure storage\'dan alındı: $role');
        return role;
      }

      // Yoksa backend'den al
      final userInfo = await getUserInfo();
      if (userInfo != null && userInfo['role'] != null) {
        role = userInfo['role'].toString().toUpperCase();
        await _secureStorage.write(key: 'user_role', value: role);
        print('Role backend\'den alındı ve kaydedildi: $role');
        return role;
      }

      print('Role bulunamadı');
      return null;
    } catch (e) {
      print('Get current user role error: $e');
      return null;
    }
  }

  static Future<bool> verify(String email, String verificationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'verificationCode': verificationCode,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }

  // Forgot Password
  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Forgot Password Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error in forgotPassword: $e');
      return false;
    }
  }

  // Change Password
  static Future<bool> changePassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/change'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      print('Change Password Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error in changePassword: $e');
      return false;
    }
  }

  // Set Password
  static Future<bool> setPassword(String email, String password) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/setPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Set Password Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error in setPassword: $e');
      return false;
    }
  }

  // Token geçerliliğini kontrol et
  static Future<bool> validateToken() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return false;

      final response = await http.get(
        Uri.parse(_randomUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // Debug: Stored values'ları logla
  static Future<void> debugStoredValues() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final role = await _secureStorage.read(key: 'user_role');
      final userId = await _secureStorage.read(key: 'user_id');
      final username = await _secureStorage.read(key: 'username');
      
      print('=== STORED VALUES ===');
      print('Token: ${token?.substring(0, 20) ?? 'null'}...');
      print('Role: $role');
      print('User ID: $userId');
      print('Username: $username');
      print('====================');
    } catch (e) {
      print('Debug stored values error: $e');
    }
  }
}