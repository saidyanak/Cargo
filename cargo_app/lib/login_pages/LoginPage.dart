import 'package:flutter/material.dart';
import 'package:cargo_app/AuthService/AuthService.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'DRIVER'; // varsayılan rol

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'EMPLOYEE', child: Text('Driver')),
                DropdownMenuItem(value: 'DISTRIBUTOR', child: Text('Distributor')),
              ],
              onChanged: (value) {
                setState(() {
                  role = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await AuthService.login(emailController.text, passwordController.text);
              },
              child: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
