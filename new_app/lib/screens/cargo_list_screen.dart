import 'package:flutter/material.dart';
import '../services/cargo_service.dart';
import 'add_cargo_screen.dart';
import 'edit_cargo_screen.dart';
import '../utils/cargo_helper.dart';

class CargoListScreen extends StatefulWidget {
  @override
  _CargoListScreenState createState() => _CargoListScreenState();
}

class _CargoListScreenState extends State<CargoListScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _cargoes = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  
  // Animation controllers
  late AnimationController _refreshController;
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadCargoes();
    _scrollController.addListener(_onScroll);
    
    // Initialize animations
    _refreshController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    // Start FAB animation
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
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

    // Animate refresh icon
    _refreshController.repeat();

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
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Kargolar yüklenirken hata oluştu')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      _refreshController.stop();
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
    // Show loading dialog
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
                Text('Kargo siliniyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await CargoService.deleteCargo(cargoId);
      Navigator.pop(context); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Kargo başarıyla silindi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadCargoes(); // Listeyi yenile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Kargo silinirken hata oluştu!'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showDeleteDialog(Map<String, dynamic> cargo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Kargo Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bu kargoyu silmek istediğinizden emin misiniz?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${cargo['description']}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCargo(cargo['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Map<String, dynamic> cargo, int index) {
    final status = cargo['cargoSituation'] ?? 'CREATED';
    final statusColor = CargoHelper.getStatusColor(status);
    final statusText = CargoHelper.getStatusDisplayName(status);
    final canEdit = status == 'CREATED'; // Sadece oluşturulmuş kargolar düzenlenebilir
    final statusIcon = CargoHelper.getStatusIcon(status);

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                statusColor.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım - Başlık ve durum
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cargo['description'] ?? 'Açıklama yok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12),
                    Hero(
                      tag: 'status_${cargo['id']}',
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Bilgi kartları
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // İlk satır
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.phone,
                            cargo['phoneNumber'] ?? 'Telefon yok',
                            Colors.green,
                          ),
                          Spacer(),
                          _buildInfoChip(
                            Icons.scale,
                            CargoHelper.formatWeight(cargo['measure']?['weight']),
                            Colors.orange,
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // İkinci satır
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.straighten,
                            CargoHelper.formatHeight(cargo['measure']?['height']),
                            Colors.purple,
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.aspect_ratio, size: 16, color: Colors.blue),
                                SizedBox(width: 4),
                                Text(
                                  CargoHelper.getSizeDisplayName(cargo['measure']?['size']),
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tarih bilgisi
                if (cargo['createdAt'] != null) ...[
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Text(
                        'Oluşturulma: ${CargoHelper.formatDate(cargo['createdAt'])}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                
                SizedBox(height: 20),
                
                // Alt butonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEdit) ...[
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Düzenle',
                        color: Colors.blue,
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
                      ),
                      SizedBox(width: 12),
                    ],
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Sil',
                      color: canEdit ? Colors.red : Colors.grey,
                      onPressed: canEdit ? () => _showDeleteDialog(cargo) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            duration: Duration(seconds: 2),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: Colors.blue[300],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Henüz kargo eklemediniz',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'İlk kargonuzu ekleyerek başlayın!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          Hero(
            tag: 'add_cargo_button',
            child: ElevatedButton.icon(
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
              icon: Icon(Icons.add, size: 24),
              label: Text(
                'İlk Kargonuzu Ekleyin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kargolarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadCargoes,
              tooltip: 'Yenile',
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[600]!, Colors.blue[800]!],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCargoes,
        color: Colors.blue,
        child: _isLoading && _cargoes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Kargolar yükleniyor...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : _cargoes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: _cargoes.length + (_hasMoreData && _isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _cargoes.length) {
                        return Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.blue),
                          ),
                        );
                      }
                      return _buildCargoCard(_cargoes[index], index);
                    },
                  ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
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
          foregroundColor: Colors.white,
          icon: Icon(Icons.add),
          label: Text(
            'Kargo Ekle',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    _fabController.dispose();
    super.dispose();
  }
}