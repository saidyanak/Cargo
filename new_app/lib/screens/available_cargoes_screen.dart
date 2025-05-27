import 'package:flutter/material.dart';
import 'cargo_detail_screen.dart';
import '../utils/cargo_helper.dart';
import '../services/cargo_service.dart';

class AvailableCargoesScreen extends StatefulWidget {
  @override
  _AvailableCargoesScreenState createState() => _AvailableCargoesScreenState();
}

class _AvailableCargoesScreenState extends State<AvailableCargoesScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _availableCargoes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSizeFilter = 'Tümü';
  int _currentPage = 0;
  bool _hasMoreData = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _refreshController;
  late AnimationController _searchAnimController;
  late AnimationController _fadeController;
  Animation<Offset>? _searchSlideAnimation;
  Animation<double>? _fadeAnimation;

  final List<String> _sizeFilterOptions = ['Tümü', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _refreshController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    
    _searchAnimController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _searchSlideAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _searchAnimController,
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
    _loadAvailableCargoes();
    
    // Start animations
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _searchAnimController.forward();
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

  Future<void> _loadAvailableCargoes() async {
    print('=== LOADING AVAILABLE CARGOES ==='); // Debug log
    
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _availableCargoes.clear();
      _hasMoreData = true;
    });

    // Animate refresh icon
    _refreshController.repeat();

    try {
      final result = await CargoService.getAllCargoes(
        page: _currentPage,
        size: 20,
      );
      
      print('Available cargoes result: $result'); // Debug log
      
      if (result != null) {
        final List<dynamic> cargoList = result['data'] ?? [];
        final Map<String, dynamic> meta = result['meta'] ?? {};
        
        // Sadece oluşturulmuş kargoları filtrele
        final availableCargoes = cargoList
            .where((cargo) => cargo['cargoSituation'] == 'CREATED')
            .toList();
        
        print('Found ${availableCargoes.length} available cargoes'); // Debug log
        
        setState(() {
          _availableCargoes = availableCargoes.cast<Map<String, dynamic>>();
          _hasMoreData = !(meta['isLast'] ?? true);
          _isLoading = false;
        });
      } else {
        print('Result is null'); // Debug log
        setState(() {
          _availableCargoes = [];
          _hasMoreData = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading available cargoes: $e');
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
      final result = await CargoService.getAllCargoes(
        page: _currentPage + 1,
        size: 20,
      );

      if (result != null) {
        final List<dynamic> newCargoes = result['data'] ?? [];
        final Map<String, dynamic> meta = result['meta'] ?? {};
        
        // Sadece oluşturulmuş kargoları filtrele
        final availableCargoes = newCargoes
            .where((cargo) => cargo['cargoSituation'] == 'CREATED')
            .toList();
        
        setState(() {
          _availableCargoes.addAll(availableCargoes.cast<Map<String, dynamic>>());
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
    return _availableCargoes.where((cargo) {
      // Arama filtresi
      final matchesSearch = _searchQuery.isEmpty ||
          (cargo['description'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (cargo['phoneNumber'] ?? '').contains(_searchQuery);

      // Boyut filtresi
      final matchesSize = _selectedSizeFilter == 'Tümü' ||
          cargo['measure']?['size'] == _selectedSizeFilter;

      return matchesSearch && matchesSize;
    }).toList();
  }

  Future<void> _takeCargo(Map<String, dynamic> cargo) async {
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
              CircularProgressIndicator(color: Colors.green[400]),
              SizedBox(height: 16),
              Text('Kargo alınıyor...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await CargoService.takeCargo(cargo['id']);
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
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
          ),
        );
        _loadAvailableCargoes(); // Listeyi yenile
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
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Bir hata oluştu: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showTakeCargoDialog(Map<String, dynamic> cargo) {
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
                  colors: [Colors.green[600]!, Colors.green[800]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_shipping, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Text('Kargo Al', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu kargoyu almak istediğinizden emin misiniz?',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[800]!.withOpacity(0.2), Colors.green[600]!.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.green[400]),
                        SizedBox(width: 4),
                        Text('Açıklama:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Text(cargo['description'] ?? 'Açıklama yok', style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.scale, size: 16, color: Colors.orange[400]),
                        SizedBox(width: 4),
                        Text('Ağırlık: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(CargoHelper.formatWeight(cargo['measure']?['weight']), style: TextStyle(color: Colors.white70)),
                        SizedBox(width: 16),
                        Icon(Icons.aspect_ratio, size: 16, color: Colors.purple[400]),
                        SizedBox(width: 4),
                        Text('Boyut: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(CargoHelper.getSizeDisplayName(cargo['measure']?['size']), style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.blue[400]),
                        SizedBox(width: 4),
                        Text('Telefon: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(cargo['phoneNumber'] ?? '', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey[400])),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[800]!],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _takeCargo(cargo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text('Kargoyu Al', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Map<String, dynamic> cargo, int index) {
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
              color: Colors.green.withOpacity(0.1),
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
                  // Üst kısım - Başlık ve al butonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[600]!, Colors.green[800]!],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showTakeCargoDialog(cargo),
                            borderRadius: BorderRadius.circular(25),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'AL',
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
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Info section
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
                              cargo['phoneNumber'] ?? 'Telefon yok',
                              LinearGradient(colors: [Colors.blue[600]!, Colors.blue[800]!]),
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
                        // Height and size
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
                                  colors: [Colors.indigo[600]!, Colors.indigo[800]!],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withOpacity(0.3),
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
                  
                  SizedBox(height: 16),
                  
                  // Konum bilgisi
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal[900]!.withOpacity(0.3), Colors.teal[800]!.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.green[400]),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Alınacak: ${cargo['selfLocation']?['latitude']?.toStringAsFixed(4) ?? 'N/A'}, ${cargo['selfLocation']?['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
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
                                'Teslim: ${cargo['targetLocation']?['latitude']?.toStringAsFixed(4) ?? 'N/A'}, ${cargo['targetLocation']?['longitude']?.toStringAsFixed(4) ?? 'N/A'}',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Action section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        icon: Icon(Icons.visibility, size: 16, color: Colors.teal[400]),
                        label: Text('Detayları Görüntüle', style: TextStyle(color: Colors.teal[400])),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.teal.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
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

  Widget _buildSearchSection() {
    if (_searchSlideAnimation == null) {
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
        child: _buildSearchContent(),
      );
    }

    return SlideTransition(
      position: _searchSlideAnimation!,
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
        child: _buildSearchContent(),
      ),
    );
  }

  Widget _buildSearchContent() {
    return Column(
      children: [
        // Arama kutusu
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[800]!, Colors.grey[700]!],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Kargo ara...',
              hintStyle: TextStyle(color: Colors.white60),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        SizedBox(height: 12),
        
        // Boyut filtresi
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[600]!, Colors.teal[800]!],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.filter_list, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Boyut Filtresi:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[800]!, Colors.grey[700]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSizeFilter,
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.teal[400]),
                    style: TextStyle(color: Colors.white),
                    items: _sizeFilterOptions.map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text(
                          size == 'Tümü' ? size : CargoHelper.getSizeDisplayName(size),
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSizeFilter = value!;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_fadeAnimation == null) {
      return Center(child: CircularProgressIndicator(color: Colors.green[400]));
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
                        colors: [Colors.green[800]!.withOpacity(0.2), Colors.green[600]!.withOpacity(0.1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü'
                          ? Icons.search_off 
                          : Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.green[400],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü'
                  ? 'Arama kriterlerinize uygun kargo bulunamadı'
                  : 'Şu anda mevcut kargo yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü'
                  ? 'Farklı bir filtre deneyin'
                  : 'Yeni kargolar eklendiğinde burada görünecek',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü') ...[
              SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[600]!, Colors.teal[800]!],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _selectedSizeFilter = 'Tümü';
                      _searchController.clear();
                    });
                  },
                  icon: Icon(Icons.clear_all, color: Colors.white),
                  label: Text('Filtreleri Temizle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          'Mevcut Kargolar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[600]!, Colors.green[800]!],
            ),
          ),
        ),
        actions: [
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadAvailableCargoes,
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildSearchSection(),
          
          // Results count
          if (!_isLoading || _availableCargoes.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.green[400]),
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
                  if (_searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedSizeFilter = 'Tümü';
                          _searchController.clear();
                        });
                      },
                      child: Text('Filtreleri Temizle', style: TextStyle(color: Colors.teal[400])),
                    ),
                ],
              ),
            ),
          
          // Cargo list
          Expanded(
            child: Container(
              color: Colors.grey[900],
              child: RefreshIndicator(
                onRefresh: _loadAvailableCargoes,
                color: Colors.green[400],
                backgroundColor: Colors.grey[800],
                child: _isLoading && _availableCargoes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.green[400]),
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
                                    child: CircularProgressIndicator(color: Colors.green[400]),
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
    _searchController.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    _searchAnimController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}