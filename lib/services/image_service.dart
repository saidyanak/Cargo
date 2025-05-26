import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';

class ImageService {
  static const String _baseUrl = 'http://localhost:8080';
  static final _picker = ImagePicker();
  static final _secureStorage = FlutterSecureStorage();

  // İzin kontrolü
  static Future<bool> requestPermissions() async {
    try {
      final cameraPermission = await Permission.camera.request();
      final storagePermission = await Permission.storage.request();
      final photosPermission = await Permission.photos.request();
      
      return cameraPermission.isGranted && 
             (storagePermission.isGranted || photosPermission.isGranted);
    } catch (e) {
      print('İzin hatası: $e');
      return false;
    }
  }

  // Kameradan fotoğraf çekme
  static Future<File?> takePhotoFromCamera({
    int imageQuality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Kamera izni verilmedi');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        print('Kameradan fotoğraf alındı: ${image.path}');
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Kameradan fotoğraf çekme hatası: $e');
      return null;
    }
  }

  // Galeriden fotoğraf seçme
  static Future<File?> pickPhotoFromGallery({
    int imageQuality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      if (image != null) {
        print('Galeriden fotoğraf seçildi: ${image.path}');
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Galeriden fotoğraf seçme hatası: $e');
      return null;
    }
  }

  // Çoklu fotoğraf seçme
  static Future<List<File>> pickMultiplePhotos({
    int imageQuality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int limit = 5,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      // Limit kontrolü
      final limitedImages = images.take(limit).toList();
      print('${limitedImages.length} fotoğraf seçildi');
      
      return limitedImages.map((image) => File(image.path)).toList();
    } catch (e) {
      print('Çoklu fotoğraf seçme hatası: $e');
      return [];
    }
  }

  // Video çekme/seçme
  static Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('İzin verilmedi');
      }

      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration ?? Duration(minutes: 5),
      );

      if (video != null) {
        print('Video seçildi/çekildi: ${video.path}');
        return File(video.path);
      }
      return null;
    } catch (e) {
      print('Video seçme/çekme hatası: $e');
      return null;
    }
  }

  // Fotoğraf upload etme
  static Future<String?> uploadCargoPhoto({
    required File imageFile,
    required int cargoId,
    String photoType = 'cargo', // 'cargo', 'delivery_proof', 'damage', 'pickup'
    String? description,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      // Dosya boyutu kontrolü (5MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Dosya boyutu 5MB\'dan büyük olamaz');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/upload/cargo-photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['cargo_id'] = cargoId.toString();
      request.fields['photo_type'] = photoType;
      
      if (description != null) {
        request.fields['description'] = description;
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        filename: '${cargoId}_${photoType}_${DateTime.now().millisecondsSinceEpoch}.${path.extension(imageFile.path)}',
      );

      request.files.add(multipartFile);

      print('Fotoğraf upload ediliyor: ${imageFile.path}');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        print('Fotoğraf upload başarılı: ${data['photo_url']}');
        return data['photo_url'];
      } else {
        print('Upload başarısız: ${response.statusCode} - $responseBody');
        throw Exception('Upload başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Fotoğraf upload hatası: $e');
      return null;
    }
  }

  // Profil fotoğrafı upload etme
  static Future<String?> uploadProfilePhoto(File imageFile) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      // Dosya boyutu kontrolü (2MB limit)
      final fileSize = await imageFile.length();
      if (fileSize > 2 * 1024 * 1024) {
        throw Exception('Profil fotoğrafı 2MB\'dan büyük olamaz');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/upload/profile-photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final multipartFile = await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.${path.extension(imageFile.path)}',
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        return data['photo_url'];
      } else {
        throw Exception('Profil fotoğrafı upload başarısız');
      }
    } catch (e) {
      print('Profil fotoğrafı upload hatası: $e');
      return null;
    }
  }

  // Kargo fotoğraflarını getirme
  static Future<List<CargoPhoto>> getCargoPhotos(int cargoId) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/cargo/$cargoId/photos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((photo) => CargoPhoto.fromJson(photo)).toList();
      }
      return [];
    } catch (e) {
      print('Kargo fotoğrafları alma hatası: $e');
      return [];
    }
  }

  // Fotoğraf silme
  static Future<bool> deleteCargoPhoto({
    required int cargoId,
    required String photoUrl,
  }) async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/cargo/$cargoId/photo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'photo_url': photoUrl}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Fotoğraf silme hatası: $e');
      return false;
    }
  }

  // Fotoğraf seçim dialog'u gösterme
  static Future<File?> showPhotoSelectionDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.photo_camera, color: Colors.blue),
            SizedBox(width: 8),
            Text('Fotoğraf Seç'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: Text('Kameradan Çek'),
              subtitle: Text('Yeni fotoğraf çek'),
              onTap: () async {
                Navigator.pop(context);
                final file = await takePhotoFromCamera();
                if (file != null) {
                  Navigator.pop(context, file);
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library, color: Colors.green),
              ),
              title: Text('Galeriden Seç'),
              subtitle: Text('Mevcut fotoğraflardan seç'),
              onTap: () async {
                Navigator.pop(context);
                final file = await pickPhotoFromGallery();
                if (file != null) {
                  Navigator.pop(context, file);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  // Çoklu fotoğraf seçim dialog'u
  static Future<List<File>?> showMultiplePhotoSelectionDialog(BuildContext context) async {
    return await showDialog<List<File>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çoklu Fotoğraf Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galeriden Seç'),
              subtitle: Text('Birden fazla fotoğraf seç'),
              onTap: () async {
                Navigator.pop(context);
                final files = await pickMultiplePhotos();
                if (files.isNotEmpty) {
                  Navigator.pop(context, files);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  // Fotoğraf sıkıştırma
  static Future<File?> compressImage(File imageFile, {int quality = 80}) async {
    try {
      // Bu fonksiyon için image package kullanılabilir
      // Şimdilik basit implementasyon
      return imageFile;
    } catch (e) {
      print('Fotoğraf sıkıştırma hatası: $e');
      return null;
    }
  }

  // Fotoğraf boyutunu kontrol et
  static Future<Map<String, dynamic>> getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileSize = bytes.length;
      
      return {
        'size_bytes': fileSize,
        'size_mb': (fileSize / (1024 * 1024)).toStringAsFixed(2),
        'path': imageFile.path,
        'name': path.basename(imageFile.path),
        'extension': path.extension(imageFile.path),
      };
    } catch (e) {
      print('Fotoğraf bilgi alma hatası: $e');
      return {};
    }
  }

  // Base64'e çevir
  static Future<String?> convertToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Base64 çevirme hatası: $e');
      return null;
    }
  }

  // Base64'ten File oluştur
  static Future<File?> createFileFromBase64(String base64String, String fileName) async {
    try {
      final bytes = base64Decode(base64String);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Base64\'ten File oluşturma hatası: $e');
      return null;
    }
  }
}

// Fotoğraf model sınıfı
class CargoPhoto {
  final int id;
  final int cargoId;
  final String photoUrl;
  final String photoType;
  final String? description;
  final DateTime createdAt;
  final int fileSize;
  final String fileName;

  CargoPhoto({
    required this.id,
    required this.cargoId,
    required this.photoUrl,
    required this.photoType,
    this.description,
    required this.createdAt,
    required this.fileSize,
    required this.fileName,
  });

  factory CargoPhoto.fromJson(Map<String, dynamic> json) {
    return CargoPhoto(
      id: json['id'],
      cargoId: json['cargo_id'],
      photoUrl: json['photo_url'],
      photoType: json['photo_type'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      fileSize: json['file_size'] ?? 0,
      fileName: json['file_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cargo_id': cargoId,
      'photo_url': photoUrl,
      'photo_type': photoType,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'file_size': fileSize,
      'file_name': fileName,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get photoTypeDisplayName {
    switch (photoType) {
      case 'cargo':
        return 'Kargo Fotoğrafı';
      case 'pickup':
        return 'Alım Fotoğrafı';
      case 'delivery':
        return 'Teslimat Fotoğrafı';
      case 'damage':
        return 'Hasar Fotoğrafı';
      default:
        return photoType;
    }
  }
}