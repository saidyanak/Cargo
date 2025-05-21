import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cargo_app/AuthService/AuthService.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  _VerifyPageState createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Üst arka plan görseli ve yazılar
            Container(
              height: 400,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -40,
                    height: 400,
                    width: width,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('images/background.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    height: 400,
                    width: width + 20,
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(255, 65, 57, 175).withOpacity(.8),
                              const Color.fromARGB(255, 28, 83, 165).withOpacity(.2),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: const Text(
                        "Verification",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 1200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_emailController, 'Email'),
                      _buildTextField(_verificationCodeController, 'Verification Code'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text("Verify"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (value) => value == null || value.isEmpty ? '$label boş olamaz' : null,
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final bool success = await AuthService.verify(
        _emailController.text,
        _verificationCodeController.text,
      );

      if (success) {
        // Doğrulama başarılı
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğrulama başarılı!')),
        );
        Navigator.pushReplacementNamed(context, '/login'); // Ana sayfaya yönlendir
      } else {
        // Doğrulama başarısız
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doğrulama başarısız. Lütfen tekrar deneyin.')),
        );
      }
    }
  }
}
