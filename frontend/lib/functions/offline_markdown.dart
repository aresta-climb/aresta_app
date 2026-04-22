import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';

/// A widget that renders Markdown content with support for local offline images.
/// 
/// It automatically resolves relative image paths against the application's 
/// local 'downloads' directory.
class OfflineMarkdown extends StatelessWidget {
  /// The raw markdown string to be rendered.
  final String data;

  const OfflineMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Directory>(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final downloadsPath = '${snapshot.data!.path}/downloads';
        
        return MarkdownBody(
          data: data,
          imageBuilder: (Uri uri, String? title, String? alt) {
            final String path = uri.toString();
            
            // If it's an online image or absolute uri, handle normally
            if (path.startsWith('http://') || path.startsWith('https://')) {
              return Image.network(path);
            }
            
            // Resolve offline local asset from our custom relative path
            final localFile = File('$downloadsPath/$path');
            if (localFile.existsSync()) {
              return Image.file(localFile);
            }
            
            // Fallback placeholder if the image is missing or cannot be found
            return const Icon(Icons.broken_image, color: Colors.grey);
          },
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(color: Colors.white70, fontSize: 16),
            h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            h2: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            h3: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
