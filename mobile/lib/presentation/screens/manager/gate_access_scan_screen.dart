import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<_FaceResult> _results = [];
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
    _controller!.startImageStream((image) async {
      if (_isProcessing) return;
      _isProcessing = true;
      try {
        final inputImage = _toInputImage(image);
        final faces = await FaceDetectorService.detectFaces(inputImage);
        List<_FaceResult> results = [];
        for (final face in faces) {
          final embedding = await FaceRecognitionService.extractEmbedding(
            cameraImage: image,
            faceBoundingBox: face.boundingBox,
          );
          final match = await FaceRecognitionService.recognizeFace(embedding);
          results.add(_FaceResult(face, match));
        }
        if (mounted) setState(() => _results = results);
      } catch (e) {
        debugPrint('Scan error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  InputImage _toInputImage(CameraImage img) {
    final bytes = img.planes.fold<Uint8List>(Uint8List(0), (p, plane) {
      final c = Uint8List(p.length + plane.bytes.length);
      c.setRange(0, p.length, p);
      c.setRange(p.length, c.length, plane.bytes);
      return c;
    });
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: img.planes[0].bytesPerRow,
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
    final hasMatch = _results.any((r) => r.match != null);
    final name = hasMatch ? _results.firstWhere((r) => r.match != null).match!['name'] : '';
    return PopScope(
      canPop: !widget.kioskMode,
      child: Scaffold(
        appBar: widget.kioskMode ? null : AppBar(title: const Text('Quét khuôn mặt mở cổng')),
        body: Stack(
          children: [
            if (_controller?.value.isInitialized ?? false)
              CameraPreview(_controller!)
            else
              const Center(child: CircularProgressIndicator()),
            if (_controller?.value.isInitialized ?? false)
              CustomPaint(
                painter: _Painter(_results, _controller!.value.previewSize!, MediaQuery.of(context).size),
              ),
            Positioned(
              top: widget.kioskMode ? 60 : 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (hasMatch ? Colors.green : Colors.red).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasMatch ? 'MỞ CỔNG - Chào $name' : 'CẢNH BÁO - Không nhận diện được',
                  style: TextStyle(color: Colors.white, fontSize: widget.kioskMode ? 24 : 18, fontWeight: FontWeight.bold),
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
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gate Scanner v1.0', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (c, s) => Text(DateFormat('HH:mm:ss').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 12)),
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

class _FaceResult {
  final Face face;
  final Map<String, dynamic>? match;
  _FaceResult(this.face, this.match);
}

class _Painter extends CustomPainter {
  final List<_FaceResult> results;
  final Size imgSize, screenSize;
  _Painter(this.results, this.imgSize, this.screenSize);
  @override
  void paint(Canvas canvas, Size size) {
    for (final r in results) {
      final rect = FaceDetectorService.scaleBoundingBox(face: r.face, imageSize: imgSize, screenSize: screenSize, rotation: InputImageRotation.rotation0deg);
      canvas.drawRect(rect, Paint()..color = (r.match != null ? Colors.green : Colors.red)..style = PaintingStyle.stroke..strokeWidth = 4);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
