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
  late AnimationController _fadeController;
  Animation<double>? _fabScaleAnimation;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _refreshController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Scroll listener
    _scrollController.addListener(_onScroll);
    
    // Load data immediately - BU EKSİKTİ!
    _loadCargoes();
    
    // Start animations
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _fabController.forward();
        _fadeController.forward();
      }
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
    print('=== LOADING DISTRIBUTOR CARGOES ==='); // Debug log
    
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _cargoes.clear();
      _hasMoreData = true;
    });

    // Animate refresh icon
    _refreshController.repeat();

    try {
      final result = await CargoService.getDistributorCargoes(
        page: _currentPage,
        size: _pageSize,
      );

      print('Service result: $result'); // Debug log

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
        
        print('Cargo list: $cargoList'); // Debug log
        print('Meta: $meta'); // Debug log
        
        setState(() {
          _cargoes = cargoList.cast<Map<String, dynamic>>();
          _hasMoreData = !(meta['isLast'] ?? true);
          _isLoading = false;
        });
      } else {
        print('Result is null'); // Debug log
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
              Expanded(child: Text('Kargolar yüklenirken hata oluştu: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.all(16),
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
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[850]!, Colors.grey[900]!],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.red[400]),
              SizedBox(height: 16),
              Text('Kargo siliniyor...', style: TextStyle(color: Colors.white)),
            ],
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
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
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
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showDeleteDialog(Map<String, dynamic> cargo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[600]!, Colors.red[800]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Text('Kargo Sil', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu kargoyu silmek istediğinizden emin misiniz?',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[800]!.withOpacity(0.2), Colors.red[600]!.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                '"${cargo['description']}"',
                style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey[400])),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[600]!, Colors.red[800]!],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCargo(cargo['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
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
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[850]!,
              Colors.grey[900]!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
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
                          color: Colors.white,
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
                          gradient: LinearGradient(
                            colors: [statusColor.withOpacity(0.8), statusColor],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: Colors.white,
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
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    children: [
                      // İlk satır
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.phone,
                            cargo['phoneNumber'] ?? 'Telefon yok',
                            LinearGradient(colors: [Colors.green[600]!, Colors.green[800]!]),
                          ),
                          Spacer(),
                          _buildInfoChip(
                            Icons.scale,
                            CargoHelper.formatWeight(cargo['measure']?['weight']),
                            LinearGradient(colors: [Colors.orange[600]!, Colors.orange[800]!]),
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
                            LinearGradient(colors: [Colors.purple[600]!, Colors.purple[800]!]),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[600]!, Colors.blue[800]!],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.aspect_ratio, size: 16, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  CargoHelper.getSizeDisplayName(cargo['measure']?['size']),
                                  style: TextStyle(
                                    color: Colors.white,
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
                      Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                      SizedBox(width: 6),
                      Text(
                        'Oluşturulma: ${CargoHelper.formatDate(cargo['createdAt'])}',
                        style: TextStyle(
                          color: Colors.grey[400],
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
                        gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[800]!]),
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
                      gradient: canEdit 
                          ? LinearGradient(colors: [Colors.red[600]!, Colors.red[800]!])
                          : LinearGradient(colors: [Colors.grey[600]!, Colors.grey[800]!]),
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

  Widget _buildInfoChip(IconData icon, String text, LinearGradient gradient) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
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
    required LinearGradient gradient,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null ? Colors.grey[700] : null,
        borderRadius: BorderRadius.circular(25),
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_fadeAnimation == null) {
      return Center(child: CircularProgressIndicator(color: Colors.purple[400]));
    }

    return FadeTransition(
      opacity: _fadeAnimation!,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: Duration(seconds: 2),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[800]!.withOpacity(0.2), Colors.purple[600]!.withOpacity(0.1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.purple[400],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              'Henüz kargo eklemediniz',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'İlk kargonuzu ekleyerek başlayın!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 32),
            Hero(
              tag: 'add_cargo_button',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[600]!, Colors.purple[800]!],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
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
                  icon: Icon(Icons.add, size: 24, color: Colors.white),
                  label: Text(
                    'İlk Kargonuzu Ekleyin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Kargolarım',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple[600]!, Colors.purple[800]!],
            ),
          ),
        ),
        actions: [
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadCargoes,
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[900],
        child: RefreshIndicator(
          onRefresh: _loadCargoes,
          color: Colors.purple[400],
          backgroundColor: Colors.grey[800],
          child: _isLoading && _cargoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.purple[400]),
                      SizedBox(height: 16),
                      Text(
                        'Kargolar yükleniyor...',
                        style: TextStyle(
                          color: Colors.white70,
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
                              child: CircularProgressIndicator(color: Colors.purple[400]),
                            ),
                          );
                        }
                        return _buildCargoCard(_cargoes[index], index);
                      },
                    ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation ?? AlwaysStoppedAnimation(1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[600]!, Colors.purple[800]!],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              'Kargo Ekle',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    _fabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}