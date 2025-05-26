import 'package:flutter/material.dart';
import '../services/cargo_service.dart';
import 'add_cargo_screen.dart';
import 'edit_cargo_screen.dart';

class CargoListScreen extends StatefulWidget {
  @override
  _CargoListScreenState createState() => _CargoListScreenState();
}

class _CargoListScreenState extends State<CargoListScreen> {
  List<Map<String, dynamic>> _cargoes = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCargoes();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreCargoes();
      }
    }
  }

  Future<void> _loadCargoes() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _cargoes.clear();
      _hasMoreData = true;
    });

    try {
      print('=== LOADING DISTRIBUTOR CARGOES ===');
      final result = await CargoService.getDistributorCargoes(
        page: _currentPage,
        size: _pageSize,
      );

      print('Service result: $result');

      if (result != null) {
        // Backend response yapısını kontrol et
        List<dynamic> cargoList = [];
        Map<String, dynamic> meta = {};
        
        // Eğer data key'i varsa onu kullan
        if (result.containsKey('data') && result['data'] is List) {
          cargoList = result['data'] as List<dynamic>;
          meta = result['meta'] as Map<String, dynamic>? ?? {};
        } 
        // Eğer direkt array dönüyorsa
        else if (result is List) {
          cargoList = result as List<dynamic>;
          meta = {'isLast': true}; // Son sayfa olarak işaretle
        }
        // Eğer content key'i varsa (Spring Boot default)
        else if (result.containsKey('content') && result['content'] is List) {
          cargoList = result['content'] as List<dynamic>;
          meta = {
            'isLast': result['last'] ?? true,
            'totalItems': result['totalElements'] ?? 0,
            'currentPage': result['number'] ?? 0,
            'pageSize': result['size'] ?? _pageSize,
            'isFirst': result['first'] ?? true,
          };
        }
        
        print('Cargo list: $cargoList');
        print('Meta: $meta');
        
        setState(() {
          _cargoes = cargoList.cast<Map<String, dynamic>>();
          _hasMoreData = !(meta['isLast'] ?? true);
          _isLoading = false;
        });
      } else {
        print('Result is null');
        setState(() {
          _cargoes = [];
          _hasMoreData = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading cargoes: $e');
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
      final result = await CargoService.getDistributorCargoes(
        page: _currentPage + 1,
        size: _pageSize,
      );

      if (result != null) {
        // Backend response yapısını kontrol et
        List<dynamic> newCargoes = [];
        Map<String, dynamic> meta = {};
        
        if (result.containsKey('data') && result['data'] is List) {
          newCargoes = result['data'] as List<dynamic>;
          meta = result['meta'] as Map<String, dynamic>? ?? {};
        } else if (result is List) {
          newCargoes = result as List<dynamic>;
          meta = {'isLast': true};
        } else if (result.containsKey('content') && result['content'] is List) {
          newCargoes = result['content'] as List<dynamic>;
          meta = {
            'isLast': result['last'] ?? true,
            'totalItems': result['totalElements'] ?? 0,
            'currentPage': result['number'] ?? 0,
            'pageSize': result['size'] ?? _pageSize,
            'isFirst': result['first'] ?? true,
          };
        }
        
        setState(() {
          _cargoes.addAll(newCargoes.cast<Map<String, dynamic>>());
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

  Future<void> _deleteCargo(int cargoId) async {
    final success = await CargoService.deleteCargo(cargoId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kargo başarıyla silindi!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCargoes(); // Listeyi yenile
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kargo silinirken hata oluştu!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(Map<String, dynamic> cargo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kargo Sil'),
        content: Text('Bu kargoyu silmek istediğinizden emin misiniz?\n\n"${cargo['description']}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCargo(cargo['id']);
            },
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Map<String, dynamic> cargo) {
    final status = cargo['cargoSituation'] ?? 'CREATED';
    final statusColor = CargoHelper.getStatusColor(status);
    final statusText = CargoHelper.getStatusDisplayName(status);
    final canEdit = status == 'CREATED'; // Sadece oluşturulmuş kargolar düzenlenebilir

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            
            // Tarih bilgisi
            if (cargo['createdAt'] != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Oluşturulma: ${CargoHelper.formatDate(cargo['createdAt'])}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 16),
            
            // Alt butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canEdit) ...[
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditCargoScreen(cargo: cargo),
                        ),
                      );
                      if (result == true) {
                        _loadCargoes(); // Listeyi yenile
                      }
                    },
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Düzenle'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: canEdit ? () => _showDeleteDialog(cargo) : null,
                  icon: Icon(Icons.delete, size: 16),
                  label: Text('Sil'),
                  style: TextButton.styleFrom(
                    foregroundColor: canEdit ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kargolarım'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCargoes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCargoes,
        child: _isLoading && _cargoes.isEmpty
            ? Center(child: CircularProgressIndicator())
            : _cargoes.isEmpty
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
                          'Henüz kargo eklemediniz',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddCargoScreen(),
                              ),
                            );
                            if (result == true) {
                              _loadCargoes();
                            }
                          },
                          icon: Icon(Icons.add),
                          label: Text('İlk Kargonuzu Ekleyin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _cargoes.length + (_hasMoreData && _isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _cargoes.length) {
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildCargoCard(_cargoes[index]);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCargoScreen()),
          );
          if (result == true) {
            _loadCargoes();
          }
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}