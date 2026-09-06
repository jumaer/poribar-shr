import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {}

  // Setup notification click routing
  NotificationService().setupNotificationClickHandlers(rootNavigatorKey);

  runApp(
    const ProviderScope(
      child: MultiFamilyApp(),
    ),
  );
}

class MultiFamilyApp extends StatelessWidget {
  const MultiFamilyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'SRH - এসআরএইচ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryGreen,
          secondary: AppColors.primaryRed,
          surface: AppColors.cardDark,
        ),
        tabBarTheme: const TabBarThemeData(
          dividerColor: Colors.transparent,
          dividerHeight: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
