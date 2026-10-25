import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/services/face_detector_service.dart';
import '../../../../core/services/face_recognition_service.dart';

class GateAccessScanScreen extends StatefulWidget {
  const GateAccessScanScreen({super.key});

  @override
  State<GateAccessScanScreen> createState() => _GateAccessScanScreenState();
}

class _GateAccessScanScreenState extends State<GateAccessScanScreen> {
  CameraController? _controller;
  List<FaceRecognitionResult> _results = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    FaceRecognitionService.initialize();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});

    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final inputImage = _inputImageFromCameraImage(image);
        final faces = await FaceDetectorService.detectFaces(inputImage);

        List<FaceRecognitionResult> results = [];
        for (final face in faces) {
          final embedding = await FaceRecognitionService.extractEmbedding(
            cameraImage: image,
            faceBoundingBox: face.boundingBox,
          );
          final match = await FaceRecognitionService.recognizeFace(embedding);
          results.add(FaceRecognitionResult(
            face: face,
            match: match,
            isMatched: match != null,
          ));
        }

        if (mounted) setState(() => _results = results);
      } catch (e) {
        debugPrint('Scan error: $e');
      } finally {
        _isProcessing = false;
      }
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

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMatch = _results.any((r) => r.isMatched);
    final matchName = hasMatch ? _results.firstWhere((r) => r.isMatched).match!['name'] : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Quét khuôn mặt mở cổng')),
      body: Stack(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator()),
          if (_controller != null && _controller!.value.isInitialized)
            CustomPaint(
              painter: _GatePainter(
                results: _results,
                imageSize: _controller!.value.previewSize!,
                screenSize: MediaQuery.of(context).size,
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasMatch ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasMatch ? 'MỞ CỔNG - Chào $matchName' : 'CẢNH BÁO - Không nhận diện được',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaceRecognitionResult {
  final Face face;
  final Map<String, dynamic>? match;
  final bool isMatched;
  FaceRecognitionResult({required this.face, this.match, required this.isMatched});
}

class _GatePainter extends CustomPainter {
  final List<FaceRecognitionResult> results;
  final Size imageSize;
  final Size screenSize;

  _GatePainter({required this.results, required this.imageSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final res in results) {
      final rect = FaceDetectorService.scaleBoundingBox(
        face: res.face,
        imageSize: imageSize,
        screenSize: screenSize,
        rotation: InputImageRotation.rotation0deg,
      );

      final paint = Paint()
        ..color = res.isMatched ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
