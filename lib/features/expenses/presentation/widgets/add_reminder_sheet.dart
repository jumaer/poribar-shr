import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../domain/entities/expense_reminder.dart';
import '../providers/expense_provider.dart';

class AddReminderSheet extends ConsumerStatefulWidget {
  const AddReminderSheet({super.key});

  static Future<void> show(BuildContext context) {
    return GlobalBottomSheet.show(
      context: context,
      title: 'মাসিক এলার্ম / পরিশোধ রিমাইন্ডার',
      child: const AddReminderSheet(),
    );
  }

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _personController = TextEditingController();
  final _purposeController = TextEditingController();
  final _detailsController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  String? _selectedPreset;

  final List<Map<String, dynamic>> _quickPresets = [
    {'title': 'মাসিক বাড়িভাড়া', 'purpose': 'বাড়িভাড়া', 'icon': Icons.home_outlined},
    {'title': 'শিক্ষকের বেতন', 'purpose': 'প্রাইভেট শিক্ষক ফি', 'icon': Icons.person_search_outlined},
    {'title': 'স্কুল/কলেজ ফি', 'purpose': 'স্কুল টিউশন ফি', 'icon': Icons.school_outlined},
    {'title': 'বিদ্যুৎ বিল', 'purpose': 'ডেসকো/পল্লী বিদ্যুৎ বিল', 'icon': Icons.bolt_outlined},
    {'title': 'গ্যাস ও পানি বিল', 'purpose': 'গ্যাস/ওয়াসা বিল', 'icon': Icons.water_drop_outlined},
    {'title': 'ইন্টারনেট বিল', 'purpose': 'ওয়াইফাই বিল', 'icon': Icons.wifi_outlined},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _personController.dispose();
    _purposeController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick presets chips
          const Text(
            'দ্রুত নির্বাচন করুন (কুইক প্রিসেট):',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPresets.map((preset) {
                final isSelected = _selectedPreset == preset['title'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPreset = preset['title'] as String;
                        _titleController.text = preset['title'] as String;
                        _purposeController.text = preset['purpose'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen.withValues(alpha: 0.2)
                            : AppColors.cardDarkSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.iosDivider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            preset['icon'] as IconData,
                            size: 14,
                            color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            preset['title'] as String,
                            style: TextStyle(
                              color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          GlassTextField(
            controller: _titleController,
            label: 'রিমাইন্ডার শিরোনাম',
            hint: 'যেমন: বাড়িভাড়া বা বিদ্যুৎ বিল',
            prefixIcon: Icons.alarm,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: TextEditingController(
              text: '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
            ),
            label: 'টাকা পরিশোধের শেষ তারিখ',
            readOnly: true,
            prefixIcon: Icons.event,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _amountController,
            label: 'টাকার পরিমাণ',
            hint: 'যেমন: ২০০০',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.monetization_on_outlined,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _personController,
            label: 'প্রাপক ব্যক্তি / প্রতিষ্ঠান',
            hint: 'যার কাছে পরিশোধ করতে হবে (যেমন: বাড়িওয়ালা, শিক্ষক)',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _purposeController,
            label: 'উদ্দেশ্য বা খাত',
            hint: 'যেমন: গ্যাস বিল / বাড়ি ভাড়া / টিউশন',
            prefixIcon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: _detailsController,
            label: 'বিস্তারিত বিবরণ (ঐচ্ছিক)',
            hint: 'প্রয়োজনে হিসাবের অতিরিক্ত নোট লিখুন...',
            maxLines: 2,
            prefixIcon: Icons.notes_outlined,
          ),
          const SizedBox(height: 18),
          GlassButton(
            text: 'এলার্ম ও রিমাইন্ডার সেট করুন',
            icon: Icons.notifications_active_outlined,
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('অনুগ্রহ করে রিমাইন্ডারের শিরোনাম দিন'),
                    backgroundColor: AppColors.primaryRed,
                  ),
                );
                return;
              }
              final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
              ref.read(reminderListProvider.notifier).addReminder(
                    ExpenseReminder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      amount: amount,
                      targetPerson: _personController.text.trim(),
                      purpose: _purposeController.text.trim(),
                      dueDate: _dueDate,
                      details: _detailsController.text.trim(),
                    ),
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('মাসিক রিমাইন্ডার / অ্যালার্ম যুক্ত হয়েছে!'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
