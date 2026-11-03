import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/formatting/byte_size.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/info_chip.dart';
import 'package:gif_loop/features/library/domain/remix.dart';

class RemixInfoSection extends StatelessWidget {
  const new({required this.remix, super.key});

  final Remix remix;

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<ConnectivityCubit, bool>(
      (cubit) => cubit.state == ConnectivityStatus.online,
    );
    final seconds = (remix.duration.inMilliseconds / 1000).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.m,
      children: [
        Wrap(
          spacing: Spacing.s,
          runSpacing: Spacing.s,
          children: [
            InfoChip(
              label: Strings.dimensions,
              value: '${remix.width} × ${remix.height}',
            ),
            InfoChip(label: Strings.frames, value: '${remix.frameCount}'),
            InfoChip(label: Strings.duration, value: Strings.seconds(seconds)),
            InfoChip(
              label: Strings.fileSize,
              value: formatByteSize(remix.sizeBytes),
            ),
            InfoChip(
              label: Strings.created,
              value: MaterialLocalizations.of(context)
                  .formatMediumDate(remix.createdAt),
            ),
          ],
        ),
        Text(
          Strings.remixedFrom,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        TextButton.icon(
          onPressed: isOnline
              ? () => context.read<AppCoordinator>().showGifDetailsById(
                  remix.sourceGifId,
                )
              : null,
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(remix.sourceTitle),
        ),
      ],
    );
  }
}
