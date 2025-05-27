import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RatingService {
  static const String _baseUrl = 'https://67n86mnm-8080.euw.devtunnels.ms';
  static final _secureStorage = FlutterSecureStorage();

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Sürücü değerlendirme
  static Future<bool> rateDriver({
    required int driverId,
    required int cargoId,
    required double rating,
    required String comment,
    List<String> tags = const [],
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rating/driver'),
        headers: headers,
        body: json.encode({
          'driver_id': driverId,
          'cargo_id': cargoId,
          'rating': rating,
          'comment': comment,
          'tags': tags,
        }),
      );

      print('Driver rating response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Sürücü değerlendirme hatası: $e');
      return false;
    }
  }

  // Kargo veren değerlendirme
  static Future<bool> rateDistributor({
    required int distributorId,
    required int cargoId,
    required double rating,
    required String comment,
    List<String> tags = const [],
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/rating/distributor'),
        headers: headers,
        body: json.encode({
          'distributor_id': distributorId,
          'cargo_id': cargoId,
          'rating': rating,
          'comment': comment,
          'tags': tags,
        }),
      );

      print('Distributor rating response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Kargo veren değerlendirme hatası: $e');
      return false;
    }
  }

  // Sürücünün ortalama puanını getirme
  static Future<DriverRating?> getDriverRating(int driverId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/driver/$driverId'),
        headers: headers,
      );

      print('Get driver rating response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriverRating.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Sürücü puanı alma hatası: $e');
      return null;
    }
  }

  // Kargo verenin ortalama puanını getirme
  static Future<DistributorRating?> getDistributorRating(int distributorId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/distributor/$distributorId'),
        headers: headers,
      );

      print('Get distributor rating response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DistributorRating.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Kargo veren puanı alma hatası: $e');
      return null;
    }
  }

  // Sürücünün aldığı değerlendirmeleri getirme
  static Future<List<Rating>> getDriverReviews(int driverId, {int page = 0, int size = 10}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/driver/$driverId/reviews?page=$page&size=$size'),
        headers: headers,
      );

      print('Get driver reviews response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reviews = data['content'] ?? data;
        return reviews.map((review) => Rating.fromJson(review)).toList();
      }
      return [];
    } catch (e) {
      print('Sürücü yorumları alma hatası: $e');
      return [];
    }
  }

  // Kargo verenin aldığı değerlendirmeleri getirme
  static Future<List<Rating>> getDistributorReviews(int distributorId, {int page = 0, int size = 10}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/distributor/$distributorId/reviews?page=$page&size=$size'),
        headers: headers,
      );

      print('Get distributor reviews response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reviews = data['content'] ?? data;
        return reviews.map((review) => Rating.fromJson(review)).toList();
      }
      return [];
    } catch (e) {
      print('Kargo veren yorumları alma hatası: $e');
      return [];
    }
  }

  // Kargonun değerlendirme durumunu kontrol etme
  static Future<RatingStatus?> getCargoRatingStatus(int cargoId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/cargo/$cargoId/status'),
        headers: headers,
      );

      print('Get cargo rating status response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RatingStatus.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Değerlendirme durumu alma hatası: $e');
      return null;
    }
  }

  // Kendi verdiğim değerlendirmeleri getirme
  static Future<List<Rating>> getMyRatings({int page = 0, int size = 10}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/my-ratings?page=$page&size=$size'),
        headers: headers,
      );

      print('Get my ratings response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ratings = data['content'] ?? data;
        return ratings.map((rating) => Rating.fromJson(rating)).toList();
      }
      return [];
    } catch (e) {
      print('Kendi değerlendirmelerimi alma hatası: $e');
      return [];
    }
  }

  // Değerlendirme güncelleme
  static Future<bool> updateRating({
    required int ratingId,
    required double rating,
    required String comment,
    List<String> tags = const [],
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/rating/$ratingId'),
        headers: headers,
        body: json.encode({
          'rating': rating,
          'comment': comment,
          'tags': tags,
        }),
      );

      print('Update rating response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Değerlendirme güncelleme hatası: $e');
      return false;
    }
  }

  // Değerlendirme silme
  static Future<bool> deleteRating(int ratingId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/rating/$ratingId'),
        headers: headers,
      );

      print('Delete rating response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Değerlendirme silme hatası: $e');
      return false;
    }
  }

  // Değerlendirme raporu alma
  static Future<Map<String, dynamic>?> getRatingReport({
    String? userType, // 'driver' or 'distributor'
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      
      final queryParams = <String, String>{};
      if (userType != null) queryParams['user_type'] = userType;
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      
      final uri = Uri.parse('$_baseUrl/api/rating/report').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      print('Get rating report response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Değerlendirme raporu alma hatası: $e');
      return null;
    }
  }

  // En iyi sürücüleri getirme
  static Future<List<Map<String, dynamic>>> getTopDrivers({int limit = 10}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/top-drivers?limit=$limit'),
        headers: headers,
      );

      print('Get top drivers response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('En iyi sürücüler alma hatası: $e');
      return [];
    }
  }

  // En iyi kargo verenleri getirme
  static Future<List<Map<String, dynamic>>> getTopDistributors({int limit = 10}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/top-distributors?limit=$limit'),
        headers: headers,
      );

      print('Get top distributors response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('En iyi kargo verenler alma hatası: $e');
      return [];
    }
  }

  // Önceden tanımlı etiketleri getirme
  static List<String> getDriverRatingTags() {
    return [
      'Hızlı Teslimat',
      'Güvenli Taşıma',
      'İyi İletişim',
      'Zamanında Teslimat',
      'Dikkatli',
      'Güvenilir',
      'Profesyonel',
      'Yardımsever',
      'Temiz Araç',
      'Nazik Davranış',
    ];
  }

  static List<String> getDistributorRatingTags() {
    return [
      'İyi Paketleme',
      'Doğru Açıklama',
      'Zamanında Hazır',
      'İyi İletişim',
      'Güvenilir',
      'Profesyonel',
      'Yardımsever',
      'Düzenli',
      'Net Talimatlar',
      'Anlayışlı',
    ];
  }

  // Rating istatistikleri getirme
  static Future<Map<String, dynamic>?> getRatingStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/rating/statistics'),
        headers: headers,
      );

      print('Get rating statistics response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Rating istatistikleri alma hatası: $e');
      return null;
    }
  }
}

