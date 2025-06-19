import 'package:flutter/material.dart';
import 'package:oneai/providers/auth_provider.dart';
import 'package:oneai/providers/chat_provider.dart';
import 'package:oneai/screens/auth/auth_wrapper.dart';
import 'package:oneai/screens/settings_screen.dart';
import 'package:oneai/screens/storage_settings_screen.dart';
import 'package:oneai/services/api_key_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Load environment variables if available
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file might not exist, which is fine
    print("No .env file found. Using SharedPreferences for API keys.");
  }

  // Initialize Storage Manager
  try {
    final storageManager = StorageManager();
    await storageManager.initialize();
    print("✅ Storage Manager initialized successfully");
  } catch (e) {
    print("❌ Error initializing Storage Manager: $e");
  }

  // Load API keys
  try {
    await ApiKeyService.loadAllApiKeys();
    print("✅ API keys loaded successfully");
  } catch (e) {
    print("❌ Error loading API keys: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'OneAI Chatbot Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            routes: {
              '/settings': (context) => const SettingsScreen(),
              '/storage-settings': (context) => const StorageSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
