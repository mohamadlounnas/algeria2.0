import 'dart:async';
import 'dart:ui' as ui;

import 'package:dowa/core/di/dio_client.dart';
import 'package:flutter/material.dart' hide Image, Colors;
import 'package:flutter/material.dart' as material show CircularProgressIndicator, Colors;

import '../../../../core/theme/colors.dart';
import '../../domain/entities/request.dart';

/// Widget to display original image with bounding boxes and animated heatmap overlay
class AnnotatedImageViewer extends StatefulWidget {
  final String imageUrl;
  final List<LeafData> leafs;

  const AnnotatedImageViewer({
    super.key,
    required this.imageUrl,
    required this.leafs,
  });

  @override
  State<AnnotatedImageViewer> createState() => _AnnotatedImageViewerState();
}

class _AnnotatedImageViewerState extends State<AnnotatedImageViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  ui.Image? _originalImage;
  ui.Image? _grayscaleImage;
  final Map<int, ui.Image?> _heatmapImages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _loadImages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _originalImage?.dispose();
    _grayscaleImage?.dispose();
    for (final img in _heatmapImages.values) {
      img?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadImages() async {
    try {
      // Load original image
      final originalImage = await _loadNetworkImage(widget.imageUrl);
      
      // Create grayscale version
      final grayscaleImage = await _createGrayscaleImage(originalImage);

      // Load heatmap images for leafs that have them
      for (int i = 0; i < widget.leafs.length; i++) {
        final heatmapUrl = widget.leafs[i].heatmap;
        if (heatmapUrl != null && heatmapUrl.isNotEmpty) {
          try {
            final heatmapImg = await _loadNetworkImage(heatmapUrl);
            _heatmapImages[i] = heatmapImg;
          } catch (e) {
            _heatmapImages[i] = null;
          }
        }
      }

      if (mounted) {
        setState(() {
          _originalImage = originalImage;
          _grayscaleImage = grayscaleImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<ui.Image> _loadNetworkImage(String url) async {
    url = url
    .replaceAll('http://10.0.2.2:3333', DioClient.getBaseUrl());
    final completer = Completer<ui.Image>();
    final imageStream = NetworkImage(url).resolve(const ImageConfiguration());
    
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      imageStream.removeListener(listener);
      completer.complete(info.image);
    }, onError: (error, stackTrace) {
      imageStream.removeListener(listener);
      completer.completeError(error);
    });
    
    imageStream.addListener(listener);
    return completer.future;
  }

  Future<ui.Image> _createGrayscaleImage(ui.Image original) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Apply grayscale color filter
    final paint = Paint()
      ..colorFilter = const ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0,      0,      0,      1, 0,
      ]);
    
    canvas.drawImage(original, Offset.zero, paint);
    
    final picture = recorder.endRecording();
    return await picture.toImage(original.width, original.height);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: material.Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: _isLoading
              ? const Center(
                  child: material.CircularProgressIndicator(),
                )
              : _originalImage == null
                  ? const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _AnnotatedImagePainter(
                            originalImage: _originalImage!,
                            grayscaleImage: _grayscaleImage,
                            heatmapImages: _heatmapImages,
                            leafs: widget.leafs,
                            animationValue: _animationController.value,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _AnnotatedImagePainter extends CustomPainter {
  final ui.Image originalImage;
  final ui.Image? grayscaleImage;
  final Map<int, ui.Image?> heatmapImages;
  final List<LeafData> leafs;
  final double animationValue;

  _AnnotatedImagePainter({
    required this.originalImage,
    required this.grayscaleImage,
    required this.heatmapImages,
    required this.leafs,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scaling to fit image in canvas
    final imageAspect = originalImage.width / originalImage.height;
    final canvasAspect = size.width / size.height;
    
    double scale;
    Offset offset;
    
    if (imageAspect > canvasAspect) {
      // Image is wider
      scale = size.width / originalImage.width;
      offset = Offset(0, (size.height - originalImage.height * scale) / 2);
    } else {
      // Image is taller
      scale = size.height / originalImage.height;
      offset = Offset((size.width - originalImage.width * scale) / 2, 0);
    }

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw base image (grayscale)
    if (grayscaleImage != null) {
      canvas.drawImage(grayscaleImage!, Offset.zero, Paint());
    } else {
      canvas.drawImage(originalImage, Offset.zero, Paint());
    }

    // Animate between normal and heatmap overlay for each leaf
    for (int i = 0; i < leafs.length; i++) {
      final leaf = leafs[i];
      final bbox = leaf.bbox;
      final heatmap = heatmapImages[i];

      if (bbox != null) {
        // Draw heatmap overlay with animation (fade in/out)
        if (heatmap != null) {
          final heatmapPaint = Paint()
            ..color = material.Colors.white.withOpacity(0.6 * animationValue);
          
          final srcRect = Rect.fromLTWH(
            0,
            0,
            heatmap.width.toDouble(),
            heatmap.height.toDouble(),
          );
          
          final dstRect = Rect.fromLTRB(
            bbox.x1.toDouble(),
            bbox.y1.toDouble(),
            bbox.x2.toDouble(),
            bbox.y2.toDouble(),
          );
          
          canvas.drawImageRect(heatmap, srcRect, dstRect, heatmapPaint);
        }

        // Draw bounding box
        final boxPaint = Paint()
          ..color = leaf.isDiseased
              ? material.Colors.red.withOpacity(0.8)
              : material.Colors.green.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        final rect = Rect.fromLTRB(
          bbox.x1.toDouble(),
          bbox.y1.toDouble(),
          bbox.x2.toDouble(),
          bbox.y2.toDouble(),
        );

        canvas.drawRect(rect, boxPaint);

        // Draw label background
        final labelText = 'Leaf ${i + 1}';
        final textSpan = TextSpan(
          text: labelText,
          style: const TextStyle(
            color: material.Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        
        final labelBgPaint = Paint()
          ..color = leaf.isDiseased
              ? material.Colors.red.withOpacity(0.8)
              : material.Colors.green.withOpacity(0.8);
        
        final labelRect = Rect.fromLTWH(
          bbox.x1.toDouble(),
          bbox.y1.toDouble() - 22,
          textPainter.width + 8,
          20,
        );
        
        canvas.drawRect(labelRect, labelBgPaint);
        
        // Draw label text
        textPainter.paint(
          canvas,
          Offset(bbox.x1.toDouble() + 4, bbox.y1.toDouble() - 20),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnnotatedImagePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.originalImage != originalImage;
  }
}
