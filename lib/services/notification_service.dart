import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Firebase imports - sadece mobilde kullan
import 'package:firebase_messaging/firebase_messaging.dart' if (dart.library.html) 'dart:html';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' if (dart.library.html) 'dart:html';

class NotificationService {
  static FirebaseMessaging? _firebaseMessaging;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static final _secureStorage = FlutterSecureStorage();
  static String? _fcmToken;
  
  // Callback fonksiyonları
  static Function(String)? onNotificationTapped;
  static Function(Map<String, dynamic>)? onMessageReceived;

  // Platform kontrolü ile başlatma
  static Future<void> initialize() async {
    if (kIsWeb) {
      print('Web platformu - Bildirimler basit modda çalışacak');
      await _initializeWebNotifications();
      return;
    }

    // Mobil platform - tam Firebase desteği
    await _initializeMobileNotifications();
  }

  // Web için basit bildirim sistemi
  static Future<void> _initializeWebNotifications() async {
    try {
      // Web için basit notification API kullanılabilir
      print('Web bildirimleri başlatıldı');
    } catch (e) {
      print('Web bildirim hatası: $e');
    }
  }

  // Mobil için tam Firebase bildirimleri
  static Future<void> _initializeMobileNotifications() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Firebase bildirim izinleri
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
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
      _fcmToken = await _firebaseMessaging!.getToken();
      print('FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _secureStorage.write(key: 'fcm_token', value: _fcmToken!);
        await _sendTokenToServer(_fcmToken!);
      }

      // Token yenilenme dinleyicisi
      _firebaseMessaging!.onTokenRefresh.listen((newToken) async {
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

      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android bildirim kanalı oluştur
      await _createNotificationChannel();

      // Mesaj dinleyicilerini kur
      _setupMessageHandlers();

      print('Mobil bildirim servisi başarıyla başlatıldı');
    } catch (e) {
      print('Mobil bildirim servisi başlatma hatası: $e');
    }
  }

  // Android bildirim kanalı oluştur
  static Future<void> _createNotificationChannel() async {
    if (kIsWeb || _localNotifications == null) return;

    const androidChannel = AndroidNotificationChannel(
      'cargo_high_importance_channel',
      'Cargo App Bildirimleri',
      description: 'Kargo durumu ve önemli bildirimler',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Mesaj işleyicilerini kur
  static void _setupMessageHandlers() {
    if (kIsWeb || _firebaseMessaging == null) return;

    // Uygulama açıkken gelen mesajlar
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Uygulama arka plandayken bildirime tıklama
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Uygulama kapalıyken bildirime tıklama
    _checkInitialMessage();
  }

  // Uygulama kapalıyken gelen mesajı kontrol et
  static Future<void> _checkInitialMessage() async {
    if (kIsWeb || _firebaseMessaging == null) return;

    try {
      RemoteMessage? initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } catch (e) {
      print('Initial message kontrol hatası: $e');
    }
  }

  // Ön planda gelen mesajları işle
  static Future<void> _handleForegroundMessage(dynamic message) async {
    if (kIsWeb) return;

    final RemoteMessage remoteMessage = message as RemoteMessage;
    print('Foreground mesaj alındı: ${remoteMessage.messageId}');
    
    // Callback çağır
    onMessageReceived?.call(remoteMessage.data);
    
    // Local bildirim göster
    await _showLocalNotification(
      title: remoteMessage.notification?.title ?? 'Cargo App',
      body: remoteMessage.notification?.body ?? 'Yeni bildirim',
      payload: json.encode(remoteMessage.data),
      data: remoteMessage.data,
    );
  }

  // Arka plan mesajlarını işle
  static Future<void> _handleBackgroundMessage(dynamic message) async {
    if (kIsWeb) return;

    final RemoteMessage remoteMessage = message as RemoteMessage;
    print('Background mesaj açıldı: ${remoteMessage.messageId}');
    
    // Mesaj tipine göre yönlendirme
    final String? type = remoteMessage.data['type'];
    final String? cargoId = remoteMessage.data['cargo_id'];
    
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
    if (kIsWeb) {
      // Web için basit alert
      print('Web Bildirim: $title - $body');
      return;
    }

    if (_localNotifications == null) return;

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

      await _localNotifications!.show(
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

  // Public metodlar - Platform kontrolü ile
  
  // FCM token al
  static Future<String?> getToken() async {
    if (kIsWeb) return 'web_token_placeholder';
    return _fcmToken ?? await _firebaseMessaging?.getToken();
  }

  // Topic'e abone ol
  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    
    try {
      await _firebaseMessaging?.subscribeToTopic(topic);
      print('Topic aboneliği: $topic');
    } catch (e) {
      print('Topic abonelik hatası: $e');
    }
  }

  // Topic aboneliğini iptal et
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    
    try {
      await _firebaseMessaging?.unsubscribeFromTopic(topic);
      print('Topic abonelik iptali: $topic');
    } catch (e) {
      print('Topic abonelik iptal hatası: $e');
    }
  }

  // Platform-safe bildirim metodları
  
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

  // Tüm bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    if (kIsWeb) return;
    
    try {
      await _localNotifications?.cancelAll();
      print('Tüm bildirimler temizlendi');
    } catch (e) {
      print('Bildirim temizleme hatası: $e');
    }
  }
}