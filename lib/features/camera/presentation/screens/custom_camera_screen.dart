import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_button.dart';

class CustomCameraScreen extends ConsumerStatefulWidget {
  const CustomCameraScreen({super.key});

  @override
  ConsumerState<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends ConsumerState<CustomCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _capturedBytes;
  String? _base64Data;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Auto trigger camera on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePhoto();
    });
  }

  Future<void> _takePhoto() async {
    final l10n = ref.read(appLocalizationsProvider);
    setState(() => _isProcessing = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _capturedBytes = bytes;
          _base64Data = FirestoreImageService.bytesToBase64(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('camera_open_error')}: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final l10n = ref.read(appLocalizationsProvider);
    setState(() => _isProcessing = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _capturedBytes = bytes;
          _base64Data = FirestoreImageService.bytesToBase64(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('gallery_open_error')}: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: _capturedBytes != null
                    ? Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.accentGreen, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _capturedBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 360,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.glassBorder,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withValues(alpha: 0.03),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 64,
                                    color: AppColors.accentGreen.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    l10n.translate('camera_box_title'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      l10n.translate('camera_box_subtitle'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _isProcessing ? null : _takePhoto,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryGreen,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: const Icon(Icons.camera_alt, size: 18),
                                        label: Text(l10n.translate('camera')),
                                      ),
                                      const SizedBox(width: 10),
                                      OutlinedButton.icon(
                                        onPressed: _isProcessing ? null : _pickFromGallery,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.amber,
                                          side: const BorderSide(color: Colors.amber),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        icon: const Icon(Icons.photo_library, size: 18),
                                        label: Text(l10n.translate('gallery')),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassBox(
                  borderRadius: 30,
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  l10n.translate('camera_scanner_title'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (_capturedBytes != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      text: l10n.translate('camera_retake'),
                      isRed: true,
                      icon: Icons.refresh,
                      onPressed: _takePhoto,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GlassButton(
                      text: l10n.translate('camera_save'),
                      icon: Icons.check,
                      onPressed: () => Navigator.pop(context, _base64Data),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
