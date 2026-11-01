import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

/// Ảnh đã chọn: giữ cả bytes (để xem trước) và base64 (để gửi API).
class PickedImage {
  final List<int> bytes;
  final String base64;
  final String name;
  PickedImage({required this.bytes, required this.base64, required this.name});
}

/// Tiện ích dùng chung cho chụp/chọn ảnh và mở file tải về.
/// Dùng chung cho các module Khách thuê, Hợp đồng, Tài chính.
class MediaHelper {
  MediaHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Hiện bottom sheet cho người dùng chọn "Chụp ảnh" hoặc "Chọn từ thư viện".
  /// Trả về null nếu người dùng hủy.
  static Future<PickedImage?> pickImage(
    BuildContext context, {
    int maxWidth = 1600,
    int imageQuality = 80,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      imageQuality: imageQuality,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedImage(
      bytes: bytes,
      base64: ApiClient.toBase64(bytes),
      name: file.name,
    );
  }

  /// Tải file từ API (vd. PDF hợp đồng), lưu vào thư mục tạm của app và mở bằng
  /// ứng dụng mặc định của máy. Trả về đường dẫn file đã lưu.
  static Future<String> downloadAndOpen(
    String endpoint, {
    required String fileName,
    Map<String, dynamic>? params,
  }) async {
    final bytes = await ApiClient.getBytes(endpoint, params: params);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await OpenFilex.open(file.path);
    return file.path;
  }
}
