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
  String? _userRole;
  bool _isLoading = true;
  
  // Form controllers
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Driver specific
  final _carTypeController = TextEditingController();
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
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final role = await _secureStorage.read(key: 'user_role');
      
      if (token != null) {
        final name = await AuthService.getNameFromToken(token);
        setState(() {
          _username = name ?? 'Kullanıcı';
          _userRole = role ?? 'DRIVER';
          _usernameController.text = _username ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _emailController.text.isEmpty) {
      _showErrorDialog('Lütfen tüm alanları doldurun');
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
          password: _passwordController.text.isEmpty ? '' : _passwordController.text,
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
          password: _passwordController.text.isEmpty ? '' : _passwordController.text,
        );
      }

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkış Yap'),
        content: Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profil'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
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
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _userRole == 'DRIVER' ? Icons.drive_eta : Icons.business,
                        size: 40,
                        color: Colors.purple[600],
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
                      'Profil Bilgileri',
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
                        labelText: 'Kullanıcı Adı',
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
                        labelText: 'Telefon Numarası',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                    ),
                    SizedBox(height: 16),
                    
                    // Şifre (opsiyonel)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre (Boş Bırakılabilir)',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Şifrenizi değiştirmek istemiyorsanız boş bırakın',
                      ),
                    ),
                    
                    // Driver için araç tipi
                    if (_userRole == 'DRIVER') ...[
                      SizedBox(height: 16),
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
                    ],
                    
                    // Distributor için adres bilgileri
                    if (_userRole == 'DISTRIBUTOR') ...[
                      SizedBox(height: 20),
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
                    ],
                    
                    SizedBox(height: 24),
                    
                    // Güncelle butonu
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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
                              'Profili Güncelle',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    _passwordController.dispose();
    _carTypeController.dispose();
    _cityController.dispose();
    _neighbourhoodController.dispose();
    _streetController.dispose();
    _buildController.dispose();
    super.dispose();
  }
}