import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/sos_shake_service.dart';

class SosAlertDialog extends StatefulWidget {
  final SosTriggerEvent event;

  const SosAlertDialog({
    super.key,
    required this.event,
  });

  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  static Future<void> show(BuildContext context, SosTriggerEvent event) async {
    if (_isShowing) {
      debugPrint('SosAlertDialog already showing, suppressing duplicate dialog popup.');
      return;
    }
    _isShowing = true;
    SosShakeService().isSosDialogActive = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SosAlertDialog(event: event),
      );
    } finally {
      _isShowing = false;
      SosShakeService().isSosDialogActive = false;
    }
  }

  @override
  State<SosAlertDialog> createState() => _SosAlertDialogState();
}

class _SosAlertDialogState extends State<SosAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnimation;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _copyLocationUrl() {
    Clipboard.setData(ClipboardData(text: widget.event.locationUrl));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryRed.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pulse Icon
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryRed.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.primaryRed.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: AppColors.primaryRed,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              '🚨 জরুরি SOS এলার্ট প্রেরিত!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              'মোবাইল ঝাঁকুনির (Shake) মাধ্যমে বিপদ সংকেত শনাক্ত করা হয়েছে এবং পরিবারের সদস্যদের কাছে পাঠানো হয়েছে।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Location Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDarkSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.iosDivider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryGreen, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        widget.event.isLocationAcquired
                            ? 'বর্তমান জিপিএস অবস্থান'
                            : 'অবস্থান নির্ণয় ব্যর্থ',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.event.isLocationAcquired) ...[
                    Text(
                      'অক্ষাংশ: ${widget.event.latitude?.toStringAsFixed(6)}, দ্রাঘিমাংশ: ${widget.event.longitude?.toStringAsFixed(6)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _copyLocationUrl,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardDarkElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.iosDivider),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ম্যাপের লিংক কপি করুন',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              _copied ? Icons.check_circle : Icons.copy_rounded,
                              color: _copied ? AppColors.primaryGreen : AppColors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'লোকেশন পারমিশন বন্ধ ছিল অথবা জিপিএস সিগন্যাল পাওয়া যায়নি। সেটিংসে লোকেশন পারমিশন চালু করুন।',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency helpline reminder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.glassRedTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.call, color: AppColors.primaryRed, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'প্রয়োজনে দ্রুত ৯৯৯ (জাতীয় জরুরি সেবা) এ কল করুন।',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.iosDivider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'আমি নিরাপদ আছি',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
