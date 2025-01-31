import 'package:flutter/material.dart';
import 'package:croppy/croppy.dart';
import 'dart:io';
import '../controllers/image_splitter_controller.dart';
import 'grid_preview.dart';

class _ImageSplitterWidget extends StatefulWidget {
  final File image;
  final int crossAxisCount;
  final int rowCount;
  final double cellHeight;
  final double cellWidth;
  final void Function(ImageSplitterController)? onControllerReady;
  final Color loaderColor;

  const _ImageSplitterWidget({
    super.key,
    required this.image,
    required this.crossAxisCount,
    required this.rowCount,
    this.cellHeight = 100,
    this.cellWidth = 100,
    this.onControllerReady,
    this.loaderColor = Colors.blue,
  });

  @override
  State<_ImageSplitterWidget> createState() => _ImageSplitterWidgetState();
}

class _ImageSplitterWidgetState extends State<_ImageSplitterWidget>
    with TickerProviderStateMixin {
  MaterialCroppableImageController? _croppyController;
  ImageSplitterController? _splitterController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(_ImageSplitterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.crossAxisCount != widget.crossAxisCount ||
        oldWidget.rowCount != widget.rowCount ||
        oldWidget.image.path != widget.image.path) {
      _cleanupControllers();
      _initializeController();
    }
  }

  void _cleanupControllers() {
    if (_isDisposed) return; // Check if already disposed

    if (_splitterController != null) {
      _splitterController!.dispose();
      _splitterController = null;
    }
    if (_croppyController != null) {
      _croppyController!.dispose();
      _croppyController = null;
    }
  }

  Future<void> _initializeController() async {
    if (_croppyController != null) return;

    try {
      final imageProvider = FileImage(widget.image);
      final data = await CroppableImageData.fromImageProvider(imageProvider);

      if (!mounted) return;

      _croppyController = MaterialCroppableImageController(
        vsync: this,
        imageProvider: imageProvider,
        data: data,
        cropShapeFn: aabbCropShapeFn,
        enabledTransformations: <Transformation>[
          Transformation.panAndScale,
          Transformation.mirror,
        ],
      );

      if (!mounted) {
        _croppyController?.dispose();
        _croppyController = null;
        return;
      }

      _splitterController = ImageSplitterController(
        croppyController: _croppyController!,
        crossAxisCount: widget.crossAxisCount,
        totalCount: widget.crossAxisCount * widget.rowCount,
      );

      if (mounted) {
        setState(() {});
        widget.onControllerReady?.call(_splitterController!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_croppyController == null) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.loaderColor,
        ),
      );
    }

    return CroppableImagePageAnimator(
      controller: _croppyController!,
      builder: (context, animation) => AnimatedCroppableImageViewport(
        controller: _croppyController!,
        maxBackgroundOpacity: 0.4,
        minBackgroundOpacity: 0,
        heroTag: widget.image.path,
        cropHandlesBuilder: (BuildContext context) {
          return CropperGridPreview(
            controller: _croppyController!,
            crossAxisCount: widget.crossAxisCount,
            rowCount: widget.rowCount,
            gesturePadding: 16.0,
          );
        },
        overlayOpacityAnimation: animation,
        gesturePadding: 16.0,
      ),
    );
  }
}

class ImageSplitter extends StatelessWidget {
  final File image;
  final int crossAxisCount;
  final int rowCount;
  final double cellHeight;
  final double cellWidth;
  final void Function(ImageSplitterController)? onControllerReady;
  final Color loaderColor;

  const ImageSplitter({
    super.key,
    required this.image,
    required this.crossAxisCount,
    required this.rowCount,
    this.cellHeight = 100,
    this.cellWidth = 100,
    this.onControllerReady,
    this.loaderColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return _ImageSplitterWidget(
      key: ValueKey('${image.path}-$crossAxisCount-$rowCount'),
      image: image,
      crossAxisCount: crossAxisCount,
      rowCount: rowCount,
      cellHeight: cellHeight,
      cellWidth: cellWidth,
      onControllerReady: onControllerReady,
      loaderColor: loaderColor,
    );
  }
}
