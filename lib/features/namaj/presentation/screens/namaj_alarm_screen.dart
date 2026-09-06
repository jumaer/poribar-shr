import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/widgets/glass_app_bar.dart';
import '../../../../core/widgets/glass_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../services/prayer_time_service.dart';

class NamajAlarmScreen extends ConsumerStatefulWidget {
  const NamajAlarmScreen({super.key});

  @override
  ConsumerState<NamajAlarmScreen> createState() => _NamajAlarmScreenState();
}

class _NamajAlarmScreenState extends ConsumerState<NamajAlarmScreen> {
  final PrayerTimeService _prayerService = PrayerTimeService();
  Map<String, dynamic> _alarmSettings = {};

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _updateSetting(String waqtId, {bool? enabled, int? offset, String? sound}) async {
    final user = ref.read(authUserProvider);
    final familyId = user?.activeFamilyId ?? 'fam_01';
    final phone = user?.phoneNumber ?? '';

    final current = Map<String, dynamic>.from(_alarmSettings[waqtId] as Map? ?? {
      'isAlarmEnabled': true,
      'reminderOffsetMinutes': 0,
      'soundType': 'adhan',
    });

    if (enabled != null) current['isAlarmEnabled'] = enabled;
    if (offset != null) current['reminderOffsetMinutes'] = offset;
    if (sound != null) current['soundType'] = sound;

    setState(() {
      _alarmSettings[waqtId] = current;
    });

    await _prayerService.savePrayerAlarmSettings(
      familyId: familyId,
      phone: phone,
      settings: _alarmSettings,
    );
  }

  Widget _buildPrayerCard(PrayerTimeItem prayer) {
    final l10n = ref.watch(appLocalizationsProvider);
    final isEnabled = prayer.isAlarmEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? AppColors.primaryGreen.withValues(alpha: 0.35) : AppColors.iosDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEnabled ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.cardDarkSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEnabled ? Icons.alarm_on : Icons.alarm_off_outlined,
                  color: isEnabled ? AppColors.primaryGreen : AppColors.textSecondary,
                  size: 22,
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
                          prayer.nameBn,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prayer.nameAr,
                          style: TextStyle(
                            color: AppColors.primaryGreen.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatTimeOfDay(prayer.startTime)} - ${_formatTimeOfDay(prayer.endTime)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: isEnabled,
                activeTrackColor: AppColors.primaryGreen,
                onChanged: (val) => _updateSetting(prayer.id, enabled: val),
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(color: AppColors.iosDivider, height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardDarkSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.iosDivider.withValues(alpha: 0.6)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: prayer.reminderOffsetMinutes,
                        isExpanded: true,
                        dropdownColor: AppColors.cardDark,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen, size: 18),
                        items: [
                          DropdownMenuItem(value: 0, child: Text(l10n.translate('offset_start'))),
                          DropdownMenuItem(value: 5, child: Text(l10n.translate('offset_5_mins'))),
                          DropdownMenuItem(value: 10, child: Text(l10n.translate('offset_10_mins'))),
                          DropdownMenuItem(value: 15, child: Text(l10n.translate('offset_15_mins'))),
                        ],
                        onChanged: (val) {
                          if (val != null) _updateSetting(prayer.id, offset: val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cardDarkSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.iosDivider.withValues(alpha: 0.6)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: prayer.soundType,
                        isExpanded: true,
                        dropdownColor: AppColors.cardDark,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen, size: 18),
                        items: [
                          DropdownMenuItem(value: 'adhan', child: Text(l10n.translate('sound_adhan'))),
                          DropdownMenuItem(value: 'gentle_alarm', child: Text(l10n.translate('sound_gentle'))),
                          DropdownMenuItem(value: 'vibrate', child: Text(l10n.translate('sound_vibrate'))),
                        ],
                        onChanged: (val) {
                          if (val != null) _updateSetting(prayer.id, sound: val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final user = ref.watch(authUserProvider);
    final familyId = user?.activeFamilyId ?? 'fam_01';
    final phone = user?.phoneNumber ?? '';

    return GlassScaffold(
      appBar: GlassAppBar(
        title: l10n.translate('namaj_alarm_screen_title'),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _prayerService.streamPrayerAlarmSettings(familyId: familyId, phone: phone),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            _alarmSettings = snapshot.data!;
          }

          final prayers = _prayerService.getTodayPrayerTimes(alarmSettings: _alarmSettings);
          final currentPrayer = _prayerService.getCurrentOrNextPrayer(prayers);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Header Card: Current Waqt
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.25),
                      AppColors.cardDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mosque_outlined, color: AppColors.primaryGreen, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              l10n.translate('today_waqt'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryGreen),
                          ),
                          child: Text(
                            l10n.translate('live_update'),
                            style: const TextStyle(color: AppColors.primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (currentPrayer != null) ...[
                      Text(
                        '${l10n.translate('currently_running')}: ${currentPrayer.nameBn} (${currentPrayer.nameAr})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.translate('time_duration')}: ${_formatTimeOfDay(currentPrayer.startTime)} - ${_formatTimeOfDay(currentPrayer.endTime)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sahri & Iftar Quick Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.iosDivider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_twilight_outlined, color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.translate('sahri_iftar_header'),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${l10n.translate('sahri_ends')}: ${_formatTimeOfDay(prayers.first.startTime)} | ${l10n.translate('iftar_starts')}: ${_formatTimeOfDay(prayers[3].startTime)}',
                      style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Five Prayers List
              ...prayers.map(_buildPrayerCard),
            ],
          );
        },
      ),
    );
  }
}
