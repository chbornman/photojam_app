import 'package:flutter/material.dart';

class WalkTheStreetsPage extends StatelessWidget {
  final List<String> lessons = [
    'Lesson 1: Street Smarts',
    'Lesson 2: Zone Focus',
    'Lesson 3: Compositions on the Street',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WALK the STREETS'),
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