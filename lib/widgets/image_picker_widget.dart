import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? imageFileName;
  final ValueChanged<String?> onImageChanged;
  final double width;
  final double height;

  const ImagePickerWidget({
    super.key,
    this.imageFileName,
    required this.onImageChanged,
    this.width = 200,
    this.height = 200,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _currentImageFileName;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentImageFileName = widget.imageFileName;
    if (_currentImageFileName != null) {
      _loadImage();
    }
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFileName != oldWidget.imageFileName) {
      _currentImageFileName = widget.imageFileName;
      if (_currentImageFileName != null) {
        _loadImage();
      } else {
        setState(() {
          _imageBytes = null;
        });
      }
    }
  }

  Future<void> _loadImage() async {
    if (_currentImageFileName == null) return;
    
    try {
      final bytes = await ImageService.getImageBytes(_currentImageFileName!);
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fileName = await ImageService.pickImage();
      if (fileName != null && mounted) {
        setState(() {
          _currentImageFileName = fileName;
        });
        widget.onImageChanged(fileName);
        await _loadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    if (_currentImageFileName != null) {
      // Delete the image file
      await ImageService.deleteImage(_currentImageFileName!);
    }
    
    setState(() {
      _currentImageFileName = null;
      _imageBytes = null;
    });
    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    if (_imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius12 - 2),
            child: Image.memory(
              _imageBytes!,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _pickImage,
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _removeImage,
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius12 - 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'เลือกรูปภาพ',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'คลิกเพื่อเพิ่มรูปภาพสินค้า',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class ProductImageDisplay extends StatefulWidget {
  final String? imageFileName;
  final double width;
  final double height;
  final BoxFit fit;

  const ProductImageDisplay({
    super.key,
    this.imageFileName,
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  });

  @override
  State<ProductImageDisplay> createState() => _ProductImageDisplayState();
}

class _ProductImageDisplayState extends State<ProductImageDisplay> {
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProductImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFileName != oldWidget.imageFileName) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageFileName == null) {
      setState(() {
        _imageBytes = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await ImageService.getImageBytes(widget.imageFileName!);
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _isLoading = false;
        });
      }
      debugPrint('Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radius8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius8),
        child: Image.memory(
          _imageBytes!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }

    // Default placeholder
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
      ),
      child: Icon(
        Icons.inventory_2,
        size: widget.width * 0.4,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
