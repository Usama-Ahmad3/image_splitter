import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_splitter/image_splitter.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageSplitterDemo(),
    );
  }
}

class ImageSplitterDemo extends StatefulWidget {
  const ImageSplitterDemo({super.key});

  @override
  State<ImageSplitterDemo> createState() => _ImageSplitterDemoState();
}

class _ImageSplitterDemoState extends State<ImageSplitterDemo> {
  File? imageFile;
  ImageSplitterController? splitterController;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> splitImage() async {
    if (splitterController != null && imageFile != null) {
      try {
        final splitImages = await splitterController!.splitImage(imageFile!);
        if (!mounted) return;

        // Show preview
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Split Images (${splitImages.length})',
                      style: Theme.of(context).textTheme.titleLarge),
                  Wrap(
                    children: splitImages
                        .map((imageData) => Padding(
                              padding: EdgeInsets.all(4),
                              child: Image.memory(
                                imageData,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error splitting image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Splitter Demo')),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: pickImage,
              child: Text('Pick Image'),
            ),
          ),
          if (imageFile != null)
            Expanded(
              child: ImageSplitter(
                image: imageFile!,
                crossAxisCount: 4,
                rowCount: 4,
                onControllerReady: (controller) {
                  splitterController = controller;
                },
              ),
            ),
          if (imageFile != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: splitImage,
                child: Text('Split Image'),
              ),
            ),
        ],
      ),
    );
  }
}
