// log_service.dart
import 'package:logger/logger.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      errorMethodCount: 5, // Number of method calls if stack trace is provided
      lineLength: 80, // Width of the output
      colors: true, // Enable colors
      printEmojis: true, // Print an emoji for each log type
      printTime: true, // Add a timestamp to each log
    ),
  );

  // Private constructor
  LogService._internal();

  // Expose the singleton instance
  static LogService get instance => _instance;

  // Logging methods
  void info(String message) {
    _logger.i(message);
  }

  void error(String message) {
    _logger.e(message);
  }

  // Add more levels if needed
}
