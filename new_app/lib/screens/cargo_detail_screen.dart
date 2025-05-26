import 'package:flutter/material.dart';
import '../services/cargo_service.dart';
import 'delivery_screen.dart';

class CargoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cargo;
  final bool isDriver;

  CargoDetailScreen({required this.cargo, this.isDriver = false});

  @override
  _CargoDetailScreenState createState() => _CargoDetailScreenState();
}

class _CargoDetailScreenState extends State<CargoDetailScreen> {
  late Map<String, dynamic> _cargo;

  @override
  void initState() {
    super.initState();
    _cargo = widget.cargo;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CREATED':
        return Colors.blue;
      case 'ASSIGNED':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
      case 'FAILED':
        return Colors.red;
      case 'EXPIRED':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'CREATED':
        return 'Oluşturuldu';
      case 'ASSIGNED':
        return 'Atandı';
      case 'PICKED_UP':
        return 'Alındı';
      case 'DELIVERED':
        return 'Teslim Edildi';
      case 'CANCELLED':
        return 'İptal Edildi';
      case 'FAILED':
        return 'Başarısız';
      case 'EXPIRED':
        return 'Süresi Doldu';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'CREATED':
        return Icons.fiber_new;
      case 'ASSIGNED':
        return Icons.assignment;
      case 'PICKED_UP':
        return Icons.local_shipping;
      case 'DELIVERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      case 'FAILED':
        return Icons.error;
      case 'EXPIRED':
        return Icons.access_time;
      default:
        return Icons.info;
    }
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
        
        return Row(
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
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _cargo['cargoSituation'] ?? 'CREATED';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

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
                    Icon(statusIcon, size: 60, color: Colors.white),
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
                              '${_cargo['measure']?['weight'] ?? 0} kg',
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
                              '${_cargo['measure']?['height'] ?? 0} cm',
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
                              _cargo['measure']?['size'] ?? 'M',
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

            // Konum bilgileri
            _buildInfoCard(
              'Konum Bilgileri',
              Column(
                children: [
                  // Alınacak konum
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green),
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
                                'Enlem: ${_cargo['selfLocation']?['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Boylam: ${_cargo['selfLocation']?['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Teslim edilecek konum
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teslim Edilecek Konum',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Enlem: ${_cargo['targetLocation']?['latitude']?.toStringAsFixed(6) ?? 'N/A'}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Boylam: ${_cargo['targetLocation']?['longitude']?.toStringAsFixed(6) ?? 'N/A'}',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              color: Colors.indigo,
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