import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final Color themeColor = const Color(0xFF0F624C);
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isNotEmpty) {
        _controller = CameraController(cameras[0], ResolutionPreset.medium);

        await _controller!.initialize();

        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 背景を黒にして映像を引き締める
      appBar: AppBar(
        title: const Text('レシートを撮影'),
        backgroundColor: Colors.white,
      ),
      // body を Stack 構造に変更
      body: Stack(
        children: [
          // 1. 一番奥：カメラの生映像プレビュー
          Positioned.fill(
            child: _isCameraInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!), // 本物のカメラ映像
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ), // 準備中はぐるぐる
                  ),
          ),

          // 2. 手前：これまでのレシートやシャッターボタンのUI（透明なレイヤーとして重ねる）
          Positioned.fill(
            child: Column(
              children: [
                const Spacer(),

                const SizedBox(height: 24),

                // シャッターボタン
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 28,
                        ),
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
