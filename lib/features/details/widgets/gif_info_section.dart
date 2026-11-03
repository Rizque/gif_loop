import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/core/formatting/byte_size.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

class GifInfoSection extends StatelessWidget {
  const new({required this.gif, super.key});

  final Gif gif;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final full = gif.full;
    final importDate = gif.importDateTime;
    final sizeBytes = full.sizeBytes;
    final frameCount = full.frameCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.m,
      children: [
        Text(
          gif.title,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (gif.authorName case final author?) _Author(name: author, gif: gif),
        Wrap(
          spacing: Spacing.s,
          runSpacing: Spacing.s,
          children: [
            if (gif.rating.isNotEmpty)
              _InfoChip(label: Strings.rating, value: gif.rating.toUpperCase()),
            if (importDate != null)
              _InfoChip(
                label: Strings.imported,
                value: MaterialLocalizations.of(context)
                    .formatMediumDate(importDate),
              ),
            if (full.width > 0 && full.height > 0)
              _InfoChip(
                label: Strings.dimensions,
                value: '${full.width} × ${full.height}',
              ),
            if (sizeBytes != null)
              _InfoChip(
                label: Strings.fileSize,
                value: formatByteSize(sizeBytes),
              ),
            if (frameCount != null)
              _InfoChip(label: Strings.frames, value: '$frameCount'),
          ],
        ),
      ],
    );
  }
}

class _Author extends StatelessWidget {
  const new({required this.name, required this.gif});

  static const double _avatarRadius = 18;

  final String name;
  final Gif gif;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarUrl = gif.user?.avatarUrl;
    final username = gif.user?.username ?? gif.username;
    return Row(
      spacing: Spacing.m,
      children: [
        CircleAvatar(
          radius: _avatarRadius,
          foregroundImage: avatarUrl == null
              ? null
              : CachedNetworkImageProvider(avatarUrl),
          child: const Icon(Icons.person_rounded),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: textTheme.titleSmall),
              if (username.isNotEmpty && username != name)
                Text('@$username', style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Radii.tile),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.m,
          vertical: Spacing.s,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}
