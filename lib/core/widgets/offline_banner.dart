import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class OfflineBanner extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isOffline = context.select<ConnectivityCubit, bool>(
      (cubit) => cubit.state == ConnectivityStatus.offline,
    );
    return Column(
      children: [
        ClipRect(
          child: AnimatedSize(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            child: isOffline
                ? const _BannerContent()
                : const SizedBox(width: double.infinity),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: isOffline,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _BannerContent extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.inverseSurface,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.l,
              vertical: Spacing.s,
            ),
            child: Row(
              spacing: Spacing.m,
              children: [
                Icon(Icons.wifi_off_rounded, color: colors.onInverseSurface),
                Expanded(
                  child: Text(
                    Strings.offlineBanner,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.onInverseSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
