import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:croppy/croppy.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class ImageSplitterController {
  final MaterialCroppableImageController croppyController;
  final int crossAxisCount;
  final int totalCount;

  ImageSplitterController({
    required this.croppyController,
    required this.crossAxisCount,
    required this.totalCount,
  });

  Future<List<Uint8List>> splitImage(File image) async {
    try {
      final cropRect = croppyController.data.cropRect;
      final cropY = (cropRect.bottom - cropRect.top).abs();
      final cropX = (cropRect.left - cropRect.right).abs();

      final List<Uint8List> splitImages = await compute(splitSelectedArea, {
        'image': image,
        'cropX': cropRect.left,
        'cropY': cropRect.top,
        'cropWidth': cropX,
        'cropHeight': cropY,
        'crossAxisCount': crossAxisCount,
        'totalCount': totalCount,
      });

      return splitImages;
    } catch (e) {
      throw Exception('Unable to split image: $e');
    }
  }

  static Future<List<Uint8List>> splitSelectedArea(
      Map<String, dynamic> params) async {
    final File imageFile = params['image'] as File;
    final double cropX = params['cropX'] as double;
    final double cropY = params['cropY'] as double;
    final double cropWidth = params['cropWidth'] as double;
    final double cropHeight = params['cropHeight'] as double;
    final int crossAxisCount = params['crossAxisCount'] as int;
    final int totalCount = params['totalCount'] as int;

    final Uint8List bytes = await imageFile.readAsBytes();
    final img.Image? original = img.decodeImage(bytes);
    if (original == null) throw Exception('Failed to decode image');

    const int targetMaxSize = 1200;
    double scale = 1.0;
    if (original.width > targetMaxSize || original.height > targetMaxSize) {
      scale = targetMaxSize / math.max(original.width, original.height);
    }

    final img.Image resizedImage = scale < 1.0
        ? img.copyResize(
            original,
            width: (original.width * scale).round(),
            height: (original.height * scale).round(),
            interpolation: img.Interpolation.nearest,
          )
        : original;

    final int adjustedCropX = math.max(0, (cropX * scale).round());
    final int adjustedCropY = math.max(0, (cropY * scale).round());
    final int adjustedCropWidth = math.min(
      (cropWidth * scale).round(),
      resizedImage.width - adjustedCropX,
    );
    final int adjustedCropHeight = math.min(
      (cropHeight * scale).round(),
      resizedImage.height - adjustedCropY,
    );

    final img.Image selectedArea = img.copyCrop(
      resizedImage,
      x: adjustedCropX,
      y: adjustedCropY,
      width: adjustedCropWidth,
      height: adjustedCropHeight,
    );

    final int rowCount = (totalCount / crossAxisCount).ceil();
    final int cellWidth = (selectedArea.width / crossAxisCount).floor();
    final int cellHeight = (selectedArea.height / rowCount).floor();

    final List<Uint8List> results = [];

    for (int i = 0; i < totalCount; i++) {
      final int row = i ~/ crossAxisCount;
      final int col = i % crossAxisCount;
      final int x = col * cellWidth;
      final int y = row * cellHeight;

      if (x >= selectedArea.width || y >= selectedArea.height) continue;

      final int width = math.min(cellWidth, selectedArea.width - x);
      final int height = math.min(cellHeight, selectedArea.height - y);

      if (width <= 0 || height <= 0) continue;

      final img.Image split = img.copyCrop(
        selectedArea,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      final List<int> jpgBytes = img.encodeJpg(split, quality: 85);
      results.add(Uint8List.fromList(jpgBytes));
    }

    return results;
  }

  void dispose() {
    croppyController.dispose();
  }
}
