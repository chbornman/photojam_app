import 'package:flutter/material.dart';
import 'package:photojam_app/utilities/standard_button.dart';

class FacilitatorSignupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facilitator Signup'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 100),
              Text(
                'Become a Facilitator',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              StandardButton(
                onPressed: () {
                  // TODO Handle facilitator request logic here
                },
                label: Text('Let PhotoJam Know You Want to Facilitate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
