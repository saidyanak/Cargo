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
  late AnimationController _fadeController;
  Animation<Offset>? _filterSlideAnimation;
  Animation<double>? _fadeAnimation;

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
    
    // Initialize animations
    _refreshController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _filterController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _filterSlideAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeOutBack,
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
    _loadMyCargoes();
    
    // Start animations
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _filterController.forward();
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

  Future<void> _loadMyCargoes() async {
    print('=== LOADING MY CARGOES ==='); // Debug log
    
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
        size: 15,
      );
      
      print('My cargoes result: $result'); // Debug log
      
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
        
        print('Found ${cargoList.length} cargoes'); // Debug log
        
        setState(() {
          _myCargoes = cargoList.cast<Map<String, dynamic>>();
          _hasMoreData = !(meta['isLast'] ?? true);
          _isLoading = false;
        });
      } else {
        print('Result is null'); // Debug log
        setState(() {
          _myCargoes = [];
          _hasMoreData = false;
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
          gradient: LinearGradient(
            colors: [Colors.orange[600]!, Colors.orange[800]!],
          ),
          onPressed: () => _showPickupDialog(cargo),
        );
      case 'PICKED_UP':
        return _buildAnimatedButton(
          icon: Icons.delivery_dining,
          label: 'Teslim Et',
          gradient: LinearGradient(
            colors: [Colors.green[600]!, Colors.green[800]!],
          ),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[600]!],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Tamamlandı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(25),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[600]!, Colors.orange[800]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Text('Kargo Al', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kargoyu teslim aldığınızı onaylıyor musunuz?',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[800]!.withOpacity(0.2), Colors.orange[600]!.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
                colors: [Colors.orange[600]!, Colors.orange[800]!],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Kargo teslim alındı!'),
                      ],
                    ),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                );
                _loadMyCargoes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text('Teslim Aldım', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Map<String, dynamic> cargo, int index) {
  final status = CargoHelper.getCargoSituation(cargo); // GÜVENLİ ERİŞİM
  final statusColor = CargoHelper.getStatusColor(status);
  final statusText = CargoHelper.getStatusDisplayName(status);
  final statusIcon = CargoHelper.getStatusIcon(status);

  return TweenAnimationBuilder(
    duration: Duration(milliseconds: 600 + (index * 100)),
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
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status - GÜNCELLEME
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        CargoHelper.getDescription(cargo), // GÜVENLİ ERİŞİM
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
                      tag: 'my_cargo_status_${CargoHelper.getCargoId(cargo)}', // GÜVENLİ ERİŞİM
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
                
                // Info section - GÜNCELLEME
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Column(
                    children: [
                      // Contact and weight
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.phone,
                            CargoHelper.getPhoneNumber(cargo), // GÜVENLİ ERİŞİM
                            LinearGradient(colors: [Colors.green[600]!, Colors.green[800]!]),
                          ),
                          Spacer(),
                          _buildInfoChip(
                            Icons.scale,
                            CargoHelper.formatWeight(CargoHelper.getMeasure(cargo)['weight']), // GÜVENLİ ERİŞİM
                            LinearGradient(colors: [Colors.orange[600]!, Colors.orange[800]!]),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Height and size
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.straighten,
                            CargoHelper.formatHeight(CargoHelper.getMeasure(cargo)['height']), // GÜVENLİ ERİŞİM
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
                                  CargoHelper.getSizeDisplayName(CargoHelper.getMeasure(cargo)['size']), // GÜVENLİ ERİŞİM
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
                
                SizedBox(height: 16),
                
                // Location info - GÜNCELLEME
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[900]!.withOpacity(0.3), Colors.blue[800]!.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.green[400]),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Alınacak: ${CargoHelper.formatCoordinates(
                                CargoHelper.getSelfLocation(cargo)['latitude'],
                                CargoHelper.getSelfLocation(cargo)['longitude']
                              )}', // GÜVENLİ ERİŞİM
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.flag, size: 16, color: Colors.red[400]),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Teslim: ${CargoHelper.formatCoordinates(
                                CargoHelper.getTargetLocation(cargo)['latitude'],
                                CargoHelper.getTargetLocation(cargo)['longitude']
                              )}', // GÜVENLİ ERİŞİM
                              style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      icon: Icon(Icons.visibility, size: 16, color: Colors.blue[400]),
                      label: Text('Detaylar', style: TextStyle(color: Colors.blue[400])),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Widget _buildFilterSection() {
    if (_filterSlideAnimation == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[850]!, Colors.grey[900]!],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
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
          gradient: LinearGradient(
            colors: [Colors.grey[850]!, Colors.grey[900]!],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
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
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[800]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.filter_list, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Durum Filtresi:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
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
                child: Text('Temizle', style: TextStyle(color: Colors.blue[400])),
              ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[800]!, Colors.grey[700]!],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatusFilter,
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[400]),
              style: TextStyle(color: Colors.white),
              items: _statusFilterOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight: status == _selectedStatusFilter 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      color: Colors.white,
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
    if (_fadeAnimation == null) {
      return Center(child: CircularProgressIndicator(color: Colors.blue[400]));
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
                        colors: [Colors.blue[800]!.withOpacity(0.2), Colors.blue[600]!.withOpacity(0.1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _selectedStatusFilter != 'Tümü' 
                          ? Icons.search_off 
                          : Icons.local_shipping_outlined,
                      size: 80,
                      color: Colors.blue[400],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              _selectedStatusFilter != 'Tümü'
                  ? 'Bu durumda kargo bulunamadı'
                  : 'Henüz kargo almadınız',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedStatusFilter != 'Tümü') ...[
              SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatusFilter = 'Tümü';
                    });
                  },
                  icon: Icon(Icons.clear_all, color: Colors.white),
                  label: Text('Tüm Kargoları Göster', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCargoes = _getFilteredCargoes();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'Aldığım Kargolar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[850]!, Colors.grey[900]!],
            ),
          ),
        ),
        actions: [
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMyCargoes,
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          _buildFilterSection(),
          
          // Results count
          if (!_isLoading || _myCargoes.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey[900],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[400]),
                  SizedBox(width: 6),
                  Text(
                    '${filteredCargoes.length} kargo bulundu',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          // Cargo list
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: RefreshIndicator(
                onRefresh: _loadMyCargoes,
                color: Colors.blue[400],
                backgroundColor: Colors.grey[800],
                child: _isLoading && _myCargoes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.blue[400]),
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
                                    child: CircularProgressIndicator(color: Colors.blue[400]),
                                  ),
                                );
                              }
                              return _buildCargoCard(filteredCargoes[index], index);
                            },
                          ),
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
    _fadeController.dispose();
    super.dispose();
  }
}