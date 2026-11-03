import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity;

void main() {
  late _MockConnectivity connectivity;
  late StreamController<List<ConnectivityResult>> changes;

  setUp(() {
    connectivity = _MockConnectivity();
    changes = StreamController<List<ConnectivityResult>>.broadcast();
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  void stubInitial(List<ConnectivityResult> results) =>
      when(connectivity.checkConnectivity).thenAnswer((_) async => results);

  group('ConnectivityCubit', () {
    test('assumes online before the first check', () {
      expect(ConnectivityCubit(connectivity).state, ConnectivityStatus.online);
    });

    blocTest<ConnectivityCubit, ConnectivityStatus>(
      'reports offline when the device has no network',
      setUp: () => stubInitial([ConnectivityResult.none]),
      build: () => ConnectivityCubit(connectivity),
      act: (cubit) => cubit.start(),
      expect: () => [ConnectivityStatus.offline],
    );

    blocTest<ConnectivityCubit, ConnectivityStatus>(
      'follows connectivity changes',
      setUp: () => stubInitial([ConnectivityResult.wifi]),
      build: () => ConnectivityCubit(connectivity),
      act: (cubit) async {
        await cubit.start();
        changes
          ..add([ConnectivityResult.none])
          ..add([ConnectivityResult.mobile, ConnectivityResult.vpn]);
      },
      expect: () => [
        ConnectivityStatus.online,
        ConnectivityStatus.offline,
        ConnectivityStatus.online,
      ],
    );
  });
}
