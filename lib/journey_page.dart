import 'package:flutter/material.dart';
import 'journeys/the_art_of_storytelling.dart';
import 'journeys/landscapes.dart';
import 'journeys/walk_the_streets.dart';
import 'journeys/abstract_photography.dart';

class JourneyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TheArtOfStorytellingPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.amberAccent,
                ),
                child: Text('the ART of STORYTELLING', style: TextStyle(fontSize: 18)),
              ),
            ),
            SizedBox(height: 20),

            // Previous Journeys section
            Text(
              'Previous Journeys',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Previous journeys with buttons
            Expanded(
              child: ListView(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AbstractPhotographyPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.amberAccent,
                      ),
                      child: Text('Abstract Photography', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => WalkTheStreetsPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.amberAccent,
                      ),
                      child: Text('Walk the Streets', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LandscapesPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.amberAccent,
                      ),
                      child: Text('Lushous Landscapes', style: TextStyle(fontSize: 18)),
                    ),
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