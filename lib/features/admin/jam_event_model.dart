import 'package:photojam_app/appwrite/database/models/jam_model.dart';

class JamEvent {
  final bool signedUp;
  final Jam jam; // Add the full Jam object

  const JamEvent({
    required this.signedUp,
    required this.jam,
  });
}
