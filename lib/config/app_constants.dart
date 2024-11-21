import 'package:flutter/material.dart';

class AppConstants {
  // Appwrite Project
  static const String appwriteEndpointId = "https://cloud.appwrite.io/v1";
  static const String appwriteProjectId = "67252f310033542bb23f";
  // // Localhost
  // static const String appwriteEndpointId = "http://192.168.0.51/v1";
  // static const String appwriteProjectId = "6720f5ca0032a3b05710";

  // For development with Appwrite Cloud
  static const String appDeepLinkUrl = 'https://cloud.appwrite.io/v1/verify-membership';

  // Later for production, you would use your own domain:
  // static const String appDeepLinkUrl = 'https://yourapp.com/verify-membership';

  // Team
  static const String appwriteTeamId = 'photojam_team_id_name';

  // Database
  static const String appwriteDatabaseId = "photojam-database";
  static const String collectionJams = "photojam-collection-jam";
  static const String collectionLessons = "photojam-collection-lesson";
  static const String collectionJourneys = "photojam-collection-journey";
  static const String collectionSubmissions = "photojam-collection-submission";

  // Storage
  static const String bucketPhotosId = "photojam-bucket-photos";
  static const String bucketLessonsId = "photojam-bucket-lessons";

  // Stripe
  static const String stripePaymentIntentUrl = 'todo'; // TODO Ask Molly for STRIPE_SECRET_KEY and STRIPE_WEBHOOK SECRET 'https://your-backend.com/create-stripe-payment-intent';

  // Signal
  static const String signalGroupUrl = 'https://signal.group/#CjQKIOsRUWoZYHxVI7YrNr4wmJCnfcObCS8jkds92nbEgt6TEhCOzgJEXXcSmaMVCceO5-0m';

  static const double defaultCornerRadius = 16;
  static const double defaultButtonHeight = 50;

  // Zoom link
  static const String zoomLinkUrl = "https://us02web.zoom.us/j/86356738535";

  // Theme colors
  static const Color photojamYellow = Color(0xFFF9D036);
  static const Color photojamDarkYellow = Color.fromARGB(255, 218, 181, 46);
  static const Color photojamPink = Color(0xFFE25B63);
  static const Color photojamDarkPink = Color.fromARGB(255, 154, 60, 67);
  static const Color photojamBlue = Color(0xFF28354F);
  static const Color photojamGreen = Color(0xFF07D114);
  static const Color photojamDarkGreen = Color(0xFF06510B);
  static const Color photojamOrange = Color(0xFFEF8634);
  static const Color photojamNewPink = Color(0xFFE45B64);
  static const Color photojamPaleBlue = Color(0xFF6ACAE4);
  static const Color photojamPurple = Color(0xFFB248E6);
}
