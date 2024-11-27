import 'dart:io' as io;
import 'package:flutter/material.dart';

class PhotoSelector extends StatelessWidget {
  final io.File? photo;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const PhotoSelector({
    super.key,
    required this.photo,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: GestureDetector(
        onTap: onSelect,
        child: Container(
          width: 100.0,
          height: 100.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Theme.of(context).dividerColor),
            image: photo != null
                ? DecorationImage(
                    image: FileImage(photo!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            children: [
              if (photo == null)
                Center(
                  child: Icon(
                    Icons.add_photo_alternate,
                    size: 40.0,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              if (photo != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}