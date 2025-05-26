import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final _secureStorage = FlutterSecureStorage();
  static String? _fcmToken;
  
  // Callback fonksiyonları
  static Function(String)? onNotificationTapped;
  static Function(Map<String, dynamic>)? onMessageReceived;

  // Bildirim servisi başlatma
  static Future<void> initialize() async {
    try {
      // Firebase bildirim izinleri
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      print('Bildirim izin durumu: ${settings.authorizationStatus}');

      // FCM token al
      _fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _secureStorage.write(key: 'fcm_token', value: _fcmToken!);
        await _sendTokenToServer(_fcmToken!);
      }

      // Token yenilenme dinleyicisi
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token yenilendi: $newToken');
        _fcmToken = newToken;
        await _secureStorage.write(key: 'fcm_token', value: newToken);
        await _sendTokenToServer(newToken);
      });

      // Local notification ayarları
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android bildirim kanalı oluştur
      await _createNotificationChannel();

      // Mesaj dinleyicilerini kur
      _setupMessageHandlers();

      print('Bildirim servisi başarıyla başlatıldı');
    } catch (e) {
      print('Bildirim servisi başlatma hatası: $e');
    }
  }

  // Android bildirim kanalı oluştur
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'cargo_high_importance_channel', // id
      'Cargo App Bildirimleri', // title
      description: 'Kargo durumu ve önemli bildirimler',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Mesaj işleyicilerini kur
  static void _setupMessageHandlers() {
    // Uygulama açıkken gelen mesajlar
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Uygulama arka plandayken bildirime tıklama
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Uygulama kapalıyken bildirime tıklama
    _checkInitialMessage();
  }

  // Uygulama kapalıyken gelen mesajı kontrol et
  static Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      print('Initial message kontrol hatası: $e');
    }
  }

  // Ön planda gelen mesajları işle
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground mesaj alındı: ${message.messageId}');
    
    // Callback çağır
    onMessageReceived?.call(message.data);
    
    // Local bildirim göster
    await _showLocalNotification(
      title: message.notification?.title ?? 'Cargo App',
      body: message.notification?.body ?? 'Yeni bildirim',
      payload: json.encode(message.data),
      data: message.data,
    );
  }

  // Arka plan mesajlarını işle
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background mesaj açıldı: ${message.messageId}');
    
    // Mesaj tipine göre yönlendirme
    final String? type = message.data['type'];
    final String? cargoId = message.data['cargo_id'];
    
    if (onNotificationTapped != null) {
      if (type == 'cargo_status' && cargoId != null) {
        onNotificationTapped!('cargo_detail:$cargoId');
      } else if (type == 'new_cargo') {
        onNotificationTapped!('available_cargoes');
      } else {
        onNotificationTapped!('home');
      }
    }
  }

  // Bildirime tıklama olayını işle
  static void _onNotificationTapped(NotificationResponse response) {
    print('Bildirime tıklandı: ${response.payload}');
    
    try {
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        final String? type = data['type'];
        final String? cargoId = data['cargo_id'];
        
        if (onNotificationTapped != null) {
          if (type == 'cargo_status' && cargoId != null) {
            onNotificationTapped!('cargo_detail:$cargoId');
          } else if (type == 'new_cargo') {
            onNotificationTapped!('available_cargoes');
          } else {
            onNotificationTapped!('home');
          }
        }
      }
    } catch (e) {
      print('Bildirim payload parse hatası: $e');
    }
  }

  // Local bildirim göster
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'cargo_high_importance_channel',
        'Cargo App Bildirimleri',
        channelDescription: 'Kargo durumu ve önemli bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Local bildirim gösterme hatası: $e');
    }
  }

  // FCM token'ı sunucuya gönder
  static Future<void> _sendTokenToServer(String token) async {
    try {
      final authToken = await _secureStorage.read(key: 'auth_token');
      if (authToken == null) return;

      await http.post(
        Uri.parse('http://localhost:8080/api/user/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'fcm_token': token}),
      );
      
      print('FCM token sunucuya gönderildi');
    } catch (e) {
      print('FCM token gönderme hatası: $e');
    }
  }

  // Public metodlar
  
  // FCM token al
  static Future<String?> getToken() async {
    try {
      return _fcmToken ?? await _firebaseMessaging.getToken();
    } catch (e) {
      print('Token alma hatası: $e');
      return null;
    }
  }

  // Topic'e abone ol
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Topic aboneliği: $topic');
    } catch (e) {
      print('Topic abonelik hatası: $e');
    }
  }

  // Topic aboneliğini iptal et
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Topic abonelik iptali: $topic');
    } catch (e) {
      print('Topic abonelik iptal hatası: $e');
    }
  }

  // Özel bildirim türleri
  
  // Kargo durumu bildirimi
  static Future<void> showCargoStatusNotification({
    required String cargoId,
    required String status,
    required String description,
  }) async {
    String title = 'Kargo Durumu Değişti';
    String body = '';
    
    switch (status) {
      case 'ASSIGNED':
        title = '📦 Kargo Atandı';
        body = 'Kargonuz bir sürücüye atandı: $description';
        break;
      case 'PICKED_UP':
        title = '🚚 Kargo Alındı';
        body = 'Kargonuz sürücü tarafından alındı: $description';
        break;
      case 'DELIVERED':
        title = '✅ Kargo Teslim Edildi';
        body = 'Kargonuz başarıyla teslim edildi: $description';
        break;
      case 'CANCELLED':
        title = '❌ Kargo İptal Edildi';
        body = 'Kargonuz iptal edildi: $description';
        break;
      default:
        body = 'Kargo durumu: $status - $description';
    }

    await _showLocalNotification(
      title: title,
      body: body,
      payload: json.encode({
        'type': 'cargo_status',
        'cargo_id': cargoId,
      }),
      data: {
        'type': 'cargo_status',
        'cargo_id': cargoId,
      },
    );
  }

  // Yeni kargo bildirimi
  static Future<void> showNewCargoNotification({
    required String location,
    required String weight,
    required String size,
    String? cargoId,
  }) async {
    await _showLocalNotification(
      title: '🆕 Yeni Kargo Mevcut',
      body: 'Yakınınızda yeni kargo: $weight kg, $size boyut - $location',
      payload: json.encode({
        'type': 'new_cargo',
        'cargo_id': cargoId,
      }),
      data: {
        'type': 'new_cargo',
        'cargo_id': cargoId,
      },
    );
  }

  // Teslim hatırlatması
  static Future<void> showDeliveryReminderNotification({
    required String cargoId,
    required String description,
  }) async {
    await _showLocalNotification(
      title: '⏰ Teslim Hatırlatması',
      body: 'Teslim edilmesi gereken kargo: $description',
      payload: json.encode({
        'type': 'delivery_reminder',
        'cargo_id': cargoId,
      }),
      data: {
        'type': 'delivery_reminder',
        'cargo_id': cargoId,
      },
    );
  }

  // Yaklaşma bildirimi
  static Future<void> showProximityNotification({
    required String cargoId,
    required String location,
    required double distanceKm,
  }) async {
    await _showLocalNotification(
      title: '📍 Hedefe Yaklaştınız',
      body: '$location konumuna ${distanceKm.toStringAsFixed(1)} km mesafede',
      payload: json.encode({
        'type': 'proximity',
        'cargo_id': cargoId,
      }),
      data: {
        'type': 'proximity',
        'cargo_id': cargoId,
      },
    );
  }

  // Rating hatırlatması
  static Future<void> showRatingReminderNotification({
    required String cargoId,
    required String targetName,
    required String targetType, // 'driver' or 'distributor'
  }) async {
    final typeText = targetType == 'driver' ? 'sürücüyü' : 'kargo vereni';
    
    await _showLocalNotification(
      title: '⭐ Değerlendirme Zamanı',
      body: 'Lütfen $targetName adlı ${typeText} değerlendirin',
      payload: json.encode({
        'type': 'rating_reminder',
        'cargo_id': cargoId,
        'target_type': targetType,
      }),
      data: {
        'type': 'rating_reminder',
        'cargo_id': cargoId,
        'target_type': targetType,
      },
    );
  }

  // Tüm bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      print('Tüm bildirimler temizlendi');
    } catch (e) {
      print('Bildirim temizleme hatası: $e');
    }
  }

  // Belirli bir bildirimi iptal et
  static Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      print('Bildirim iptal edildi: $id');
    } catch (e) {
      print('Bildirim iptal hatası: $e');
    }
  }

  // Basit zamanlanmış bildirim (timezone olmadan)
  static Future<void> scheduleSimpleNotification({
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    try {
      // Basit bir delay ile bildirim zamanla
      Future.delayed(delay, () async {
        await _showLocalNotification(
          title: title,
          body: body,
          payload: payload,
        );
      });
    } catch (e) {
      print('Zamanlanmış bildirim hatası: $e');
    }
  }
}