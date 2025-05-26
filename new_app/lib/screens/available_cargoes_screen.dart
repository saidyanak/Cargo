import 'package:flutter/material.dart';
import '../services/cargo_service.dart';
import 'cargo_detail_screen.dart';

class AvailableCargoesScreen extends StatefulWidget {
  @override
  _AvailableCargoesScreenState createState() => _AvailableCargoesScreenState();
}

class _AvailableCargoesScreenState extends State<AvailableCargoesScreen> {
  List<Map<String, dynamic>> _availableCargoes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSizeFilter = 'Tümü';
  int _currentPage = 0;
  bool _hasMoreData = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _sizeFilterOptions = ['Tümü', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _loadAvailableCargoes();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMoreData) {
        _loadMoreCargoes();
      }
    }
  }

  Future<void> _loadAvailableCargoes() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _availableCargoes.clear();
      _hasMoreData = true;
    });

    try {
      final result = await CargoService.getAllCargoes(
        page: _currentPage,
        size: 20,
      );
      
      if (result != null) {
        final List<dynamic> cargoList = result['data'] ?? [];
        final Map<String, dynamic> meta = result['meta'] ?? {};
        
        // Sadece oluşturulmuş kargoları filtrele
        final availableCargoes = cargoList
            .where((cargo) => cargo['cargoSituation'] == 'CREATED')
            .toList();
        
        setState(() {
          _availableCargoes = availableCargoes.cast<Map<String, dynamic>>();
          _hasMoreData = !(meta['isLast'] ?? true);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading available cargoes: $e');
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
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await CargoService.takeCargo(cargo['id']);
      Navigator.pop(context); // Loading dialog'u kapat

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kargo başarıyla alındı!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAvailableCargoes(); // Listeyi yenile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kargo alınırken hata oluştu!'),
            backgroundColor: Colors.red,
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

  void _showTakeCargoDialog(Map<String, dynamic> cargo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kargo Al'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bu kargoyu almak istediğinizden emin misiniz?'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Açıklama:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(cargo['description'] ?? 'Açıklama yok'),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Ağırlık: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(CargoHelper.formatWeight(cargo['measure']?['weight'])),
                        Spacer(),
                        Text('Boyut: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(CargoHelper.getSizeDisplayName(cargo['measure']?['size'])),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Telefon: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(cargo['phoneNumber'] ?? ''),
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
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _takeCargo(cargo);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Kargoyu Al', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoCard(Map<String, dynamic> cargo) {
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
              // Üst kısım - Başlık ve al butonu
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
                  ElevatedButton(
                    onPressed: () => _showTakeCargoDialog(cargo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Al', style: TextStyle(fontSize: 12)),
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
              SizedBox(height: 8),
              
              // Konum bilgisi
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
        title: Text('Mevcut Kargolar'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAvailableCargoes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama ve filtre
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Arama kutusu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Kargo ara...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 12),
                
                // Boyut filtresi
                Row(
                  children: [
                    Text(
                      'Boyut Filtresi:',
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
                            value: _selectedSizeFilter,
                            isExpanded: true,
                            items: _sizeFilterOptions.map((size) {
                              return DropdownMenuItem(
                                value: size,
                                child: Text(size == 'Tümü' ? size : CargoHelper.getSizeDisplayName(size)),
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
            ),
          ),
          
          // Sonuç sayısı
          if (!_isLoading || _availableCargoes.isNotEmpty)
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
                  if (_searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedSizeFilter = 'Tümü';
                          _searchController.clear();
                        });
                      },
                      child: Text('Filtreleri Temizle'),
                    ),
                ],
              ),
            ),
          
          // Kargo listesi
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAvailableCargoes,
              child: _isLoading && _availableCargoes.isEmpty
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
                                _searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü'
                                    ? 'Arama kriterlerinize uygun kargo bulunamadı'
                                    : 'Şu anda mevcut kargo yok',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isNotEmpty || _selectedSizeFilter != 'Tümü') ...[
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedSizeFilter = 'Tümü';
                                      _searchController.clear();
                                    });
                                  },
                                  child: Text('Filtreleri Temizle'),
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}