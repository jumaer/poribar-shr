import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/services/splash_config_service.dart';
import '../../../../core/widgets/glass_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UpdateSplashDialog extends ConsumerStatefulWidget {
  const UpdateSplashDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const UpdateSplashDialog(),
    );
  }

  @override
  ConsumerState<UpdateSplashDialog> createState() => _UpdateSplashDialogState();
}

class _UpdateSplashDialogState extends ConsumerState<UpdateSplashDialog> {
  String? _selectedImageBase64;
  bool _isLoading = false;
  String? _currentSplashImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentSplash();
  }

  Future<void> _loadCurrentSplash() async {
    final user = ref.read(authUserProvider);
    final familyId = user?.activeFamilyId ?? 'fam_01';
    final current = await SplashConfigService().getSplashImage(familyId: familyId);
    if (mounted) {
      setState(() {
        _currentSplashImage = current;
      });
    }
  }

  Future<void> _pickImage(ImageSource source, AppLocalizations l10n) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImageBase64 = FirestoreImageService.bytesToBase64(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate("splash_image_pick_error")}: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _saveSplash(AppLocalizations l10n) async {
    if (_selectedImageBase64 == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authUserProvider);
      final familyId = user?.activeFamilyId ?? 'fam_01';
      final userName = user?.fullName ?? 'Admin';

      await SplashConfigService().updateSplashImage(
        familyId: familyId,
        base64Image: _selectedImageBase64!,
        updatedBy: userName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('splash_save_success')),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate("splash_save_failed")}: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefault(AppLocalizations l10n) async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authUserProvider);
      final familyId = user?.activeFamilyId ?? 'fam_01';

      await SplashConfigService().resetSplashImage(familyId: familyId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('splash_reset_success')),
          backgroundColor: AppColors.primaryBlue,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate("splash_reset_failed")}: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImage = _selectedImageBase64 ?? _currentSplashImage;
    final l10n = ref.watch(appLocalizationsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.iosDivider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined, color: AppColors.accentGreen, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.translate('splash_change_title'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('splash_change_desc'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            // Preview box
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.cardDarkSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedImageBase64 != null
                        ? AppColors.primaryGreen
                        : AppColors.iosDivider,
                    width: 2,
                  ),
                  boxShadow: [
                    if (_selectedImageBase64 != null)
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                        blurRadius: 16,
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: displayImage != null
                      ? FirestoreImageService.buildFirestoreImage(
                          base64Data: displayImage,
                          width: 130,
                          height: 130,
                        )
                      : Image.asset(
                          'assets/icon/app_icon.png',
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.family_restroom, size: 60, color: Colors.white70),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _selectedImageBase64 != null
                    ? l10n.translate('splash_new_selected')
                    : (_currentSplashImage != null
                        ? l10n.translate('splash_current_custom')
                        : l10n.translate('splash_default_active')),
                style: TextStyle(
                  color: _selectedImageBase64 != null
                      ? AppColors.primaryGreen
                      : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera, l10n),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.primaryGreen),
                    label: Text(l10n.translate('camera'), style: const TextStyle(fontSize: 12, color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.iosDivider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery, l10n),
                    icon: const Icon(Icons.photo_library_outlined, size: 18, color: Colors.amber),
                    label: Text(l10n.translate('gallery'), style: const TextStyle(fontSize: 12, color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.iosDivider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                ),
              )
            else ...[
              if (_selectedImageBase64 != null)
                GlassButton(
                  text: l10n.translate('splash_save_btn'),
                  icon: Icons.check_circle_outline,
                  onPressed: () => _saveSplash(l10n),
                ),
              if (_currentSplashImage != null && _selectedImageBase64 == null)
                TextButton.icon(
                  onPressed: () => _resetToDefault(l10n),
                  icon: const Icon(Icons.refresh, color: AppColors.primaryRed, size: 18),
                  label: Text(
                    l10n.translate('splash_reset_btn'),
                    style: const TextStyle(color: AppColors.primaryRed, fontSize: 13),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
