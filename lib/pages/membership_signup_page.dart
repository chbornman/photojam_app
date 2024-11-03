import 'package:flutter/material.dart';

class MembershipSignupPage extends StatefulWidget {
  @override
  _MembershipSignupPageState createState() => _MembershipSignupPageState();
}

class _MembershipSignupPageState extends State<MembershipSignupPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Membership Signup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Sign Up'),
      ),
    );
  }
}