import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/auth_validators.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../expenses/presentation/screens/dashboard_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/otp_verification_sheet.dart';
import '../../../family_management/data/datasources/family_firestore_datasource.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final FamilyFirestoreDatasource _datasource = FamilyFirestoreDatasource();
  int _activeTab = 0;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final phoneErr = AuthValidators.validatePhone(phone);
    if (phoneErr != null) {
      setState(() => _errorMessage = phoneErr);
      return;
    }

    if (_activeTab == 0) {
      // Login flow: User logs in directly using Phone + Password
      if (password.isEmpty) {
        setState(() => _errorMessage = 'পাসওয়ার্ড প্রদান করুন');
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(authUserProvider.notifier).login(
              phoneNumber: phone,
              password: password,
            );

        // Initialize Firebase notifications & retrieve/sync FCM token
        final user = ref.read(authUserProvider);
        try {
          await NotificationService().initializeNotificationEngine(userIdOrPhone: phone);
          if (user?.activeFamilyId != null && user!.activeFamilyId.isNotEmpty) {
            NotificationService().listenToFamilyNotifications(user.activeFamilyId);
            if (NotificationService().cachedFcmToken != null) {
              await NotificationService().syncTokenToFirestore(
                phone,
                NotificationService().cachedFcmToken!,
                familyId: user.activeFamilyId,
              );
            }
          }
        } catch (_) {}

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          String raw = e.toString().replaceAll('Exception:', '').trim();
          String friendlyMsg;
          if (raw.contains('PERMISSION_DENIED') ||
              raw.contains('unavailable') ||
              raw.contains('offline') ||
              raw.contains('UnknownHostException') ||
              raw.contains('cloud_firestore')) {
            friendlyMsg =
                'সার্ভারের সাথে সংযোগ পাওয়া যায়নি। অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ অথবা ফায়ারবেস ক্লাউড ফায়ারস্টোর ডাটাবেস সক্রিয় আছে কিনা যাচাই করুন।';
          } else {
            friendlyMsg = raw;
          }
          setState(() {
            _errorMessage = friendlyMsg;
            _isLoading = false;
          });
        }
      }
    } else {
      // Registration flow: Requires strict Password Regex and Mobile OTP verification
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => _errorMessage = 'আপনার পূর্ণ নাম লিখুন');
        return;
      }

      final passErr = AuthValidators.validatePassword(password);
      if (passErr != null) {
        setState(() => _errorMessage = passErr);
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
      try {
        final existing = await _datasource.getUserByPhone(cleanPhone);
        if (existing != null) {
          final role = existing['role']?.toString() ?? 'member';
          final isOwner = existing['isFamilyOwner'] == true;
          setState(() {
            _isLoading = false;
            if (role == 'admin' || isOwner) {
              _errorMessage = 'এই নম্বরে ইতিমধ্যে অ্যাডমিন অ্যাকাউন্ট রয়েছে! নতুন অ্যাকাউন্ট তৈরি সম্ভব নয়, অনুগ্রহ করে সরাসরি লগইন করুন।';
            } else {
              _errorMessage = 'এই নম্বরে ইতিমধ্যে পরিবার সদস্যের অ্যাকাউন্ট রয়েছে! অনুগ্রহ করে সরাসরি পাসওয়ার্ড দিয়ে লগইন করুন।';
            }
          });
          return;
        }
      } catch (_) {}

      setState(() => _isLoading = false);
      if (!mounted) return;

      // Open OTP Verification Sheet
      final verified = await OtpVerificationSheet.show(
        context: context,
        phoneNumber: phone,
        onVerified: () async {
          await ref.read(authUserProvider.notifier).signUp(
                fullName: name,
                phoneNumber: phone,
                password: password,
              );
          // Initialize Firebase notifications & retrieve/sync FCM token
          final registeredUser = ref.read(authUserProvider);
          try {
            await NotificationService().initializeNotificationEngine(userIdOrPhone: phone);
            if (registeredUser?.activeFamilyId != null && registeredUser!.activeFamilyId.isNotEmpty) {
              NotificationService().listenToFamilyNotifications(registeredUser.activeFamilyId);
              if (NotificationService().cachedFcmToken != null) {
                await NotificationService().syncTokenToFirestore(
                  phone,
                  NotificationService().cachedFcmToken!,
                  familyId: registeredUser.activeFamilyId,
                );
              }
            }
          } catch (_) {}
        },
      );

      if (verified == true && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom > 0
        ? MediaQuery.of(context).viewPadding.bottom + 20
        : 24.0;

    return GlassScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.iosDivider),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: AppColors.primaryGreen,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'পরিবার বন্ধন',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'স্মার্ট পারিবারিক হিসাব ও বাজেট নিয়ন্ত্রণ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _activeTab = 0;
                          _errorMessage = null;
                          _obscurePassword = true;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? AppColors.cardDarkSecondary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'লগইন',
                            style: TextStyle(
                              color: _activeTab == 0 ? Colors.white : AppColors.textSecondary,
                              fontWeight: _activeTab == 0 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _activeTab = 1;
                          _errorMessage = null;
                          _obscurePassword = true;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? AppColors.cardDarkSecondary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'নতুন পরিবার',
                            style: TextStyle(
                              color: _activeTab == 1 ? Colors.white : AppColors.textSecondary,
                              fontWeight: _activeTab == 1 ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkRed,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.primaryRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (_activeTab == 1) ...[
                GlassTextField(
                  controller: _nameController,
                  label: 'আপনার পূর্ণ নাম',
                  hint: 'যেমন: তানভীর আহমেদ',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
              ],
              GlassTextField(
                controller: _phoneController,
                label: 'মোবাইল নম্বর',
                hint: '০১XXXXXXXXX',
                maxLength: 11,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                prefixIcon: Icons.phone_android_outlined,
              ),
              const SizedBox(height: 12),
              GlassTextField(
                controller: _passwordController,
                label: _activeTab == 1 ? 'পাসওয়ার্ড (৮+ অক্ষর, বড়-ছোট হাত ও সংখ্যা)' : 'পাসওয়ার্ড',
                hint: 'গোপন পাসওয়ার্ড লিখুন',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 22),
              GlassButton(
                text: _activeTab == 0
                    ? 'প্রবেশ করুন'
                    : 'ওটিপি পাঠান ও পরিবার খুলুন',
                isLoading: _isLoading,
                icon: _activeTab == 0 ? Icons.login_rounded : Icons.sms_outlined,
                onPressed: _isLoading ? null : _handleAuth,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
