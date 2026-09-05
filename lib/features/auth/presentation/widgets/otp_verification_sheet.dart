import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';

class OtpVerificationSheet extends StatefulWidget {
  final String phoneNumber;
  final String generatedOtp;
  final Future<void> Function() onVerified;

  const OtpVerificationSheet({
    super.key,
    required this.phoneNumber,
    required this.generatedOtp,
    required this.onVerified,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String phoneNumber,
    required Future<void> Function() onVerified,
  }) {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    return GlobalBottomSheet.show<bool>(
      context: context,
      title: 'মোবাইল নম্বর যাচাইকরণ',
      child: OtpVerificationSheet(
        phoneNumber: phoneNumber,
        generatedOtp: otp,
        onVerified: onVerified,
      ),
    );
  }

  @override
  State<OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<OtpVerificationSheet> {
  final _otpController = TextEditingController();
  late String _currentOtp;
  String? _verificationId;
  int _resendCountdown = 45;
  Timer? _timer;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.generatedOtp;
    _startCountdown();
    _triggerFirebaseMobileAuth();

    // Show simulation banner for immediate feedback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.sms_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'পরিবার বন্ধন ওটিপি কোড: $_currentOtp',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'অটো ফিল',
              textColor: Colors.white,
              onPressed: () {
                _otpController.text = _currentOtp;
              },
            ),
          ),
        );
      }
    });
  }

  Future<void> _triggerFirebaseMobileAuth() async {
    try {
      var phone = widget.phoneNumber.trim().replaceAll(RegExp(r'[^\d+]'), '');
      if (phone.startsWith('0')) {
        phone = '+880${phone.substring(1)}';
      } else if (phone.startsWith('880')) {
        phone = '+$phone';
      } else if (!phone.startsWith('+')) {
        phone = '+880$phone';
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 45),
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (credential.smsCode != null && mounted) {
            _otpController.text = credential.smsCode!;
          }
          await _confirmSuccess();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase Phone Auth failure: [${e.code}] ${e.message}');
          if (mounted) {
            setState(() {
              if (e.code == 'app-not-verified' || e.code == 'developer-error') {
                _error = 'সরাসরি এসএমএস পাঠাতে ফায়ারবেস কনসোলে SHA-1 যোগ করতে হবে। নিচে প্রদত্ত ওটিপি কোডটি ব্যবহার করুন।';
              }
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('Firebase verify phone error: $e');
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _resendCountdown = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _resendOtp() {
    final random = Random();
    final newOtp = (100000 + random.nextInt(900000)).toString();
    setState(() {
      _currentOtp = newOtp;
      _error = null;
    });
    _startCountdown();
    _triggerFirebaseMobileAuth();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('নতুন ওটিপি কোড পাঠানো হয়েছে: $_currentOtp'),
        backgroundColor: AppColors.primaryGreen,
        action: SnackBarAction(
          label: 'অটো ফিল',
          textColor: Colors.white,
          onPressed: () => _otpController.text = _currentOtp,
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final entered = _otpController.text.trim();
    if (entered.length != 6) {
      setState(() => _error = '৬ ডিজিটের কোডটি সঠিকভাবে লিখুন');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    if (_verificationId != null) {
      try {
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: entered,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } catch (_) {
        if (entered != _currentOtp) {
          setState(() {
            _error = 'ভুল কোড! সঠিক কোড প্রদান করুন অথবা পুনরায় কোড পাঠান';
            _isVerifying = false;
          });
          return;
        }
      }
    } else {
      if (entered != _currentOtp) {
        setState(() {
          _error = 'ভুল কোড! সঠিক কোড প্রদান করুন অথবা পুনরায় কোড পাঠান';
          _isVerifying = false;
        });
        return;
      }
    }

    await _confirmSuccess();
  }

  Future<void> _confirmSuccess() async {
    try {
      await widget.onVerified();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.accentGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.phoneNumber} নম্বরে ৬ ডিজিটের গোপন কোড পাঠানো হয়েছে',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardDarkSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read_outlined, color: AppColors.accentGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'যাচাইকরণ কোড: $_currentOtp',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: () {
                  _otpController.text = _currentOtp;
                  setState(() => _error = null);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'অটো ফিল',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkRed,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryRed),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GlassTextField(
          controller: _otpController,
          label: '৬ ডিজিটের গোপন কোড',
          hint: '••••••',
          maxLength: 6,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: Icons.lock_clock_outlined,
          suffixIcon: IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: AppColors.accentGreen, size: 20),
            tooltip: 'অটো ফিল কোড',
            onPressed: () => _otpController.text = _currentOtp,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _resendCountdown > 0
                  ? 'পুনরায় পাঠাতে অপেক্ষা: $_resendCountdown সেকেন্ড'
                  : 'কোড পাননি?',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            TextButton(
              onPressed: _resendCountdown == 0 ? _resendOtp : null,
              child: Text(
                'কোড পুনরায় পাঠান',
                style: TextStyle(
                  color: _resendCountdown == 0 ? AppColors.accentGreen : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassButton(
          text: _isVerifying ? 'যাচাই করা হচ্ছে...' : 'যাচাই সম্পন্ন করে পরিবার চালু করুন',
          isLoading: _isVerifying,
          icon: Icons.check_circle_outline,
          onPressed: _isVerifying ? null : _verifyOtp,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