// Model sınıfları
class DriverRating {
  final int driverId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // 1-5 yıldız dağılımı
  final List<String> topTags;

  DriverRating({
    required this.driverId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    required this.topTags,
  });

  factory DriverRating.fromJson(Map<String, dynamic> json) {
    return DriverRating(
      driverId: json['driver_id'],
      averageRating: json['average_rating'].toDouble(),
      totalRatings: json['total_ratings'],
      ratingDistribution: Map<int, int>.from(json['rating_distribution'] ?? {}),
      topTags: List<String>.from(json['top_tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driver_id': driverId,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'rating_distribution': ratingDistribution,
      'top_tags': topTags,
    };
  }

  String get formattedRating => averageRating.toStringAsFixed(1);
  
  String get ratingText {
    if (averageRating >= 4.5) return 'Mükemmel';
    if (averageRating >= 4.0) return 'Çok İyi';
    if (averageRating >= 3.5) return 'İyi';
    if (averageRating >= 3.0) return 'Orta';
    return 'Gelişmeli';
  }
}

class DistributorRating {
  final int distributorId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution;
  final List<String> topTags;

  DistributorRating({
    required this.distributorId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    required this.topTags,
  });

  factory DistributorRating.fromJson(Map<String, dynamic> json) {
    return DistributorRating(
      distributorId: json['distributor_id'],
      averageRating: json['average_rating'].toDouble(),
      totalRatings: json['total_ratings'],
      ratingDistribution: Map<int, int>.from(json['rating_distribution'] ?? {}),
      topTags: List<String>.from(json['top_tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distributor_id': distributorId,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'rating_distribution': ratingDistribution,
      'top_tags': topTags,
    };
  }

  String get formattedRating => averageRating.toStringAsFixed(1);
  
  String get ratingText {
    if (averageRating >= 4.5) return 'Mükemmel';
    if (averageRating >= 4.0) return 'Çok İyi';
    if (averageRating >= 3.5) return 'İyi';
    if (averageRating >= 3.0) return 'Orta';
    return 'Gelişmeli';
  }
}

class Rating {
  final int id;
  final int cargoId;
  final int raterId; // Değerlendiren kişi
  final int ratedId; // Değerlendirilen kişi
  final String raterType; // DRIVER veya DISTRIBUTOR
  final String ratedType; // DRIVER veya DISTRIBUTOR
  final double rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? raterName;
  final String? ratedName;

  Rating({
    required this.id,
    required this.cargoId,
    required this.raterId,
    required this.ratedId,
    required this.raterType,
    required this.ratedType,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    this.raterName,
    this.ratedName,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      cargoId: json['cargo_id'],
      raterId: json['rater_id'],
      ratedId: json['rated_id'],
      raterType: json['rater_type'],
      ratedType: json['rated_type'],
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      raterName: json['rater_name'],
      ratedName: json['rated_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cargo_id': cargoId,
      'rater_id': raterId,
      'rated_id': ratedId,
      'rater_type': raterType,
      'rated_type': ratedType,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'rater_name': raterName,
      'rated_name': ratedName,
    };
  }

  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedDate => '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  bool get isUpdated => updatedAt != null;
}

class RatingStatus {
  final int cargoId;
  final bool canRateDriver;
  final bool canRateDistributor;
  final bool hasRatedDriver;
  final bool hasRatedDistributor;
  final Rating? driverRating;
  final Rating? distributorRating;

  RatingStatus({
    required this.cargoId,
    required this.canRateDriver,
    required this.canRateDistributor,
    required this.hasRatedDriver,
    required this.hasRatedDistributor,
    this.driverRating,
    this.distributorRating,
  });

  factory RatingStatus.fromJson(Map<String, dynamic> json) {
    return RatingStatus(
      cargoId: json['cargo_id'],
      canRateDriver: json['can_rate_driver'] ?? false,
      canRateDistributor: json['can_rate_distributor'] ?? false,
      hasRatedDriver: json['has_rated_driver'] ?? false,
      hasRatedDistributor: json['has_rated_distributor'] ?? false,
      driverRating: json['driver_rating'] != null ? Rating.fromJson(json['driver_rating']) : null,
      distributorRating: json['distributor_rating'] != null ? Rating.fromJson(json['distributor_rating']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargo_id': cargoId,
      'can_rate_driver': canRateDriver,
      'can_rate_distributor': canRateDistributor,
      'has_rated_driver': hasRatedDriver,
      'has_rated_distributor': hasRatedDistributor,
      'driver_rating': driverRating?.toJson(),
      'distributor_rating': distributorRating?.toJson(),
    };
  }

  bool get canRate => canRateDriver || canRateDistributor;
  bool get hasRated => hasRatedDriver || hasRatedDistributor;
  bool get allRated => (canRateDriver ? hasRatedDriver : true) && (canRateDistributor ? hasRatedDistributor : true);
}