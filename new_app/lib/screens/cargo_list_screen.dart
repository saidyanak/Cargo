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
    });

    try {
      final result = await CargoService.getDistributorCargoes(
        page: _currentPage,
        size: _pageSize,
      );

      if (result != null && result['content'] != null) {
        setState(() {
          _cargoes = List<Map<String, dynamic>>.from(result['content']);
          _hasMoreData = !result['last'];
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

      if (result != null && result['content'] != null) {
        final newCargoes = List<Map<String, dynamic>>.from(result['content']);
        setState(() {
          _cargoes.addAll(newCargoes);
          _currentPage++;
          _hasMoreData = !result['last'];
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

  Widget _buildCargoCard(Map<String, dynamic> cargo) {
    final status = cargo['cargoSituation'] ?? 'CREATED';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
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
                    itemCount: _cargoes.length + (_hasMoreData ? 1 : 0),
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