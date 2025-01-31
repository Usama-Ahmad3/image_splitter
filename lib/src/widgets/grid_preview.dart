import 'package:croppy/croppy.dart';
import 'package:flutter/cupertino.dart';

class CropperGridPreview extends StatelessWidget {
  const CropperGridPreview({
    super.key,
    required this.controller,
    required this.gesturePadding,
    required this.crossAxisCount,
    required this.rowCount,
    this.lineColor = CupertinoColors.white,
  });

  final CroppableImageController controller;
  final double gesturePadding;
  final int crossAxisCount;
  final int rowCount;
  final Color lineColor;

  Widget _buildGrid(BuildContext context, bool areGuideLinesVisible) {
    final innerLines = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      opacity: areGuideLinesVisible ? 1.0 : 0.0,
      child: CustomPaint(
        painter: _CupertinoImageCropperGuidesPainter(
          lineColor,
          crossAxisCount: crossAxisCount,
          rowCount: rowCount,
        ),
      ),
    );

    final cropShape = controller.data.cropShape;

    Widget child = Stack(
      fit: StackFit.passthrough,
      children: [
        CustomPaint(
          painter: _OuterLinesPainter(
            cropShape: cropShape,
            color: lineColor,
          ),
        ),
        ClipPath(
          clipper: CropShapeClipper(cropShape),
          child: innerLines,
        ),
      ],
    );

    return CroppableImageGestureDetector(
      controller: controller,
      gesturePadding: gesturePadding,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildGrid(context, true);
  }
}

class _OuterLinesPainter extends CustomPainter {
  _OuterLinesPainter({
    required this.cropShape,
    required this.color,
  });

  final Color color;
  final CropShape cropShape;

  @override
  void paint(Canvas canvas, Size size) {
    size = Size(size.width, size.height);

    final cropPath = cropShape.getTransformedPathForSize(size);

    final pathPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw the path
    canvas.drawPath(cropPath.toUiPath(), pathPaint);
    canvas.clipPath(cropPath.toUiPath());
  }

  @override
  bool shouldRepaint(_OuterLinesPainter oldDelegate) =>
      oldDelegate.cropShape != cropShape;
}

class _CupertinoImageCropperGuidesPainter extends CustomPainter {
  _CupertinoImageCropperGuidesPainter(this.color,
      {required this.crossAxisCount, required this.rowCount});

  final Color color;
  final int crossAxisCount;
  final int rowCount;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0;

    // Draw vertical lines
    for (int i = 1; i < crossAxisCount; i++) {
      final x = size.width * i / crossAxisCount;
      canvas.drawLine(
        Offset(x, 0.0),
        Offset(x, size.height),
        guidePaint,
      );
    }

    // Draw horizontal lines
    for (int i = 1; i < rowCount; i++) {
      final y = size.height * i / rowCount;
      canvas.drawLine(
        Offset(0.0, y),
        Offset(size.width, y),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CupertinoImageCropperGuidesPainter oldDelegate) =>
      oldDelegate.crossAxisCount != crossAxisCount ||
      oldDelegate.rowCount != rowCount;
}
