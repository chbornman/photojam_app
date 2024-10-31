import 'package:flutter/material.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/pages/journey_page.dart';
import 'package:provider/provider.dart';

class AllJourneysPage extends StatelessWidget {
  final String userId;

  AllJourneysPage({required this.userId});

  Future<List<Map<String, dynamic>>> _fetchUserJourneys(BuildContext context) async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final response = await databaseApi.getJourneysByUser(userId);
      
      return response.documents.map((doc) {
        return {
          'id': doc.$id,
          'title': doc.data['title'] ?? 'Untitled Journey',
        };
      }).toList();
    } catch (e) {
      print('Error fetching user journeys: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Journeys")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserJourneys(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No journeys available."));
          }
          final userJourneys = snapshot.data!;
          return ListView.builder(
            itemCount: userJourneys.length,
            itemBuilder: (context, index) {
              final journey = userJourneys[index];
              return ListTile(
                title: Text(journey['title']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JourneyPage(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}