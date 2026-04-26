import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:worknet/core/constants/worknet_constants.dart';

class AvatarResult {
  final String localPath;
  final String thumbBase64;
  final String hash;

  const AvatarResult({
    required this.localPath,
    required this.thumbBase64,
    required this.hash,
  });
}

class AvatarService {
  AvatarService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<AvatarResult?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: WorkNetConstants.avatarImageSizePx.toDouble(),
      maxHeight: WorkNetConstants.avatarImageSizePx.toDouble(),
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (picked == null) return null;
    return processPickedFile(File(picked.path));
  }

  Future<AvatarResult?> captureWithCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: WorkNetConstants.avatarImageSizePx.toDouble(),
      maxHeight: WorkNetConstants.avatarImageSizePx.toDouble(),
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (picked == null) return null;
    return processPickedFile(File(picked.path));
  }

  Future<AvatarResult?> recoverLostData() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.files == null || response.files!.isEmpty) {
      return null;
    }
    return processPickedFile(File(response.files!.first.path));
  }

  Future<AvatarResult> processPickedFile(File source) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Unsupported image file');
    }

    final square = _centerCropSquare(decoded);
    final full = img.copyResize(
      square,
      width: WorkNetConstants.avatarImageSizePx,
      height: WorkNetConstants.avatarImageSizePx,
      interpolation: img.Interpolation.average,
    );
    final thumb = img.copyResize(
      square,
      width: WorkNetConstants.avatarBroadcastSizePx,
      height: WorkNetConstants.avatarBroadcastSizePx,
      interpolation: img.Interpolation.average,
    );

    final fullBytes = img.encodeJpg(full, quality: 82);
    var thumbBytes = img.encodeJpg(thumb, quality: 56);
    var thumbBase64 = base64Encode(thumbBytes);
    if (thumbBase64.length > WorkNetConstants.avatarBroadcastMaxBase64Chars) {
      thumbBytes = img.encodeJpg(thumb, quality: 42);
      thumbBase64 = base64Encode(thumbBytes);
    }
    if (thumbBase64.length > WorkNetConstants.avatarBroadcastMaxBase64Chars) {
      throw const FormatException('Avatar thumbnail exceeds broadcast limit');
    }

    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory(p.join(dir.path, 'avatars'));
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final digest = sha256.convert(fullBytes).toString();
    final target = File(p.join(avatarDir.path, 'me_$digest.jpg'));
    await target.writeAsBytes(fullBytes, flush: true);

    return AvatarResult(
      localPath: target.path,
      thumbBase64: thumbBase64,
      hash: digest,
    );
  }

  Future<void> deleteAvatarFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup; profile deletion must not fail on file cleanup.
    }
  }

  img.Image _centerCropSquare(img.Image image) {
    final side = image.width < image.height ? image.width : image.height;
    final x = (image.width - side) ~/ 2;
    final y = (image.height - side) ~/ 2;
    return img.copyCrop(image, x: x, y: y, width: side, height: side);
  }
}

final avatarServiceProvider = Provider<AvatarService>((_) => AvatarService());
