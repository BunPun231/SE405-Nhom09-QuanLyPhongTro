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
  DateTime _lastFaceDetectedAt = DateTime.fromMillisecondsSinceEpoch(0);
  Rect? _overlayBox;

  @override
  void initState() {
    super.initState();
    _initCamera();
    FaceRecognitionService.initialize();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    await _startCamera(back);
  }

  Future<void> _startCamera(CameraDescription camera) async {
    _cameraDescription = camera;
    final controller = CameraController(camera, ResolutionPreset.medium);
    _controller = controller;
    await controller.initialize();
    if (!mounted) return;
    setState(() {});

    await controller.startImageStream((image) async {
      if (!mounted || controller != _controller) return;
      if (_isProcessing) return;
      if (DateTime.now().difference(_lastProcessedAt) <
          const Duration(milliseconds: 90)) {
        return;
      }
      _lastProcessedAt = DateTime.now();
      _isProcessing = true;
      _lastCameraImage = image;
      final frameId = ++_frameSequence;

      try {
        final camera = _cameraDescription;
        if (camera == null) return;
        final inputImage = FaceDetectorService.fromCameraImage(
          image: image,
          camera: camera,
          deviceOrientation: controller.value.deviceOrientation,
        );
        final faces = await FaceDetectorService.detectFaces(inputImage);
        if (faces.isEmpty) {
          _lastCameraImage = null;
          _lastDetectedFrame = null;
          if (mounted &&
              DateTime.now().difference(_lastFaceDetectedAt) >
                  const Duration(milliseconds: 300)) {
            setState(() {
              _detectedFaces = [];
              _overlayBox = null;
            });
          }
          return;
        }
        _lastDetectedFrame = frameId;
        _lastFaceDetectedAt = DateTime.now();
        if (mounted) {
          final box = FaceDetectorService.scaleBoundingBox(
            face: faces.first,
            imageSize: Size(image.width.toDouble(), image.height.toDouble()),
            screenSize: MediaQuery.sizeOf(context),
            rotation: FaceDetectorService.rotationForCamera(
              camera,
              controller.value.deviceOrientation,
            ),
            mirrorX: camera.lensDirection == CameraLensDirection.front,
          );
          _overlayBox = _smoothBox(box);
          setState(() => _detectedFaces = faces);
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  Rect _smoothBox(Rect next) {
    final previous = _overlayBox;
    if (previous == null) return next;
    const factor = 0.35;
    return Rect.fromLTRB(
      previous.left + (next.left - previous.left) * factor,
      previous.top + (next.top - previous.top) * factor,
      previous.right + (next.right - previous.right) * factor,
      previous.bottom + (next.bottom - previous.bottom) * factor,
    );
  }

  Future<void> _switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.length < 2 || _cameraDescription == null) return;
    final target = cameras.firstWhere(
      (camera) => camera.lensDirection != _cameraDescription!.lensDirection,
      orElse: () => cameras.first,
    );
    final oldController = _controller;
    _controller = null;
    _detectedFaces = [];
    _lastCameraImage = null;
    _lastDetectedFrame = null;
    _overlayBox = null;
    if (mounted) setState(() {});
    await oldController?.stopImageStream();
    await oldController?.dispose();
    if (mounted) await _startCamera(target);
  }

  Future<void> _register() async {
    if (_detectedFaces.isEmpty ||
        _lastCameraImage == null ||
        _lastDetectedFrame == null) {
      print(
        '[FACE REGISTER] Cannot register: '
        'faces=${_detectedFaces.length}, '
        'hasImage=${_lastCameraImage != null}, '
        'detectedFrame=$_lastDetectedFrame',
      );
      return;
    }
    final face = _detectedFaces.first;
    final cameraImage = _lastCameraImage!;
    print(
      '[FACE REGISTER] Starting: frame=$_lastDetectedFrame '
      'faces=${_detectedFaces.length} '
      'image=${cameraImage.width}x${cameraImage.height} '
      'box=${face.boundingBox}',
    );
    setState(() => _isProcessing = true);
    try {
      final embedding = await FaceRecognitionService.extractEmbedding(
        cameraImage: cameraImage,
        faceBoundingBox: face.boundingBox,
      );
      await FaceRecognitionService.registerFace(
        userId: widget.userId,
        name: widget.userName,
        embedding: embedding,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký khuôn mặt thành công!')));
      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      print('[FACE REGISTER ERROR] $e');
      print(stackTrace);
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
      appBar: AppBar(
        title: const Text('Đăng ký khuôn mặt'),
        actions: [
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Đổi camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: _FullScreenCameraPreview(controller: _controller!),
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (_detectedFaces.isNotEmpty && _overlayBox != null)
            Positioned.fill(
              child: CustomPaint(
                painter: _RegisterPainter(_overlayBox!),
              ),
            ),
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

class _FullScreenCameraPreview extends StatelessWidget {
  final CameraController controller;
  const _FullScreenCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _RegisterPainter extends CustomPainter {
  final Rect box;
  _RegisterPainter(this.box);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      box,
      Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant _RegisterPainter oldDelegate) =>
      oldDelegate.box != box;
}
