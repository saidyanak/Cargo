import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  final String email;

  VerificationScreen({required this.email});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _verificationCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    if (_verificationCodeController.text.isEmpty) {
      _showErrorDialog('Doğrulama kodu boş bırakılamaz');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AuthService.verify(
        widget.email,
        _verificationCodeController.text.trim(),
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Doğrulama kodu hatalı veya süresi dolmuş.');
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Başarılı'),
        content: Text('E-posta adresiniz başarıyla doğrulandı. Şimdi giriş yapabilirsiniz.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('E-posta Doğrulama'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 32),
              
              // Başlık
              Text(
                'E-posta Doğrulama',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // Açıklama
              Text(
                'Size gönderilen doğrulama kodunu girin.\nE-posta: ${widget.email}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              
              // Doğrulama kodu input
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: _verificationCodeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: 'Doğrulama Kodu',
                          hintText: '123456',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Doğrula butonu
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verify,
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
                                'Doğrula',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              
              // Kod gelmedi mi?
              Text(
                'Kod gelmedi mi?',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Yeniden kod gönderme işlemi burada yapılacak
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Yeni doğrulama kodu gönderildi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(
                  'Tekrar Gönder',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }
}