import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  static final Set<String> _loggedCameraFormats = <String>{};
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  /// Detect faces from InputImage
  static Future<List<Face>> detectFaces(InputImage inputImage) async {
    final faces = await _detector.processImage(inputImage);
    print('[FACE DETECT] Found ${faces.length} face(s)');
    return faces;
  }

  static InputImage fromCameraImage({
    required CameraImage image,
    required CameraDescription camera,
    DeviceOrientation deviceOrientation = DeviceOrientation.portraitUp,
  }) {
    final rotation = rotationForCamera(camera, deviceOrientation);
    final formatGroup = image.format.group;
    final formatKey =
        '${camera.lensDirection}:${camera.sensorOrientation}:${image.format.raw}:'
        '${image.width}x${image.height}:${image.planes.map((p) => '${p.bytesPerRow}/${p.bytesPerPixel}').join(',')}';
    if (_loggedCameraFormats.add(formatKey)) {
      print(
        '[CAMERA FORMAT] raw=${image.format.raw}, '
        'size=${image.width}x${image.height}, '
        'sensorOrientation=${camera.sensorOrientation}, '
        'lensDirection=${camera.lensDirection}, '
        'planeCount=${image.planes.length}',
      );
      for (var index = 0; index < image.planes.length; index++) {
        final plane = image.planes[index];
        print(
          '[CAMERA PLANE] index=$index, bytes=${plane.bytes.length}, '
          'bytesPerRow=${plane.bytesPerRow}, '
          'bytesPerPixel=${plane.bytesPerPixel}',
        );
      }
    }
    final bytes = formatGroup == ImageFormatGroup.bgra8888
        ? image.planes.first.bytes
        : _yuv420ToNv21(image);
    final format = formatGroup == ImageFormatGroup.bgra8888
        ? InputImageFormat.bgra8888
        : InputImageFormat.nv21;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: formatGroup == ImageFormatGroup.bgra8888
            ? image.planes.first.bytesPerRow
            : image.width,
      ),
    );
  }

  static InputImageRotation rotationForCamera(
    CameraDescription camera, [
    DeviceOrientation deviceOrientation = DeviceOrientation.portraitUp,
  ]) {
    const deviceRotations = <DeviceOrientation, int>{
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final deviceRotation = deviceRotations[deviceOrientation] ?? 0;
    final isFrontCamera = camera.lensDirection == CameraLensDirection.front;
    final compensation = isFrontCamera
        ? (camera.sensorOrientation + deviceRotation) % 360
        : (camera.sensorOrientation - deviceRotation + 360) % 360;
    return _rotationForDegrees(compensation);
  }

  static Uint8List _yuv420ToNv21(CameraImage image) {
    if (image.planes.length < 3) {
      throw StateError(
          'Expected three YUV420 planes, got ${image.planes.length}');
    }

    final width = image.width;
    final height = image.height;
    final output = Uint8List(width * height + (width * height ~/ 2));
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    var outputOffset = 0;
    for (var row = 0; row < height; row++) {
      final rowOffset = row * yPlane.bytesPerRow;
      for (var column = 0; column < width; column++) {
        output[outputOffset++] = yPlane.bytes[rowOffset + column];
      }
    }

    final chromaWidth = (width + 1) ~/ 2;
    final chromaHeight = (height + 1) ~/ 2;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < chromaHeight; row++) {
      final uRowOffset = row * uPlane.bytesPerRow;
      final vRowOffset = row * vPlane.bytesPerRow;
      for (var column = 0; column < chromaWidth; column++) {
        final uIndex = uRowOffset + column * uPixelStride;
        final vIndex = vRowOffset + column * vPixelStride;
        output[outputOffset++] = vPlane.bytes[vIndex];
        output[outputOffset++] = uPlane.bytes[uIndex];
      }
    }
    return output;
  }

  static InputImageRotation _rotationForDegrees(int orientation) {
    switch (orientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
        return InputImageRotation.rotation0deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Scale Bounding Box from actual camera image coords to screen logical pixels
  static Rect scaleBoundingBox({
    required Face face,
    required Size imageSize,
    required Size screenSize,
    required InputImageRotation rotation,
    bool mirrorX = false,
  }) {
    final isQuarterTurn = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final orientedSize =
        isQuarterTurn ? Size(imageSize.height, imageSize.width) : imageSize;
    final scale = max(
      screenSize.width / orientedSize.width,
      screenSize.height / orientedSize.height,
    );
    final offsetX = (orientedSize.width * scale - screenSize.width) / 2;
    final offsetY = (orientedSize.height * scale - screenSize.height) / 2;
    final box = face.boundingBox;
    final left = box.left * scale - offsetX;
    final right = box.right * scale - offsetX;
    final top = box.top * scale - offsetY;
    final bottom = box.bottom * scale - offsetY;
    if (!mirrorX) return Rect.fromLTRB(left, top, right, bottom);
    return Rect.fromLTRB(
      screenSize.width - right,
      top,
      screenSize.width - left,
      bottom,
    );
  }

  static void dispose() {
    _detector.close();
  }
}
