// lib/features/jams/screens/jam_page.dart
import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photojam_app/appwrite/database_api.dart';
import 'package:photojam_app/appwrite/auth_api.dart';
import 'package:photojam_app/core/services/log_service.dart';
import 'package:photojam_app/features/jams/screens/jamdetails_page.dart';
import 'package:photojam_app/features/jams/screens/jamsignup_page.dart';
import 'package:photojam_app/core/widgets/standard_card.dart';
import 'package:provider/provider.dart';

class JamPage extends StatefulWidget {
  const JamPage({super.key});

  @override
  _JamPageState createState() => _JamPageState();
}

class _JamPageState extends State<JamPage> {
  List<Document> _upcomingJams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserJams();
  }

  Future<void> _fetchUserJams() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthAPI>();
      if (!auth.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final userId = auth.userId;
      if (userId == null) {
        throw Exception('User ID not available');
      }

      final databaseApi = context.read<DatabaseAPI>();
      final response = await databaseApi.getUpcomingJamsByUser(userId);

      if (!mounted) return;

      final validJams = _processJams(response.documents);
      
      setState(() {
        _upcomingJams = validJams;
        _isLoading = false;
      });
    } catch (e) {
      LogService.instance.error('Error fetching upcoming jams: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load jams';
        _isLoading = false;
      });
    }
  }

  List<Document> _processJams(List<Document> jams) {
    final validJams = jams
        .where((doc) => doc.data['date'] != null)
        .toList();

    validJams.sort((a, b) {
      final dateA = DateTime.tryParse(a.data['date']) ?? DateTime.now();
      final dateB = DateTime.tryParse(b.data['date']) ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    return validJams;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSignupCard(),
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildJamsList(),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildSignupCard() {
    return StandardCard(
      icon: Icons.add_circle_outline,
      title: "Sign Up for a Jam",
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JamSignupPage()),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Text(
      "Upcoming Jams",
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildJamsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_upcomingJams.isEmpty) {
      return Center(
        child: Text(
          "No upcoming jams available",
          style: TextStyle(
            fontSize: 18.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUserJams,
      child: ListView.builder(
        itemCount: _upcomingJams.length,
        itemBuilder: (context, index) => _buildJamCard(_upcomingJams[index]),
      ),
    );
  }

  Widget _buildJamCard(Document jam) {
    final jamData = jam.data;
    final jamTitle = jamData['title'] ?? 'Untitled Jam';
    final jamDate = _parseJamDate(jamData['date']);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(
          Icons.event,
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: Text(
          jamTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              jamDate != null
                ? 'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(jamDate)}'
                : 'Date unavailable',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () => _navigateToJamDetails(jam),
      ),
    );
  }

  DateTime? _parseJamDate(String? dateStr) {
    if (dateStr?.isEmpty ?? true) return null;
    try {
      return DateTime.parse(dateStr!);
    } catch (_) {
      return null;
    }
  }

  void _navigateToJamDetails(Document jam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JamDetailsPage(jam: jam),
      ),
    );
  }
}