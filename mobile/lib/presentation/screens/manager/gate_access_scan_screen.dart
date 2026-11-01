import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import '../../../core/services/face_detector_service.dart';
import '../../../core/services/face_recognition_service.dart';

class GateAccessScanScreen extends StatefulWidget {
  final bool kioskMode;
  const GateAccessScanScreen({super.key, this.kioskMode = false});
  @override
  State<GateAccessScanScreen> createState() => _GateAccessScanScreenState();
}

class _GateAccessScanScreenState extends State<GateAccessScanScreen> {
  CameraController? _controller;
  CameraDescription? _cameraDescription;
  List<_FaceResult> _results = [];
  bool _isProcessingFrame = false;
  bool _hasCompletedFaceScan = false;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastFaceDetectedAt = DateTime.fromMillisecondsSinceEpoch(0);
  Rect? _overlayBox;

  @override
  void initState() {
    super.initState();
    _initCamera();
    FaceRecognitionService.initialize().then((_) {
      if (!mounted) return;
      FaceRecognitionService.preloadFaces();
    });
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    await _startCamera(front);
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
      if (_isProcessingFrame) return;
      if (DateTime.now().difference(_lastProcessedAt) <
          const Duration(milliseconds: 90)) {
        return;
      }
      _lastProcessedAt = DateTime.now();
      _isProcessingFrame = true;
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
          if (mounted &&
              DateTime.now().difference(_lastFaceDetectedAt) >
                  const Duration(milliseconds: 300)) {
            setState(() {
              _results = [];
              _overlayBox = null;
              _hasCompletedFaceScan = false;
            });
          }
          return;
        }
        List<_FaceResult> results = [];
        for (final face in faces) {
          final embedding = await FaceRecognitionService.extractEmbedding(
            cameraImage: image,
            faceBoundingBox: face.boundingBox,
          );
          final match = await FaceRecognitionService.recognizeFace(embedding);
          results.add(_FaceResult(face, match));
        }
        if (mounted) {
          final newBox = FaceDetectorService.scaleBoundingBox(
            face: faces.first,
            imageSize: Size(image.width.toDouble(), image.height.toDouble()),
            screenSize: MediaQuery.sizeOf(context),
            rotation: FaceDetectorService.rotationForCamera(
              camera,
              controller.value.deviceOrientation,
            ),
            mirrorX: camera.lensDirection == CameraLensDirection.front,
          );
          _overlayBox = _smoothBox(newBox);
          _lastFaceDetectedAt = DateTime.now();
          setState(() {
            _results = results;
            _hasCompletedFaceScan = faces.isNotEmpty;
          });
        }
      } catch (e) {
        debugPrint('Scan error: $e');
      } finally {
        _isProcessingFrame = false;
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
    _results = [];
    _overlayBox = null;
    if (mounted) setState(() {});
    await oldController?.stopImageStream();
    await oldController?.dispose();
    if (mounted) await _startCamera(target);
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMatch = _results.any((r) => r.match != null);
    final hasUnmatchedFace =
        _hasCompletedFaceScan && _results.isNotEmpty && !hasMatch;
    final name = hasMatch
        ? _results.firstWhere((r) => r.match != null).match!['name']
        : '';
    final statusColor = hasMatch
        ? Colors.green
        : hasUnmatchedFace
            ? Colors.red
            : Colors.blueGrey;
    final statusText = hasMatch
        ? 'MỞ CỔNG - Chào $name'
        : hasUnmatchedFace
            ? 'CẢNH BÁO - Không nhận diện được'
            : 'ĐANG QUÉT KHUÔN MẶT...';
    return PopScope(
      canPop: !widget.kioskMode,
      child: Scaffold(
        appBar: widget.kioskMode
            ? null
            : AppBar(title: const Text('Quét khuôn mặt mở cổng')),
        body: Stack(
          children: [
            if (_controller?.value.isInitialized ?? false)
              Positioned.fill(
                child: _FullScreenCameraPreview(controller: _controller!),
              )
            else
              const Center(child: CircularProgressIndicator()),
            if (_controller?.value.isInitialized ?? false)
              Positioned.fill(
                child: CustomPaint(
                  painter: _Painter(_results, _overlayBox),
                ),
              ),
            Positioned(
              top: widget.kioskMode ? 12 : 8,
              right: 12,
              child: IconButton(
                onPressed: _switchCamera,
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                icon: const Icon(Icons.flip_camera_android),
                tooltip: 'Đổi camera',
              ),
            ),
            Positioned(
              top: widget.kioskMode ? 60 : 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.kioskMode ? 24 : 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (widget.kioskMode)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gate Scanner v1.0',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (c, s) => Text(
                            DateFormat('HH:mm:ss').format(DateTime.now()),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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

class _FaceResult {
  final Face face;
  final Map<String, dynamic>? match;
  _FaceResult(this.face, this.match);
}

class _Painter extends CustomPainter {
  final List<_FaceResult> results;
  final Rect? overlayBox;
  _Painter(this.results, this.overlayBox);
  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < results.length; index++) {
      final r = results[index];
      final rect = index == 0 ? overlayBox : null;
      if (rect == null) continue;
      canvas.drawRect(
          rect,
          Paint()
            ..color = (r.match != null ? Colors.green : Colors.red)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
