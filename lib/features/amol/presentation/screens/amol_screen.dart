import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/amol_entity.dart';
import '../../domain/entities/surah_dua_entity.dart';
import '../../services/amol_service.dart';

class AmolScreen extends ConsumerStatefulWidget {
  const AmolScreen({super.key});

  @override
  ConsumerState<AmolScreen> createState() => _AmolScreenState();
}

class _AmolScreenState extends ConsumerState<AmolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AmolService _amolService = AmolService();

  List<AmolItem> _amols = [];
  int _selectedIndex = 0;
  int _selectedSurahIndex = 0;
  bool _isVibrationEnabled = true;
  StreamSubscription<List<AmolItem>>? _templatesSub;
  StreamSubscription<List<AmolItem>>? _customAmolsSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _amols = List.from(_amolService.getDefaultAmols());

    // Stream templates directly from Firestore app_config/amol_templates
    _templatesSub = _amolService.streamAmolTemplates().listen((templates) {
      if (!mounted) return;
      _mergeNewTemplates(templates);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authUserProvider);
      if (user != null && user.activeFamilyId.isNotEmpty) {
        _customAmolsSub = _amolService
            .streamFamilyCustomAmols(user.activeFamilyId)
            .listen((customs) {
          if (!mounted) return;
          _mergeNewTemplates(customs);
        });
      }
    });
  }

  void _mergeNewTemplates(List<AmolItem> incoming) {
    setState(() {
      for (final item in incoming) {
        final existingIdx = _amols.indexWhere((a) => a.id == item.id);
        if (existingIdx == -1) {
          _amols.add(item);
        } else {
          final current = _amols[existingIdx];
          _amols[existingIdx] = item.copyWith(count: current.count);
        }
      }
    });
  }

  @override
  void dispose() {
    _templatesSub?.cancel();
    _customAmolsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onTasbihTap() {
    if (_amols.isEmpty) return;
    if (_isVibrationEnabled) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      final current = _amols[_selectedIndex];
      final newCount = current.count + 1;
      _amols[_selectedIndex] = current.copyWith(count: newCount);

      if (current.target > 0 && newCount == current.target) {
        HapticFeedback.heavyImpact();
      }
    });

    _syncAmols();
  }

  void _resetCurrentAmol() {
    if (_amols.isEmpty) return;
    setState(() {
      final current = _amols[_selectedIndex];
      _amols[_selectedIndex] = current.copyWith(count: 0);
    });
    _syncAmols();
  }

  void _changeTarget(int newTarget) {
    if (_amols.isEmpty) return;
    setState(() {
      final current = _amols[_selectedIndex];
      _amols[_selectedIndex] = current.copyWith(target: newTarget);
    });
    _syncAmols();
  }

  void _syncAmols() {
    final user = ref.read(authUserProvider);
    if (user != null) {
      _amolService.saveUserAmolState(
        familyId: user.activeFamilyId,
        phone: user.phoneNumber,
        memberName: user.fullName,
        memberRelation: user.role == 'admin' ? 'এডমিন' : 'সদস্য',
        amols: _amols,
      );
    }
  }

  void _showAddCustomAmolDialog() {
    final l10n = ref.read(appLocalizationsProvider);
    final nameBnCtrl = TextEditingController();
    final nameArCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.iosDivider),
        ),
        title: Text(
          l10n.translate('add_new_amol'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassTextField(
              controller: nameBnCtrl,
              label: l10n.translate('amol_name_bn'),
              hint: 'যেমন: সাইয়্যিদুল ইস্তিগফার',
              prefixIcon: Icons.edit_outlined,
            ),
            const SizedBox(height: 10),
            GlassTextField(
              controller: nameArCtrl,
              label: l10n.translate('amol_name_ar'),
              hint: 'যেমন: اللَّهُمَّ أَنْتَ رَبِّي',
              prefixIcon: Icons.menu_book_outlined,
            ),
            const SizedBox(height: 10),
            GlassTextField(
              controller: targetCtrl,
              label: l10n.translate('amol_target'),
              hint: 'যেমন: ১০০',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.flag_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameBnCtrl.text.trim();
              if (name.isNotEmpty) {
                final target = int.tryParse(targetCtrl.text.trim()) ?? 100;
                final newItem = AmolItem(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  nameBn: name,
                  nameAr: nameArCtrl.text.trim(),
                  virtue: 'কাস্টম জিকির ও আমল',
                  count: 0,
                  target: target,
                );
                setState(() {
                  _amols.add(newItem);
                  _selectedIndex = _amols.length - 1;
                });
                _syncAmols();
                // Persist new Amol item directly to Firebase Server
                await _amolService.addNewAmolTemplate(newItem);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.translate('save_amol_success')),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.translate('submit'), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddCustomSurahDialog() {
    final l10n = ref.read(appLocalizationsProvider);
    final titleBnCtrl = TextEditingController();
    final titleArCtrl = TextEditingController();
    final arabicScriptCtrl = TextEditingController();
    final pronunciationCtrl = TextEditingController();
    final meaningCtrl = TextEditingController();
    final virtueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.iosDivider),
        ),
        title: const Text(
          'নতুন সূরা বা দুআ যুক্ত করুন 📖',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassTextField(
                controller: titleBnCtrl,
                label: 'সূরা বা দোয়ার নাম (বাংলা)',
                hint: 'যেমন: সূরা আল-ফাতিহা বা আয়াত',
                prefixIcon: Icons.edit_outlined,
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: titleArCtrl,
                label: 'আরবি শিরোনাম (ঐচ্ছিক)',
                hint: 'যেমন: سورة الفاتحة',
                prefixIcon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: arabicScriptCtrl,
                label: 'মূল আরবি তিলাওয়াত',
                hint: 'যেমন: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ...',
                maxLines: 3,
                prefixIcon: Icons.translate_rounded,
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: pronunciationCtrl,
                label: 'বাংলা উচ্চারণ',
                hint: 'যেমন: বিসমিল্লাহির রাহমানির রাহিম...',
                maxLines: 2,
                prefixIcon: Icons.record_voice_over_outlined,
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: meaningCtrl,
                label: 'বাংলা অনুবাদ ও অর্থ',
                hint: 'যেমন: পরম করুণাময় অসীম দয়ালু আল্লাহর নামে...',
                maxLines: 2,
                prefixIcon: Icons.notes_outlined,
              ),
              const SizedBox(height: 10),
              GlassTextField(
                controller: virtueCtrl,
                label: 'ফজিলত ও তাৎপর্য',
                hint: 'যেমন: এটি কুরআনের সূচনা ও শিফায়ে কুল্লি...',
                maxLines: 2,
                prefixIcon: Icons.star_outline_rounded,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final titleBn = titleBnCtrl.text.trim();
              if (titleBn.isNotEmpty) {
                final newEntity = SurahDuaEntity(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  titleBn: titleBn,
                  titleAr: titleArCtrl.text.trim(),
                  surahNumber: 'কাস্টম সূরা/দুআ',
                  arabicScript: arabicScriptCtrl.text.trim(),
                  pronunciationBn: pronunciationCtrl.text.trim(),
                  meaningBn: meaningCtrl.text.trim(),
                  virtue: virtueCtrl.text.trim().isNotEmpty ? virtueCtrl.text.trim() : 'ফজিলতপূর্ণ আমল',
                );

                await _amolService.addNewSurahDua(newEntity);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('নতুন সূরা/দুআ সফলভাবে সার্ভারে যুক্ত হয়েছে!'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                }
              }
            },
            child: Text(l10n.translate('submit'), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalTasbihTab() {
    if (_amols.isEmpty) return const SizedBox.shrink();
    final active = _amols[_selectedIndex];
    final progress = active.target > 0 ? (active.count / active.target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // Horizontal Amol Selector Chips
        Container(
          height: 48,
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _amols.length + 1,
            itemBuilder: (context, index) {
              if (index == _amols.length) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ActionChip(
                    backgroundColor: AppColors.cardDarkSecondary,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    avatar: const Icon(Icons.add, size: 16, color: AppColors.primaryGreen),
                    label: const Text('+ কাস্টম আমল', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12)),
                    onPressed: _showAddCustomAmolDialog,
                  ),
                );
              }

              final item = _amols[index];
              final isSelected = index == _selectedIndex;

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(item.nameBn),
                  selected: isSelected,
                  selectedColor: AppColors.primaryGreen,
                  backgroundColor: AppColors.cardDarkSecondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedIndex = index);
                  },
                ),
              );
            },
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // Dhikr Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.iosDivider),
                  ),
                  child: Column(
                    children: [
                      if (active.nameAr.isNotEmpty) ...[
                        Text(
                          active.nameAr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        active.nameBn,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        active.virtue,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Large Circular Tasbih Tap Button
                GestureDetector(
                  onTap: _onTasbihTap,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.cardDarkSecondary,
                          AppColors.cardDark,
                          AppColors.primaryGreen.withValues(alpha: 0.15),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.6),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${active.count}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          active.target > 0 ? 'টার্গেট: ${active.target}' : 'আনলিমিটেড',
                          style: TextStyle(
                            color: active.count >= active.target && active.target > 0
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ট্যাপ করুন',
                            style: TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Progress Bar
                if (active.target > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.cardDarkSecondary,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).toInt()}% সম্পন্ন',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Bar: Targets, Reset, Haptics
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primaryRed),
                      tooltip: 'কাউন্টার রিসেট',
                      onPressed: _resetCurrentAmol,
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      children: [33, 100, 1000].map((tgt) {
                        final isCur = active.target == tgt;
                        return ChoiceChip(
                          label: Text('$tgt'),
                          selected: isCur,
                          selectedColor: AppColors.primaryGreen.withValues(alpha: 0.25),
                          backgroundColor: AppColors.cardDarkSecondary,
                          labelStyle: TextStyle(
                            color: isCur ? AppColors.primaryGreen : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          onSelected: (_) => _changeTarget(tgt),
                        );
                      }).toList(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        _isVibrationEnabled ? Icons.vibration : Icons.phone_android,
                        color: _isVibrationEnabled ? AppColors.primaryGreen : AppColors.textSecondary,
                      ),
                      tooltip: 'ভাইব্রেশন অন/অফ',
                      onPressed: () => setState(() => _isVibrationEnabled = !_isVibrationEnabled),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyBoardTab(String familyId) {
    final currentUser = ref.watch(authUserProvider);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _amolService.streamFamilyAmolBoard(familyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen)),
          );
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'পরিবারে এখনও কেউ আমল শুরু করেননি।\nআজই জিকির শুরু করে পরিবারকে উৎসাহিত করুন!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final data = list[index];
            final name = data['memberName']?.toString() ?? 'সদস্য';
            final relation = data['memberRelation']?.toString() ?? 'সদস্য';
            final phone = data['phoneNumber']?.toString() ?? '';
            final total = (data['totalCount'] as num?)?.toInt() ?? 0;
            final likes = (data['likesCount'] as num?)?.toInt() ?? 0;
            final items = (data['items'] as List?) ?? [];
            final isMe = currentUser?.phoneNumber == phone;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMe ? AppColors.primaryGreen.withValues(alpha: 0.35) : AppColors.iosDivider,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1) : 'প',
                          style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  const Text('(আপনি)', style: TextStyle(color: AppColors.primaryGreen, fontSize: 11)),
                                ],
                              ],
                            ),
                            Text(
                              relation,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardDarkSecondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.iosDivider),
                        ),
                        child: Text(
                          'মোট জিকির: $total',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Top Amols done
                  if (items.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: items.take(4).map((i) {
                        final m = Map<String, dynamic>.from(i as Map);
                        final count = m['count'] ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.cardDarkSecondary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.iosDivider.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '${m['nameBn']}: $count বার',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const Divider(color: AppColors.iosDivider, height: 16),

                  // Like & Reminder Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: AppColors.primaryRed, size: 16),
                          const SizedBox(width: 4),
                          Text('$likes টি লাইক', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          if (!isMe) ...[
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.favorite_border, color: AppColors.primaryRed, size: 16),
                              label: const Text('লাইক দিন', style: TextStyle(color: AppColors.primaryRed, fontSize: 12)),
                              onPressed: () {
                                _amolService.likeMemberAmol(
                                  familyId: familyId,
                                  targetPhone: phone,
                                  senderName: currentUser?.fullName ?? 'পরিবার সদস্য',
                                  senderPhone: currentUser?.phoneNumber ?? '',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name-এর আমলে লাইক ও উৎসাহ পাঠানো হয়েছে!'),
                                    backgroundColor: AppColors.primaryGreen,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryGreen, size: 16),
                              label: const Text('দাওয়াত দিন', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12)),
                              onPressed: () {
                                _amolService.sendAmolReminder(
                                  familyId: familyId,
                                  targetPhone: phone,
                                  senderName: currentUser?.fullName ?? 'পরিবার সদস্য',
                                  amolName: 'দুরূদ শরীফ ও ইস্তিগফার',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name-কে জিকিরের রিমাইন্ডার পাঠানো হয়েছে!'),
                                    backgroundColor: AppColors.primaryGreen,
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSurahsDuasTab() {
    final l10n = ref.watch(appLocalizationsProvider);
    final surahsAsync = ref.watch(surahsDuasProvider);

    return surahsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen)),
      ),
      error: (e, _) => Center(
        child: Text('${l10n.translate("sync_success")}: $e', style: const TextStyle(color: AppColors.primaryRed)),
      ),
      data: (surahs) {
        if (surahs.isEmpty) {
          return Center(child: Text(l10n.translate('no_data'), style: const TextStyle(color: AppColors.textSecondary)));
        }

        if (_selectedSurahIndex >= surahs.length) {
          _selectedSurahIndex = 0;
        }
        final currentSurah = surahs[_selectedSurahIndex];

        final amolIdx = _amols.indexWhere((a) => a.id == currentSurah.id || (currentSurah.id.contains('ayatul') && a.id == 'ayatul_kursi'));
        final amolItem = amolIdx != -1 ? _amols[amolIdx] : null;
        final count = amolItem?.count ?? 0;
        final target = amolItem?.target ?? 33;
        final progress = target > 0 ? (count / target).clamp(0.0, 1.0) : 0.0;

        void incrementSurahCount() {
          if (_isVibrationEnabled) HapticFeedback.lightImpact();
          setState(() {
            if (amolIdx != -1) {
              _amols[amolIdx] = amolItem!.copyWith(count: count + 1);
            } else {
              final newItem = AmolItem(
                id: currentSurah.id,
                nameBn: currentSurah.titleBn,
                nameAr: currentSurah.titleAr,
                virtue: currentSurah.virtue,
                count: 1,
                target: 33,
              );
              _amols.add(newItem);
            }
          });
          _syncAmols();
        }

        void resetSurahCount() {
          setState(() {
            if (amolIdx != -1) {
              _amols[amolIdx] = amolItem!.copyWith(count: 0);
            }
          });
          _syncAmols();
        }

        void setSurahTarget(int newTarget) {
          setState(() {
            if (amolIdx != -1) {
              _amols[amolIdx] = amolItem!.copyWith(target: newTarget);
            } else {
              _amols.add(AmolItem(
                id: currentSurah.id,
                nameBn: currentSurah.titleBn,
                nameAr: currentSurah.titleAr,
                virtue: currentSurah.virtue,
                count: 0,
                target: newTarget,
              ));
            }
          });
          _syncAmols();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: surahs.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx == surahs.length) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ActionChip(
                          backgroundColor: AppColors.cardDarkSecondary,
                          side: const BorderSide(color: AppColors.primaryGreen),
                          avatar: const Icon(Icons.add, size: 16, color: AppColors.primaryGreen),
                          label: const Text('+ নতুন সূরা/দুআ', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12)),
                          onPressed: _showAddCustomSurahDialog,
                        ),
                      );
                    }
                    final isSel = idx == _selectedSurahIndex;
                    final s = surahs[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s.titleBn),
                        selected: isSel,
                        selectedColor: AppColors.primaryGreen,
                        backgroundColor: AppColors.cardDarkSecondary,
                        labelStyle: TextStyle(
                          color: isSel ? Colors.black : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        ),
                        onSelected: (_) => setState(() => _selectedSurahIndex = idx),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.22),
                      AppColors.cardDarkSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primaryGreen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSurah.titleBn,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                currentSurah.surahNumber,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.translate('server_synced'),
                                  style: const TextStyle(color: AppColors.accentGreen, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.translate('arabic_script'),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: AppColors.textSecondary, size: 18),
                          tooltip: l10n.translate('copy_success'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(
                              text: '${currentSurah.arabicScript}\n\n${currentSurah.pronunciationBn}\n\n${currentSurah.meaningBn}',
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.translate('copy_success')),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        currentSurah.arabicScript,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          height: 2.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.translate('bangla_pronunciation'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentSurah.pronunciationBn,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.translate('bangla_meaning'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentSurah.meaningBn,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_outline_rounded, color: AppColors.primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          l10n.translate('virtues_and_benefits'),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentSurah.virtue,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.translate('amol_tasbih_title'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
                          tooltip: l10n.translate('refresh'),
                          onPressed: resetSurahCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: incrementSurahCount,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardDarkSecondary,
                          border: Border.all(color: AppColors.primaryGreen, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$count',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'টার্গেট: $target',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ট্যাপ করুন',
                                style: TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.cardDarkSecondary,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(progress * 100).toInt()}% সম্পন্ন',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [1, 3, 7, 11, 33, 100].map((t) {
                        final isSel = target == t;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ChoiceChip(
                            label: Text('$t'),
                            selected: isSel,
                            selectedColor: AppColors.primaryGreen,
                            backgroundColor: AppColors.cardDarkSecondary,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.black : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setSurahTarget(t),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final familyId = user?.activeFamilyId ?? 'fam_01';
    final l10n = ref.watch(appLocalizationsProvider);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: l10n.translate('amol_tasbih_title'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryGreen,
          tabs: [
            Tab(text: l10n.translate('digital_tasbih'), icon: const Icon(Icons.touch_app_outlined, size: 18)),
            Tab(text: l10n.translate('surahs_and_duas'), icon: const Icon(Icons.auto_stories_outlined, size: 18)),
            Tab(text: l10n.translate('family_amol_board'), icon: const Icon(Icons.leaderboard_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDigitalTasbihTab(),
          _buildSurahsDuasTab(),
          _buildFamilyBoardTab(familyId),
        ],
      ),
    );
  }
}
