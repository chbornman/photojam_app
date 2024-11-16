import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/facilitator/screens/photo_selection_screen.dart';

class JamSelectionDialog extends StatefulWidget {
  const JamSelectionDialog({super.key});

  @override
  State<JamSelectionDialog> createState() => _JamSelectionDialogState();
}

class _JamSelectionDialogState extends State<JamSelectionDialog> {
  bool isLoading = true;
  bool isAdmin = false;
  List<Map<String, dynamic>> jams = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJams();
  }

  Future<void> _loadJams() async {
    try {
      final databaseApi = Provider.of<DatabaseAPI>(context, listen: false);
      final auth = Provider.of<AuthAPI>(context, listen: false);
      final userId = auth.userId;
      final roleService = auth.roleService;

      if (userId == null) {
        throw Exception("User not authenticated");
      }

      final userRole = await roleService.getCurrentUserRole();

      // Update the instance variable `isAdmin`
      setState(() {
        isAdmin = userRole == 'admin';
      });

      // Log the role for debugging
      LogService.instance.info('User role: $userRole, isAdmin: $isAdmin');

      final response = await databaseApi.getJams();

      // Filter jams
      final now = DateTime.now();
      final sortedJams = response.documents
          .map((doc) {
            final facilitatorId = doc.data['facilitator_id'];
            final jamDate = DateTime.parse(doc.data['date']);
            final isJamsFacilitator = facilitatorId == userId;

            // Log each jam's facilitator status
            LogService.instance.info(
              'Jam ID: ${doc.$id}, isJamsFacilitator: $isJamsFacilitator, jamDate: $jamDate',
            );

            return {
              'id': doc.$id,
              'title': doc.data['title'] ?? 'Untitled Jam',
              'date': jamDate,
              'hasSelectedPhotos':
                  (doc.data['selected_photos'] ?? []).isNotEmpty,
              'isJamsFacilitator': isJamsFacilitator,
            };
          })
          .where((jam) =>
              jam['date'].isAfter(now) &&
              (isAdmin ||
                  jam['isJamsFacilitator'])) // Filter by admin or facilitator
          .toList()
        ..sort((a, b) => b['date'].compareTo(a['date'])); // Sort by date

      setState(() {
        jams = sortedJams;
        isLoading = false;
      });
    } catch (e) {
      LogService.instance.error('Error loading jams: $e');
      setState(() {
        errorMessage = 'Failed to load jams';
        isLoading = false;
      });
    }
  }

  void _selectJam(BuildContext context, Map<String, dynamic> jam) {
    Navigator.pop(context); // Close the dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoSelectionScreen(jamId: jam['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select a Jam',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),

            // Content
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadJams,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (jams.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('No jams found')),
              )
            else
              ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jams.length,
                    itemBuilder: (context, index) {
                      final jam = jams[index];
                      final hasSelectedPhotos =
                          jam['hasSelectedPhotos'] as bool;
                      final isJamsFacilitator =
                          jam['isJamsFacilitator'] as bool;

                      return ListTile(
                        title: Text(
                          jam['title'],
                        ),
                        subtitle: Text(
                          jam['date'].toString().split(' ')[0],
                        ),
                        trailing: hasSelectedPhotos
                            ? Tooltip(
                                message:
                                    'Photos already selected, you can edit them',
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              )
                            : null,
                        onTap: (isJamsFacilitator || isAdmin)
                            ? () =>
                                _selectJam(context, jam) // Allow reselection
                            : null,
                      );
                    },
                  )),
          ],
        ),
      ),
    );
  }
}
