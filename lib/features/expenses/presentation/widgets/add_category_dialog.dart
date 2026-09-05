import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/category_provider.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  const AddCategoryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AddCategoryDialog(),
    );
  }

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _nameBnCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  int _selectedColor = 0xFF10B981;
  bool _isSaving = false;
  String? _error;

  final List<int> _colorPalette = [
    0xFF10B981, // Emerald green
    0xFFE53935, // Crimson red
    0xFF3B82F6, // Blue
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Purple
    0xFF06B6D4, // Cyan
    0xFFEC4899, // Pink
    0xFFF97316, // Orange
    0xFF64748B, // Slate
  ];

  @override
  void dispose() {
    _nameBnCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bn = _nameBnCtrl.text.trim();
    final en = _nameEnCtrl.text.trim();

    if (bn.isEmpty) {
      setState(() => _error = 'খরচের খাতের বাংলা নাম লিখুন');
      return;
    }

    final user = ref.read(authUserProvider);
    final familyId = user?.activeFamilyId ?? '';

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(categoryListProvider.notifier).addCustomCategory(
            familyId: familyId,
            nameBn: bn,
            nameEn: en.isEmpty ? bn : en,
            colorValue: _selectedColor,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('নতুন খরচের খাত "$bn" সফলভাবে যুক্ত হয়েছে!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.iosDivider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.category_outlined, color: AppColors.accentGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'নতুন খরচের খাত',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkRed,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryRed),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],
            GlassTextField(
              controller: _nameBnCtrl,
              label: 'খাতের নাম (বাংলায়)',
              hint: 'যেমন: পেট্রোল ও জ্বালানি',
              prefixIcon: Icons.edit_outlined,
            ),
            const SizedBox(height: 12),
            GlassTextField(
              controller: _nameEnCtrl,
              label: 'Category Name (English - ঐচ্ছিক)',
              hint: 'e.g. Fuel & Gas',
              prefixIcon: Icons.language_outlined,
            ),
            const SizedBox(height: 14),
            const Text(
              'রং নির্বাচন করুন:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorPalette.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            GlassButton(
              text: _isSaving ? 'সংরক্ষণ করা হচ্ছে...' : 'খাত সংরক্ষণ করুন',
              isLoading: _isSaving,
              icon: Icons.check_circle_outline,
              onPressed: _isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
