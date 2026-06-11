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
        _controller = CameraController(main, ResolutionPreset.high);
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: kDarkGreen),
                  SizedBox(height: 16),
                  Text('レシートを読み取り中…',
                      style: TextStyle(fontFamily: kFont, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      );

      final items = await ReceiptRecognitionService.recognizeReceipt(imageFile);

      if (!mounted) return;
      Navigator.pop(context); // ローディングを閉じる

      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品を認識できませんでした。もう一度お試しください。')),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptConfirmPage(items: items),
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

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── 右下 9-sided cookie（dark green） ──
          ClipPath(
            clipper: CookieClipper(
              points: 9,
              size: size.width * 1.2,
              offset: Offset(size.width * 0.38, size.height * 0.55),
            ),
            child: const ColoredBox(color: kDarkGreen, child: SizedBox.expand()),
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: kDarkGreen),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'レシートを撮影',
                        style: TextStyle(
                          fontFamily: kFont,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kDarkGreen,
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
                              color: const Color(0xFFD9D9D9),
                              child: const Center(
                                child: CircularProgressIndicator(color: kDarkGreen),
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
                        color: Colors.white,
                        border: Border.all(color: kDarkGreen, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: kDarkGreen.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isProcessing
                              ? kDarkGreen.withValues(alpha: 0.4)
                              : kDarkGreen,
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
