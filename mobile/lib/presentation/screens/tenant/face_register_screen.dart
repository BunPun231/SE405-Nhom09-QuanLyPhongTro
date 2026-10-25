import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/services/face_detector_service.dart';
import '../../../../core/services/face_recognition_service.dart';

class FaceRegisterScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const FaceRegisterScreen({super.key, required this.userId, required this.userName});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _controller;
  List<Face> _detectedFaces = [];
  bool _isProcessing = false;
  CameraImage? _lastCameraImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
    FaceRecognitionService.initialize();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
    _controller = CameraController(front, ResolutionPreset.medium);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    _controller!.startImageStream((image) async {
      if (_isProcessing) return;
      _isProcessing = true;
      _lastCameraImage = image;

      final inputImage = _inputImageFromCameraImage(image);
      final faces = await FaceDetectorService.detectFaces(inputImage);
      if (mounted) setState(() => _detectedFaces = faces);
      _isProcessing = false;
    });
  }

  InputImage _inputImageFromCameraImage(CameraImage image) {
    final bytes = image.planes.fold<Uint8List>(Uint8List(0), (prev, plane) {
      final combined = Uint8List(prev.length + plane.bytes.length);
      combined.setRange(0, prev.length, prev);
      combined.setRange(prev.length, combined.length, plane.bytes);
      return combined;
    });
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _register() async {
    if (_detectedFaces.isEmpty || _lastCameraImage == null) return;
    setState(() => _isProcessing = true);
    try {
      final embedding = await FaceRecognitionService.extractEmbedding(
        cameraImage: _lastCameraImage!,
        faceBoundingBox: _detectedFaces.first.boundingBox,
      );
      await FaceRecognitionService.registerFace(
        userId: widget.userId,
        name: widget.userName,
        embedding: embedding,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký khuôn mặt thành công!')));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký khuôn mặt')),
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _detectedFaces.isEmpty || _isProcessing ? null : _register,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Xác nhận đăng ký'),
            ),
          ),
        ],
      ),
    );
  }
}
