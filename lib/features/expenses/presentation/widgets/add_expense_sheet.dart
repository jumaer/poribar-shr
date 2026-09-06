import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/services/network_status_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../../camera/presentation/screens/custom_camera_screen.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'add_category_dialog.dart';
import 'salary_celebration_dialog.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  static Future<void> show(BuildContext context) {
    return GlobalBottomSheet.show(
      context: context,
      title: 'নতুন লেনদেন এন্ট্রি যোগ করুন',
      child: const AddExpenseSheet(),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  TransactionType _type = TransactionType.expense;
  LedgerCategory _categoryScope = LedgerCategory.family;
  ExpenseCategory? _selectedCategory;
  String? _attachedImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _categoryScope = ref.read(selectedLedgerCategoryProvider);
  }

  Future<void> _captureFromCamera() async {
    try {
      final base64 = await CustomCameraScreen.open(context);
      if (base64 != null && base64.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _attachedImageBase64 = base64;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('স্বচ্ছ ক্যামেরা থেকে রসিদের ছবি সফলভাবে যুক্ত হয়েছে!'),
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
            content: Text('গ্যালারি থেকে ভাউচার ছবি সফলভাবে যুক্ত হয়েছে!'),
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

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final user = ref.watch(authUserProvider);
    final isAdmin = user?.role == 'admin' || user?.isFamilyOwner == true;
    final isOnline = ref.watch(networkStatusProvider);
    final l10n = ref.watch(appLocalizationsProvider);

    _selectedCategory ??= categories.first;

    final isRedTheme = _type == TransactionType.expense;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isOnline)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: AppColors.primaryRed, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'আপনি অফলাইনে আছেন। ক্লাউড ডাটাবেসের অখণ্ডতা বজায় রাখতে অফলাইনে কোনো এন্ট্রি নেওয়া হয় না। অনুগ্রহ করে ইন্টারনেট সংযোগ চালু করুন।',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // Scope Pill: Personal vs Family
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.cardDarkSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _categoryScope = LedgerCategory.personal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _categoryScope == LedgerCategory.personal ? AppColors.cardDarkElevated : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: _categoryScope == LedgerCategory.personal ? Border.all(color: AppColors.primaryGreen) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.translate('personal_scope'),
                        style: TextStyle(
                          color: _categoryScope == LedgerCategory.personal ? AppColors.primaryGreen : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _categoryScope = LedgerCategory.family),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _categoryScope == LedgerCategory.family ? AppColors.cardDarkElevated : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: _categoryScope == LedgerCategory.family ? Border.all(color: AppColors.primaryGreen) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.translate('family_scope'),
                        style: TextStyle(
                          color: _categoryScope == LedgerCategory.family ? AppColors.primaryGreen : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Type Selector: Expense, Income, Savings, Loan Given, Loan Taken
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
            text: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} (আজকে)',
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
        GlassTextField(
          controller: _amountController,
          label: 'টাকার পরিমাণ',
          hint: 'যেমন: ৫০০',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.monetization_on_outlined,
        ),
        const SizedBox(height: 10),
        GlassTextField(
          controller: _purposeController,
          label: 'উদ্দেশ্য',
          hint: 'যেমন: বাজার খরচ / বেতন / ডিপিএস',
          prefixIcon: Icons.shopping_basket_outlined,
        ),
        const SizedBox(height: 10),
        GlassTextField(
          controller: _descriptionController,
          label: 'বিবরণ',
          hint: 'প্রয়োজনে বিস্তারিত নোট লিখুন...',
          maxLines: 2,
          prefixIcon: Icons.notes_outlined,
        ),
        const SizedBox(height: 10),
        GlassTextField(
          controller: TextEditingController(
            text: _dueDate != null
                ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} (সকাল ৭টা, ৮টা, ১২টায় অ্যালার্ম)'
                : 'পরিশোধের শেষ তারিখ (ঐচ্ছিক অ্যালার্ম)',
          ),
          label: 'পরিশোধের শেষ তারিখ ও অ্যালার্ম',
          readOnly: true,
          prefixIcon: Icons.alarm_on_outlined,
          suffixIcon: _dueDate != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.primaryRed),
                  onPressed: () => setState(() => _dueDate = null),
                )
              : null,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (picked != null) setState(() => _dueDate = picked);
          },
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
                        'ফায়ারবেসে স্বয়ংক্রিয়ভাবে সেভ হবে',
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
        const SizedBox(height: 18),
        GlassButton(
          text: !isOnline
              ? 'অফলাইনে এন্ট্রি বন্ধ'
              : (_type == TransactionType.expense
                  ? 'খরচ জমা দিন'
                  : (_type == TransactionType.income
                      ? 'আয় জমা দিন'
                      : 'সঞ্চয় জমা দিন')),
          isRed: isRedTheme,
          icon: !isOnline ? Icons.cloud_off_rounded : Icons.check_circle_outline,
          onPressed: !isOnline
              ? null
              : () async {
                  if (!NetworkStatusService().isOnline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('অফলাইন মোডে নতুন এন্ট্রি বা লেনদেন যোগ করা সম্ভব নয়। দয়া করে ইন্টারনেট সংযোগ চালু করুন।'),
                        backgroundColor: AppColors.primaryRed,
                      ),
                    );
                    return;
                  }
                  final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
            if (amount > 0) {
              final purposeText = _purposeController.text.trim().isEmpty
                  ? (_selectedCategory?.nameBn ?? 'সাধারণ')
                  : _purposeController.text.trim();

              final currentUser = ref.read(authUserProvider);
              final familyId = currentUser?.activeFamilyId ?? 'fam_01';
              final userId = currentUser?.uid ?? 'usr_01';
              final userName = currentUser?.fullName ?? 'পরিবার সদস্য';

              final isSalary = _type == TransactionType.income &&
                  (purposeText.toLowerCase().contains('বেতন') ||
                      purposeText.toLowerCase().contains('salary'));

              // Save image to Firestore images collection, keep only the path in the transaction
              String? imagePath = _attachedImageBase64;
              if (_attachedImageBase64 != null) {
                imagePath = await FirestoreImageService.saveImageToFirestore(_attachedImageBase64!);
              }

              try {
                await ref.read(expenseListProvider.notifier).addExpense(
                      ExpenseEntity(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        familyId: familyId,
                        type: _type,
                        category: _categoryScope,
                        amount: amount,
                        purpose: purposeText,
                        description: _descriptionController.text.trim(),
                        date: _selectedDate,
                        recordedByUserId: userId,
                        recordedByUserName: userName,
                        imageUrl: imagePath,
                      ),
                    );

                if (isSalary) {
                  // Broadcast celebratory salary arrival notification with voucher/slip image
                  NotificationService().broadcastSalaryCreditNotification(
                    familyId: familyId,
                    userName: userName,
                    amount: amount,
                    imageUrl: imagePath,
                  );
                } else {
                  // Broadcast regular push notification with image to all family members
                  NotificationService().broadcastExpenseEntryNotification(
                    familyId: familyId,
                    userName: userName,
                    purpose: purposeText,
                    amount: amount,
                    imageUrl: imagePath,
                  );
                }

                // Case 7: Schedule exact alarms on due date at 7:00 AM, 8:00 AM, and 12:00 PM
                if (_dueDate != null) {
                  NotificationService().scheduleDueDatePaymentAlarms(
                    baseId: DateTime.now().millisecondsSinceEpoch.remainder(10000),
                    title: purposeText,
                    amount: amount,
                    dueDate: _dueDate!,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (isSalary && context.mounted) {
                  SalaryCelebrationDialog.show(
                    context,
                    amount: amount,
                    userName: userName,
                    date: _selectedDate,
                    slipImageBase64: _attachedImageBase64,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ক্লাউড ডাটাবেসে সেভ করতে ব্যর্থ: $e'),
                      backgroundColor: AppColors.primaryRed,
                    ),
                  );
                }
              }
            }
          },
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
