import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final List<Map<String, List<String>>> submissions = [
    {
      'the ART of STORYTELLING': [
        'assets/images/photo1.jpeg',
        'assets/images/photo2.jpeg',
        'assets/images/photo3.jpeg',
      ]
    },
    {
      'EVERYDAY MOMENTS': [
        'assets/images/photo4.jpeg',
        'assets/images/photo5.jpeg',
        'assets/images/photo6.jpeg',
      ]
    },
    {
      'the GESTURE': [
        'assets/images/photo7.jpeg',
        'assets/images/photo8.jpeg',
        'assets/images/photo9.jpeg',
      ]
    },
        {
      'test': [
        'assets/images/photo7.jpeg',
        'assets/images/photo8.jpeg',
        'assets/images/photo9.jpeg',
      ]
    },
        {
      'test2': [
        'assets/images/photo7.jpeg',
        'assets/images/photo8.jpeg',
        'assets/images/photo9.jpeg',
      ]
    },
        {
      'test3': [
        'assets/images/photo7.jpeg',
        'assets/images/photo8.jpeg',
        'assets/images/photo9.jpeg',
      ]
    },
    // Add more weeks as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous Submissions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  String week = submissions[index].keys.first;
                  List<String> images = submissions[index][week]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          week,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: images
                              .map(
                                (image) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Image.asset(
                                      image,
                                      fit: BoxFit.cover,
                                      height: 100,  // Set a height for the images
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}