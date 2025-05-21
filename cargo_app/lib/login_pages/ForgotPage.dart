import 'package:flutter/material.dart';
import 'package:cargo_app/AuthService/AuthService.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  _ForgotPageState createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _forgotPassword() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text;
      final success = await AuthService.forgotPassword(email);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre sıfırlama talebi gönderildi.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bir hata oluştu. Lütfen tekrar deneyin.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre Unutma')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email boş olamaz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _forgotPassword,
                child: const Text('Şifreyi Sıfırla'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
