import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/log_service.dart';
import 'package:provider/provider.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Membership> _teamMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if user is admin
      final authApi = context.read<AuthAPI>();
      final isAdmin = await authApi.isUserAdmin();
      
      if (!isAdmin) {
        setState(() {
          _error = 'Unauthorized access';
          _isLoading = false;
        });
        return;
      }

      // Load team members using the ADMIN_TEAM_ID
      final members = await authApi.getTeamMembers(AuthAPI.ADMIN_TEAM_ID);
      
      setState(() {
        _teamMembers = members;
        _isLoading = false;
      });

    } catch (e) {
      LogService.instance.error('Error loading team members: $e');
      setState(() {
        _error = 'Failed to load team members';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeTeamMember(Membership member) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Team Member'),
          content: Text('Are you sure you want to remove this team member?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isLoading = true);

      await context.read<AuthAPI>().removeUserFromTeam(
        membershipId: member.$id,
        teamId: AuthAPI.ADMIN_TEAM_ID,
      );
      
      await _loadTeamMembers(); // Reload the list after removal

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team member removed successfully')),
      );

    } catch (e) {
      LogService.instance.error('Error removing team member: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove team member')),
      );
    }
  }

  Future<void> _addNewTeamMember() async {
    final TextEditingController emailController = TextEditingController();
    
    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Team Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter member email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (confirmed != true || emailController.text.isEmpty) return;

      setState(() => _isLoading = true);

      await context.read<AuthAPI>().addUserToTeam(
        email: emailController.text,
        teamId: AuthAPI.ADMIN_TEAM_ID,
        roles: ['admin'], // You might want to make this configurable
      );
      
      await _loadTeamMembers(); // Reload the list after adding

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team member added successfully')),
      );

    } catch (e) {
      LogService.instance.error('Error adding team member: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add team member')),
      );
    } finally {
      emailController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Management')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Management')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeamMembers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addNewTeamMember,
            tooltip: 'Add Team Member',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTeamMembers,
        child: _teamMembers.isEmpty
            ? const Center(child: Text('No team members found'))
            : ListView.builder(
                itemCount: _teamMembers.length,
                itemBuilder: (context, index) {
                  final member = _teamMembers[index];
                  return ListTile(
                    title: Text(member.userName),
                    subtitle: Text(member.userEmail),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      onPressed: () => _removeTeamMember(member),
                      tooltip: 'Remove Member',
                    ),
                  );
                },
              ),
      ),
    );
  }
}