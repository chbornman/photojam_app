import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/storage_api.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:convert';

class MyJamsPage extends StatelessWidget {
  final String userId;

  MyJamsPage({required this.userId});

  Future<List<Map<String, dynamic>>> _fetchUserJams(
      BuildContext context) async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final response = await databaseApi.getJamsByUser(userId);

      return response.documents.map((doc) {
        return {
          'id': doc.$id,
          'title': doc.data['title'] ?? 'Untitled Jam',
          'lessons': doc.data['lessons'] as List<dynamic>? ?? []
        };
      }).toList();
    } catch (e) {
      print('Error fetching user jams: $e');
      return [];
    }
  }

  Future<String> _fetchLessonTitle(
      BuildContext context, String lessonUrl) async {
    final storageApi = Provider.of<StorageAPI>(context, listen: false);
    try {
      Uint8List lessonData = await storageApi.getLessonByURL(lessonUrl);
      final content = utf8.decode(lessonData);
      final firstLine = content.split('\n').first.trim();
      return firstLine.startsWith('#')
          ? firstLine.replaceFirst('#', '').trim()
          : 'Untitled Lesson';
    } catch (e) {
      print('Error fetching lesson title: $e');
      return 'Untitled Lesson';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Jams")),
      body: Text("My Jams Page"),
    );
  }
}
