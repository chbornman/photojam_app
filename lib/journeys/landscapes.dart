import 'package:flutter/material.dart';

class LandscapesPage extends StatelessWidget {
  final List<String> lessons = [
    'Lesson 1: Landscape Basics',
    'Lesson 2: Time of Day',
    'Lesson 3: Non-human Subjects',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LANDSCAPES'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(lessons[index]),
            );
          },
        ),
      ),
    );
  }
}