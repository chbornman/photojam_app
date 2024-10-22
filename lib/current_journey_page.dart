import 'package:flutter/material.dart';

class CurrentJourneyPage extends StatelessWidget {
  final List<String> lessons = [
    'Lesson 1: Introduction to Storytelling',
    'Lesson 2: Crafting Your Narrative',
    'Lesson 3: Developing Characters',
    'Lesson 4: The Art of Dialogue',
    'Lesson 5: Visual Storytelling',
    'Lesson 6: Storytelling in Photography',
    'Lesson 7: Editing Your Story',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ART of STORYTELLING'),
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