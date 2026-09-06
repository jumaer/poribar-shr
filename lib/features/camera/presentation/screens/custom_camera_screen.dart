import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/l10n_provider.dart';
import '../../../../core/services/firestore_image_service.dart';

class CustomCameraScreen extends ConsumerStatefulWidget {
  const CustomCameraScreen({super.key});

  static Future<String?> open(BuildContext context) async {
    return Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
    );
  }

  @override
  ConsumerState<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends ConsumerState<CustomCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isTakingPicture = false;
  FlashMode _flashMode = FlashMode.auto;
  String? _previewBase64;
  Uint8List? _previewBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initSelectedCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initSelectedCamera();
      } else {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      debugPrint('Error getting cameras: $e');
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _initSelectedCamera() async {
    if (_cameras.isEmpty) return;
    setState(() => _isInitializing = true);

    final prev = _controller;
    _controller = null;
    await prev?.dispose();

    final camera = _cameras[_selectedCameraIndex];
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    FlashMode nextMode;
    if (_flashMode == FlashMode.off) {
      nextMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      nextMode = FlashMode.always;
    } else {
      nextMode = FlashMode.off;
    }

    try {
      await controller.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initSelectedCamera();
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isTakingPicture) return;

    HapticFeedback.mediumImpact();
    setState(() => _isTakingPicture = true);

    try {
      final xfile = await controller.takePicture();
      final bytes = await xfile.readAsBytes();
      final base64 = FirestoreImageService.bytesToBase64(bytes);

      if (mounted) {
        setState(() {
          _previewBytes = bytes;
          _previewBase64 = base64;
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64 = FirestoreImageService.bytesToBase64(bytes);
        if (mounted) {
          setState(() {
            _previewBytes = bytes;
            _previewBase64 = base64;
          });
        }
      }
    } catch (e) {
      debugPrint('Gallery picker error: $e');
    }
  }

  void _confirmAndUsePhoto() {
    if (_previewBase64 != null) {
      Navigator.pop(context, _previewBase64);
    }
  }

  void _retakePhoto() {
    setState(() {
      _previewBytes = null;
      _previewBase64 = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Real-time Camera Preview or Captured Image
          if (_previewBytes != null)
            Positioned.fill(
              child: Image.memory(
                _previewBytes!,
                fit: BoxFit.contain,
              ),
            )
          else if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: _isInitializing
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 54),
                            const SizedBox(height: 16),
                            Text(
                              l10n.translate('camera_initialize_error'),
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: Text(l10n.translate('receipt_camera')),
                            ),
                          ],
                        ),
                ),
              ),
            ),

          // 2. Transparent Viewfinder Overlay (when live previewing)
          if (_previewBytes == null && _controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    // Dark semi-transparent scrim around receipt box
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.55),
                        BlendMode.srcOut,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              backgroundBlendMode: BlendMode.dstOut,
                            ),
                          ),
                          Center(
                            child: Container(
                              width: size.width * 0.82,
                              height: size.height * 0.55,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Viewfinder border reticle
                    Center(
                      child: Container(
                        width: size.width * 0.82,
                        height: size.height * 0.55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.8), width: 2),
                        ),
                        child: Stack(
                          children: [
                            // Corner brackets
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.accentGreen, width: 3),
                                    left: BorderSide(color: AppColors.accentGreen, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: AppColors.accentGreen, width: 3),
                                    right: BorderSide(color: AppColors.accentGreen, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.accentGreen, width: 3),
                                    left: BorderSide(color: AppColors.accentGreen, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.accentGreen, width: 3),
                                    right: BorderSide(color: AppColors.accentGreen, width: 3),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Hint text below scanner
                    Positioned(
                      top: size.height * 0.76,
                      left: 20,
                      right: 20,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            l10n.translate('camera_scan_hint'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Top Floating Glass Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                if (_previewBytes == null) ...[
                  // Flash toggle
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: Icon(
                        _flashMode == FlashMode.always
                            ? Icons.flash_on
                            : (_flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_off),
                        color: _flashMode == FlashMode.always ? AppColors.accentGreen : Colors.white,
                        size: 20,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),

                  // Camera switch
                  if (_cameras.length > 1)
                    CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 20),
                        onPressed: _switchCamera,
                      ),
                    ),
                ],
              ],
            ),
          ),

          // 4. Bottom Controls Bar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: _previewBytes != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Retake button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.black54,
                        ),
                        onPressed: _retakePhoto,
                        icon: const Icon(Icons.refresh, color: AppColors.primaryRed),
                        label: Text(l10n.translate('retake_photo')),
                      ),

                      // Use photo button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _confirmAndUsePhoto,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          l10n.translate('use_photo'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery import button
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white12,
                        child: IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                          onPressed: _pickFromGallery,
                        ),
                      ),

                      // Shutter Capture Button
                      GestureDetector(
                        onTap: _isTakingPicture ? null : _capturePhoto,
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.transparent,
                          ),
                          child: Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryGreen,
                              ),
                              child: _isTakingPicture
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation(Colors.black),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),

                      // Spacer placeholder to balance gallery icon
                      const SizedBox(width: 48),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
