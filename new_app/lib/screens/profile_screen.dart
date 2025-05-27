import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../services/cargo_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _secureStorage = FlutterSecureStorage();
  String? _username;
  String? _email;
  String? _userRole;
  String? _tcOrVkn;
  bool _isLoading = true;
  
  // Form controllers
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Driver specific
  String _selectedCarType = 'SEDAN';
  
  // Distributor specific
  final _cityController = TextEditingController();
  final _neighbourhoodController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildController = TextEditingController();

  final List<String> _carTypes = [
    'SEDAN',
    'HATCHBACK',
    'SUV',
    'MINIVAN',
    'PICKUP',
    'PANELVAN',
    'MOTORCYCLE',
    'TRUCK',
    'TRAILER'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Güncellenmiş AuthService metodlarını kullan
      final userData = await AuthService.getUserData();
      
      if (userData['token'] != null) {
        setState(() {
          _username = userData['username'];
          _email = userData['email'];
          _userRole = userData['role'];
          _tcOrVkn = userData['tcOrVkn'];
        });

        // Form alanlarını doldur
        _usernameController.text = _username ?? '';
        _emailController.text = _email ?? '';

        print('Profil bilgileri yüklendi:');
        print('Username: $_username');
        print('Email: $_email');
        print('Role: $_userRole');
        print('TC/VKN: $_tcOrVkn');

        // Backend'den ek kullanıcı bilgilerini al
        await _loadAdditionalUserInfo();
      } else {
        // Token yoksa login'e yönlendir
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Kullanıcı bilgisi yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı bilgileri yüklenirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAdditionalUserInfo() async {
    try {
      // Backend'den güncel kullanıcı bilgilerini al
      final userInfo = await AuthService.getUserInfo();
      
      if (userInfo != null) {
        setState(() {
          _username = userInfo['username'] ?? _username;
          _email = userInfo['email'] ?? _email;
          _userRole = userInfo['role'] ?? _userRole;
        });

        // Form alanlarını güncelle
        _usernameController.text = _username ?? '';
        _emailController.text = _email ?? '';

        // Eğer driver ise araç tipi bilgisini al
        if (_userRole == 'DRIVER' && userInfo['carType'] != null) {
          setState(() {
            _selectedCarType = userInfo['carType'];
          });
        }

        // Eğer distributor ise adres bilgilerini al
        if (_userRole == 'DISTRIBUTOR') {
          _cityController.text = userInfo['city'] ?? '';
          _neighbourhoodController.text = userInfo['neighbourhood'] ?? '';
          _streetController.text = userInfo['street'] ?? '';
          _buildController.text = userInfo['build'] ?? '';
        }

        // Telefon numarasını al
        if (userInfo['phoneNumber'] != null) {
          _phoneController.text = userInfo['phoneNumber'];
        }
      }
    } catch (e) {
      print('Ek kullanıcı bilgisi alma hatası: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _emailController.text.isEmpty) {
      _showErrorDialog('Lütfen zorunlu alanları doldurun');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? result;
      
      if (_userRole == 'DRIVER') {
        result = await CargoService.updateDriver(
          username: _usernameController.text.trim(),
          carType: _selectedCarType,
          phoneNumber: _phoneController.text.trim(),
          mail: _emailController.text.trim(),
          password: '', // Şifre güncelleme kaldırıldı
        );
      } else {
        result = await CargoService.updateDistributor(
          phoneNumber: _phoneController.text.trim(),
          city: _cityController.text.trim(),
          neighbourhood: _neighbourhoodController.text.trim(),
          street: _streetController.text.trim(),
          build: _buildController.text.trim(),
          username: _usernameController.text.trim(),
          mail: _emailController.text.trim(),
          password: '', // Şifre güncelleme kaldırıldı
        );
      }

      if (result != null) {
        // Başarılı güncelleme sonrası local storage'ı güncelle
        await _secureStorage.write(key: 'username', value: _usernameController.text.trim());
        await _secureStorage.write(key: 'email', value: _emailController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profil başarıyla güncellendi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Kullanıcı bilgilerini yeniden yükle
        await _loadUserInfo();
      } else {
        _showErrorDialog('Profil güncellenirken bir hata oluştu.');
      }
    } catch (e) {
      _showErrorDialog('Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendPasswordResetLink() async {
    if (_email == null || _email!.isEmpty) {
      _showErrorDialog('E-posta adresi bulunamadı');
      return;
    }

    // Onay dialog'u göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.blue),
            SizedBox(width: 8),
            Text('Şifre Sıfırlama'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Şifre sıfırlama bağlantısı aşağıdaki e-posta adresine gönderilecek:'),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _email!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Text('Devam etmek istiyor musunuz?'),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('E-posta gönderiliyor...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final success = await AuthService.forgotPassword(_email!);
        Navigator.pop(context); // Loading dialog'u kapat

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Şifre sıfırlama bağlantısı e-postanıza gönderildi!')),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          _showErrorDialog('E-posta gönderilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin.');
        }
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog('Bir hata oluştu: $e');
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Çıkış Yap'),
          ],
        ),
        content: Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Hata'),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  String _getCarTypeDisplayName(String carType) {
    final Map<String, String> carTypeNames = {
      'SEDAN': 'Sedan',
      'HATCHBACK': 'Hatchback',
      'SUV': 'SUV',
      'MINIVAN': 'Minivan',
      'PICKUP': 'Pickup',
      'PANELVAN': 'Panel Van',
      'MOTORCYCLE': 'Motorsiklet',
      'TRUCK': 'Kamyon',
      'TRAILER': 'Tır',
    };
    return carTypeNames[carType] ?? carType;
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? Colors.purple).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color ?? Colors.purple, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value.isEmpty ? 'Belirtilmemiş' : value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: value.isEmpty ? Colors.grey[400] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profil'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Profil bilgileri yükleniyor...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserInfo,
            tooltip: 'Bilgileri Yenile',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profil kartı
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.purple[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Hero(
                      tag: 'profile_avatar',
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(
                          _userRole == 'DRIVER' ? Icons.drive_eta : Icons.business,
                          size: 40,
                          color: Colors.purple[600],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _username ?? 'Kullanıcı',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_email != null && _email!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        _email!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _userRole == 'DRIVER' ? 'Sürücü' : 'Kargo Veren',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Kullanıcı bilgi kartları
            Text(
              'Hesap Bilgileri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            
            _buildInfoCard('TC/VKN', _tcOrVkn ?? '', Icons.credit_card, color: Colors.indigo),
            _buildInfoCard('E-posta', _email ?? '', Icons.email, color: Colors.blue),
            _buildInfoCard('Kullanıcı Tipi', _userRole == 'DRIVER' ? 'Sürücü' : 'Kargo Veren', Icons.badge, color: Colors.green),
            
            SizedBox(height: 24),
            
            // Profil düzenleme formu
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil Bilgilerini Düzenle',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[800],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Kullanıcı adı
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Kullanıcı Adı *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Telefon
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon Numarası *',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: '+90 5XX XXX XX XX',
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // E-posta
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-posta *',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Driver için araç tipi
                    if (_userRole == 'DRIVER') ...[
                      Text(
                        'Araç Tipi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCarType,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.directions_car),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _carTypes.map((carType) {
                            return DropdownMenuItem(
                              value: carType,
                              child: Text(_getCarTypeDisplayName(carType)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCarType = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    
                    // Distributor için adres bilgileri
                    if (_userRole == 'DISTRIBUTOR') ...[
                      Text(
                        'Adres Bilgileri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Şehir
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'Şehir',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Mahalle
                      TextFormField(
                        controller: _neighbourhoodController,
                        decoration: InputDecoration(
                          labelText: 'Mahalle',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Sokak
                      TextFormField(
                        controller: _streetController,
                        decoration: InputDecoration(
                          labelText: 'Sokak',
                          prefixIcon: Icon(Icons.streetview),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Bina/Kapı No
                      TextFormField(
                        controller: _buildController,
                        decoration: InputDecoration(
                          labelText: 'Bina/Kapı No',
                          prefixIcon: Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    
                    // Güncelle butonu
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Profili Güncelle',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Şifre sıfırlama linki
                    Center(
                      child: TextButton.icon(
                        onPressed: _sendPasswordResetLink,
                        icon: Icon(Icons.lock_reset, size: 18),
                        label: Text('Şifre Sıfırlama Bağlantısı Gönder'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    Text(
                      '* Zorunlu alanlar',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Çıkış yap butonu
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('Hesabınızdan güvenli çıkış yapın'),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
                onTap: _showLogoutDialog,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _neighbourhoodController.dispose();
    _streetController.dispose();
    _buildController.dispose();
    super.dispose();
  }
}