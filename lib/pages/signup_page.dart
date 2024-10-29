import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up for the Jam'),
      ),
      body: Center(
        child: Text(
          'Sign up form goes here!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}