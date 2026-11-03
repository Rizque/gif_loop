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

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    ConnectivityCubit? connectivity,
    AppCoordinator? coordinator,
    List<RepositoryProvider<Object>> repositories = const [],
  }) {
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
          child: MaterialApp(theme: AppTheme.light(), home: child),
        ),
      ),
    );
  }
}
