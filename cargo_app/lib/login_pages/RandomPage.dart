import 'package:flutter/material.dart';
import 'package:cargo_app/AuthService/AuthService.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RandomPage extends StatefulWidget {
  const RandomPage({super.key});

  @override
  State<RandomPage> createState() => _RandomPageState();
}

class _RandomPageState extends State<RandomPage> {
  String name = "";

  @override
  void initState() {
    super.initState();
    getRandomName();
  }

  static final _secureStorage = FlutterSecureStorage();

  Future<void> getRandomName() async {
    final result = await AuthService.getNameFromToken(await _secureStorage.read(key: 'auth_token').toString());
    setState(() {
      name = result.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İsim Getir')),
      body: Center(
        child: Text(name.isNotEmpty ? "İsim: $name" : "Yükleniyor...", style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
