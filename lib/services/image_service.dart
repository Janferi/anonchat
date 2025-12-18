import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'chat-images';

  /// Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Compress image to reduce file size
  Future<File?> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressedFile == null) return null;

      return File(compressedFile.path);
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original if compression fails
    }
  }

  /// Upload image to Supabase Storage
  Future<String?> uploadImage(File file, String userId) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from(_bucketName).upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Pick, compress, and upload image in one go
  Future<String?> pickCompressAndUpload({
    required String userId,
    ImageSource source = ImageSource.gallery,
  }) async {
    // Pick image
    final pickedFile = await pickImage(source: source);
    if (pickedFile == null) return null;

    // Compress image
    final compressedFile = await compressImage(pickedFile);
    if (compressedFile == null) return null;

    // Upload to Supabase
    final imageUrl = await uploadImage(compressedFile, userId);

    // Clean up temporary file
    try {
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }
    } catch (e) {
      print('Error deleting temp file: $e');
    }

    return imageUrl;
  }

  /// Delete image from Supabase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.skip(uri.pathSegments.indexOf(_bucketName) + 1).join('/');

      await _supabase.storage.from(_bucketName).remove([path]);
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
