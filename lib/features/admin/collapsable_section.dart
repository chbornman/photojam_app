
import 'package:flutter/material.dart';

class CollapsibleSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final Color? color;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.children,
    this.color,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            tileColor: widget.color?.withOpacity(0.3),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }
}