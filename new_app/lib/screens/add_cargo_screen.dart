import 'package:cargo_app/utils/cargo_helper.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/cargo_service.dart';
import '../services/location_service.dart';
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
  
  String _selectedSize = 'M';
  bool _isLoading = false;

  // Konum bilgileri
  double? _selfLatitude;
  double? _selfLongitude;
  String? _selfAddress;
  
  double? _targetLatitude;
  double? _targetLongitude;
  String? _targetAddress;

  final List<String> _sizeOptions = ['S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAutomatically();
  }

  Future<void> _getCurrentLocationAutomatically() async {
  try {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _selfLatitude = position.latitude;
        _selfLongitude = position.longitude;
      });
      
      // Adres almayı ayrı try-catch'e al
      try {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude, 
          position.longitude,
        );
        
        setState(() {
          _selfAddress = address;
        });
      } catch (e) {
        print('Adres alma hatası: $e');
        setState(() {
          _selfAddress = 'Koordinatlar: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    }
  } catch (e) {
    print('Otomatik konum alma hatası: $e');
  }
}

Future<void> _getCurrentLocation(bool isPickup) async {
  setState(() {
    _isLoading = true;
  });

  try {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      // Önce koordinatları kaydet
      setState(() {
        if (isPickup) {
          _selfLatitude = position.latitude;
          _selfLongitude = position.longitude;
        } else {
          _targetLatitude = position.latitude;
          _targetLongitude = position.longitude;
        }
      });

      // Adres çevirmeyi ayrı try-catch'e al
      String address;
      try {
        address = await LocationService.getAddressFromCoordinates(
          position.latitude, 
          position.longitude,
        );
      } catch (e) {
        print('Adres çevirme hatası: $e');
        address = 'Koordinatlar: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
      
      setState(() {
        if (isPickup) {
          _selfAddress = address;
        } else {
          _targetAddress = address;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum başarıyla alındı!'),
          backgroundColor: Colors.green,
        ),
      );
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

  // Harita üzerinden konum seç
  Future<void> _selectLocationOnMap(bool isPickup) async {
    final initialLocation = isPickup
        ? (_selfLatitude != null && _selfLongitude != null
            ? LatLng(_selfLatitude!, _selfLongitude!)
            : null)
        : (_targetLatitude != null && _targetLongitude != null
            ? LatLng(_targetLatitude!, _targetLongitude!)
            : null);

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
        final address = await LocationService.getAddressFromCoordinates(
          selectedLocation.latitude,
          selectedLocation.longitude,
        );

        setState(() {
          if (isPickup) {
            _selfLatitude = selectedLocation.latitude;
            _selfLongitude = selectedLocation.longitude;
            _selfAddress = address;
          } else {
            _targetLatitude = selectedLocation.latitude;
            _targetLongitude = selectedLocation.longitude;
            _targetAddress = address;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum seçildi!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showErrorDialog('Adres bilgisi alınamadı: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kargo başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
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
        title: Text('Hata'),
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

  Widget _buildLocationCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isPickup,
    required double? latitude,
    required double? longitude,
    required String? address,
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
            SizedBox(height: 16),
            
            // Seçilen konum bilgisi
            if (latitude != null && longitude != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Konum Seçildi',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (address != null) ...[
                      Text(
                        address,
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                    ],
                    Text(
                      'Koordinatlar: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],
            
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _getCurrentLocation(isPickup),
                    icon: Icon(Icons.my_location, size: 16),
                    label: Text('Mevcut Konum'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _selectLocationOnMap(isPickup),
                    icon: Icon(Icons.map, size: 16),
                    label: Text('Haritadan Seç'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
        title: Text('Kargo Ekle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedSize,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.aspect_ratio),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              ),
              SizedBox(height: 24),
              
              // Kaydet butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _addCargo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 12),
                          Text('Kaydediliyor...'),
                        ],
                      )
                    : Text(
                        'Kargo Ekle',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    super.dispose();
  }
}