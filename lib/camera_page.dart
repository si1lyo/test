import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'app_theme.dart';
import 'services/receipt_recognition_service.dart';
import 'receipt_confirm_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // 背面カメラのうち最初のもの（= メインカメラ）を選ぶ
      // cameras[0] はデバイスによっては超広角になるため lensDirection で絞る
      final main = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      if (cameras.isNotEmpty) {
        _controller = CameraController(main, ResolutionPreset.medium, enableAudio: false);
        await _controller!.initialize();
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePhotoAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final xFile = await _controller!.takePicture();
      final imageFile = File(xFile.path);

      if (!mounted) return;

      // ローディング表示
      final accentColor = AppColors.of(context).accent;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 16),
                  const Text('レシートを読み取り中…',
                      style: TextStyle(fontFamily: kFont, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await ReceiptRecognitionService.recognizeReceipt(imageFile);

      if (!mounted) return;
      Navigator.pop(context); // ローディングを閉じる

      if (result.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品を認識できませんでした。もう一度お試しください。')),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptConfirmPage(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // ローディングを閉じる
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          // ── 右下 9-sided cookie（dark green） ──
          ClipPath(
            clipper: CookieClipper(
              points: 9,
              size: size.width * 1.2,
              offset: Offset(size.width * 0.38, size.height * 0.55),
            ),
            child: ColoredBox(color: colors.navBg, child: const SizedBox.expand()),
          ),

          // ── コンテンツ ──
          SafeArea(
            child: Column(
              children: [
                // 戻るボタン + タイトル
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new, color: colors.accent),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'レシートを撮影',
                        style: TextStyle(
                          fontFamily: kFont,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // ── カメラプレビュー ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: _isCameraInitialized
                          ? CameraPreview(_controller!)
                          : Container(
                              color: colors.surface,
                              child: Center(
                                child: CircularProgressIndicator(color: colors.accent),
                              ),
                            ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── シャッターボタン ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _takePhotoAndRecognize,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surface,
                        border: Border.all(color: colors.accent, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isProcessing
                              ? colors.accent.withValues(alpha: 0.4)
                              : colors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 28),
                      ),
                    ),
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
