import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/cargo_service.dart';
import '../services/auth_service.dart';
import 'add_cargo_screen.dart';
import 'cargo_list_screen.dart';
import 'profile_screen.dart';

class DistributorHomeScreen extends StatefulWidget {
  @override
  _DistributorHomeScreenState createState() => _DistributorHomeScreenState();
}

class _DistributorHomeScreenState extends State<DistributorHomeScreen> {
  int _currentIndex = 0;
  String? _username;
  List<Map<String, dynamic>> _recentCargoes = [];
  final _secureStorage = FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadRecentCargoes();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null) {
        final name = await AuthService.getNameFromToken(token);
        setState(() {
          _username = name ?? 'Kullanıcı';
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _loadRecentCargoes() async {
    try {
      final result = await CargoService.getDistributorCargoes(size: 5);
      if (result != null && result['content'] != null) {
        setState(() {
          _recentCargoes = List<Map<String, dynamic>>.from(result['content']);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recent cargoes: $e');
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

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadRecentCargoes();
        await _loadUserInfo();
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
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: Colors.blue[600],
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
                        ],
                      ),
                    ),
                    Icon(
                      Icons.local_shipping,
                      size: 40,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
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
                    'Kargo Ekle',
                    Icons.add_box,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddCargoScreen()),
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
                      MaterialPageRoute(builder: (context) => CargoListScreen()),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            // Son kargolar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Kargolarım',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CargoListScreen()),
                  ),
                  child: Text('Tümünü Gör'),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _recentCargoes.isEmpty
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
                                'Henüz kargo eklemediniz',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddCargoScreen()),
                                ),
                                child: Text('İlk Kargonuzu Ekleyin'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _recentCargoes
                            .map((cargo) => _buildCargoCard(cargo))
                            .toList(),
                      ),
          ],
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

  Widget _buildCargoCard(Map<String, dynamic> cargo) {
    final status = cargo['cargoSituation'] ?? 'CREATED';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
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
                  '${cargo['measure']?['weight'] ?? 0} kg',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CREATED':
        return Colors.blue;
      case 'ASSIGNED':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.red;
      case 'EXPIRED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'CREATED':
        return 'Oluşturuldu';
      case 'ASSIGNED':
        return 'Atandı';
      case 'PICKED_UP':
        return 'Alındı';
      case 'DELIVERED':
        return 'Teslim Edildi';
      case 'CANCELLED':
        return 'İptal Edildi';
      case 'FAILED':
        return 'Başarısız';
      case 'EXPIRED':
        return 'Süresi Doldu';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kargo Veren'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          CargoListScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
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
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCargoScreen()),
              ),
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}