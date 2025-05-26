import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static final _secureStorage = FlutterSecureStorage();
  static String? _currentUserId;
  static Timer? _reconnectTimer;
  static Timer? _heartbeatTimer;
  static bool _isConnecting = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _reconnectDelaySeconds = 5;
  
  // Event listeners
  static Function(Map<String, dynamic>)? _onLocationUpdate;
  static Function(Map<String, dynamic>)? _onStatusUpdate;
  static Function(Map<String, dynamic>)? _onNewCargo;
  static Function(Map<String, dynamic>)? _onMessage;
  static Function()? _onConnected;
  static Function()? _onDisconnected;
  static Function(dynamic)? _onError;

  // WebSocket bağlantısı kur
  static Future<void> connect() async {
    if (_isConnecting || isConnected) return;
    
    try {
      _isConnecting = true;
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        print('WebSocket: Token bulunamadı');
        return;
      }

      // WebSocket bağlantısı
      final wsUrl = 'ws://localhost:8080/ws?token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Bağlantı durumunu dinle
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Heartbeat başlat
      _startHeartbeat();
      
      _isConnecting = false;
      _reconnectAttempts = 0;
      _onConnected?.call();
      
      print('WebSocket bağlantısı kuruldu');
    } catch (e) {
      _isConnecting = false;
      print('WebSocket bağlantı hatası: $e');
      _handleError(e);
    }
  }

  // Bağlantıyı kapat
  static void disconnect() {
    try {
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();
      _channel?.sink.close();
      _channel = null;
      _onDisconnected?.call();
      print('WebSocket bağlantısı kapatıldı');
    } catch (e) {
      print('WebSocket kapatma hatası: $e');
    }
  }

  // Bağlantı durumu
  static bool get isConnected => _channel != null;

  // Mesaj işleme
  static void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message.toString());
      final type = data['type'];

      print('WebSocket mesaj alındı: $type');

      // Genel mesaj callback'i çağır
      _onMessage?.call(data);

      switch (type) {
        case 'location_update':
          _onLocationUpdate?.call(data);
          break;
        case 'status_update':
          _onStatusUpdate?.call(data);
          break;
        case 'new_cargo':
          _onNewCargo?.call(data);
          break;
        case 'pong':
          // Heartbeat yanıtı - özel işlem gerekmez
          break;
        case 'connection_established':
          print('WebSocket bağlantısı onaylandı');
          break;
        case 'error':
          print('WebSocket sunucu hatası: ${data['message']}');
          _onError?.call(data['message']);
          break;
        default:
          print('Bilinmeyen mesaj tipi: $type');
      }
    } catch (e) {
      print('Mesaj işleme hatası: $e');
    }
  }

  // Hata işleme
  static void _handleError(dynamic error) {
    print('WebSocket hatası: $error');
    _onError?.call(error);
    
    // Otomatik yeniden bağlanma
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    } else {
      print('Maksimum yeniden bağlanma denemesi aşıldı');
    }
  }

  // Bağlantı kesilme işleme
  static void _handleDisconnect() {
    print('WebSocket bağlantısı kesildi');
    _channel = null;
    _heartbeatTimer?.cancel();
    _onDisconnected?.call();
    
    // Otomatik yeniden bağlanma
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  // Yeniden bağlanma zamanla
  static void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    
    final delay = Duration(seconds: _reconnectDelaySeconds * _reconnectAttempts);
    print('WebSocket yeniden bağlanma ${_reconnectAttempts}/$_maxReconnectAttempts - ${delay.inSeconds}s sonra');
    
    _reconnectTimer = Timer(delay, () {
      if (!isConnected) {
        connect();
      }
    });
  }

  // Heartbeat başlat
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (isConnected) {
        _sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Mesaj gönderme
  static void _sendMessage(Map<String, dynamic> message) {
    if (!isConnected) {
      print('WebSocket bağlı değil, mesaj gönderilemedi');
      return;
    }

    try {
      _channel!.sink.add(json.encode(message));
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
    }
  }

  // Event listeners

  static void setLocationUpdateListener(Function(Map<String, dynamic>) callback) {
    _onLocationUpdate = callback;
  }

  static void setStatusUpdateListener(Function(Map<String, dynamic>) callback) {
    _onStatusUpdate = callback;
  }

  static void setNewCargoListener(Function(Map<String, dynamic>) callback) {
    _onNewCargo = callback;
  }

  static void setMessageListener(Function(Map<String, dynamic>) callback) {
    _onMessage = callback;
  }

  static void setConnectionListener({
    Function()? onConnected,
    Function()? onDisconnected,
    Function(dynamic)? onError,
  }) {
    _onConnected = onConnected;
    _onDisconnected = onDisconnected;
    _onError = onError;
  }

  // Mesaj gönderme fonksiyonları

  // Konum güncelleme gönder
  static void sendLocationUpdate(double latitude, double longitude, int cargoId) {
    _sendMessage({
      'type': 'location_update',
      'data': {
        'cargo_id': cargoId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // Durum güncelleme gönder
  static void sendStatusUpdate(int cargoId, String status, {String? message}) {
    _sendMessage({
      'type': 'status_update',
      'data': {
        'cargo_id': cargoId,
        'status': status,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // Kargo odasına katıl
  static void joinCargoRoom(int cargoId) {
    _sendMessage({
      'type': 'join_room',
      'data': {
        'cargo_id': cargoId,
      }
    });
  }

  // Kargo odasından ayrıl
  static void leaveCargoRoom(int cargoId) {
    _sendMessage({
      'type': 'leave_room',
      'data': {
        'cargo_id': cargoId,
      }
    });
  }

  // Sürücü konumunu paylaş
  static void shareDriverLocation(double latitude, double longitude) {
    _sendMessage({
      'type': 'driver_location',
      'data': {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // Acil durum bildirimi
  static void sendEmergencyAlert(int cargoId, String alertType, {String? message}) {
    _sendMessage({
      'type': 'emergency_alert',
      'data': {
        'cargo_id': cargoId,
        'alert_type': alertType,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // Mesaj gönder (chat)
  static void sendChatMessage(int cargoId, String message) {
    _sendMessage({
      'type': 'chat_message',
      'data': {
        'cargo_id': cargoId,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // ETA (Estimated Time of Arrival) güncelleme
  static void sendETAUpdate(int cargoId, DateTime estimatedArrival) {
    _sendMessage({
      'type': 'eta_update',
      'data': {
        'cargo_id': cargoId,
        'estimated_arrival': estimatedArrival.millisecondsSinceEpoch,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // Teslim kodu doğrulama isteği
  static void requestDeliveryCodeVerification(int cargoId, String code) {
    _sendMessage({
      'type': 'verify_delivery_code',
      'data': {
        'cargo_id': cargoId,
        'delivery_code': code,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // Kargo resimleri paylaş
  static void shareCargoImages(int cargoId, List<String> imageUrls, String imageType) {
    _sendMessage({
      'type': 'cargo_images',
      'data': {
        'cargo_id': cargoId,
        'image_urls': imageUrls,
        'image_type': imageType, // 'pickup', 'delivery', 'damage'
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }
    });
  }

  // Özel mesaj gönder
  static void sendCustomMessage(String type, Map<String, dynamic> data) {
    _sendMessage({
      'type': type,
      'data': data,
    });
  }

  // Bağlantı durumunu sıfırla
  static void resetConnection() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    if (!isConnected) {
      connect();
    }
  }

  // Listener'ları temizle
  static void clearListeners() {
    _onLocationUpdate = null;
    _onStatusUpdate = null;
    _onNewCargo = null;
    _onMessage = null;
    _onConnected = null;
    _onDisconnected = null;
    _onError = null;
  }

  // Bağlantı istatistikleri
  static Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': isConnected,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
      'isConnecting': _isConnecting,
    };
  }
}

// Real-time tracking için kullanılacak model sınıfları
class LocationUpdate {
  final int cargoId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationUpdate({
    required this.cargoId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationUpdate.fromJson(Map<String, dynamic> json) {
    return LocationUpdate(
      cargoId: json['cargo_id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargo_id': cargoId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class StatusUpdate {
  final int cargoId;
  final String status;
  final String? message;
  final DateTime timestamp;

  StatusUpdate({
    required this.cargoId,
    required this.status,
    this.message,
    required this.timestamp,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      cargoId: json['cargo_id'],
      status: json['status'],
      message: json['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargo_id': cargoId,
      'status': status,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class ChatMessage {
  final int cargoId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.cargoId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      cargoId: json['cargo_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      message: json['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cargo_id': cargoId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}