import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  /// Detect faces from InputImage
  static Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _detector.processImage(inputImage);
  }

  /// Scale Bounding Box from actual camera image coords to screen logical pixels
  static Rect scaleBoundingBox({
    required Face face,
    required Size imageSize,
    required Size screenSize,
    required InputImageRotation rotation,
  }) {
    // Coordinate transformation logic for camera preview overlay
    double scaleX = screenSize.width / imageSize.height;
    double scaleY = screenSize.height / imageSize.width;

    final boundingBox = face.boundingBox;

    // Adjust based on rotation/mirroring if needed
    double left = boundingBox.left * scaleX;
    double top = boundingBox.top * scaleY;
    double right = boundingBox.right * scaleX;
    double bottom = boundingBox.bottom * scaleY;

    return Rect.fromLTRB(left, top, right, bottom);
  }

  static void dispose() {
    _detector.close();
  }
}
