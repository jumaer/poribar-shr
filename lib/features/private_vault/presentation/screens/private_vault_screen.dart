import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/global_bottom_sheet.dart';
import '../../../direct_chat/presentation/widgets/rate_limited_ping_sheet.dart';
import '../providers/private_vault_provider.dart';

class PrivateVaultScreen extends ConsumerStatefulWidget {
  const PrivateVaultScreen({super.key});

  @override
  ConsumerState<PrivateVaultScreen> createState() => _PrivateVaultScreenState();
}

class _PrivateVaultScreenState extends ConsumerState<PrivateVaultScreen> {
  int _selectedTab = 0;

  void _openAddItemSheet() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = _selectedTab == 0 ? 'গোপন আইটেম' : 'ব্যক্তিগত মেহমান';

    GlobalBottomSheet.show(
      context: context,
      title: 'ব্যক্তিগত ভল্টে নোট যোগ করুন',
      child: Column(
        children: [
          GlassTextField(
            controller: titleCtrl,
            label: 'নোটের শিরোনাম',
            hint: 'যেমন: টাকার অবস্থান বা চাবি',
            prefixIcon: CupertinoIcons.lock_shield,
          ),
          const SizedBox(height: 10),
          GlassTextField(
            controller: contentCtrl,
            label: 'গোপন বিবরণ',
            hint: 'বিস্তারিত বিবরণ লিখুন...',
            maxLines: 3,
            prefixIcon: CupertinoIcons.doc_text,
          ),
          const SizedBox(height: 14),
          GlassButton(
            text: 'নিরাপদে সংরক্ষণ করুন',
            icon: CupertinoIcons.lock_fill,
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                ref.read(privateVaultProvider.notifier).addItem(
                      titleCtrl.text.trim(),
                      contentCtrl.text.trim(),
                      category,
                    );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(privateVaultProvider);

    final hiddenItems = allItems.where((i) => i.category.contains('Hidden') || i.category.contains('গোপন')).toList();
    final guestItems = allItems.where((i) => i.category.contains('Guests') || i.category.contains('মেহমান')).toList();
    final activeItems = _selectedTab == 0 ? hiddenItems : guestItems;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'আমার গোপন ভল্ট',
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.chat_bubble_text_fill, color: AppColors.accentGreen, size: 20),
            tooltip: 'সরাসরি বার্তা পাঠান (৩টি/দিন)',
            onPressed: () => RateLimitedPingSheet.show(context),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.accentGreen, size: 22),
            onPressed: _openAddItemSheet,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.lock_shield_fill, color: AppColors.primaryGreen, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'জিরো-নলেজ ব্যক্তিগত ভল্ট',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'এই তথ্য সম্পূর্ণ এনক্রিপ্টেড। পরিবারের এডমিন বা অন্য কোনো সদস্যের এই সেকশনে কোনো অ্যাক্সেস নেই।',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.iosDivider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? AppColors.cardDarkSecondary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'লুকানো জিনিস (${hiddenItems.length})',
                        style: TextStyle(
                          color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? AppColors.cardDarkSecondary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ব্যক্তিগত মেহমান (${guestItems.length})',
                        style: TextStyle(
                          color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (activeItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(CupertinoIcons.archivebox, color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    _selectedTab == 0
                        ? 'কোনো গোপন জিনিস সংরক্ষিত নেই'
                        : 'কোনো ব্যক্তিগত মেহমানের নোট নেই',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...activeItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardDarkSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _selectedTab == 0 ? CupertinoIcons.lock_fill : CupertinoIcons.person_crop_circle_badge_checkmark,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.secretContent,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.trash, color: AppColors.primaryRed, size: 18),
                      onPressed: () {
                        ref.read(privateVaultProvider.notifier).deleteItem(item.id);
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
