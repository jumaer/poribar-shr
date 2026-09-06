import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';

class OtpVerificationSheet extends ConsumerStatefulWidget {
  final String phoneNumber;
  final Future<void> Function() onVerified;

  const OtpVerificationSheet({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String phoneNumber,
    required Future<void> Function() onVerified,
  }) {
    return GlobalBottomSheet.show<bool>(
      context: context,
      title: 'OTP Verification',
      child: OtpVerificationSheet(
        phoneNumber: phoneNumber,
        onVerified: onVerified,
      ),
    );
  }

  @override
  ConsumerState<OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends ConsumerState<OtpVerificationSheet> {
  final _otpController = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  int _resendCountdown = 60;
  Timer? _timer;
  bool _isSendingCode = true;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _statusInfo;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _triggerFirebaseMobileAuth();
  }

  String _formatPhoneForFirebase(String raw) {
    var phone = raw.trim().replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('0')) {
      phone = '+880${phone.substring(1)}';
    } else if (phone.startsWith('880')) {
      phone = '+$phone';
    } else if (!phone.startsWith('+')) {
      phone = '+880$phone';
    }
    return phone;
  }

  Future<void> _triggerFirebaseMobileAuth({bool isResend = false}) async {
    final l10n = ref.read(appLocalizationsProvider);
    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
      _statusInfo = l10n.translate('otp_sending_status');
    });

    final formattedPhone = _formatPhoneForFirebase(widget.phoneNumber);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Firebase auto-verification completed');
          if (credential.smsCode != null && mounted) {
            _otpController.text = credential.smsCode!;
          }
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            await _confirmSuccess();
          } catch (e) {
            debugPrint('Auto signInWithCredential error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase Phone Auth failure: [${e.code}] ${e.message}');
          if (!mounted) return;
          final errStr = '${e.code} ${e.message} $e'.toLowerCase();
          String friendly;
          if (errStr.contains('billing') || errStr.contains('billing_not_enabled')) {
            friendly = l10n.language == AppLanguage.bangla
                ? 'ফায়ারবেস এসএমএস গেটওয়েতে বিলিং অ্যাকাউন্ট (Blaze Plan) সক্রিয় করা প্রয়োজন।'
                : 'Firebase SMS gateway requires a billing account (Blaze Plan) to send SMS.';
          } else {
            switch (e.code) {
              case 'operation-not-allowed':
                friendly = 'ফায়ারবেস কনসোলে বাংলাদেশ (+880) এর এসএমএস পলিসি অথবা টেস্ট ফোন নম্বর সক্রিয় করুন।';
                break;
              case 'invalid-phone-number':
                friendly = 'মোবাইল নম্বরটি সঠিক নয়। অনুগ্রহ করে সঠিক ১১ ডিজিটের নম্বর দিন।';
                break;
              case 'too-many-requests':
                friendly = 'খুব বেশি রিকোয়েস্ট পাঠানো হয়েছে। অনুগ্রহ করে কিছুক্ষণ পর আবার চেষ্টা করুন।';
                break;
              case 'app-not-verified':
              case 'developer-error':
                friendly = 'ফায়ারবেস কনসোলে অ্যাপের SHA-1 ও SHA-256 যোগ করা প্রয়োজন।';
                break;
              default:
                friendly = e.message ?? l10n.translate('otp_verification_failed');
            }
          }
          setState(() {
            _isSendingCode = false;
            _errorMessage = friendly;
            _statusInfo = null;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Firebase SMS OTP codeSent: verificationId=$verificationId');
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isSendingCode = false;
            _statusInfo = '$formattedPhone ${l10n.translate("otp_sent_status")}';
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('verifyPhoneNumber invocation error: $e');
      if (mounted) {
        setState(() {
          _isSendingCode = false;
          _errorMessage = '$e';
          _statusInfo = null;
        });
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _resendCountdown = 60;
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
    _startCountdown();
    _triggerFirebaseMobileAuth(isResend: true);
  }

  Future<void> _verifyOtp() async {
    final l10n = ref.read(appLocalizationsProvider);
    final entered = _otpController.text.trim();
    if (entered.length != 6) {
      setState(() => _errorMessage = l10n.translate('otp_enter_6_digits'));
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = _errorMessage ?? l10n.translate('otp_code_not_sent_yet'));
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: entered,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('Firebase Phone Auth signInWithCredential SUCCESS');
      await _confirmSuccess();
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP verify error [${e.code}]: ${e.message}');
      if (mounted) {
        String msg;
        if (e.code == 'invalid-verification-code') {
          msg = l10n.translate('otp_invalid_code');
        } else if (e.code == 'session-expired') {
          msg = l10n.translate('otp_session_expired');
        } else {
          msg = e.message ?? l10n.translate('otp_verification_failed');
        }
        setState(() {
          _isVerifying = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _errorMessage = '$e';
        });
      }
    }
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
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);

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
              const Icon(Icons.phone_android_rounded, color: AppColors.accentGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.phoneNumber} ${l10n.translate("otp_info_prefix")}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (_statusInfo != null && _errorMessage == null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Row(
              children: [
                if (_isSendingCode)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                  )
                else
                  const Icon(Icons.mark_email_read_outlined, color: AppColors.accentGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusInfo!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        GlassTextField(
          controller: _otpController,
          label: l10n.translate('otp_code_label'),
          hint: '••••••',
          maxLength: 6,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: Icons.sms_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _resendCountdown > 0
                    ? '${l10n.translate("otp_wait_seconds")}: $_resendCountdown ${l10n.translate("otp_seconds_unit")}'
                    : l10n.translate('otp_didnt_get_code'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: (_resendCountdown == 0 && !_isSendingCode) ? _resendOtp : null,
              child: Text(
                l10n.translate('otp_resend'),
                style: TextStyle(
                  color: (_resendCountdown == 0 && !_isSendingCode)
                      ? AppColors.accentGreen
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassButton(
          text: _isVerifying ? l10n.translate('otp_verifying') : l10n.translate('otp_verify_btn'),
          isLoading: _isVerifying,
          icon: Icons.verified_user_outlined,
          onPressed: (_isVerifying || _isSendingCode) ? null : _verifyOtp,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
