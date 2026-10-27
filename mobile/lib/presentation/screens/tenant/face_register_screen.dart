import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/services/face_detector_service.dart';
import '../../../../core/services/face_recognition_service.dart';

class FaceRegisterScreen extends StatefulWidget {
  final String userId;
  final String userName;
  const FaceRegisterScreen(
      {super.key, required this.userId, required this.userName});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _controller;
  CameraDescription? _cameraDescription;
  List<Face> _detectedFaces = [];
  bool _isProcessing = false;
  CameraImage? _lastCameraImage;
  int _frameSequence = 0;
  int? _lastDetectedFrame;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initCamera();
    FaceRecognitionService.initialize();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);
    _cameraDescription = front;
    _controller = CameraController(front, ResolutionPreset.medium);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    _controller!.startImageStream((image) async {
      if (_isProcessing) return;
      if (DateTime.now().difference(_lastProcessedAt) <
          const Duration(milliseconds: 200)) {
        return;
      }
      _lastProcessedAt = DateTime.now();
      _isProcessing = true;
      _lastCameraImage = image;
      final frameId = ++_frameSequence;

      try {
        final inputImage = FaceDetectorService.fromCameraImage(
          image: image,
          camera: _cameraDescription!,
          deviceOrientation: _controller!.value.deviceOrientation,
        );
        final faces = await FaceDetectorService.detectFaces(inputImage);
        if (faces.isEmpty) {
          _lastCameraImage = null;
          _lastDetectedFrame = null;
          if (mounted) setState(() => _detectedFaces = []);
          return;
        }
        _lastDetectedFrame = frameId;
        if (mounted) setState(() => _detectedFaces = faces);
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _register() async {
    if (_detectedFaces.isEmpty ||
        _lastCameraImage == null ||
        _lastDetectedFrame == null) {
      return;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký khuôn mặt thành công!')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
              onPressed:
                  _detectedFaces.isEmpty || _isProcessing ? null : _register,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Xác nhận đăng ký'),
            ),
          ),
        ],
      ),
    );
  }
}
