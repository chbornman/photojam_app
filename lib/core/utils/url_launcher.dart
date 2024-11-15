import 'package:url_launcher/url_launcher.dart';
import 'package:photojam_app/core/services/log_service.dart';

class UrlLauncher {
  static Future<void> launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri.toString());
      } else {
        LogService.instance.error("Could not launch URL: $url");
        throw Exception("Could not open the link");
      }
    } catch (e) {
      LogService.instance.error("Error launching URL: $e");
      throw Exception("Error opening the link");
    }
  }
}