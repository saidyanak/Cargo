import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = FlutterSecureStorage();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Kullanıcı adı ve şifre boş bırakılamaz');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (token != null) {
        print('Login başarılı, token alındı: $token');
        
        // Kullanıcı bilgilerini backend'den al
        final userInfo = await AuthService.getUserInfo();
        print('Kullanıcı bilgileri: $userInfo');
        
        String? userRole;
        
        if (userInfo != null && userInfo['role'] != null) {
          // Backend'den role bilgisi geldi
          userRole = userInfo['role'].toString().toUpperCase();
          print('Backend\'den gelen role: $userRole');
        } else {
          // Fallback: Token'dan kullanıcı adına göre tahmin et (geçici çözüm)
          final name = await AuthService.getNameFromToken(token);
          print('Token\'dan gelen name: $name');
          
          // Burada username'e göre role tahmin edebilirsiniz (geçici)
          // Veya kullanıcıdan role seçmesini isteyebilirsiniz
          userRole = await _showRoleSelectionDialog();
        }
        
        if (userRole != null) {
          // Role'u kaydet
          await _secureStorage.write(key: 'user_role', value: userRole);
          print('Role kaydedildi: $userRole');
          
          // Kullanıcıyı rolüne göre yönlendir
          if (userRole == 'DRIVER') {
            print('Driver olarak yönlendiriliyor...');
            Navigator.pushReplacementNamed(context, '/driver_home');
          } else if (userRole == 'DISTRIBUTOR') {
            print('Distributor olarak yönlendiriliyor...');
            Navigator.pushReplacementNamed(context, '/distributor_home');
          } else {
            _showErrorDialog('Geçersiz kullanıcı rolü: $userRole');
          }
        } else {
          _showErrorDialog('Kullanıcı rolü belirlenemedi');
        }
      } else {
        _showErrorDialog('Giriş başarısız. Kullanıcı adı veya şifre hatalı.');
      }
    } catch (e) {
      print('Login hatası: $e');
      _showErrorDialog('Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Role seçim dialog'u (backend'den role gelmezse)
  Future<String?> _showRoleSelectionDialog() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Hesap Türünüz'),
        content: Text('Hangi tür kullanıcısınız?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'DRIVER'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drive_eta, color: Colors.green),
                SizedBox(width: 8),
                Text('Sürücü'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'DISTRIBUTOR'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business, color: Colors.blue),
                SizedBox(width: 8),
                Text('Kargo Veren'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),
              // Logo ve başlık
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Cargo App',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Hoş Geldiniz',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),
              
              // Login formu
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Kullanıcı adı
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Şifre
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Şifremi unuttum
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text('Şifremi Unuttum'),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Giriş butonu
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Giriş Yap',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              
              // Test kullanıcıları (geliştirme için)
              if (true) // DEBUG MODE
                Column(
                  children: [
                    Text(
                      'Test Kullanıcıları:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _usernameController.text = 'driver1';
                              _passwordController.text = '123456';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Test Driver'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _usernameController.text = 'distributor1';
                              _passwordController.text = '123456';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Test Distributor'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              
              SizedBox(height: 20),
              
              // Kayıt ol
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hesabınız yok mu? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}