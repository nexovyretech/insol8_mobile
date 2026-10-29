import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/device_data.dart';
import 'package:insol8_mobile/models/device_detail_data.dart';
import 'package:insol8_mobile/pages/devices/bulk_cycle_control_sheet.dart';
import 'package:insol8_mobile/services/device_repository.dart';

// Records started jobs; the sheet calls nothing else when starting.
class _RecordingDevices implements DeviceRepository {
  final started = <(String, DeviceCycleSettings)>[];

  @override
  Future<void> startDryingCycle({
    required String deviceId,
    required DeviceCycleSettings settings,
  }) async => started.add((deviceId, settings));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DeviceData _dryer(String id, String name, {double maxLoadKg = 8}) => DeviceData(
  id: id,
  name: name,
  status: DeviceStatus.idle,
  temperatureCelsius: 30,
  batteryPercent: null,
  cycleDuration: '0min',
  lastUpdated: '',
  maxLoadKg: maxLoadKg,
);

Future<void> _openSheet(
  WidgetTester tester,
  List<DeviceData> devices,
  DeviceRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showBulkCycleControlSheet(
            context: context,
            devices: devices,
            repository: repository,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _enterLoad(WidgetTester tester, String kg) async {
  await tester.enterText(find.byKey(const ValueKey('load-weight')), kg);
  await tester.pumpAndSettle();
}

bool _startEnabled(WidgetTester tester) {
  final button = tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.textContaining('Start ('),
      matching: find.bySubtype<ButtonStyleButton>(),
    ),
  );
  return button.onPressed != null;
}

void main() {
  testWidgets(
    'the load field comes before the dryer list and shows the limit',
    (tester) async {
      await _openSheet(tester, [
        _dryer('INSOL8_01', 'Real Dryer'),
      ], _RecordingDevices());
      expect(
        tester.getTopLeft(find.text('Load Weight')).dy,
        lessThan(tester.getTopLeft(find.text('Select devices')).dy),
      );
      expect(find.text('Up to 8 kg per dryer.'), findsOneWidget);
    },
  );

  testWidgets('warns about and blocks a load over a selected dryer\'s limit', (
    tester,
  ) async {
    final repository = _RecordingDevices();
    await _openSheet(tester, [
      _dryer('INSOL8_01', 'Real Dryer'),
      _dryer('SMALL_01', 'Small Dryer', maxLoadKg: 5),
    ], repository);
    // Before any dryer is selected, the smallest limit is shown.
    expect(find.text('Up to 5 kg per dryer.'), findsOneWidget);

    await tester.tap(find.text('Real Dryer'));
    await tester.pumpAndSettle();
    expect(find.text('Up to 8 kg per dryer.'), findsOneWidget);
    // A job needs a load weight.
    expect(_startEnabled(tester), isFalse);

    await _enterLoad(tester, '9');
    expect(
      find.text('Over the 8 kg limit of Real Dryer. Reduce the load to start.'),
      findsOneWidget,
    );
    expect(_startEnabled(tester), isFalse);

    await _enterLoad(tester, '6.5');
    expect(find.text('Up to 8 kg per dryer.'), findsOneWidget);
    expect(_startEnabled(tester), isTrue);

    await tester.tap(find.textContaining('Start ('));
    await tester.pumpAndSettle();
    expect(repository.started, hasLength(1));
    final (deviceId, settings) = repository.started.single;
    expect(deviceId, 'INSOL8_01');
    expect(settings.loadKg, 6.5);
    expect(settings.fabricType, 'Cotton');
    expect(settings.runtimeMinutes, 30);
  });

  testWidgets('fits without overflow while the keyboard is open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await _openSheet(tester, [
      _dryer('INSOL8_01', 'Real Dryer'),
      _dryer('INSOL8_02', 'Second Dryer'),
    ], _RecordingDevices());

    // A typical phone keyboard covers about half the screen.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Start ('), findsOneWidget);
  });

  testWidgets('only accepts kilograms as numbers', (tester) async {
    await _openSheet(tester, [
      _dryer('INSOL8_01', 'Real Dryer'),
    ], _RecordingDevices());
    await _enterLoad(tester, 'abc');
    expect(find.text('abc'), findsNothing);
    await _enterLoad(tester, '7.256');
    // At most two decimals are kept.
    expect(find.text('7.256'), findsNothing);
  });
}
