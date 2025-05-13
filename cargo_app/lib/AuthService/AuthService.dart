import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _url = 'http://localhost:8080/auth/login';  // Login URL
  static const String _registerUrl = 'http://localhost:8080/auth/register';  // Register URL

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['token'];  // Token'ı döndürüyoruz
    } else {
      return null;  // Hata durumu
    }
  }

  Future<bool> register(String tcOrVkn, String mail, String username, String password, String phoneNumber, String role) async {
    final response = await http.post(
      Uri.parse(_registerUrl),
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

    if (response.statusCode == 201) {
      return true;  // Başarılı register
    } else {
      return false;  // Hata durumu
    }
  }

  // Logout işlemi için herhangi bir body gönderilmiyor
  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/auth/logout'),
    );

    if (response.statusCode == 200) {
      print("Logout başarılı");
    } else {
      print("Logout başarısız");
    }
  }
}
