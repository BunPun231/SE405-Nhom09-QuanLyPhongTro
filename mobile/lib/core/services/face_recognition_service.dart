import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceRecognitionService {
  static Interpreter? _interpreter;
  static const String MODEL_PATH = 'assets/models/mobilefacenet.tflite';
  static const int INPUT_SIZE = 112;
  static const int EMBEDDING_SIZE = 192;
  static const double THRESHOLD = 0.8;

  static Future<void> initialize() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(MODEL_PATH);
    } catch (e) {
      debugPrint('Error loading TFLite model: $e');
    }
  }

  static Future<List<double>> extractEmbedding({
    required CameraImage cameraImage,
    required Rect faceBoundingBox,
  }) async {
    await initialize();
    if (_interpreter == null) throw Exception('TFLite interpreter not initialized');

    final Float32List input = await compute(_preprocessImageIsolate, {
      'cameraImage': cameraImage,
      'boundingBox': faceBoundingBox,
    });

    var output = List.filled(1 * EMBEDDING_SIZE, 0.0).reshape([1, EMBEDDING_SIZE]);
    _interpreter!.run([input], output);
    return List<double>.from(output[0]);
  }

  static Float32List _preprocessImageIsolate(Map<String, dynamic> params) {
    CameraImage cameraImage = params['cameraImage'];
    Rect box = params['boundingBox'];

    img.Image rgbImage = img.Image(width: cameraImage.width, height: cameraImage.height);
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      rgbImage = img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: cameraImage.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    } else {
      final yPlane = cameraImage.planes[0];
      final uPlane = cameraImage.planes[1];
      final vPlane = cameraImage.planes[2];
      for (int y = 0; y < cameraImage.height; y++) {
        for (int x = 0; x < cameraImage.width; x++) {
          final uvIndex = (uPlane.bytesPerPixel! * (x / 2).floor()) + (uPlane.bytesPerRow * (y / 2).floor());
          final index = y * cameraImage.width + x;
          final yp = yPlane.bytes[index];
          final up = uPlane.bytes[uvIndex];
          final vp = vPlane.bytes[uvIndex];
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          rgbImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }

    int x = box.left.toInt().clamp(0, rgbImage.width - 1);
    int y = box.top.toInt().clamp(0, rgbImage.height - 1);
    int w = box.width.toInt().clamp(1, rgbImage.width - x);
    int h = box.height.toInt().clamp(1, rgbImage.height - y);

    img.Image cropped = img.copyCrop(rgbImage, x: x, y: y, width: w, height: h);
    img.Image resized = img.copyResize(cropped, width: INPUT_SIZE, height: INPUT_SIZE);

    Float32List normalized = Float32List(INPUT_SIZE * INPUT_SIZE * 3);
    int idx = 0;
    for (int py = 0; py < INPUT_SIZE; py++) {
      for (int px = 0; px < INPUT_SIZE; px++) {
        final pixel = resized.getPixel(px, py);
        normalized[idx++] = (pixel.r.toDouble() - 127.5) / 127.5;
        normalized[idx++] = (pixel.g.toDouble() - 127.5) / 127.5;
        normalized[idx++] = (pixel.b.toDouble() - 127.5) / 127.5;
      }
    }
    return normalized;
  }

  static double calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  static Future<void> registerFace({
    required String userId,
    required String name,
    required List<double> embedding,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode({'userId': userId, 'name': name, 'embedding': embedding});
    await prefs.setString('face_$userId', data);
  }

  static Future<Map<String, Map<String, dynamic>>> getRegisteredFaces() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('face_'));
    Map<String, Map<String, dynamic>> faces = {};
    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          faces[key] = json.decode(jsonStr);
        } catch (_) {}
      }
    }
    return faces;
  }

  static Future<Map<String, dynamic>?> recognizeFace(List<double> embedding) async {
    final registered = await getRegisteredFaces();
    double maxSim = 0.0;
    Map<String, dynamic>? bestMatch;
    for (final entry in registered.values) {
      List<double> stored = List<double>.from(entry['embedding']);
      double sim = calculateCosineSimilarity(embedding, stored);
      if (sim > maxSim) {
        maxSim = sim;
        bestMatch = entry;
      }
    }
    if (maxSim >= THRESHOLD && bestMatch != null) {
      return {...bestMatch, 'similarity': maxSim};
    }
    return null;
  }
}
