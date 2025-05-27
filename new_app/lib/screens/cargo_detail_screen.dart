import 'package:cargo_app/services/cargo_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import 'delivery_screen.dart';
import '../utils/cargo_helper.dart';


class CargoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cargo;
  final bool isDriver;

  CargoDetailScreen({required this.cargo, this.isDriver = false});

  @override
  _CargoDetailScreenState createState() => _CargoDetailScreenState();
}

class _CargoDetailScreenState extends State<CargoDetailScreen> {
  late Map<String, dynamic> _cargo;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _cargo = widget.cargo;
    _setupMarkers();
  }

  void _setupMarkers() {
    _markers.clear();
    
    // Alınacak konum marker'ı
    final selfLat = _cargo['selfLocation']?['latitude'];
    final selfLng = _cargo['selfLocation']?['longitude'];
    if (selfLat != null && selfLng != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('pickup'),
          position: LatLng(selfLat.toDouble(), selfLng.toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Alınacak Konum',
            snippet: _cargo['selfLocation']?['address'] ?? 'Adres bilgisi yok',
          ),
        ),
      );
    }

    // Teslim edilecek konum marker'ı
    final targetLat = _cargo['targetLocation']?['latitude'];
    final targetLng = _cargo['targetLocation']?['longitude'];
    if (targetLat != null && targetLng != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('delivery'),
          position: LatLng(targetLat.toDouble(), targetLng.toDouble()),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Teslim Konumu',
            snippet: _cargo['targetLocation']?['address'] ?? 'Adres bilgisi yok',
          ),
        ),
      );
    }
  }

  // Google Maps'te aç
  Future<void> _openInGoogleMaps() async {
    final selfLat = _cargo['selfLocation']?['latitude'];
    final selfLng = _cargo['selfLocation']?['longitude'];
    final targetLat = _cargo['targetLocation']?['latitude'];
    final targetLng = _cargo['targetLocation']?['longitude'];

    if (selfLat != null && selfLng != null && targetLat != null && targetLng != null) {
      // Yön tarifi için Google Maps URL'i
      final url = 'https://www.google.com/maps/dir/$selfLat,$selfLng/$targetLat,$targetLng';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Maps açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Apple Maps'te aç (iOS için)
  Future<void> _openInAppleMaps() async {
    final selfLat = _cargo['selfLocation']?['latitude'];
    final selfLng = _cargo['selfLocation']?['longitude'];
    final targetLat = _cargo['targetLocation']?['latitude'];
    final targetLng = _cargo['targetLocation']?['longitude'];

    if (selfLat != null && selfLng != null && targetLat != null && targetLng != null) {
      // Apple Maps URL'i
      final url = 'https://maps.apple.com/?saddr=$selfLat,$selfLng&daddr=$targetLat,$targetLng&dirflg=d';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // Fallback olarak Google Maps'i dene
        _openInGoogleMaps();
      }
    }
  }

  // Harita seçenekleri dialog'u
  void _showMapOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Harita Uygulaması Seç',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.map, color: Colors.blue),
              title: Text('Google Maps'),
              subtitle: Text('Yön tarifi için Google Maps\'i aç'),
              onTap: () {
                Navigator.pop(context);
                _openInGoogleMaps();
              },
            ),
            ListTile(
              leading: Icon(Icons.map, color: Colors.grey[700]),
              title: Text('Apple Maps'),
              subtitle: Text('Yön tarifi için Apple Maps\'i aç'),
              onTap: () {
                Navigator.pop(context);
                _openInAppleMaps();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _takeCargo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await CargoService.takeCargo(_cargo['id']);
      Navigator.pop(context); // Loading dialog'u kapat

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kargo başarıyla alındı!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Ana ekrana geri dön
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

  void _showTakeCargoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kargo Al'),
        content: Text('Bu kargoyu almak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _takeCargo();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Kargoyu Al', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content, {Color? color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (color != null)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (color != null) SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    final selfLat = _cargo['selfLocation']?['latitude'];
    final selfLng = _cargo['selfLocation']?['longitude'];
    final targetLat = _cargo['targetLocation']?['latitude'];
    final targetLng = _cargo['targetLocation']?['longitude'];

    if (selfLat == null || selfLng == null || targetLat == null || targetLng == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Konum bilgisi mevcut değil',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Merkez nokta hesapla
    final centerLat = (selfLat + targetLat) / 2;
    final centerLng = (selfLng + targetLng) / 2;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kargo Rotası',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showMapOptions,
                  icon: Icon(Icons.navigation, size: 16),
                  label: Text('Yön Tarifi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(centerLat, centerLng),
                  zoom: 12,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  
                  // Haritayı tüm marker'ları gösterecek şekilde ayarla
                  if (_markers.length > 1) {
                    Future.delayed(Duration(milliseconds: 500), () {
                      _fitMarkersInView();
                    });
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          
          // Konum bilgileri
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alınacak Konum',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _cargo['selfLocation']?['address'] ?? 
                            '${selfLat.toStringAsFixed(6)}, ${selfLng.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teslim Konumu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _cargo['targetLocation']?['address'] ?? 
                            '${targetLat.toStringAsFixed(6)}, ${targetLng.toStringAsFixed(6)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Mesafe bilgisi
                FutureBuilder<double>(
                  future: _calculateDistance(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten, color: Colors.blue, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Tahmini Mesafe: ${LocationService.formatDistance(snapshot.data!)}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<double> _calculateDistance() async {
    final selfLat = _cargo['selfLocation']?['latitude'];
    final selfLng = _cargo['selfLocation']?['longitude'];
    final targetLat = _cargo['targetLocation']?['latitude'];
    final targetLng = _cargo['targetLocation']?['longitude'];

    if (selfLat != null && selfLng != null && targetLat != null && targetLng != null) {
      return LocationService.calculateDistance(
        selfLat.toDouble(),
        selfLng.toDouble(),
        targetLat.toDouble(),
        targetLng.toDouble(),
      );
    }
    return 0.0;
  }

  void _fitMarkersInView() {
    if (_mapController != null && _markers.length > 1) {
      final bounds = _calculateBounds();
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  LatLngBounds _calculateBounds() {
    final selfLat = _cargo['selfLocation']?['latitude'];
    final selfLng = _cargo['selfLocation']?['longitude'];
    final targetLat = _cargo['targetLocation']?['latitude'];
    final targetLng = _cargo['targetLocation']?['longitude'];

    final southwest = LatLng(
      selfLat < targetLat ? selfLat.toDouble() : targetLat.toDouble(),
      selfLng < targetLng ? selfLng.toDouble() : targetLng.toDouble(),
    );
    
    final northeast = LatLng(
      selfLat > targetLat ? selfLat.toDouble() : targetLat.toDouble(),
      selfLng > targetLng ? selfLng.toDouble() : targetLng.toDouble(),
    );

    return LatLngBounds(southwest: southwest, northeast: northeast);
  }

  Widget _buildStatusTimeline() {
    final status = _cargo['cargoSituation'] ?? 'CREATED';
    final statuses = [
      {'key': 'CREATED', 'title': 'Oluşturuldu', 'icon': Icons.fiber_new},
      {'key': 'ASSIGNED', 'title': 'Atandı', 'icon': Icons.assignment},
      {'key': 'PICKED_UP', 'title': 'Alındı', 'icon': Icons.local_shipping},
      {'key': 'DELIVERED', 'title': 'Teslim Edildi', 'icon': Icons.check_circle},
    ];

    int currentIndex = statuses.indexWhere((s) => s['key'] == status);
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: statuses.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> statusInfo = entry.value;
        
        bool isCompleted = index <= currentIndex;
        bool isCurrent = index == currentIndex;
        
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // İkon
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusInfo['icon'],
                  color: isCompleted ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              
              // Başlık
              Expanded(
                child: Text(
                  statusInfo['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.green : Colors.grey[600],
                  ),
                ),
              ),
              
              // Durum göstergesi
              if (isCurrent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Mevcut',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _cargo['cargoSituation'] ?? 'CREATED';
    final statusColor = CargoHelper.getStatusColor(status);
    final statusText = CargoHelper.getStatusDisplayName(status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kargo Detayları'),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Durum kartı
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.7), statusColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(CargoHelper.getStatusIcon(status), size: 60, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kargo ID: ${_cargo['id'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Harita kartı
            _buildMapCard(),
            SizedBox(height: 16),

            // Açıklama kartı
            _buildInfoCard(
              'Kargo Açıklaması',
              Text(
                _cargo['description'] ?? 'Açıklama yok',
                style: TextStyle(fontSize: 16),
              ),
              color: Colors.blue,
            ),
            SizedBox(height: 16),

            // İletişim bilgileri
            _buildInfoCard(
              'İletişim Bilgileri',
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    _cargo['phoneNumber'] ?? 'Telefon yok',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              color: Colors.green,
            ),
            SizedBox(height: 16),

            // Ölçüler kartı
            _buildInfoCard(
              'Kargo Ölçüleri',
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.scale, color: Colors.orange),
                            SizedBox(height: 4),
                            Text(
                              CargoHelper.formatWeight(_cargo['measure']?['weight']),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Ağırlık', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.straighten, color: Colors.purple),
                            SizedBox(height: 4),
                            Text(
                              CargoHelper.formatHeight(_cargo['measure']?['height']),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Yükseklik', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.aspect_ratio, color: Colors.red),
                            SizedBox(height: 4),
                            Text(
                              CargoHelper.getSizeDisplayName(_cargo['measure']?['size']),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Boyut', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              color: Colors.orange,
            ),
            SizedBox(height: 16),

            // Durum zaman çizelgesi
            _buildInfoCard(
              'Kargo Durumu',
              _buildStatusTimeline(),
              color: statusColor,
            ),
            SizedBox(height: 24),

            // Aksiyon butonları
            if (widget.isDriver && status == 'CREATED')
              ElevatedButton(
                onPressed: _showTakeCargoDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Kargoyu Al',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

            if (widget.isDriver && status == 'PICKED_UP')
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryScreen(cargo: _cargo),
                    ),
                  ).then((_) {
                    Navigator.pop(context, true);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Teslim Et',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
