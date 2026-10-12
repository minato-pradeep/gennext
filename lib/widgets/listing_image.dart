import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Renders a listing photo stored as base64, a local file path, or a URL.
class ListingImage extends StatelessWidget {
  final String imageData;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ListingImage({
    super.key,
    required this.imageData,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _buildImage() {
    if (imageData.isEmpty) return _placeholder();

    if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      return Image.network(
        imageData,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _loading(),
      );
    }

    final isFilePath = imageData.startsWith('file:') ||
        imageData.startsWith('/') ||
        (imageData.length < 400 &&
            (imageData.contains('\\') ||
                imageData.contains('.jpg') ||
                imageData.contains('.jpeg') ||
                imageData.contains('.png') ||
                imageData.contains('.webp')));

    if (isFilePath) {
      final path = imageData.startsWith('file:')
          ? Uri.parse(imageData).toFilePath()
          : imageData;
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
    }

    try {
      final raw = imageData.contains(',')
          ? imageData.split(',').last
          : imageData;
      final bytes = base64Decode(raw);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: (height != null && height! < 90) ? 28 : 48,
          color: Colors.grey,
        ),
      );

  Widget _loading() => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
}

void showListingImagePreview(BuildContext context, String imageData) {
  if (imageData.isEmpty) return;
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: ListingImage(
              imageData: imageData,
              width: double.infinity,
              height: MediaQuery.of(ctx).size.height * 0.7,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}
