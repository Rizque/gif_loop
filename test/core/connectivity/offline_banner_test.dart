import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/widgets/offline_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  late MockConnectivityCubit connectivity;
  late StreamController<ConnectivityStatus> statuses;

  setUp(() {
    connectivity = MockConnectivityCubit();
    statuses = StreamController<ConnectivityStatus>.broadcast();
    whenListen(
      connectivity,
      statuses.stream,
      initialState: ConnectivityStatus.online,
    );
  });

  tearDown(() => statuses.close());

  group('OfflineBanner', () {
    testWidgets('slides in when offline and out when back online', (
      tester,
    ) async {
      await tester.pumpApp(
        const OfflineBanner(child: Text('content')),
        connectivity: connectivity,
      );
      expect(find.text(Strings.offlineBanner), findsNothing);
      expect(find.text('content'), findsOneWidget);

      statuses.add(ConnectivityStatus.offline);
      await tester.pumpAndSettle();
      expect(find.text(Strings.offlineBanner), findsOneWidget);
      expect(find.text('content'), findsOneWidget);

      statuses.add(ConnectivityStatus.online);
      await tester.pumpAndSettle();
      expect(find.text(Strings.offlineBanner), findsNothing);
    });
  });

  group('ReconnectListener', () {
    testWidgets('fires only when going from offline to online', (tester) async {
      var reconnects = 0;
      await tester.pumpApp(
        ReconnectListener(
          onReconnected: () => reconnects++,
          child: const SizedBox(),
        ),
        connectivity: connectivity,
      );

      statuses.add(ConnectivityStatus.online);
      await tester.pump();
      expect(reconnects, 0);

      statuses.add(ConnectivityStatus.offline);
      await tester.pump();
      expect(reconnects, 0);

      statuses.add(ConnectivityStatus.online);
      await tester.pump();
      expect(reconnects, 1);
    });
  });
}
