import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityStatus { online, offline }

// connectivity_plus only reports network interfaces, not real internet
// access, so request failures are still mapped to NoConnectionFailure.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  new(this._connectivity) : super(ConnectivityStatus.online);

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> start() async {
    _subscription ??= _connectivity.onConnectivityChanged.listen(_update);
    _update(await _connectivity.checkConnectivity());
  }

  void _update(List<ConnectivityResult> results) {
    if (isClosed) return;
    final isOffline = results.every(
      (result) => result == ConnectivityResult.none,
    );
    emit(isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
