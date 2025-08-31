import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static const String _imageDirectory = 'product_images';

  /// Pick an image file from device storage
  static Future<String?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (kIsWeb) {
          // Handle web platform
          if (file.bytes != null) {
            return await _saveImageFromBytes(file.bytes!, file.name);
          }
        } else {
          // Handle desktop/mobile platforms
          if (file.path != null) {
            return await _saveImageFromPath(file.path!);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Save image from file path (desktop/mobile)
  static Future<String> _saveImageFromPath(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileName = path.basename(filePath);
    return await _saveImageFromBytes(bytes, fileName);
  }

  /// Save image from bytes data
  static Future<String> _saveImageFromBytes(Uint8List bytes, String originalFileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(path.join(appDir.path, _imageDirectory));
    
    // Create directory if it doesn't exist
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalFileName);
    final fileName = 'product_$timestamp$extension';
    
    final savePath = path.join(imageDir.path, fileName);
    final file = File(savePath);
    
    await file.writeAsBytes(bytes);
    
    return fileName; // Return relative filename only
  }

  /// Get full path to image file
  static Future<String> getImagePath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, _imageDirectory, fileName);
  }

  /// Check if image file exists
  static Future<bool> imageExists(String fileName) async {
    try {
      final fullPath = await getImagePath(fileName);
      return await File(fullPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete image file
  static Future<bool> deleteImage(String fileName) async {
    try {
      final fullPath = await getImagePath(fileName);
      final file = File(fullPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
    return false;
  }

  /// Get image file as bytes for display
  static Future<Uint8List?> getImageBytes(String fileName) async {
    try {
      if (kIsWeb) {
        // For web, images might be stored differently
        // This is a simplified implementation
        return null;
      } else {
        final fullPath = await getImagePath(fileName);
        final file = File(fullPath);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error reading image: $e');
    }
    return null;
  }

  /// Clean up unused images (call this periodically)
  static Future<void> cleanupUnusedImages(List<String> usedImageNames) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(appDir.path, _imageDirectory));
      
      if (await imageDir.exists()) {
        final files = await imageDir.list().toList();
        for (final entity in files) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            if (!usedImageNames.contains(fileName)) {
              await entity.delete();
              debugPrint('Deleted unused image: $fileName');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up images: $e');
    }
  }
}
