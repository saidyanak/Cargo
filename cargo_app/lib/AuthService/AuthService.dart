import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:8080/auth';
  static const String _randomUrl = 'http://localhost:8080/random';
  final _secureStorage = FlutterSecureStorage();

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final String token = data['token'];
      await _secureStorage.write(key: 'auth_token', value: token);
      return token;
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    final response = await http.post(Uri.parse('$_baseUrl/logout'));
    if (response.statusCode == 200) {
      print("Logout başarılı");
    } else {
      print("Logout başarısız");
    }
  }

  Future<bool> register(String tcOrVkn, String mail, String username, String password, String phoneNumber, String role) async {
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

    return response.statusCode == 201;
  }

  Future<String?> getNameFromToken(String token) async {
    final String? token = await _secureStorage.read(key: 'auth_token');
    if (token == null) {
      print("Token bulunamadı");
      return null;
    }

    final response = await http.get(
      Uri.parse(_randomUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['name'];
    } else {
      print('Hata: ${response.statusCode}');
      return null;
    }
  }
}
