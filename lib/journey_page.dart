import 'package:flutter/material.dart';
import 'current_journey_page.dart';

class JourneyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jam Journey'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Journey section
            Text(
              'Current Journey',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CurrentJourneyPage()),
                );
              },
              child: Text(
                'the ART of STORYTELLING',
                style: TextStyle(fontSize: 18, color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            SizedBox(height: 20),
            // Previous Journeys section
            Text(
              'Previous Journeys',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Placeholder for previous journeys
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text('Previous Journey 1'),
                  ),
                  ListTile(
                    title: Text('Previous Journey 2'),
                  ),
                  ListTile(
                    title: Text('Previous Journey 3'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}