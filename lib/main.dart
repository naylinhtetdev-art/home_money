import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:home_money/controllers/profile_controller.dart';
import 'package:home_money/providers/notification_provider.dart';
import 'package:home_money/services/auth_service.dart';
import 'package:home_money/services/notification_service.dart';
import 'package:home_money/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'views/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, initialize Firebase.
  await Firebase.initializeApp();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup background message handler for Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions (iOS / Android 13+)
  try {
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {}

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  // Initialize NotificationService (local notifications, tap handlers)
  try {
    await NotificationService.instance.initialize(navigatorKey: navigatorKey);
    await NotificationService.instance.handleInitialMessage();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  runApp(HomeMoneyApp(themeProvider: themeProvider));
}

class HomeMoneyApp extends StatelessWidget {
  const HomeMoneyApp({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;
  //final themeProvider = ThemeProvider();
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        ChangeNotifierProvider<ProfileController>(
          create: (context) => ProfileController(
            authService: context.read<AuthService>(),
            profileService: context.read<ProfileService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => AuthNotificationBinder(
          child: MaterialApp(
            title: AppStrings.appName,
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _theme(Brightness.light),
            darkTheme: _theme(Brightness.dark),
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: brightness == Brightness.light
        ? AppColors.background
        : null,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

/// Widget that binds auth state to notification lifecycle.
class AuthNotificationBinder extends StatefulWidget {
  final Widget child;
  const AuthNotificationBinder({required this.child, super.key});

  @override
  State<AuthNotificationBinder> createState() => _AuthNotificationBinderState();
}

class _AuthNotificationBinderState extends State<AuthNotificationBinder> {
  String? _currentUid;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      // initial sync
      _handleAuthChange();
      // listen for future changes
      _listener = () => _handleAuthChange();
      auth.addListener(_listener!);
    });
  }

  Future<void> _handleAuthChange() async {
    final auth = context.read<AuthProvider>();
    final notif = context.read<NotificationProvider>();
    final newUid = auth.user?.uid;

    if (_currentUid == newUid) return;

    final old = _currentUid;
    _currentUid = newUid;

    if (old != null) {
      try {
        await NotificationService.instance.removeToken(old);
      } catch (_) {}
      try {
        notif.stop();
      } catch (_) {}
    }

    if (newUid != null) {
      try {
        await NotificationService.instance.saveTokenForUser(newUid);
      } catch (_) {}
      try {
        notif.start(newUid);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    final auth = context.read<AuthProvider>();
    if (_listener != null) auth.removeListener(_listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
