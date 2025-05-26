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
  int _currentPage = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> _statusFilterOptions = [
    'Tümü',
    'Atandı',
    'Alındı',
    'Teslim Edildi',
    'İptal Edildi',
  ];

  @override
  void initState() {
    super.initState();
    _loadMyCargoes();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreCargoes();
      }
    }
  }

  Future<void> _loadMyCargoes() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _myCargoes.clear();
      _hasMoreData = true;
    });

    try {
      final result = await CargoService.getDriverCargoes(
        page: _currentPage,
        size: 10,
      );
      
      if (result != null) {
        final List<dynamic> cargoList = result['data'] ?? [];
        final Map<String, dynamic> meta = result['meta'] ?? {};
        
        setState(() {
          _myCargoes = cargoList.cast<Map<String, dynamic>>();
          _hasMoreData = !(meta['isLast'] ?? true);
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

  Future<void> _loadMoreCargoes() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CargoService.getDriverCargoes(
        page: _currentPage + 1,
        size: 10,
      );

      if (result != null) {
        final List<dynamic> newCargoes = result['data'] ?? [];
        final Map<String, dynamic> meta = result['meta'] ?? {};
        
        setState(() {
          _myCargoes.addAll(newCargoes.cast<Map<String, dynamic>>());
          _currentPage++;
          _hasMoreData = !(meta['isLast'] ?? true);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading more cargoes: $e');
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
      case 'İptal Edildi':
        filterStatus = 'CANCELLED';
        break;
      default:
        return _myCargoes;
    }

    return _myCargoes.where((cargo) => cargo['cargoSituation'] == filterStatus).toList();
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
              // Burada backend API çağrısı yapılacak (pickup işlemi için ayrı endpoint)
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
    final statusColor = CargoHelper.getStatusColor(status);
    final statusText = CargoHelper.getStatusDisplayName(status);

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
              
              // Konum bilgileri
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.green[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Alınacak: ${cargo['selfLocation']?['latitude']?.toStringAsFixed(4) ?? 'N/A'}, ${cargo['selfLocation']?['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
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
                      'Teslim: ${cargo['targetLocation']?['latitude']?.toStringAsFixed(4) ?? 'N/A'}, ${cargo['targetLocation']?['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
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
          if (!_isLoading || _myCargoes.isNotEmpty)
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
              child: _isLoading && _myCargoes.isEmpty
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
                          controller: _scrollController,
                          itemCount: filteredCargoes.length + (_hasMoreData && _isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredCargoes.length) {
                              return Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildCargoCard(filteredCargoes[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}