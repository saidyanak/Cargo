import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class MapSelectionScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  MapSelectionScreen({
    this.initialLocation,
    this.title = 'Konum Seç',
  });

  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = 'Konum seçiliyor...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _getAddressFromLocation(_selectedLocation!);
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() {
      _isLoading = true;
    });

    final address = await LocationService.getAddressFromCoordinates(
      location.latitude,
      location.longitude,
    );

    setState(() {
      _selectedAddress = address;
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      final location = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = location;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15.0),
      );

      await _getAddressFromLocation(location);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLocation(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? LatLng(41.0082, 28.9784), // İstanbul
              zoom: 12.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: MarkerId('selected_location'),
                      position: _selectedLocation!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _selectedLocation = newPosition;
                        });
                        _getAddressFromLocation(newPosition);
                      },
                    ),
                  }
                : {},
          ),

          // Alt bilgi kartı
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Seçili Konum',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    if (_isLoading)
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Adres alınıyor...'),
                        ],
                      )
                    else
                      Text(
                        _selectedAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    
                    if (_selectedLocation != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Koordinatlar: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedLocation != null
                                ? () => Navigator.pop(context, _selectedLocation)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Konumu Seç',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('İptal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Harita merkezi göstergesi
          if (_selectedLocation == null)
            Center(
              child: Icon(
                Icons.location_on,
                size: 40,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}