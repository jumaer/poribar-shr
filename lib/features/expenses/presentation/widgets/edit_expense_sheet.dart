import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../../../core/widgets/global_delete_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import 'add_category_dialog.dart';
import 'salary_celebration_dialog.dart';

class EditExpenseSheet extends ConsumerStatefulWidget {
  final ExpenseEntity expense;

  const EditExpenseSheet({super.key, required this.expense});

  static Future<void> show(BuildContext context, {required ExpenseEntity expense}) {
    return GlobalBottomSheet.show(
      context: context,
      title: 'লেনদেন সম্পাদনা ও মুছে ফেলা',
      child: EditExpenseSheet(expense: expense),
    );
  }

  @override
  ConsumerState<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<EditExpenseSheet> {
  late TextEditingController _amountController;
  late TextEditingController _purposeController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TransactionType _type;
  ExpenseCategory? _selectedCategory;
  String? _attachedImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toStringAsFixed(0));
    _purposeController = TextEditingController(text: widget.expense.purpose);
    _descriptionController = TextEditingController(text: widget.expense.description);
    _selectedDate = widget.expense.date;
    _type = widget.expense.type;
    _attachedImageBase64 = widget.expense.imageUrl;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _attachedImageBase64 = FirestoreImageService.bytesToBase64(bytes);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ক্যামেরা থেকে নতুন রসিদের ছবি যুক্ত হয়েছে!'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ক্যামেরা ওপেন করতে সমস্যা: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _attachedImageBase64 = FirestoreImageService.bytesToBase64(bytes);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('গ্যালারি থেকে নতুন ভাউচার ছবি যুক্ত হয়েছে!'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('গ্যালারি ওপেন করতে সমস্যা: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await GlobalDeleteDialog.show(
      context: context,
      title: 'লেনদেন মুছে ফেলা নিশ্চিত করুন',
      message: 'আপনি কি নিশ্চিতভাবে এই লেনদেন এন্ট্রিটি মুছে ফেলতে চান? এটি পরিবার ব্যালেন্স থেকে স্থায়ীভাবে বাদ যাবে।',
      itemName: widget.expense.purpose,
      itemAmount: '৳ ${widget.expense.amount.toStringAsFixed(0)}',
    );

