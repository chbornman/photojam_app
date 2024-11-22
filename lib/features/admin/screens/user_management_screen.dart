// import 'package:appwrite/models.dart';
// import 'package:flutter/material.dart';
// import 'package:photojam_app/config/app_constants.dart';
// import 'package:photojam_app/core/services/log_service.dart';

// class UserManagementPage extends StatefulWidget {
//   const UserManagementPage({super.key});

//   @override
//   _UserManagementPageState createState() => _UserManagementPageState();
// }

// class _UserManagementPageState extends State<UserManagementPage> {
//   List<Membership> _teamMembers = [];
//   bool _isLoading = true;
//   String? _error;

//   late final TeamService _teamService;

//   @override
//   void initState() {
//     super.initState();
//     _teamService = context.read<TeamService>();
//     _loadTeamMembers();
//   }

//   Future<void> _loadTeamMembers() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });

//       // Load team members using the appwriteTeamId from constants
//       final members = await _teamService.getTeamMembers(AppConstants.appwriteTeamId);

//       setState(() {
//         _teamMembers = members;
//         _isLoading = false;
//       });
//     } catch (e) {
//       LogService.instance.error('Error loading team members: $e');
//       setState(() {
//         _error = 'Failed to load team members';
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _removeTeamMember(Membership member) async {
//     try {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Remove Team Member'),
//           content: Text('Are you sure you want to remove ${member.userEmail}?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: TextButton.styleFrom(foregroundColor: Colors.red),
//               child: const Text('Remove'),
//             ),
//           ],
//         ),
//       );

//       if (confirmed != true) return;

//       setState(() => _isLoading = true);

//       await _teamService.removeMember(
//         teamId: AppConstants.appwriteTeamId,
//         membershipId: member.$id,
//       );

//       await _loadTeamMembers();

//       if (!mounted) return;
//       _showSuccessMessage('Team member removed successfully');
//     } catch (e) {
//       LogService.instance.error('Error removing team member: $e');
//       if (!mounted) return;
//       _showErrorMessage('Failed to remove team member');
//     }
//   }

//   Future<void> _addNewTeamMember() async {
//     final emailController = TextEditingController();

//     try {
//       final confirmed = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Add Team Member'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   hintText: 'Enter member email',
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Add'),
//             ),
//           ],
//         ),
//       );

//       if (confirmed != true || emailController.text.isEmpty) return;

//       setState(() => _isLoading = true);

//       await _teamService.addMember(
//         teamId: AppConstants.appwriteTeamId,
//         email: emailController.text,
//         roles: ['member'], // Changed from 'admin' to 'member' for safety
//       );

//       await _loadTeamMembers();

//       if (!mounted) return;
//       _showSuccessMessage('Invitation sent successfully');
//     } catch (e) {
//       LogService.instance.error('Error adding team member: $e');
//       if (!mounted) return;
//       _showErrorMessage('Failed to send invitation');
//     } finally {
//       emailController.dispose();
//     }
//   }

//   void _showSuccessMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_error != null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Team Management')),
//         body: Center(child: Text(_error!)),
//       );
//     }

//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Team Management')),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Team Management'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadTeamMembers,
//             tooltip: 'Refresh',
//           ),
//           IconButton(
//             icon: const Icon(Icons.person_add),
//             onPressed: _addNewTeamMember,
//             tooltip: 'Add Team Member',
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadTeamMembers,
//         child: _teamMembers.isEmpty
//             ? const Center(child: Text('No team members found'))
//             : ListView.builder(
//                 itemCount: _teamMembers.length,
//                 itemBuilder: (context, index) {
//                   final member = _teamMembers[index];
//                   return ListTile(
//                     title: Text(member.userEmail),
//                     subtitle: Text('Roles: ${member.roles.join(", ")}'),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.remove_circle_outline),
//                       color: Colors.red,
//                       onPressed: () => _removeTeamMember(member),
//                       tooltip: 'Remove Member',
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }
