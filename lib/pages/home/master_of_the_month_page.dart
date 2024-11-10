import 'package:flutter/material.dart';

class MasterOfTheMonthPage extends StatelessWidget {
  const MasterOfTheMonthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Master of the Month'),
      ),
      body: Center(
        child: Text(
          'Details about the Master of the Month go here!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}