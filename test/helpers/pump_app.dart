import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityCubit extends MockCubit<ConnectivityStatus>
    implements ConnectivityCubit;

class MockAppCoordinator extends Mock implements AppCoordinator;

enum TestScreen {
  phonePortrait(Size(360, 640)),
  phoneLandscape(Size(640, 360)),
  tabletLandscape(Size(1280, 800));

  new(this.size);

  final Size size;
}

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    ConnectivityCubit? connectivity,
    AppCoordinator? coordinator,
    List<RepositoryProvider<Object>> repositories = const [],
    TestScreen screen = TestScreen.phonePortrait,
    double textScale = 1,
  }) {
    view
      ..physicalSize = screen.size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);

    final connectivityCubit = connectivity ?? MockConnectivityCubit();
    if (connectivity == null) {
      when(() => connectivityCubit.state).thenReturn(ConnectivityStatus.online);
    }
    return pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AppCoordinator>.value(
            value: coordinator ?? MockAppCoordinator(),
          ),
          ...repositories,
        ],
        child: BlocProvider<ConnectivityCubit>.value(
          value: connectivityCubit,
          child: MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child ?? const SizedBox.shrink(),
            ),
            home: child,
          ),
        ),
      ),
    );
  }
}
