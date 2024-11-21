// // lib/features/journeys/widgets/journey_list.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../appwrite/database/providers/journey_provider.dart';
// import 'journey_tile.dart';

// class JourneyList extends StatefulWidget {
//   final String userId;
//   final bool showAllJourneys;

//   const JourneyList({
//     super.key,
//     required this.userId,
//     required this.showAllJourneys,
//   });

//   @override
//   State<JourneyList> createState() => _JourneyListState();
// }

// class _JourneyListState extends State<JourneyList> {
//   @override
//   void initState() {
//     super.initState();
//     // Use Future.microtask to schedule the loading after the build is complete
//     Future.microtask(() {
//       final provider = Provider.of<JourneyProvider>(context, listen: false);
//       if (widget.showAllJourneys) {
//         provider.loadAllJourneys();
//       } else {
//         provider.loadUserJourneys(widget.userId);
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<JourneyProvider>(
//       builder: (context, provider, _) {
//         if (provider.isLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (provider.error != null) {
//           return Center(child: Text(provider.error!));
//         }

//         final journeys = provider.journeys;
//         if (journeys == null || journeys.isEmpty) {
//           return const Center(
//             child: Text('No journeys available'),
//           );
//         }

//         return ListView.builder(
//           itemCount: journeys.length,
//           itemBuilder: (context, index) {
//             return JourneyTile(journey: journeys[index]);
//           },
//         );
//       },
//     );
//   }
// }