import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photojam_app/appwrite/auth/providers/user_role_provider.dart';
import 'package:photojam_app/appwrite/database/models/jam_model.dart';
import 'package:photojam_app/appwrite/database/providers/jam_provider.dart';
import 'package:photojam_app/core/services/log_service.dart';

// Provider for filtered and sorted jams for selection
final jamSelectionProvider = Provider<AsyncValue<List<Jam>>>((ref) {
  final jamsAsync = ref.watch(jamsProvider);
  final roleAsync = ref.watch(userRoleProvider);
  final userLabelsAsync = ref.watch(userLabelsProvider);

  return jamsAsync.whenData((jams) {
    return roleAsync.whenData((role) {
      return userLabelsAsync.whenData((labels) {
        LogService.instance.info('Filtering jams for role: $role');
        
        final now = DateTime.now();
        final isAdmin = labels.contains('admin');
        
        // Filter and sort jams
        final filteredJams = jams.where((jam) {
          final isUpcoming = jam.eventDatetime.isAfter(now);
          final isJamFacilitator = jam.facilitatorId == labels.first; // Assuming first label is userId
          
          LogService.instance.info(
            'Jam ${jam.id}: upcoming=$isUpcoming, facilitator=$isJamFacilitator, admin=$isAdmin'
          );
          
          return isUpcoming && (isAdmin || isJamFacilitator);
        }).toList()
          ..sort((a, b) => b.eventDatetime.compareTo(a.eventDatetime));

        LogService.instance.info('Found ${filteredJams.length} filtered jams');
        return filteredJams;
      }).value ?? [];
    }).value ?? [];
  });
});