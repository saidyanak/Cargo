import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../services/rating_service.dart';

class RatingScreen extends StatefulWidget {
  final Map<String, dynamic> cargo;
  final String ratingType; // 'driver' veya 'distributor'
  final int targetUserId;
  final String targetUserName;

  RatingScreen({
    required this.cargo,
    required this.ratingType,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  List<String> _selectedTags = [];
  bool _isLoading = false;

  List<String> get _availableTags {
    if (widget.ratingType == 'driver') {
      return RatingService.getDriverRatingTags();
    } else {
      return RatingService.getDistributorRatingTags();
    }
  }

  Future<void> _submitRating() async {
    if (_commentController.text.trim().isEmpty) {
      _showErrorDialog('Lütfen bir yorum yazın');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = false;
      
      if (widget.ratingType == 'driver') {
        success = await RatingService.rateDriver(
          driverId: widget.targetUserId,
          cargoId: widget.cargo['id'],
          rating: _rating,
          comment: _commentController.text.trim(),
          tags: _selectedTags,
        );
      } else {
        success = await RatingService.rateDistributor(
          distributorId: widget.targetUserId,
          cargoId: widget.cargo['id'],
          rating: _rating,
          comment: _commentController.text.trim(),
          tags: _selectedTags,
        );
      }

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Değerlendirme gönderilirken bir hata oluştu.');
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Başarılı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Değerlendirmeniz başarıyla gönderildi!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context, true); // Rating ekranını kapat
            },
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    return FilterChip(
      label: Text(tag),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.remove(tag);
          }
        });
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Mükemmel';
    if (rating >= 3.5) return 'Çok İyi';
    if (rating >= 2.5) return 'İyi';
    if (rating >= 1.5) return 'Orta';
    return 'Kötü';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.green;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final targetTitle = widget.ratingType == 'driver' ? 'Sürücüyü' : 'Kargo Vereni';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$targetTitle Değerlendir'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık kartı
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.amber[600]!, Colors.amber[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.ratingType == 'driver' ? Icons.drive_eta : Icons.business,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.targetUserName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$targetTitle Değerlendir',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Kargo bilgileri
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.cargo['description'] ?? 'Açıklama yok',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kargo ID: ${widget.cargo['id']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Puan verme
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Kaç yıldız veriyorsunuz?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 50,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getRatingColor(_rating).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_rating.toStringAsFixed(1)} - ${_getRatingText(_rating)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(_rating),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Etiketler
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deneyiminizi tanımlayın (opsiyonel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map(_buildTagChip).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Yorum
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yorumunuz *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Deneyiminizi detaylarıyla anlatın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),

            // Gönder butonu
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size(double.infinity, 56),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 12),
                        Text('Gönderiliyor...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Değerlendirmeyi Gönder',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 16),

            // İptal butonu
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}