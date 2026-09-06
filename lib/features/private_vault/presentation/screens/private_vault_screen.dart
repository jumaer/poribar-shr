import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firebase_dropdown_service.dart';
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

  void _openAddItemSheet(AppLocalizations l10n, List<String> categories) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedCategory = categories.isNotEmpty
        ? (_selectedTab == 0 ? categories.first : (categories.length > 1 ? categories[1] : categories.first))
        : (_selectedTab == 0 ? l10n.translate('vault_hidden_items') : l10n.translate('vault_guest_items'));

    GlobalBottomSheet.show(
      context: context,
      title: l10n.translate('vault_add_note_title'),
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (categories.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.iosDivider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: categories.contains(selectedCategory) ? selectedCategory : categories.first,
                      dropdownColor: AppColors.cardDark,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              GlassTextField(
                controller: titleCtrl,
                label: l10n.translate('vault_note_title_label'),
                hint: l10n.translate('vault_note_title_hint'),
                prefixIcon: CupertinoIcons.lock_shield,
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: contentCtrl,
                label: l10n.translate('vault_note_desc_label'),
                hint: l10n.translate('vault_note_desc_hint'),
                maxLines: 3,
                prefixIcon: CupertinoIcons.doc_text,
              ),
              const SizedBox(height: 14),
              GlassButton(
                text: l10n.translate('vault_save_btn'),
                icon: CupertinoIcons.lock_fill,
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                    ref.read(privateVaultProvider.notifier).addItem(
                          titleCtrl.text.trim(),
                          contentCtrl.text.trim(),
                          selectedCategory,
                        );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(privateVaultProvider);
    final l10n = ref.watch(appLocalizationsProvider);
    final dropdownConfigAsync = ref.watch(dropdownOptionsProvider);
    final dropdownConfig = dropdownConfigAsync.value ?? DropdownConfigModel.defaults;
    final vaultCats = dropdownConfig.vaultCategories;

    final hiddenItems = allItems.where((i) => i.category.contains('Hidden') || i.category.contains('গোপন')).toList();
    final guestItems = allItems.where((i) => i.category.contains('Guests') || i.category.contains('মেহমান')).toList();
    final activeItems = _selectedTab == 0 ? hiddenItems : guestItems;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: l10n.translate('private_vault_appbar'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.chat_bubble_text_fill, color: AppColors.accentGreen, size: 20),
            tooltip: l10n.translate('direct_msg_tooltip'),
            onPressed: () => RateLimitedPingSheet.show(context),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.accentGreen, size: 22),
            onPressed: () => _openAddItemSheet(l10n, vaultCats),
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
            child: Row(
              children: [
                const Icon(CupertinoIcons.lock_shield_fill, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('zero_knowledge_vault'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.translate('zero_knowledge_desc'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
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
                        '${l10n.translate("vault_hidden_items")} (${hiddenItems.length})',
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
                        '${l10n.translate("vault_guest_items")} (${guestItems.length})',
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
                        ? l10n.translate('vault_no_hidden_items')
                        : l10n.translate('vault_no_guest_items'),
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
