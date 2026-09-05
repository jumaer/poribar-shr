import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/splash_config_service.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../expenses/presentation/screens/dashboard_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String? _customSplashImage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();

    _loadSplashImage();

    // Trigger notification permission request right after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authUserProvider);
      NotificationService().initializeNotificationEngine(
        userIdOrPhone: user?.phoneNumber.isNotEmpty == true ? user!.phoneNumber : user?.activeFamilyId,
      );
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        final user = ref.read(authUserProvider);
        if (user != null && user.activeFamilyId.isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }

  Future<void> _loadSplashImage() async {
    final user = ref.read(authUserProvider);
    final img = await SplashConfigService().getSplashImage(familyId: user?.activeFamilyId);
    if (mounted && img != null) {
      setState(() {
        _customSplashImage = img;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.iosDivider),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _customSplashImage != null
                      ? FirestoreImageService.buildFirestoreImage(
                          base64Data: _customSplashImage,
                          width: 85,
                          height: 85,
                        )
                      : Image.asset(
                          'assets/icon/app_icon.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.darkGreen,
                            ),
                            child: const Icon(Icons.family_restroom, size: 52, color: Colors.white),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'পরিবার বন্ধন',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'স্মার্ট যৌথ পরিবার ম্যানেজমেন্ট',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
