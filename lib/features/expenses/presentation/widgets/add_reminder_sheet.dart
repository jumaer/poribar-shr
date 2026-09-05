import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          label: 'প্রাপক ব্যক্তি',
          hint: 'যার কাছে পরিশোধ করতে হবে',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 10),
        GlassTextField(
          controller: _purposeController,
          label: 'উদ্দেশ্য',
          hint: 'যেমন: গ্যাস বিল / বাড়ি ভাড়া',
          prefixIcon: Icons.receipt_long_outlined,
        ),
        const SizedBox(height: 10),
        GlassTextField(
          controller: _detailsController,
          label: 'বিস্তারিত বিবরণ',
          hint: 'প্রয়োজনে নোট লিখুন...',
          maxLines: 2,
          prefixIcon: Icons.notes_outlined,
        ),
        const SizedBox(height: 18),
        GlassButton(
          text: 'এলার্ম সেট করুন',
          icon: Icons.notifications_active_outlined,
          onPressed: () {
            final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
            if (_titleController.text.isNotEmpty) {
              ref.read(reminderListProvider.notifier).addReminder(
                    ExpenseReminder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleController.text.trim(),
                      amount: amount,
                      targetPerson: _personController.text.trim(),
                      purpose: _purposeController.text.trim(),
                      dueDate: _dueDate,
                      details: _detailsController.text.trim(),
                    ),
                  );
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
