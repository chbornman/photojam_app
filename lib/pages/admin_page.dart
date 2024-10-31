
import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // User Management Section
            Card(
              child: ListTile(
                leading: Icon(Icons.people),
                title: Text('User Management'),
                subtitle: Text('View and manage users'),
                onTap: () {
                  // Navigate to User Management Page (placeholder)
                },
              ),
            ),
            SizedBox(height: 10),
            // Content Management Section
            Card(
              child: ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Content Management'),
                subtitle: Text('Manage photos and submissions'),
                onTap: () {
                  // Navigate to Content Management Page (placeholder)
                },
              ),
            ),
            SizedBox(height: 10),
            // System Logs Section
            Card(
              child: ListTile(
                leading: Icon(Icons.report),
                title: Text('System Logs'),
                subtitle: Text('View system logs and errors'),
                onTap: () {
                  // Navigate to System Logs Page (placeholder)
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
