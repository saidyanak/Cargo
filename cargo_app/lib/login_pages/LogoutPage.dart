import 'package:flutter/material.dart';
import 'package:cargo_app/AuthService/AuthService.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çıkış Yap')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await AuthService.logout();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Çıkış yapıldı")),
            );
          },
          child: const Text("Çıkış Yap"),
        ),
      ),
    );
  }
}
