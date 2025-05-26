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


// State Management
import 'providers/app_state_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase başlatma
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase başlatıldı');
  } catch (e) {
    print('Firebase başlatma hatası: $e');
  }
  
  // Bildirim servisi başlatma
  try {
    await NotificationService.initialize();
    print('Bildirim servisi başlatıldı');
  } catch (e) {
    print('Bildirim servisi hatası: $e');
  }
  
  // İzinleri kontrol et
  await _requestPermissions();
  
  runApp(CargoApp());
}

Future<void> _requestPermissions() async {
  final locationStatus = await Permission.location.request();
  if (!locationStatus.isGranted) {
    print('Konum izni reddedildi!');
  }

  final cameraStatus = await Permission.camera.request();
  if (!cameraStatus.isGranted) {
    print('Kamera izni reddedildi!');
  }

  if (!kIsWeb) {
    // Web platformunda storage izni desteklenmiyor, sadece mobilde iste
    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      print('Depolama izni reddedildi!');
    }
  } else {
    print('Storage permission is not required on web');
  }

  final notificationStatus = await Permission.notification.request();
  if (!notificationStatus.isGranted) {
    print('Bildirim izni reddedildi!');
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
        },
        onGenerateRoute: (settings) {
          // Dinamik routing için
          switch (settings.name) {
            case '/verification':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => VerificationScreen(
                  email: args['email'],
                ),
              );
            case '/forgot_password':
              return MaterialPageRoute(
                builder: (context) => ForgotPasswordScreen(),
              );
            case '/add_cargo':
              return MaterialPageRoute(
                builder: (context) => AddCargoScreen(),
              );
            case '/edit_cargo':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => EditCargoScreen(
                  cargo: args['cargo'],
                ),
              );
            case '/cargo_list':
              return MaterialPageRoute(
                builder: (context) => CargoListScreen(),
              );
            case '/available_cargoes':
              return MaterialPageRoute(
                builder: (context) => AvailableCargoesScreen(),
              );
            case '/my_cargoes':
              return MaterialPageRoute(
                builder: (context) => MyCargoesScreen(),
              );
            case '/cargo_detail':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => CargoDetailScreen(
                  cargo: args['cargo'],
                  isDriver: args['isDriver'] ?? false,
                ),
              );
            case '/delivery':
              final args = settings.arguments as Map<String, dynamic>;
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
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => RatingScreen(
                  cargo: args['cargo'],
                  ratingType: args['ratingType'],
                  targetUserId: args['targetUserId'],
                  targetUserName: args['targetUserName'],
                ),
              );
            case '/photo_gallery':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => PhotoGalleryScreen(
                  cargoId: args['cargoId'],
                  canAddPhotos: args['canAddPhotos'] ?? false,
                  initialPhotos: args['initialPhotos'] ?? [],
                ),
              );
            default:
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: Text('Sayfa Bulunamadı')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Sayfa bulunamadı',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: Text('Ana Sayfaya Dön'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
          }
        },
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
      
      if (token != null && role != null) {
        // Token geçerliliğini kontrol et
        final isValid = await _validateToken(token);
        
        if (isValid) {
          // WebSocket bağlantısını başlat
          await WebSocketService.connect();
          
          // Kullanıcıyı rolüne göre yönlendir
          if (role == 'DISTRIBUTOR') {
            Navigator.pushReplacementNamed(context, '/distributor_home');
          } else if (role == 'DRIVER') {
            Navigator.pushReplacementNamed(context, '/driver_home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          // Token geçersizse temizle ve login'e yönlendir
          await _secureStorage.deleteAll();
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Auth kontrol hatası: $e');
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<bool> _validateToken(String token) async {
    try {
      // Token doğrulama için basit bir API çağrısı
      final userInfo = await AuthService.getNameFromToken(token);
      return userInfo != null;
    } catch (e) {
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

// Global Error Handler
class GlobalErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Flutter Error: ${details.exception}');
      print('Stack Trace: ${details.stack}');
    };
  }
}

// App State Provider - Global durum yönetimi için
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

// User Provider - Kullanıcı bilgileri için
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