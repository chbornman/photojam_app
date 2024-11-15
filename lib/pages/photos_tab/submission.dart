import 'dart:typed_data';

class Submission {
  final String date;
  final String jamTitle;
  final List<Uint8List?> photos;

  const Submission({
    required this.date,
    required this.jamTitle,
    required this.photos,
  });
}