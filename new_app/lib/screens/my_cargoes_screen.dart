import 'package:flutter/material.dart';
import '../services/cargo_service.dart';
import 'cargo_detail_screen.dart';
import 'delivery_screen.dart';

class MyCargoesScreen extends StatefulWidget {
  @override
  _MyCargoesScreenState createState() => _MyCargoesScreenState();
}

class _MyCargoesScreenState extends State<MyCargoesScreen> {
  List<Map<String, dynamic>> _myCargoes = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'Tümü';

  final List<String> _statusFilterOptions = [
    'Tümü',
    'Atandı',
    'Alındı',
    'Teslim Edildi',
  ];

  @override
  void initState() {
    super.initState();
    _loadMyCargoes();
  }

  Future<void> _loadMyCargoes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CargoService.getDriverCargoes(size: 50);
      if (result != null && result['content'] != null) {
        setState(() {
          _myCargoes = List<Map<String, dynamic>>.from(result['content']);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading my cargoes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredCargoes() {
    if (_selectedStatusFilter == 'Tümü') {
      return _myCargoes;
    }

    String filterStatus;
    switch (_selectedStatusFilter) {
      case 'Atandı':
        filterStatus = 'ASSIGNED';
        break;
      case 'Alındı':
        filterStatus = 'PICKED_UP';
        break;
      case 'Teslim Edildi':
        filterStatus = 'DELIVERED';
        break;
      default:
        return _myCargoes;
    }

    return _myCargoes.where((cargo) => cargo['cargoSituation'] == filterStatus).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ASSIGNED':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
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
      default:
        return status;
    }
  }

  Widget _getStatusAction(Map<String, dynamic> cargo) {
    final status = cargo['cargoSituation'];
    
    switch (status) {
      case 'ASSIGNED':
        return ElevatedButton(
          onPressed: () => _showPickupDialog(cargo),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Text('Kargoyu Al', style: TextStyle(fontSize: 12)),
        );
      case 'PICKED_UP':
        return ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryScreen(cargo: cargo),
              ),
            ).then((_) => _loadMyCargoes());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Text('Teslim Et', style: TextStyle(fontSize: 12)),
        );
      case 'DELIVERED':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '✓ Tamamlandı',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }

  Future<void> _showPickupDialog(Map<String, dynamic> cargo) async {
    // Bu fonksiyon gerçek uygulamada kargo alma işlemini simüle eder
    // Backend'de ASSIGNED durumundan PICKED_UP durumuna geçiş yapılır
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kargo Al'),
        content: Text('Kargoyu teslim aldığınızı onaylıyor musunuz?\n\n"${cargo['description']}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Burada backend API çağrısı yapılacak (şimdilik simüle ediyoruz)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kargo teslim alındı!'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadMyCargoes();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Teslim Aldım', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Map<String, dynamic> cargo) {
    final status = cargo['cargoSituation'] ?? '';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CargoDetailScreen(cargo: cargo, isDriver: true),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - Başlık ve durum
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
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
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
              SizedBox(height: 12),
              
              // Bilgiler
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
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${cargo['measure']?['height'] ?? 0} cm',
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
                      cargo['measure']?['size'] ?? 'M',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Konum bilgileri
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.green[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Alınacak: ${cargo['selfLocation']?['latitude']?.toStringAsFixed(4)}, ${cargo['selfLocation']?['longitude']?.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: Colors.red[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Teslim: ${cargo['targetLocation']?['latitude']?.toStringAsFixed(4)}, ${cargo['targetLocation']?['longitude']?.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Alt kısım - Aksiyon butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _getStatusAction(cargo),
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
    final filteredCargoes = _getFilteredCargoes();

    return Scaffold(
      appBar: AppBar(
        title: Text('Aldığım Kargolar'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMyCargoes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Durum filtresi
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Text(
                  'Durum Filtresi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        isExpanded: true,
                        items: _statusFilterOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatusFilter = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sonuç sayısı
          if (!_isLoading)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredCargoes.length} kargo bulundu',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  if (_selectedStatusFilter != 'Tümü')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatusFilter = 'Tümü';
                        });
                      },
                      child: Text('Filtreyi Temizle'),
                    ),
                ],
              ),
            ),
          
          // Kargo listesi
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMyCargoes,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredCargoes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                _selectedStatusFilter != 'Tümü'
                                    ? 'Bu durumda kargo bulunamadı'
                                    : 'Henüz kargo almadınız',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_selectedStatusFilter != 'Tümü') ...[
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStatusFilter = 'Tümü';
                                    });
                                  },
                                  child: Text('Tüm Kargoları Göster'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCargoes.length,
                          itemBuilder: (context, index) {
                            return _buildCargoCard(filteredCargoes[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}