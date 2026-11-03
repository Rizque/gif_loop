import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';

class ReconnectListener extends StatelessWidget {
  const new({required this.onReconnected, required this.child, super.key});

  final VoidCallback onReconnected;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<ConnectivityCubit, ConnectivityStatus>(
        listenWhen: (previous, current) =>
            previous == ConnectivityStatus.offline &&
            current == ConnectivityStatus.online,
        listener: (context, _) => onReconnected(),
        child: child,
      );
}
