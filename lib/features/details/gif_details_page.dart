import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/widgets/adaptive_loader.dart';
import 'package:gif_loop/core/widgets/error_view.dart';
import 'package:gif_loop/features/details/cubit/gif_details_cubit.dart';
import 'package:gif_loop/features/details/cubit/gif_details_state.dart';
import 'package:gif_loop/features/details/widgets/dominant_color_background.dart';
import 'package:gif_loop/features/details/widgets/gif_details_view.dart';

class GifDetailsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GifDetailsCubit>();
    final state = cubit.state;
    return ReconnectListener(
      onReconnected: cubit.reconnected,
      child: DominantColorBackground(
        color: state.dominantColor,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            leading: BackButton(onPressed: context.read<AppCoordinator>().back),
          ),
          body: SafeArea(
            top: false,
            child: switch (state) {
              GifDetailsState(gif: final gif?) => GifDetailsView(gif: gif),
              GifDetailsState(status: GifDetailsStatus.failure) => ErrorView(
                failure: state.failure ?? const UnknownFailure(),
                onRetry: cubit.load,
              ),
              GifDetailsState() => const AdaptiveLoader(),
            },
          ),
        ),
      ),
    );
  }
}
