import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tcOrVknController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'DRIVER';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.register(
        _tcOrVknController.text.trim(),
        _emailController.text.trim(),
        _usernameController.text.trim(),
        _passwordController.text,
        _phoneController.text.trim(),
        _selectedRole,
      );

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        _showErrorDialog('Kayıt başarısız. Lütfen bilgilerinizi kontrol edin.');
      }
    } catch (e) {
      _showErrorDialog('Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  String? _validateTcOrVkn(String? value) {
    if (value == null || value.isEmpty) {
      return 'TC/VKN boş bırakılamaz';
    }
    if (_selectedRole == 'DRIVER' && value.length != 11) {
      return 'TC Kimlik No 11 haneli olmalıdır';
    }
    if (_selectedRole == 'DISTRIBUTOR' && (value.length < 10 || value.length > 11)) {
      return 'VKN 10-11 haneli olmalıdır';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta boş bırakılamaz';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası boş bırakılamaz';
    }
    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
      return 'Geçerli bir telefon numarası girin';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Kayıt Ol'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                
                // Rol seçimi
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hesap Türü',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Sürücü'),
                                subtitle: Text('Kargo taşırım'),
                                value: 'DRIVER',
                                groupValue: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Kargo Gönderen'),
                                subtitle: Text('Kargo gönderirim'),
                                value: 'DISTRIBUTOR',
                                groupValue: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Form alanları
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // TC/VKN
                        TextFormField(
                          controller: _tcOrVknController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: _selectedRole == 'DRIVER' ? 'TC Kimlik No' : 'VKN',
                            prefixIcon: Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validateTcOrVkn,
                        ),
                        SizedBox(height: 16),
                        
                        // E-posta
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                        SizedBox(height: 16),
                        
                        // Kullanıcı adı
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kullanıcı adı boş bırakılamaz';
                            }
                            if (value.length < 3) {
                              return 'Kullanıcı adı en az 3 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Telefon
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Telefon Numarası',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: _validatePhone,
                        ),
                        SizedBox(height: 16),
                        
                        // Şifre
                        TextFormField(
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
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre boş bırakılamaz';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        
                        // Şifre tekrar
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre Tekrar',
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre tekrar boş bırakılamaz';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // Kayıt ol butonu
                        ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                                  'Kayıt Ol',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Giriş yap linki
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zaten hesabınız var mı? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Giriş Yap',
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
      ),
    );
  }

  @override
  void dispose() {
    _tcOrVknController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}