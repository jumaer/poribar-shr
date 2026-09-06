import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'core/l10n/l10n_provider.dart';
import 'features/amol/services/amol_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // Automatically seed all static Surahs, Duas, Amols, and Configs to Firestore if missing on server
    AmolService().autoSeedSuperGlobalDefaults();
  } catch (_) {}

  // Setup notification click routing
  NotificationService().setupNotificationClickHandlers(rootNavigatorKey);

  runApp(
    const ProviderScope(
      child: MultiFamilyApp(),
    ),
  );
}

class MultiFamilyApp extends ConsumerWidget {
  const MultiFamilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'SRH - এসআরএইচ',
      locale: locale,
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
