import 'package:flutter/material.dart';
import 'package:oneai/providers/auth_provider.dart';
import 'package:oneai/providers/chat_provider.dart';
import 'package:oneai/screens/auth/auth_wrapper.dart';
import 'package:oneai/screens/settings_screen.dart';
import 'package:oneai/screens/pocketbase_setup_screen.dart';
import 'package:oneai/services/api_key_service.dart';
import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/storage_manager.dart';
import 'package:provider/provider.dart';
import 'package:oneai/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    try {
      final isDarkMode = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getBool('is_dark_mode') ?? false);
      _isDarkMode = isDarkMode;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool('is_dark_mode', _isDarkMode));
    notifyListeners();
  }
}

class StorageProvider extends ChangeNotifier {
  final StorageManager _storageManager = StorageManager();
  bool _isInitialized = false;
  StorageType _currentStorage = StorageType.local;
  bool _autoSync = false;
  Map<String, dynamic> _storageStatus = {};

  StorageManager get storageManager => _storageManager;
  bool get isInitialized => _isInitialized;
  StorageType get currentStorage => _currentStorage;
  bool get autoSync => _autoSync;
  Map<String, dynamic> get storageStatus => _storageStatus;

  Future<void> initialize() async {
    try {
      print('🚀 Initializing Storage Provider...');
      await _storageManager.initialize();
      _currentStorage = _storageManager.currentStorage;
      _autoSync = _storageManager.autoSync;
      _isInitialized = true;
      await refreshStatus();
      print('✅ Storage Provider initialized successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing Storage Provider: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> refreshStatus() async {
    try {
      _storageStatus = await _storageManager.getStorageStatus();
      notifyListeners();
    } catch (e) {
      print('Error refreshing storage status: $e');
    }
  }

  Future<bool> switchStorage(StorageType newType) async {
    try {
      final success = await _storageManager.switchStorage(newType);
      if (success) {
        _currentStorage = newType;
        await refreshStatus();
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error switching storage: $e');
      return false;
    }
  }

  Future<void> setAutoSync(bool enabled) async {
    try {
      await _storageManager.setAutoSync(enabled);
      _autoSync = enabled;
      notifyListeners();
    } catch (e) {
      print('Error setting auto sync: $e');
    }
  }

  Future<bool> migrateToCloud() async {
    try {
      final success = await _storageManager.migrateToCloud();
      if (success) {
        await refreshStatus();
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error migrating to cloud: $e');
      return false;
    }
  }

  Future<bool> syncData() async {
    try {
      return await _storageManager.syncData();
    } catch (e) {
      print('Error syncing data: $e');
      return false;
    }
  }

  Future<StorageType> getRecommendedStorage() async {
    try {
      return await _storageManager.getRecommendedStorage();
    } catch (e) {
      print('Error getting recommended storage: $e');
      return StorageType.local;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting OneAI Chatbot Hub...');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables if available
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Environment variables loaded");
  } catch (e) {
    // .env file might not exist, which is fine
    print("ℹ️ No .env file found. Using SharedPreferences for API keys.");
  }

  // Initialize local database (SharedPreferences)
  try {
    final dbService = DatabaseService();
    await dbService.database; // This will initialize SharedPreferences
    print("✅ Local database initialized successfully");
  } catch (e) {
    print("❌ Error initializing local database: $e");
  }

  // Load API keys
  try {
    await ApiKeyService.loadAllApiKeys();
    print("✅ API keys loaded successfully");
  } catch (e) {
    print("❌ Error loading API keys: $e");
  }

  print("🎉 OneAI initialization completed!");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => StorageProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'OneAI Chatbot Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppInitializer(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/pocketbase-setup': (context) => const PocketBaseSetupScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle dynamic routes if needed
              switch (settings.name) {
                case '/pocketbase-setup':
                  return MaterialPageRoute(
                    builder: (context) => const PocketBaseSetupScreen(),
                    settings: settings,
                  );
                default:
                  return null;
              }
            },
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;
  String _initializationStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _initializationStatus = 'Initializing storage...';
      });

      // Initialize storage provider
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      await storageProvider.initialize();

      setState(() {
        _initializationStatus = 'Loading user data...';
      });

      // Initialize auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Auth provider will initialize automatically

      setState(() {
        _initializationStatus = 'Setting up chat...';
      });

      // Initialize chat provider
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.initialize();

      setState(() {
        _initializationStatus = 'Ready!';
      });

      // Small delay to show "Ready!" message
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('❌ App initialization error: $e');
      setState(() {
        _initializationStatus = 'Initialization failed. Using local storage.';
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App title
                  const Text(
                    'OneAI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chatbot Hub',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Loading indicator
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status text
                  Text(
                    _initializationStatus,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Version info
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const AuthWrapper();
  }
}
