import 'package:flutter/material.dart';

class AbstractPhotographyPage extends StatelessWidget {
  final List<String> lessons = [
    'Lesson 1: Light and Shadow',
    'Lesson 2: Constructivism',
    'Lesson 3: Minimalism',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Abstract Photography'),
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