import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../services/cargo_service.dart';
import '../services/location_service.dart';
import '../utils/cargo_helper.dart';
import 'map_selection_screen.dart';

class AddCargoScreen extends StatefulWidget {
  @override
  _AddCargoScreenState createState() => _AddCargoScreenState();
}

class _AddCargoScreenState extends State<AddCargoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  // Adres input controllers
  final _selfAddressController = TextEditingController();
  final _targetAddressController = TextEditingController();
  
  String _selectedSize = 'M';
  bool _isLoading = false;

  // Konum bilgileri
  double? _selfLatitude;
  double? _selfLongitude;
  String? _selfAddress;
  String _selfLocationMethod = 'none'; // 'none', 'current', 'address', 'map'
  
  double? _targetLatitude;
  double? _targetLongitude;
  String? _targetAddress;
  String _targetLocationMethod = 'none'; // 'none', 'current', 'address', 'map'

  final List<String> _sizeOptions = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    // Otomatik olarak mevcut konumu almasın, kullanıcı seçsin
  }

  // 🎯 Method 1: Mevcut konumu al
  Future<void> _getCurrentLocation(bool isPickup) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        // Koordinatları kaydet
        setState(() {
          if (isPickup) {
            _selfLatitude = position.latitude;
            _selfLongitude = position.longitude;
            _selfLocationMethod = 'current';
            _selfAddressController.clear(); // Adres input'u temizle
          } else {
            _targetLatitude = position.latitude;
            _targetLongitude = position.longitude;
            _targetLocationMethod = 'current';
            _targetAddressController.clear();
          }
        });

        // Adres çevirmeyi dene
        try {
          final address = await LocationService.getAddressFromCoordinates(
            position.latitude, 
            position.longitude,
          );
          
          setState(() {
            if (isPickup) {
              _selfAddress = address;
            } else {
              _targetAddress = address;
            }
          });
        } catch (e) {
          print('Adres çevirme hatası: $e');
          setState(() {
            if (isPickup) {
              _selfAddress = 'Koordinatlar: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            } else {
              _targetAddress = 'Koordinatlar: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            }
          });
        }

        _showSuccessMessage('Mevcut konum başarıyla alındı!');
      } else {
        _showErrorDialog('Konum alınamadı. Lütfen konum izinlerini kontrol edin.');
      }
    } catch (e) {
      _showErrorDialog('Konum alma hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🎯 Method 2: Adres girişinden koordinat al
  Future<void> _getLocationFromAddress(bool isPickup) async {
    final addressController = isPickup ? _selfAddressController : _targetAddressController;
    final address = addressController.text.trim();
    
    if (address.isEmpty) {
      _showErrorDialog('Lütfen adres girin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await LocationService.getCoordinatesFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        
        setState(() {
          if (isPickup) {
            _selfLatitude = location.latitude;
            _selfLongitude = location.longitude;
            _selfAddress = address;
            _selfLocationMethod = 'address';
          } else {
            _targetLatitude = location.latitude;
            _targetLongitude = location.longitude;
            _targetAddress = address;
            _targetLocationMethod = 'address';
          }
        });

        _showSuccessMessage('Adres başarıyla koordinatlara çevrildi!');
      } else {
        _showErrorDialog('Adres bulunamadı. Lütfen geçerli bir adres girin.');
      }
    } catch (e) {
      _showErrorDialog('Adres çevirme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🎯 Method 3: Harita üzerinden konum seç
  Future<void> _selectLocationOnMap(bool isPickup) async {
    // Mevcut konumu başlangıç noktası olarak kullan
    LatLng? initialLocation;
    
    if (isPickup && _selfLatitude != null && _selfLongitude != null) {
      initialLocation = LatLng(_selfLatitude!, _selfLongitude!);
    } else if (!isPickup && _targetLatitude != null && _targetLongitude != null) {
      initialLocation = LatLng(_targetLatitude!, _targetLongitude!);
    }

    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialLocation: initialLocation,
          title: isPickup ? 'Alınacak Konumu Seç' : 'Teslim Konumunu Seç',
        ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Koordinatları kaydet
        setState(() {
          if (isPickup) {
            _selfLatitude = selectedLocation.latitude;
            _selfLongitude = selectedLocation.longitude;
            _selfLocationMethod = 'map';
            _selfAddressController.clear(); // Adres input'u temizle
          } else {
            _targetLatitude = selectedLocation.latitude;
            _targetLongitude = selectedLocation.longitude;
            _targetLocationMethod = 'map';
            _targetAddressController.clear();
          }
        });

        // Adres çevirmeyi dene
        try {
          final address = await LocationService.getAddressFromCoordinates(
            selectedLocation.latitude,
            selectedLocation.longitude,
          );

          setState(() {
            if (isPickup) {
              _selfAddress = address;
            } else {
              _targetAddress = address;
            }
          });
        } catch (e) {
          print('Adres çevirme hatası: $e');
          setState(() {
            if (isPickup) {
              _selfAddress = 'Haritadan seçilen konum: ${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}';
            } else {
              _targetAddress = 'Haritadan seçilen konum: ${selectedLocation.latitude.toStringAsFixed(6)}, ${selectedLocation.longitude.toStringAsFixed(6)}';
            }
          });
        }

        _showSuccessMessage('Konum haritadan başarıyla seçildi!');
      } catch (e) {
        _showErrorDialog('Harita seçimi hatası: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Konumu temizle
  void _clearLocation(bool isPickup) {
    setState(() {
      if (isPickup) {
        _selfLatitude = null;
        _selfLongitude = null;
        _selfAddress = null;
        _selfLocationMethod = 'none';
        _selfAddressController.clear();
      } else {
        _targetLatitude = null;
        _targetLongitude = null;
        _targetAddress = null;
        _targetLocationMethod = 'none';
        _targetAddressController.clear();
      }
    });
  }

  Future<void> _addCargo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selfLatitude == null || _selfLongitude == null) {
      _showErrorDialog('Lütfen alınacak konumu seçin.');
      return;
    }

    if (_targetLatitude == null || _targetLongitude == null) {
      _showErrorDialog('Lütfen teslim konumunu seçin.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CargoService.addCargo(
        description: _descriptionController.text.trim(),
        selfLatitude: _selfLatitude!,
        selfLongitude: _selfLongitude!,
        targetLatitude: _targetLatitude!,
        targetLongitude: _targetLongitude!,
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        size: _selectedSize,
        phoneNumber: _phoneController.text.trim(),
        selfAddress: _selfAddress,
        targetAddress: _targetAddress,
      );

      if (result != null) {
        _showSuccessMessage('Kargo başarıyla eklendi!');
        Navigator.pop(context, true);
      } else {
        _showErrorDialog('Kargo eklenirken bir hata oluştu.');
      }
    } catch (e) {
      _showErrorDialog('Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Hata'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildLocationCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isPickup,
    required double? latitude,
    required double? longitude,
    required String? address,
    required String locationMethod,
    required TextEditingController addressController,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (locationMethod != 'none')
                  IconButton(
                    onPressed: () => _clearLocation(isPickup),
                    icon: Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Konumu Temizle',
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            // Seçilen konum bilgisi
            if (latitude != null && longitude != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 18),
                        SizedBox(width: 8),
                        Text(
                          _getLocationMethodText(locationMethod),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (address != null) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(Icons.my_location, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Adres girişi
            if (locationMethod == 'none' || locationMethod == 'address') ...[
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Adres Girin',
                  hintText: 'Örn: Taksim Meydanı, İstanbul',
                  prefixIcon: Icon(Icons.edit_location_alt),
                  suffixIcon: addressController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () => _getLocationFromAddress(isPickup),
                          icon: Icon(Icons.search, color: color),
                          tooltip: 'Adresi Ara',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Suffıx icon için rebuild
                },
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _getLocationFromAddress(isPickup);
                  }
                },
              ),
              SizedBox(height: 12),
            ],
            
            // Konum seçim butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _getCurrentLocation(isPickup),
                    icon: Icon(Icons.my_location, size: 18),
                    label: Text('Mevcut Konum'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _selectLocationOnMap(isPickup),
                    icon: Icon(Icons.map, size: 18),
                    label: Text('Haritadan Seç'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            if (addressController.text.isNotEmpty && locationMethod != 'address') ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _getLocationFromAddress(isPickup),
                  icon: Icon(Icons.search, size: 18),
                  label: Text('Bu Adresi Ara'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLocationMethodText(String method) {
    switch (method) {
      case 'current':
        return '📍 Mevcut Konum Kullanıldı';
      case 'address':
        return '🔍 Adresten Bulundu';
      case 'map':
        return '🗺️ Haritadan Seçildi';
      default:
        return 'Konum Seçilmedi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kargo Ekle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kargo bilgileri kartı
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kargo Bilgileri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Açıklama
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Kargo Açıklaması',
                          hintText: 'Kargonuzun açıklamasını yazın...',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Açıklama boş bırakılamaz';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Telefon
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Telefon Numarası',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Telefon numarası boş bırakılamaz';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Ölçüler kartı
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kargo Ölçüleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      Row(
                        children: [
                          // Ağırlık
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Ağırlık (kg)',
                                prefixIcon: Icon(Icons.scale),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ağırlık boş bırakılamaz';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Geçerli bir sayı girin';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          
                          // Yükseklik
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Yükseklik (cm)',
                                prefixIcon: Icon(Icons.straighten),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Yükseklik boş bırakılamaz';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Geçerli bir sayı girin';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Boyut seçimi
                      Text(
                        'Kargo Boyutu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedSize,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.aspect_ratio),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _sizeOptions.map((size) {
                          return DropdownMenuItem(
                            value: size,
                            child: Text(CargoHelper.getSizeDisplayName(size)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSize = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Alınacak konum kartı
              _buildLocationCard(
                title: 'Alınacak Konum',
                icon: Icons.location_on,
                color: Colors.green,
                isPickup: true,
                latitude: _selfLatitude,
                longitude: _selfLongitude,
                address: _selfAddress,
                locationMethod: _selfLocationMethod,
                addressController: _selfAddressController,
              ),
              SizedBox(height: 16),
              
              // Teslim edilecek konum kartı
              _buildLocationCard(
                title: 'Teslim Edilecek Konum',
                icon: Icons.flag,
                color: Colors.red,
                isPickup: false,
                latitude: _targetLatitude,
                longitude: _targetLongitude,
                address: _targetAddress,
                locationMethod: _targetLocationMethod,
                addressController: _targetAddressController,
              ),
              SizedBox(height: 24),
              
              // Kaydet butonu
              Container(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addCargo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Kaydediliyor...',
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Kargo Ekle',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _selfAddressController.dispose();
    _targetAddressController.dispose();
    super.dispose();
  }
}