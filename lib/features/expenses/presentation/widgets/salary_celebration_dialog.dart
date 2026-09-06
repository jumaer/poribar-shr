import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/widgets/glass_button.dart';

class SalaryCelebrationDialog extends ConsumerWidget {
  final double amount;
  final String userName;
  final DateTime date;
  final String? slipImageBase64;

  const SalaryCelebrationDialog({
    super.key,
    required this.amount,
    required this.userName,
    required this.date,
    this.slipImageBase64,
  });

  static Future<void> show(
    BuildContext context, {
    required double amount,
    required String userName,
    required DateTime date,
    String? slipImageBase64,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => SalaryCelebrationDialog(
        amount: amount,
        userName: userName,
        date: date,
        slipImageBase64: slipImageBase64,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    // 50/30/20 breakdown
    final essential = amount * 0.50;
    final lifestyle = amount * 0.30;
    final savings = amount * 0.20;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.translate('salary_alhamdulillah'),
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('salary_celebration_subtitle'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              // Big amount display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      '৳ ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.translate('deposited_by')}: $userName • ${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (slipImageBase64 != null && slipImageBase64!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iosDivider),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: FirestoreImageService.buildFirestoreImage(
                          base64Data: slipImageBase64,
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.translate('salary_slip_attached'),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Smart budget allocation guide
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.translate('smart_budget_advice'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildAllocationRow(
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFF3B82F6),
                title: l10n.translate('budget_50_essential'),
                amount: essential,
              ),
              const SizedBox(height: 6),
              _buildAllocationRow(
                icon: Icons.local_mall_outlined,
                color: const Color(0xFFEC4899),
                title: l10n.translate('budget_30_lifestyle'),
                amount: lifestyle,
              ),
              const SizedBox(height: 6),
              _buildAllocationRow(
                icon: Icons.savings_outlined,
                color: AppColors.primaryGreen,
                title: l10n.translate('budget_20_savings'),
                amount: savings,
              ),
              const SizedBox(height: 20),
              GlassButton(
                text: l10n.translate('salary_done_btn'),
                icon: Icons.check,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationRow({
    required IconData icon,
    required Color color,
    required String title,
    required double amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDarkSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.iosDivider),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          Text(
            '৳ ${amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
