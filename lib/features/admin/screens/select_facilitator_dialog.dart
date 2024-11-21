// import 'package:flutter/material.dart';
// import 'package:photojam_app/core/services/log_service.dart';
// import 'package:photojam_app/core/services/team_service.dart';
// import 'package:provider/provider.dart';

// class SelectFacilitatorDialog extends StatelessWidget {
//   final String jamId;

//   const SelectFacilitatorDialog({
//     Key? key,
//     required this.jamId,
//   }) : super(key: key);

//   Future<List<Map<String, dynamic>>> _fetchFacilitators(BuildContext context) async {
//     try {
//       final teamService = Provider.of<TeamService>(context, listen: false);
//       const String teamId = 'facilitators_team_id'; // Replace with your actual team ID
//       final facilitators = await teamService.getFacilitators(teamId);

//       return facilitators.map((facilitator) {
//         return {
//           'id': facilitator.userId,
//           'name': facilitator.userName,
//         };
//       }).toList();
//     } catch (e) {
//       LogService.instance.error('Error fetching facilitators: $e');
//       return [];
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: FutureBuilder<List<Map<String, dynamic>>>(
//           future: _fetchFacilitators(context),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               return const Center(
//                 child: Text('No facilitators available'),
//               );
//             }
//             final facilitators = snapshot.data!;
//             return ListView.builder(
//               itemCount: facilitators.length,
//               itemBuilder: (context, index) {
//                 final facilitator = facilitators[index];
//                 return ListTile(
//                   title: Text(facilitator['name']),
//                   onTap: () => Navigator.pop(context, facilitator['id']),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }