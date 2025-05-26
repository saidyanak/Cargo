import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _userId;
  String? _username;
  String? _email;
  String? _role;
  String? _profilePhotoUrl;
  String? _phoneNumber;
  Map<String, dynamic>? _additionalInfo;

  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;
  String? get profilePhotoUrl => _profilePhotoUrl;
  String? get phoneNumber => _phoneNumber;
  Map<String, dynamic>? get additionalInfo => _additionalInfo;

  void setUser({
    String? userId,
    String? username,
    String? email,
    String? role,
    String? profilePhotoUrl,
    String? phoneNumber,
    Map<String, dynamic>? additionalInfo,
  }) {
    _userId = userId;
    _username = username;
    _email = email;
    _role = role;
    _profilePhotoUrl = profilePhotoUrl;
    _phoneNumber = phoneNumber;
    _additionalInfo = additionalInfo;
    notifyListeners();
  }

  void updateProfilePhoto(String photoUrl) {
    _profilePhotoUrl = photoUrl;
    notifyListeners();
  }

  void updateUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void updateEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void updatePhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _username = null;
    _email = null;
    _role = null;
    _profilePhotoUrl = null;
    _phoneNumber = null;
    _additionalInfo = null;
    notifyListeners();
  }

  bool get isDriver => _role == 'DRIVER';
  bool get isDistributor => _role == 'DISTRIBUTOR';
  bool get isLoggedIn => _userId != null;
}