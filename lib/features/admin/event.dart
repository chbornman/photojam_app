// lib/features/admin/screens/jam_event.dart

class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String? facilitatorId;
  final int submissionCount;
  final String? zoomLink;
  final List<String> selectedPhotosIds;

  const Event({
    required this.id,
    required this.title,
    required this.dateTime,
    this.facilitatorId,
    required this.submissionCount,
    this.zoomLink,
    required this.selectedPhotosIds,
  });

  // Helper getters for status checks
  bool get hasFacilitator => facilitatorId != null && facilitatorId!.isNotEmpty;
  bool get hasPhotosSelected => selectedPhotosIds.isNotEmpty;
}
