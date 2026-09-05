import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
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

  Future<void> _pickImage(ImageSource source) async {
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
            content: Text('ছবি নির্বাচন করতে সমস্যা হয়েছে: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _saveSplash() async {
    if (_selectedImageBase64 == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authUserProvider);
      final familyId = user?.activeFamilyId ?? 'fam_01';
      final userName = user?.fullName ?? 'এডমিন';

      await SplashConfigService().updateSplashImage(
        familyId: familyId,
        base64Image: _selectedImageBase64!,
        updatedBy: userName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 স্প্ল্যাশ স্ক্রিনের ছবি সফলভাবে ফায়ারবেসে সংরক্ষিত হয়েছে!'),
          backgroundColor: AppColors.primaryGreen,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সংরক্ষণ ব্যর্থ হয়েছে: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authUserProvider);
      final familyId = user?.activeFamilyId ?? 'fam_01';

      await SplashConfigService().resetSplashImage(familyId: familyId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ডিফল্ট পরিবার লোগো সফলভাবে রিসেট করা হয়েছে।'),
          backgroundColor: AppColors.primaryBlue,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('রিসেট ব্যর্থ হয়েছে: $e'),
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
                const Row(
                  children: [
                    Icon(Icons.palette_outlined, color: AppColors.accentGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'স্প্ল্যাশ স্ক্রিন ছবি পরিবর্তন',
                      style: TextStyle(
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
            const Text(
              'ব্যবহারকারী বা এডমিন হিসেবে পরিবারের অ্যাপ চালু হওয়ার স্প্ল্যাশ স্ক্রিনের ছবি কাস্টমাইজ করুন:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                    ? '✓ নতুন ছবি নির্বাচিত হয়েছে (প্রিভিউ)'
                    : (_currentSplashImage != null
                        ? 'বর্তমান কাস্টম স্প্ল্যাশ ছবি'
                        : 'ডিফল্ট অ্যাপ লোগো সক্রিয়'),
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
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18, color: AppColors.primaryGreen),
                    label: const Text('ক্যামেরা', style: TextStyle(fontSize: 12, color: Colors.white)),
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
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18, color: Colors.amber),
                    label: const Text('গ্যালারি', style: TextStyle(fontSize: 12, color: Colors.white)),
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
                  text: 'স্প্ল্যাশ ছবি সংরক্ষণ করুন',
                  icon: Icons.check_circle_outline,
                  onPressed: _saveSplash,
                ),
              if (_currentSplashImage != null && _selectedImageBase64 == null)
                TextButton.icon(
                  onPressed: _resetToDefault,
                  icon: const Icon(Icons.refresh, color: AppColors.primaryRed, size: 18),
                  label: const Text(
                    'ডিফল্ট লোগোতে রিসেট করুন',
                    style: TextStyle(color: AppColors.primaryRed, fontSize: 13),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
