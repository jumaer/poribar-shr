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
  bool _isVibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _amols = _amolService.getDefaultAmols();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final familyId = user?.activeFamilyId ?? 'fam_01';

    return GlassScaffold(
      appBar: GlassAppBar(
        title: 'দৈনিক আমল ও ডিজিটাল তসবিহ',
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'ডিজিটাল তসবিহ'),
            Tab(text: 'পরিবারের আমল বোর্ড'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDigitalTasbihTab(),
          _buildFamilyBoardTab(familyId),
        ],
      ),
    );
  }
}
