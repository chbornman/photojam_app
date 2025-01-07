import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/auth_state_provider.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/features/jams/jam_calendar_page.dart';

class JamPage extends ConsumerStatefulWidget {
  const JamPage({super.key});

  @override
  _JamPageState createState() => _JamPageState();
}

class _JamPageState extends ConsumerState<JamPage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _refreshJams() async {
    await AsyncValue.guard(() async {
      ref.invalidate(jamsProvider);
      final authState = ref.read(authStateProvider);
      authState.maybeWhen(
        authenticated: (user) =>
            ref.invalidate(userUpcomingJamsProvider(user.id)),
        orElse: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: JamCalendarPage()),

            //   _buildSignupCard(),
            //   const SizedBox(height: 20),
            //   _buildHeader(),
            //   const SizedBox(height: 10),
            //   Expanded(
            //     child: _buildJamsList(userJams),
            //   ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

//   Widget _buildSignupCard() {
//     return StandardCard(
//       icon: Icons.add_circle_outline,
//       title: "Sign Up for a Jam",
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const JamSignupPage()),
//         );
//       },
//     );
//   }

//   Widget _buildHeader() {
//     return Text(
//       "Your Upcoming Jams",
//       style: Theme.of(context).textTheme.headlineLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//           ),
//     );
//   }

//   Widget _buildJamsList(AsyncValue<List<Jam>>? userJams) {
//     return userJams?.when(
//           data: (jams) {
//             if (jams.isEmpty) {
//               return Center(
//                 child: Text(
//                   "No upcoming jams available",
//                   style: TextStyle(
//                     fontSize: 18.0,
//                     color: Theme.of(context).colorScheme.onSurface,
//                   ),
//                 ),
//               );
//             }

//             return RefreshIndicator(
//               onRefresh: _refreshJams,
//               child: ListView.builder(
//                 itemCount: jams.length,
//                 itemBuilder: (context, index) => _buildJamCard(jams[index]),
//               ),
//             );
//           },
//           loading: () => const Center(child: CircularProgressIndicator()),
//           error: (error, stack) => Center(child: Text('Error: $error')),
//         ) ??
//         const Center(child: Text('Not authenticated'));
//   }

//   Widget _buildJamCard(Jam jam) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//         leading: Icon(
//           Icons.event,
//           color: Theme.of(context).colorScheme.primary,
//           size: 30,
//         ),
//         title: Text(
//           jam.title,
//           style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 4),
//             Text(
//               DateFormat('MMM dd, yyyy - hh:mm a').format(jam.eventDatetime),
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Colors.grey[600],
//                   ),
//             ),
//           ],
//         ),
//         trailing: Icon(
//           Icons.arrow_forward_ios,
//           size: 16,
//           color: Theme.of(context).colorScheme.primary,
//         ),
//         onTap: () => _navigateToJamDetails(jam),
//       ),
//     );
//   }

//   void _navigateToJamDetails(Jam jam) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => JamDetailsPage(jam: jam),
//       ),
//     );
//   }
}
