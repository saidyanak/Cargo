import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../services/image_service.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final int cargoId;
  final bool canAddPhotos;
  final List<String> initialPhotos;

  PhotoGalleryScreen({
    required this.cargoId,
    this.canAddPhotos = false,
    this.initialPhotos = const [],
  });

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<String> _photos = [];
  List<CargoPhoto> _cargoPhotos = []; // CargoPhoto listesi
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.initialPhotos);
    _loadCargoPhotos();
  }

  Future<void> _loadCargoPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // CargoPhoto listesi al
      final cargoPhotos = await ImageService.getCargoPhotos(widget.cargoId);
      
      // URL'leri String listesine çevir
      final photoUrls = cargoPhotos.map((photo) => photo.photoUrl).toList();
      
      setState(() {
        _cargoPhotos = cargoPhotos;
        _photos = photoUrls;
      });
    } catch (e) {
      print('Fotoğraf yükleme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addPhoto() async {
    final file = await ImageService.showPhotoSelectionDialog(context);
    if (file != null) {
      setState(() {
        _isLoading = true;
      });

      final photoUrl = await ImageService.uploadCargoPhoto(
        imageFile: file,
        cargoId: widget.cargoId,
        photoType: 'cargo',
      );

      if (photoUrl != null) {
        setState(() {
          _photos.add(photoUrl);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Listeyi yenile
        await _loadCargoPhotos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf eklenirken hata oluştu!'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhoto(String photoUrl, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fotoğrafı Sil'),
        content: Text('Bu fotoğrafı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await ImageService.deleteCargoPhoto(
        cargoId: widget.cargoId,
        photoUrl: photoUrl,
      );

      if (success) {
        setState(() {
          _photos.removeAt(index);
          if (index < _cargoPhotos.length) {
            _cargoPhotos.removeAt(index);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf silindi!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf silinirken hata oluştu!'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewFullScreenPhoto(String photoUrl, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhotoViewer(
          photos: _photos,
          initialIndex: index,
          cargoPhotos: _cargoPhotos,
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _photos.length + (widget.canAddPhotos ? 1 : 0),
      itemBuilder: (context, index) {
        // Fotoğraf ekleme kartı
        if (widget.canAddPhotos && index == _photos.length) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: _addPhoto,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.none,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fotoğraf Ekle',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Fotoğraf kartı
        final photoUrl = _photos[index];
        final cargoPhoto = index < _cargoPhotos.length ? _cargoPhotos[index] : null;
        
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fotoğraf
                GestureDetector(
                  onTap: () => _viewFullScreenPhoto(photoUrl, index),
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.grey[400]),
                          SizedBox(height: 4),
                          Text(
                            'Yüklenemedi',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fotoğraf tipi badge'i
                if (cargoPhoto != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cargoPhoto.photoTypeDisplayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Silme butonu
                if (widget.canAddPhotos)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.white, size: 20),
                        onPressed: () => _deletePhoto(photoUrl, index),
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ),

                // Zoom ikonu
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.zoom_in, color: Colors.white, size: 16),
                  ),
                ),

                // Dosya boyutu (eğer varsa)
                if (cargoPhoto != null && cargoPhoto.fileSize > 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cargoPhoto.formattedFileSize,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kargo Fotoğrafları'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          if (widget.canAddPhotos)
            IconButton(
              icon: Icon(Icons.add_a_photo),
              onPressed: _addPhoto,
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCargoPhotos,
          ),
        ],
      ),
      body: _isLoading && _photos.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Henüz fotoğraf yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (widget.canAddPhotos) ...[
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addPhoto,
                          icon: Icon(Icons.add_a_photo),
                          label: Text('İlk Fotoğrafı Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Stack(
                  children: [
                    _buildPhotoGrid(),
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('İşlem yapılıyor...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final List<CargoPhoto> cargoPhotos;

  FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
    this.cargoPhotos = const [],
  });

  @override
  _FullScreenPhotoViewerState createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = _currentIndex < widget.cargoPhotos.length 
        ? widget.cargoPhotos[_currentIndex] 
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
        actions: [
          if (currentPhoto != null)
            IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                _showPhotoInfo(currentPhoto);
              },
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.photos[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Fotoğraf yüklenemedi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: currentPhoto != null 
          ? Container(
              color: Colors.black.withOpacity(0.8),
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPhoto.photoTypeDisplayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentPhoto.description != null) ...[
                    SizedBox(height: 4),
                    Text(
                      currentPhoto.description!,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        currentPhoto.formattedFileSize,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(width: 16),
                      Text(
                        currentPhoto.createdAt.toString().split('.')[0],
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _showPhotoInfo(CargoPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fotoğraf Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tip:', photo.photoTypeDisplayName),
            if (photo.description != null)
              _buildInfoRow('Açıklama:', photo.description!),
            _buildInfoRow('Dosya Boyutu:', photo.formattedFileSize),
            _buildInfoRow('Dosya Adı:', photo.fileName),
            _buildInfoRow('Yüklenme Tarihi:', photo.createdAt.toString().split('.')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}