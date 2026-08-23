import 'dart:io';
import 'package:flutter/material.dart';

class MediaThumbnail extends StatelessWidget {
  final String? artworkPath;
  final String mediaType; // 'audio' or 'video'
  final double size;
  final double borderRadius;

  const MediaThumbnail({
    super.key,
    required this.artworkPath,
    required this.mediaType,
    this.size = 48,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fallbackIcon = mediaType == 'video' ? Icons.movie_rounded : Icons.music_note_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: colorScheme.primaryContainer,
        child: (artworkPath != null && artworkPath!.isNotEmpty)
            ? Image.file(
                File(artworkPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  fallbackIcon,
                  color: colorScheme.onPrimaryContainer,
                  size: size * 0.5,
                ),
              )
            : Icon(
                fallbackIcon,
                color: colorScheme.onPrimaryContainer,
                size: size * 0.5,
              ),
      ),
    );
  }
}