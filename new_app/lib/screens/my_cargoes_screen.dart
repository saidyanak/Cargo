import 'package:flutter/material.dart';
import '../services/cargo_service.dart';
import 'cargo_detail_screen.dart';
import 'delivery_screen.dart';
import '../utils/cargo_helper.dart';

class MyCargoesScreen extends StatefulWidget {
  @override
  _MyCargoesScreenState createState() => _MyCargoesScreenState();
}

class _MyCargoesScreenState extends State<MyCargoesScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _myCargoes = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'Tümü';
  int _currentPage = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _refreshController;
  late AnimationController _filterController;
  Animation<Offset>? _filterSlideAnimation; // nullable yaptık

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
    
    // Initialize animations
    _refreshController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _filterController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _filterSlideAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.0), // Yukarıdan aşağıya kayma
      end: Offset(0.0, 0.0),    // Normal pozisyon
    ).animate(CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOut,
    ));
    
    // Start filter animation
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) _filterController.forward();
    });
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

    // Animate refresh icon
    _refreshController.repeat();

    try {
      final result = await CargoService.getDriverCargoes(
        page: _currentPage,
        size: 15, // Increased page size
      );
      
      if (result != null) {
        List<dynamic> cargoList = [];
        Map<String, dynamic> meta = {};
        
        // Backend response yapısını kontrol et
        if (result.containsKey('data') && result['data'] is List) {
          cargoList = result['data'] as List<dynamic>;
          meta = result['meta'] as Map<String, dynamic>? ?? {};
        } else if (result is List) {
          cargoList = result as List<dynamic>;
          meta = {'isLast': true};
        } else if (result.containsKey('content') && result['content'] is List) {
          cargoList = result['content'] as List<dynamic>;
          meta = {
            'isLast': result['last'] ?? true,
            'totalItems': result['totalElements'] ?? 0,
          };
        }
        
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
      final result = await CargoService.getDriverCargoes(
        page: _currentPage + 1,
        size: 15,
      );

      if (result != null) {
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
          };
        }
        
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
        return _buildAnimatedButton(
          icon: Icons.local_shipping,
          label: 'Kargoyu Al',
          color: Colors.orange,
          onPressed: () => _showPickupDialog(cargo),
        );
      case 'PICKED_UP':
        return _buildAnimatedButton(
          icon: Icons.delivery_dining,
          label: 'Teslim Et',
          color: Colors.green,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryScreen(cargo: cargo),
              ),
            ).then((_) => _loadMyCargoes());
          },
        );
      case 'DELIVERED':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                'Tamamlandı',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildAnimatedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
            label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 4,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPickupDialog(Map<String, dynamic> cargo) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.orange),
            SizedBox(width: 8),
            Text('Kargo Al'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kargoyu teslim aldığınızı onaylıyor musunuz?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                '"${cargo['description']}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
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
              // Show success animation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Kargo teslim alındı!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              _loadMyCargoes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Teslim Aldım'),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Map<String, dynamic> cargo, int index) {
    final status = cargo['cargoSituation'] ?? '';
    final statusColor = CargoHelper.getStatusColor(status);
    final statusText = CargoHelper.getStatusDisplayName(status);
    final statusIcon = CargoHelper.getStatusIcon(status);

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 150)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(100 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CargoDetailScreen(cargo: cargo, isDriver: true),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  statusColor.withOpacity(0.03),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with status
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
                        tag: 'my_cargo_status_${cargo['id']}',
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
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
                  
                  // Info section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Contact and weight
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
                        // Height and size
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
                  
                  SizedBox(height: 16),
                  
                  // Location info
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.green[600]),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Alınacak: ${cargo['selfLocation']?['address'] ?? 'Koordinat: ${cargo['selfLocation']?['latitude']?.toStringAsFixed(4) ?? 'N/A'}, ${cargo['selfLocation']?['longitude']?.toStringAsFixed(4) ?? 'N/A'}'}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.flag, size: 16, color: Colors.red[600]),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Teslim: ${cargo['targetLocation']?['address'] ?? 'Koordinat: ${cargo['targetLocation']?['latitude']?.toStringAsFixed(4) ?? 'N/A'}, ${cargo['targetLocation']?['longitude']?.toStringAsFixed(4) ?? 'N/A'}'}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Action section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CargoDetailScreen(cargo: cargo, isDriver: true),
                            ),
                          );
                        },
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('Detaylar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                      _getStatusAction(cargo),
                    ],
                  ),
                ],
              ),
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

  Widget _buildFilterSection() {
    // Animasyon hazır değilse basit container döndür
    if (_filterSlideAnimation == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _buildFilterContent(),
      );
    }

    return SlideTransition(
      position: _filterSlideAnimation!,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _buildFilterContent(),
      ),
    );
  }

  Widget _buildFilterContent() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.filter_list, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Durum Filtresi:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Spacer(),
            if (_selectedStatusFilter != 'Tümü')
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatusFilter = 'Tümü';
                  });
                },
                child: Text('Temizle'),
              ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatusFilter,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue),
              items: _statusFilterOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight: status == _selectedStatusFilter 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
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
      ],
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
                _selectedStatusFilter != 'Tümü' 
                    ? Icons.search_off 
                    : Icons.local_shipping_outlined,
                size: 80,
                color: Colors.blue[300],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _selectedStatusFilter != 'Tümü'
                ? 'Bu durumda kargo bulunamadı'
                : 'Henüz kargo almadınız',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _selectedStatusFilter != 'Tümü'
                ? 'Farklı bir filtre deneyin'
                : 'Mevcut kargolardan birini alarak başlayın!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedStatusFilter != 'Tümü') ...[
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatusFilter = 'Tümü';
                });
              },
              icon: Icon(Icons.clear_all),
              label: Text('Tüm Kargoları Göster'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCargoes = _getFilteredCargoes();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Aldığım Kargolar',
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
              onPressed: _loadMyCargoes,
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
      body: Column(
        children: [
          // Filter section
          _buildFilterSection(),
          
          // Results count
          if (!_isLoading || _myCargoes.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    '${filteredCargoes.length} kargo bulundu',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          // Cargo list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMyCargoes,
              color: Colors.blue,
              child: _isLoading && _myCargoes.isEmpty
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
                  : filteredCargoes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: filteredCargoes.length + (_hasMoreData && _isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == filteredCargoes.length) {
                              return Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(color: Colors.blue),
                                ),
                              );
                            }
                            return _buildCargoCard(filteredCargoes[index], index);
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
    _refreshController.dispose();
    _filterController.dispose();
    super.dispose();
  }
}