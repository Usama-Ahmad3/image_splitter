import 'dart:typed_data';

class SplitResult {
  final List<Uint8List> images;
  final int crossAxisCount;
  final int rowCount;

  SplitResult({
    required this.images,
    required this.crossAxisCount,
    required this.rowCount,
  });
}
