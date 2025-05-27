import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Services
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/websocket_service.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/distributor_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/add_cargo_screen.dart';
import 'screens/edit_cargo_screen.dart';
import 'screens/cargo_list_screen.dart';
import 'screens/available_cargoes_screen.dart';
import 'screens/my_cargoes_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cargo_detail_screen.dart';
import 'screens/delivery_screen.dart';
import 'screens/map_selection_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/photo_gallery_screen.dart';

import 'firebase_options.dart';

// State Management Providers
class AppStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentUser => _currentUser;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void setCurrentUser(Map<String, dynamic>? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class UserProvider extends ChangeNotifier {
  String? _userId;
  String? _username;
  String? _email;
  String? _role;
  String? _profilePhotoUrl;

  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;
  String? get profilePhotoUrl => _profilePhotoUrl;

  void setUser({
    String? userId,
    String? username,
    String? email,
    String? role,
    String? profilePhotoUrl,
  }) {
    _userId = userId;
    _username = username;
    _email = email;
    _role = role;
    _profilePhotoUrl = profilePhotoUrl;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _username = null;
    _email = null;
    _role = null;
    _profilePhotoUrl = null;
    notifyListeners();
  }

  bool get isDriver => _role == 'DRIVER';
  bool get isDistributor => _role == 'DISTRIBUTOR';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase başlatma
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('Firebase başlatıldı');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase başlatma hatası: $e');
    }
  }
  
  // Bildirim servisi başlatma
  try {
    await NotificationService.initialize();
    if (kDebugMode) {
      print('Bildirim servisi başlatıldı');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Bildirim servisi hatası: $e');
    }
  }
  
  // İzinleri kontrol et
  await _requestPermissions();

  runApp(CargoApp());
}

Future<void> _requestPermissions() async {
  try {
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted && kDebugMode) {
      print('Konum izni reddedildi!');
    }

    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted && kDebugMode) {
      print('Kamera izni reddedildi!');
    }

    if (!kIsWeb) {
      // Web platformunda storage izni desteklenmiyor, sadece mobilde iste
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted && kDebugMode) {
        print('Depolama izni reddedildi!');
      }
    }

    final notificationStatus = await Permission.notification.request();
    if (!notificationStatus.isGranted && kDebugMode) {
      print('Bildirim izni reddedildi!');
    }
  } catch (e) {
    if (kDebugMode) {
      print('İzin isteme hatası: $e');
    }
  }
}

class CargoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Cargo App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        home: SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/distributor_home': (context) => DistributorHomeScreen(),
          '/driver_home': (context) => DriverHomeScreen(),
          '/profile': (context) => ProfileScreen(),
          // ROUTE'LARI DÜZELTTİM - STATIC ROUTE OLARAK EKLEDİM
          '/add_cargo': (context) => AddCargoScreen(),
          '/cargo_list': (context) => CargoListScreen(),
          '/available_cargoes': (context) => AvailableCargoesScreen(),
          '/my_cargoes': (context) => MyCargoesScreen(),
          '/forgot_password': (context) => ForgotPasswordScreen(),
        },
        onGenerateRoute: (settings) {
          if (kDebugMode) {
            print('=== ROUTE DEBUG ===');
            print('Route name: ${settings.name}');
            print('Arguments: ${settings.arguments}');
            print('==================');
          }
          
          try {
            switch (settings.name) {
              case '/verification':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => VerificationScreen(
                    email: args?['email'] ?? '',
                  ),
                );
              case '/edit_cargo':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null || args['cargo'] == null) {
                  if (kDebugMode) {
                    print('HATA: edit_cargo için cargo parametresi eksik!');
                  }
                  return MaterialPageRoute(
                    builder: (context) => _buildErrorPage(
                      context, 
                      'Kargo bilgisi bulunamadı',
                      'Kargo düzenleme sayfasına erişmek için geçerli bir kargo seçin.'
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => EditCargoScreen(
                    cargo: args['cargo'],
                  ),
                );
              case '/cargo_detail':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null || args['cargo'] == null) {
                  if (kDebugMode) {
                    print('HATA: cargo_detail için cargo parametresi eksik!');
                  }
                  return MaterialPageRoute(
                    builder: (context) => _buildErrorPage(
                      context, 
                      'Kargo bilgisi bulunamadı',
                      'Kargo detay sayfasına erişmek için geçerli bir kargo seçin.'
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => CargoDetailScreen(
                    cargo: args['cargo'],
                    isDriver: args?['isDriver'] ?? false,
                  ),
                );
              case '/delivery':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args == null || args['cargo'] == null) {
                  if (kDebugMode) {
                    print('HATA: delivery için cargo parametresi eksik!');
                  }
                  return MaterialPageRoute(
                    builder: (context) => _buildErrorPage(
                      context, 
                      'Kargo bilgisi bulunamadı',
                      'Teslimat sayfasına erişmek için geçerli bir kargo seçin.'
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (context) => DeliveryScreen(
                    cargo: args['cargo'],
                  ),
                );
              case '/map_selection':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => MapSelectionScreen(
                    initialLocation: args?['initialLocation'],
                    title: args?['title'] ?? 'Konum Seç',
                  ),
                );
              case '/rating':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => RatingScreen(
                    cargo: args?['cargo'] ?? {},
                    ratingType: args?['ratingType'] ?? 'driver',
                    targetUserId: args?['targetUserId'] ?? 0,
                    targetUserName: args?['targetUserName'] ?? '',
                  ),
                );
              case '/photo_gallery':
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => PhotoGalleryScreen(
                    cargoId: args?['cargoId'] ?? 0,
                    canAddPhotos: args?['canAddPhotos'] ?? false,
                    initialPhotos: List<String>.from(args?['initialPhotos'] ?? []),
                  ),
                );
              default:
                if (kDebugMode) {
                  print('Bilinmeyen route: ${settings.name}');
                }
                return MaterialPageRoute(
                  builder: (context) => _buildNotFoundPage(context, settings.name),
                );
            }
          } catch (e) {
            if (kDebugMode) {
              print('Route oluşturma hatası: $e');
              print('Settings: ${settings.name}');
              print('Arguments: ${settings.arguments}');
            }
            return MaterialPageRoute(
              builder: (context) => _buildErrorPage(
                context,
                'Sayfa Yükleme Hatası',
                'Sayfa yüklenirken bir hata oluştu: $e'
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildNotFoundPage(BuildContext context, String? routeName) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sayfa Bulunamadı'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Sayfa Bulunamadı',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              if (routeName != null) ...[
                Text(
                  'Aranan sayfa: $routeName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
              ],
              Text(
                'Bu sayfa mevcut değil veya kaldırılmış olabilir.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                    label: Text('Geri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/login', 
                      (route) => false
                    ),
                    icon: Icon(Icons.home),
                    label: Text('Ana Sayfa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage(BuildContext context, String title, String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hata'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                    label: Text('Geri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/login', 
                      (route) => false
                    ),
                    icon: Icon(Icons.refresh),
                    label: Text('Yenile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final _secureStorage = FlutterSecureStorage();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animasyon kontrolcüsü
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Splash ekranı için minimum bekleme süresi
    await Future.delayed(Duration(seconds: 3));
    
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final role = await _secureStorage.read(key: 'user_role');
      
      if (kDebugMode) {
        print('=== AUTH CHECK ===');
        print('Token exists: ${token != null}');
        print('Role: $role');
        print('==================');
      }
      
      if (token != null && role != null) {
        // Token geçerliliğini kontrol et
        final isValid = await _validateToken(token);
        
        if (isValid) {
          // WebSocket bağlantısını başlat (hata durumunda devam et)
          try {
            await WebSocketService.connect();
          } catch (e) {
            if (kDebugMode) {
              print('WebSocket bağlantı hatası: $e');
            }
            // WebSocket bağlantı hatası uygulamayı durdurmasın
          }
          
          // Kullanıcıyı rolüne göre yönlendir
          if (mounted) {
            if (role == 'DISTRIBUTOR') {
              Navigator.pushReplacementNamed(context, '/distributor_home');
            } else if (role == 'DRIVER') {
              Navigator.pushReplacementNamed(context, '/driver_home');
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        } else {
          // Token geçersizse temizle ve login'e yönlendir
          await _secureStorage.deleteAll();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Auth kontrol hatası: $e');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<bool> _validateToken(String token) async {
    try {
      // Token doğrulama için basit bir API çağrısı
      final userInfo = await AuthService.getNameFromToken(token);
      return userInfo != null;
    } catch (e) {
      if (kDebugMode) {
        print('Token doğrulama hatası: $e');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[400] ?? Colors.blue,
              Colors.blue[600] ?? Colors.blue,
              Colors.blue[800] ?? Colors.blue,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_shipping,
                          size: 80,
                          color: Colors.blue[600],
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // Başlık
                      Text(
                        'Cargo App',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      
                      // Alt başlık
                      Text(
                        'Hızlı ve Güvenli Kargo Taşımacılığı',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 50),
                      
                      // Loading göstergesi
                      Container(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      Text(
                        'Başlatılıyor...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}