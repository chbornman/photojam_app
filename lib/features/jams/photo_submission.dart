// lib/features/jams/models/photo_submission.dart
class PhotoSubmission {
  final String jamId;
  final List<String> photoUrls;
  final String userId;
  final String? comment;
  final DateTime submissionDate;

  PhotoSubmission({
    required this.jamId,
    required this.photoUrls,
    required this.userId,
    this.comment,
    DateTime? submissionDate,
  }) : submissionDate = submissionDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'jamId': jamId,
    'photoUrls': photoUrls,
    'userId': userId,
    'comment': comment,
    'submissionDate': submissionDate.toIso8601String(),
  };

  factory PhotoSubmission.fromJson(Map<String, dynamic> json) {
    return PhotoSubmission(
      jamId: json['jamId'],
      photoUrls: List<String>.from(json['photoUrls']),
      userId: json['userId'],
      comment: json['comment'],
      submissionDate: DateTime.parse(json['submissionDate']),
    );
  }
}
