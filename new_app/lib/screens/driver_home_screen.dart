import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/cargo_service.dart';
import '../services/auth_service.dart';
import 'available_cargoes_screen.dart';
import 'my_cargoes_screen.dart';
import 'profile_screen.dart';
import '../utils/cargo_helper.dart';

class DriverHomeScreen extends StatefulWidget {
  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  String? _username;
  String? _email;
  List<Map<String, dynamic>> _myCargoes = [];
  List<Map<String, dynamic>> _availableCargoes = [];
  final _secureStorage = FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCargoes();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Güncellenmiş AuthService metodlarını kullan
      final userData = await AuthService.getUserData();
      
      setState(() {
        _username = userData['username'] ?? 'Sürücü';
        _email = userData['email'];
      });
      
      print('Kullanıcı bilgileri yüklendi: $_username');
    } catch (e) {
      print('Kullanıcı bilgisi yükleme hatası: $e');
      setState(() {
        _username = 'Sürücü';
      });
    }
  }

  Future<void> _loadCargoes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('=== KARGO VERİLERİ YÜKLENİYOR ===');
      
      // Kendi kargolarımı yükle - daha fazla göster
      final myCargoesResult = await CargoService.getDriverCargoes(page: 0, size: 10);
      print('Aldığım kargolar sonucu: $myCargoesResult');
      
      if (myCargoesResult != null) {
        List<dynamic> myCargoList = [];
        
        // Response yapısını kontrol et
        if (myCargoesResult.containsKey('data') && myCargoesResult['data'] is List) {
          myCargoList = myCargoesResult['data'] as List<dynamic>;
        } else if (myCargoesResult is List) {
          myCargoList = myCargoesResult as List<dynamic>;
        } else if (myCargoesResult.containsKey('content') && myCargoesResult['content'] is List) {
          myCargoList = myCargoesResult['content'] as List<dynamic>;
        }
        
        print('Aldığım kargo sayısı: ${myCargoList.length}');
        
        setState(() {
          _myCargoes = myCargoList.cast<Map<String, dynamic>>();
        });
      }

      // Mevcut kargoları yükle
      final availableCargoesResult = await CargoService.getAllCargoes(page: 0, size: 15);
      print('Mevcut kargolar sonucu: $availableCargoesResult');
      
      if (availableCargoesResult != null) {
        List<dynamic> allCargoList = [];
        
        // Response yapısını kontrol et
        if (availableCargoesResult.containsKey('data') && availableCargoesResult['data'] is List) {
          allCargoList = availableCargoesResult['data'] as List<dynamic>;
        } else if (availableCargoesResult is List) {
          allCargoList = availableCargoesResult as List<dynamic>;
        } else if (availableCargoesResult.containsKey('content') && availableCargoesResult['content'] is List) {
          allCargoList = availableCargoesResult['content'] as List<dynamic>;
        }
        
        // Sadece oluşturulmuş kargoları filtrele
        final availableCargoes = allCargoList
            .where((cargo) => cargo['cargoSituation'] == 'CREATED')
            .take(8) // Daha fazla göster
            .toList();
        
        print('Mevcut kargo sayısı: ${availableCargoes.length}');
        
        setState(() {
          _availableCargoes = availableCargoes.cast<Map<String, dynamic>>();
        });
      }

    } catch (e) {
      print('Kargo yükleme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, '/login');
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

  Future<void> _takeCargo(int cargoId) async {
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
                Text('Kargo alınıyor...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      final success = await CargoService.takeCargo(cargoId);
      Navigator.pop(context); // Loading dialog'u kapat
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Kargo başarıyla alındı!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Verileri yenile
        await _loadCargoes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Kargo alınırken hata oluştu!'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTakeCargoDialog(Map<String, dynamic> cargo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.green),
            SizedBox(width: 8),
            Text('Kargo Al'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bu kargoyu almak istediğinizden emin misiniz?'),
              SizedBox(height: 16),
              
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Açıklama:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(cargo['description'] ?? 'Açıklama yok'),
                    SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(Icons.scale, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text('Ağırlık: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(CargoHelper.formatWeight(cargo['measure']?['weight'])),
                        SizedBox(width: 16),
                        Icon(Icons.aspect_ratio, size: 16, color: Colors.purple),
                        SizedBox(width: 4),
                        Text('Boyut: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(CargoHelper.getSizeDisplayName(cargo['measure']?['size'])),
                      ],
                    ),
                    SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Telefon: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(cargo['phoneNumber'] ?? ''),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              _takeCargo(cargo['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Kargoyu Al', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadCargoes(),
          _loadUserInfo(),
        ]);
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş geldin kartı
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
                    colors: [Colors.green[600]!, Colors.green[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'driver_avatar',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.local_shipping,
                          size: 35,
                          color: Colors.green[600],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hoş Geldin,',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _username ?? 'Yükleniyor...',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (_email != null)
                            Text(
                              _email!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.drive_eta,
                      size: 40,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // İstatistikler
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Aldığım Kargolar',
                    _myCargoes.length.toString(),
                    Icons.assignment_turned_in,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Mevcut Kargolar',
                    _availableCargoes.length.toString(),
                    Icons.local_shipping,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Hızlı işlemler
            Text(
              'Hızlı İşlemler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Kargo Bul',
                    Icons.search,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AvailableCargoesScreen()),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Kargolarım',
                    Icons.list_alt,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyCargoesScreen()),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Mevcut kargolar başlığı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mevcut Kargolar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _loadCargoes,
                      icon: Icon(Icons.refresh, color: Colors.blue),
                      tooltip: 'Yenile',
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AvailableCargoesScreen()),
                      ),
                      child: Text('Tümünü Gör'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Kargo listesi
            _isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Kargolar yükleniyor...'),
                        ],
                      ),
                    ),
                  )
                : _availableCargoes.isEmpty
                    ? Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Şu anda mevcut kargo yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _loadCargoes,
                                icon: Icon(Icons.refresh),
                                label: Text('Yenile'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _availableCargoes
                            .map((cargo) => _buildAvailableCargoCard(cargo))
                            .toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (title.contains('Aldığım')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyCargoesScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AvailableCargoesScreen()),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCargoCard(Map<String, dynamic> cargo) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTakeCargoDialog(cargo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      cargo['description'] ?? 'Açıklama yok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AL',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    cargo['phoneNumber'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Spacer(),
                  Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    CargoHelper.formatWeight(cargo['measure']?['weight']),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    CargoHelper.formatHeight(cargo['measure']?['height']),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      CargoHelper.getSizeDisplayName(cargo['measure']?['size']),
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sürücü Paneli'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCargoes,
            tooltip: 'Verileri Yenile',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          AvailableCargoesScreen(),
          MyCargoesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Kargo Bul',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Kargolarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}