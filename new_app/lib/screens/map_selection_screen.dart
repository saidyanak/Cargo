import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSelectionScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  const MapSelectionScreen({
    Key? key,
    this.initialLocation,
    required this.title,
  }) : super(key: key);

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  bool _isMapLoading = true;
  String? _mapError;
  bool _isEmulator = true; // Emulator detection

  // Önceden tanımlı konum seçenekleri
  final List<Map<String, dynamic>> _predefinedLocations = [
    {
      'name': 'Taksim Meydanı',
      'location': LatLng(41.0367, 28.9850),
      'icon': Icons.location_city,
      'color': Colors.red,
    },
    {
      'name': 'Sultanahmet',
      'location': LatLng(41.0082, 28.9784),
      'icon': Icons.account_balance,
      'color': Colors.blue,
    },
    {
      'name': 'Kadıköy İskele',
      'location': LatLng(40.9833, 29.0167),
      'icon': Icons.directions_boat,
      'color': Colors.green,
    },
    {
      'name': 'Beşiktaş',
      'location': LatLng(41.0422, 29.0067),
      'icon': Icons.stadium,
      'color': Colors.purple,
    },
    {
      'name': 'Üsküdar',
      'location': LatLng(41.0214, 29.0078),
      'icon': Icons.mosque,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    print('=== MAP SELECTION SCREEN INIT ===');

    _selectedLocation = widget.initialLocation;
    _updateMarkers();

    // Emulator detection (basit method)
    _detectEmulator();

    // Timeout
    Future.delayed(Duration(seconds: 8), () {
      if (mounted && _isMapLoading) {
        setState(() {
          _isMapLoading = false;
          _mapError = _isEmulator
              ? 'Emulator\'da harita sorunlu olabilir'
              : 'Harita yüklenemedi';
        });
      }
    });
  }

  void _detectEmulator() {
    // Basit emulator detection
    // Gerçek projede platform channels kullanılabilir
    _isEmulator = true; // Şimdilik true kabul et
  }

  void _updateMarkers() {
    _markers.clear();
    if (_selectedLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: _selectedLocation!,
          draggable: true,
          onDragEnd: (LatLng position) {
            setState(() {
              _selectedLocation = position;
            });
          },
          infoWindow: InfoWindow(
            title: 'Seçilen Konum',
            snippet: '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateMarkers();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    print('Map created successfully!');
    _mapController = controller;
    setState(() {
      _isMapLoading = false;
      _mapError = null;
    });
  }

  void _selectPredefinedLocation(Map<String, dynamic> locationData) {
    final LatLng location = locationData['location'];
    setState(() {
      _selectedLocation = location;
      _updateMarkers();
    });

    // Haritayı bu konuma odakla (eğer harita yüklendiyse)
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 16.0),
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${locationData['name']} seçildi'),
        backgroundColor: locationData['color'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedLocation != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              icon: Icon(Icons.check, color: Colors.white),
              label: Text(
                'SEÇ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Hazır konum seçenekleri (Emulator için)
          if (_isEmulator || _mapError != null) ...[
            Container(
              height: 120,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      _isEmulator
                          ? '📱 Emulator için hazır konumlar:'
                          : '🗺️ Hızlı konum seçimi:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _predefinedLocations.length,
                      itemBuilder: (context, index) {
                        final location = _predefinedLocations[index];
                        final isSelected = _selectedLocation == location['location'];

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => _selectPredefinedLocation(location),
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? location['color']
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? location['color']
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    location['icon'],
                                    color: isSelected
                                        ? Colors.white
                                        : location['color'],
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    location['name'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Divider(),
          ],

          // Harita bölümü
          Expanded(
            child: Stack(
              children: [
                // Harita veya alternatif görünüm
                if (_mapError != null)
                  _buildMapAlternative()
                else if (_isMapLoading)
                  _buildLoadingView()
                else
                  _buildMapView(),

                // Seçilen konum bilgisi
                if (_selectedLocation != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildLocationInfo(),
                  ),
              ],
            ),
          ),

          // Alt butonlar
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final initialLocation = widget.initialLocation ?? LatLng(41.0082, 28.9784);

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 12.0,
      ),
      onTap: _onMapTapped,
      markers: _markers,
      myLocationEnabled: false, // Emulator'da sorun çıkarabilir
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
      buildingsEnabled: false, // Performance için
      indoorViewEnabled: false,
      mapType: MapType.normal,
      liteModeEnabled: _isEmulator, // Emulator için lite mode
    );
  }

  Widget _buildMapAlternative() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Harita Alternatifi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Yukarıdaki hazır konumlardan birini seçin\nveya koordinat girin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isMapLoading = true;
                  _mapError = null;
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('Haritayı Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Google Maps yükleniyor...',
              style: TextStyle(fontSize: 16),
            ),
            if (_isEmulator) ...[
              SizedBox(height: 8),
              Text(
                'Emulator\'da yavaş olabilir',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seçilen Konum',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          if (_selectedLocation != null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedLocation = null;
                    _markers.clear();
                  });
                },
                icon: Icon(Icons.clear),
                label: Text('Temizle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _selectedLocation != null
                  ? () => Navigator.pop(context, _selectedLocation)
                  : null,
              icon: Icon(Icons.check),
              label: Text(_selectedLocation != null
                  ? 'Bu Konumu Seç'
                  : 'Konum Seçin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}