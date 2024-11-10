import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:photojam_app/log_service.dart';
import 'package:url_launcher/url_launcher.dart';

class JamDetailsPage extends StatelessWidget {
  final Document jam;

  const JamDetailsPage({Key? key, required this.jam}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jamDate = DateTime.parse(jam.data['date']);
    final title = jam.data['title'];
    final description = jam.data['description'] ?? "No description available.";
    final zoomLink = jam.data['zoom_link'];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Date: ${jamDate.toLocal()}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Description",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: Icon(Icons.link),
              label: Text("Join Zoom Call"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _openZoomLink(zoomLink);
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.calendar_today),
              label: Text("Add to Calendar"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _addToCalendar(jamDate, title, description);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  // Function to open the Zoom link
  void _openZoomLink(String zoomLink) async {
    if (await canLaunch(zoomLink)) {
      await launch(zoomLink);
    } else {
      LogService.instance.info('Could not open the Zoom link.');
    }
  }

  // Function to add the event to the user's calendar (pseudo-code)
  void _addToCalendar(DateTime date, String title, String description) {
    // You can use a package like add_2_calendar to add the event to the calendar
    // Example:
    // Add2Calendar.addEvent2Cal(Event(
    //   title: title,
    //   description: description,
    //   startDate: date,
    //   endDate: date.add(Duration(hours: 1)), // Assume a 1-hour event
    // ));
  }
}