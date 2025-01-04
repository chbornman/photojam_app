import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photojam_app/appwrite/storage/providers/storage_providers.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownViewer extends ConsumerStatefulWidget {
  final Uint8List content;

  const MarkdownViewer({
    super.key, 
    required this.content,
  });

  @override
  ConsumerState<MarkdownViewer> createState() => _MarkdownViewerState();
}

class _MarkdownViewerState extends ConsumerState<MarkdownViewer> {
  String? _processedMarkdown;
  bool _loading = true;
  final Map<String, String> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _processMarkdown();
  }

  Future<void> _processMarkdown() async {
    try {
      String markdown = utf8.decode(widget.content);
      
      // Find all image references
      final regex = RegExp(r'!\[([^\]]*)\]\(/imageBuilder/([^\)]+)\)');
      final matches = regex.allMatches(markdown);

      for (final match in matches) {
        final altText = match[1] ?? '';
        final contentId = match[2] ?? '';
        
        if (contentId.isEmpty) continue;

        // Download and cache image
        final storageNotifier = ref.read(lessonStorageProvider.notifier);
        final bytes = await storageNotifier.downloadFile(contentId);

        // Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$contentId.jpg');
        await file.writeAsBytes(bytes);
        
        // Cache the file path
        _imageCache[contentId] = file.path;

        // Replace in markdown
        final newImageRef = '![$altText](file://${file.path})';
        markdown = markdown.replaceFirst(match[0]!, newImageRef);
      }

      if (mounted) {
        setState(() {
          _processedMarkdown = markdown;
          _loading = false;
        });
      }

    } catch (e) {
      LogService.instance.error('Error processing markdown: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _processedMarkdown = utf8.decode(widget.content); // Fallback to original
        });
      }
    }
  }

  @override
  void dispose() {
    // Cleanup temporary files
    for (final path in _imageCache.values) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        LogService.instance.error('Error deleting cached file: $e');
      }
    }
    super.dispose();
  }

  Future<void> _handleLinkTap(String text, String? href, String title) async {
    if (href == null) return;

    try {
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        LogService.instance.error('Could not launch URL: $href');
      }
    } catch (e) {
      LogService.instance.error('Error launching URL $href: $e');
    }
  }

  @override 
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(
          data: _processedMarkdown ?? '',
          onTapLink: _handleLinkTap, // Add this
          imageBuilder: (uri, title, alt) {
            // Handle local file images
            if (uri.scheme == 'file') {
              return Image.file(File(uri.path));
            }
            // Handle web images 
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return Image.network(uri.toString());
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}