import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

/// Extracts the title from markdown content
String extractTitleFromMarkdown(String content) {
  final lines = content.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#')) {
      return trimmed.replaceFirst(RegExp(r'#+'), '').trim();
    }
  }
  return 'Untitled Lesson';
}

/// Downloads and extracts title from a markdown file
Future<String> getLessonTitle(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return extractTitleFromMarkdown(response.body);
    } else {
      throw Exception('Failed to load lesson');
    }
  } catch (e) {
    return 'Error Loading Lesson';
  }
}

class JourneyContainer extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> lessons;
  final ThemeData theme;
  final Function(String url) onLessonTap;

  const JourneyContainer({
    super.key,
    required this.title,
    required this.lessons,
    required this.theme,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return FutureBuilder<String>(
                future: getLessonTitle(lesson['url']),
                builder: (context, snapshot) {
                  final lessonTitle = snapshot.data ?? 'Loading...';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          '${index + 1}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      title: Text(
                        lessonTitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => onLessonTap(lesson['url']),
                      trailing: Icon(
                        Icons.arrow_forward,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
