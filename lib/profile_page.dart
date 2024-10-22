import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  // Mock data for the current week submission with three images
  final List<String> currentSubmission = [
    'assets/images/current_week.jpg',
    'assets/icon/app_icon.png',
    'assets/icon/app_icon.png',
  ];

  // Mock data for the previous submissions
  final List<Map<String, List<String>>> previousSubmissions = [
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
      'Week 4': [
        'assets/images/photo1.jpeg',
        'assets/images/photo2.jpeg',
        'assets/images/photo3.jpeg',
      ]
    },
    {
      'Week 5': [
        'assets/images/photo4.jpeg',
        'assets/images/photo5.jpeg',
        'assets/images/photo6.jpeg',
      ]
    },
    {
      'Week 6': [
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
            // Current Week Submission section
            Text(
              'Current Week Submission',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: currentSubmission
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
            SizedBox(height: 20),
            // Previous Submissions section
            Text(
              'Previous Submissions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: previousSubmissions.length,
                itemBuilder: (context, index) {
                  String week = previousSubmissions[index].keys.first;
                  List<String> images = previousSubmissions[index][week]!;

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