    if (confirmed == true && mounted) {
      final familyId = widget.expense.familyId;
      final expenseId = widget.expense.id;
      Navigator.pop(context); // close edit sheet

      await ref.read(expenseListProvider.notifier).deleteExpense(expenseId, familyId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('লেনদেনটি সফলভাবে মুছে ফেলা হয়েছে!'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  bool get _isAmountEditable {
    final diff = DateTime.now().difference(widget.expense.date).inDays;
    return diff <= 3;
  }

  void _saveChanges() async {
    final amount = _isAmountEditable
        ? (double.tryParse(_amountController.text.trim()) ?? widget.expense.amount)
        : widget.expense.amount;

    if (amount > 0) {
      final purposeText = _purposeController.text.trim().isEmpty
          ? (_selectedCategory?.nameBn ?? widget.expense.purpose)
          : _purposeController.text.trim();

      String? imagePath = _attachedImageBase64;
      if (_attachedImageBase64 != null && !_attachedImageBase64!.startsWith('images/')) {
        imagePath = await FirestoreImageService.saveImageToFirestore(_attachedImageBase64!);
      }

      final updated = widget.expense.copyWith(
        amount: amount,
        type: _type,
        purpose: purposeText,
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        imageUrl: imagePath,
      );

      final isSalary = _type == TransactionType.income &&
          (purposeText.toLowerCase().contains('বেতন') ||
              purposeText.toLowerCase().contains('salary'));

      ref.read(expenseListProvider.notifier).addExpense(updated);

      // Case 4: Broadcast entry update notification to other family members
      final user = ref.read(authUserProvider);
      NotificationService().broadcastExpenseUpdateNotification(
        familyId: widget.expense.familyId,
        userName: user?.fullName ?? widget.expense.recordedByUserName,
        purpose: purposeText,
        amount: amount,
        imageUrl: imagePath,
      );

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('লেনদেন সফলভাবে সংরক্ষণ করা হয়েছে!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }

      if (isSalary && mounted) {
        SalaryCelebrationDialog.show(
          context,
          amount: amount,
          userName: widget.expense.recordedByUserName,
          date: _selectedDate,
          slipImageBase64: imagePath,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final user = ref.watch(authUserProvider);
    final isAdmin = user?.role == 'admin' || user?.isFamilyOwner == true;
    final l10n = ref.watch(appLocalizationsProvider);

    _selectedCategory ??= categories.firstWhere(
      (c) => widget.expense.purpose.contains(c.nameBn),
      orElse: () => categories.first,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeSegment(l10n.translate('tab_expense'), TransactionType.expense, AppColors.primaryRed),
                  _buildTypeSegment(l10n.translate('tab_income'), TransactionType.income, AppColors.primaryGreen),
                  _buildTypeSegment(l10n.translate('tab_savings'), TransactionType.savings, AppColors.primaryBlue),
                  _buildTypeSegment(l10n.translate('loan_given'), TransactionType.loanGiven, const Color(0xFF10B981)),
                  _buildTypeSegment(l10n.translate('loan_taken'), TransactionType.loanTaken, const Color(0xFFF59E0B)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardDarkSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iosDivider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ExpenseCategory>(
                      isExpanded: true,
                      value: _selectedCategory,
                      dropdownColor: AppColors.cardDark,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accentGreen),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(cat.colorValue),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.nameBn,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.accentGreen, size: 24),
                  tooltip: 'নতুন খাতের ধরণ যুক্ত করুন',
                  onPressed: () => AddCategoryDialog.show(context),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: TextEditingController(
              text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            label: 'তারিখ',
            readOnly: true,
            prefixIcon: Icons.calendar_today_outlined,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 10),
          if (!_isAmountEditable)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock, color: AppColors.primaryRed, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '৩ দিন পার হওয়ায় টাকার পরিমাণ পরিবর্তন লক করা হয়েছে।',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time_filled, color: AppColors.accentGreen, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'টাকার পরিমাণ পরিবর্তনের সুযোগ রয়েছে (৩ দিনের মধ্যে)',
                      style: TextStyle(color: AppColors.accentGreen, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          GlassTextField(
            controller: _amountController,
            label: _isAmountEditable
                ? 'টাকার পরিমাণ'
                : 'টাকার পরিমাণ (🔒 পরিবর্তন লক)',
            hint: 'যেমন: ৫০০',
            readOnly: !_isAmountEditable,
            keyboardType: TextInputType.number,
            prefixIcon: _isAmountEditable ? Icons.monetization_on_outlined : Icons.lock_outline,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _purposeController,
            label: 'উদ্দেশ্য',
            hint: 'যেমন: বাজার খরচ / বেতন',
            prefixIcon: Icons.shopping_basket_outlined,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _descriptionController,
            label: 'বিবরণ',
            hint: 'প্রয়োজনে বিস্তারিত বিবরণ লিখুন...',
            maxLines: 2,
            prefixIcon: Icons.notes_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _captureFromCamera,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.accentGreen),
                  label: const Text('ক্যামেরা ছবি', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectFromGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.photo_library_outlined, size: 18, color: Colors.amber),
                  label: const Text('গ্যালারি ছবি', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          if (_attachedImageBase64 != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: FirestoreImageService.buildFirestoreImage(
                      base64Data: _attachedImageBase64,
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ভাউচার ছবি সংযুক্ত হয়েছে',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ফায়ারবেসে সংরক্ষিত রয়েছে',
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.primaryRed, size: 20),
                    tooltip: 'ছবি মুছুন',
                    onPressed: () => setState(() => _attachedImageBase64 = null),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          GlassButton(
            text: 'পরিবর্তন সংরক্ষণ করুন',
            icon: Icons.check_circle_outline,
            onPressed: _saveChanges,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _deleteEntry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryRed,
              side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text(
              'এই এন্ট্রিটি মুছে ফেলুন',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSegment(String title, TransactionType type, Color activeColor) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.7)) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
