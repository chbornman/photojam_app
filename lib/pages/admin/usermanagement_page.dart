import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<User> users = [];

  @override
  void initState() {
    super.initState();
  }


  void editUser(User user) {
    // Code to edit user details, redirect to edit page or show dialog
  }

  void deleteUser(User user) {
    // Code to delete the user, update backend and state
    setState(() {
      users.remove(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Management"),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text('hi'),
            trailing: PopupMenuButton(
              onSelected: (value) {
                if (value == 'edit') editUser(user);
                if (value == 'delete') deleteUser(user);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Details'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete User'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}