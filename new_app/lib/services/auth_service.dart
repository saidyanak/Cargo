import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  static const String baseUrl = 'https://67n86mnm-8080.euw.devtunnels.ms';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Login işlemi - Backend'den LoginResponse alır
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Backend'den gelen LoginResponse yapısı:
        // {
        //   "token": "jwt_token_here",
        //   "userResponse": {
        //     "tcOrVkn": "12345678901",
        //     "username": "testuser",
        //     "email": "test@example.com",
        //     "role": "DRIVER" // veya "DISTRIBUTOR"
        //   }
        // }

        final String token = responseData['token'];
        final Map<String, dynamic> userResponse = responseData['userResponse'];
        final String role = userResponse['role'];

        // Token ve kullanıcı bilgilerini kaydet
        await _secureStorage.write(key: 'auth_token', value: token);
        await _secureStorage.write(key: 'user_role', value: role);
        await _secureStorage.write(key: 'username', value: userResponse['username']);
        await _secureStorage.write(key: 'email', value: userResponse['email']);
        await _secureStorage.write(key: 'tc_or_vkn', value: userResponse['tcOrVkn']);

        // Login response'u döndür
        return {
          'success': true,
          'token': token,
          'role': role,
          'userResponse': userResponse,
        };
      } else {
        print('Login başarısız: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Login hatası: $e');
      return null;
    }
  }

  // Kullanıcı bilgilerini backend'den al
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/user-info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(response.body);
        
        // Kullanıcı bilgilerini güncelle
        await _secureStorage.write(key: 'user_role', value: userData['role']);
        await _secureStorage.write(key: 'username', value: userData['username']);
        await _secureStorage.write(key: 'email', value: userData['email']);
        
        return userData;
      } else {
        print('Kullanıcı bilgisi alınamadı: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Kullanıcı bilgisi alma hatası: $e');
      return null;
    }
  }

  // Token'dan kullanıcı adını al (JWT decode)
  static Future<String?> getNameFromToken(String token) async {
    try {
      if (JwtDecoder.isExpired(token)) {
        return null;
      }
      
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      return decodedToken['username'] ?? decodedToken['sub'];
    } catch (e) {
      print('Token decode hatası: $e');
      return null;
    }
  }

  // Token geçerliliğini kontrol et
  static Future<bool> isTokenValid() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return false;
      
      // JWT token'ın süresini kontrol et
      if (JwtDecoder.isExpired(token)) {
        await logout(); // Süresi dolmuş token'ı temizle
        return false;
      }
      
      // Backend'e token geçerliliği sorgusu (opsiyonel)
      final response = await http.get(
        Uri.parse('$baseUrl/auth/validate-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Token doğrulama hatası: $e');
      return false;
    }
  }

  // Kayıtlı kullanıcı bilgilerini al
  static Future<Map<String, String?>> getUserData() async {
    return {
      'token': await _secureStorage.read(key: 'auth_token'),
      'role': await _secureStorage.read(key: 'user_role'),
      'username': await _secureStorage.read(key: 'username'),
      'email': await _secureStorage.read(key: 'email'),
      'tcOrVkn': await _secureStorage.read(key: 'tc_or_vkn'),
    };
  }

  // Kayıt işlemi
  static Future<bool> register(
    String tcOrVkn,
    String email,
    String username,
    String password,
    String phoneNumber,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tcOrVkn': tcOrVkn,
          'email': email,
          'username': username,
          'password': password,
          'phoneNumber': phoneNumber,
          'role': role,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Kayıt hatası: $e');
      return false;
    }
  }

  // E-posta doğrulama
  static Future<bool> verify(String email, String verificationCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'verificationCode': verificationCode,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Doğrulama hatası: $e');
      return false;
    }
  }

  // Şifre sıfırlama
  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Şifre sıfırlama hatası: $e');
      return false;
    }
  }

  // Çıkış işlemi
  static Future<void> logout() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      // Backend'e logout isteği gönder (opsiyonel)
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      print('Logout backend hatası: $e');
    } finally {
      // Her durumda local storage'ı temizle
      await _secureStorage.deleteAll();
    }
  }
}