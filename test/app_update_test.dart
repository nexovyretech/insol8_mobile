import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:insol8_mobile/constants/release_notes.dart';
import 'package:insol8_mobile/pages/settings/settings_content_page.dart';
import 'package:insol8_mobile/pages/settings/settings_page.dart';
import 'package:insol8_mobile/services/api_client.dart';
import 'package:insol8_mobile/services/app_update_service.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/widgets/app_update_listener.dart';
import 'package:insol8_mobile/widgets/whats_new_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/fake_repositories.dart';

class _FakePlatform implements AppUpdatePlatform {
  _FakePlatform({this.build = 3, this.canInstall = true, required this.dir});

  int build;
  bool canInstall;
  final Directory dir;
  final installed = <String>[];
  var settingsOpened = 0;

  @override
  Future<int> installedBuild() async => build;
  @override
  Future<String> updateDir() async => dir.path;
  @override
  Future<bool> canInstallPackages() async => canInstall;
  @override
  Future<void> openInstallPermissionSettings() async => settingsOpened++;
  @override
  Future<void> installApk(String path) async => installed.add(path);
}

Map<String, dynamic> _latest({int build = 5, int minSupported = 0}) => {
  'latest': {
    'build': build,
    'version': 'v0.6.0',
    'notes': 'Faster dashboard',
    'sizeBytes': 4,
    'downloadUrl': 'https://s3.test/builds/$build/insol8-$build.apk',
  },
  'minSupportedBuild': minSupported,
};

ApiClient _api(Map<String, dynamic> data, {List<String>? paths}) => ApiClient(
  client: MockClient((request) async {
    paths?.add(request.url.path);
    return http.Response(jsonEncode({'success': true, 'data': data}), 200);
  }),
  baseUrl: 'https://api.test',
  accessToken: () async => 'token',
);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('app_update_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('updateFrom', () {
    test('offers a newer build', () {
      final update = AppUpdateService.updateFrom(_latest(), installedBuild: 3);
      expect(update!.build, 5);
      expect(update.forced, isFalse);
      expect(update.version, 'v0.6.0');
      expect(update.notes, 'Faster dashboard');
    });

    test('shows a version number but not a branch name', () {
      AppUpdate withVersion(String version) => AppUpdate(
        build: 5,
        downloadUrl: 'x',
        forced: false,
        version: version,
      );
      expect(withVersion('v0.6.1').displayVersion, 'v0.6.1');
      expect(withVersion('0.6.1').displayVersion, 'v0.6.1');
      expect(withVersion('main').displayVersion, isNull);
    });

    test('ignores the same or an older build', () {
      expect(AppUpdateService.updateFrom(_latest(), installedBuild: 5), isNull);
      expect(AppUpdateService.updateFrom(_latest(), installedBuild: 9), isNull);
    });

    test('forces the update below minSupportedBuild', () {
      final data = _latest(minSupported: 4);
      expect(
        AppUpdateService.updateFrom(data, installedBuild: 3)!.forced,
        isTrue,
      );
      expect(
        AppUpdateService.updateFrom(data, installedBuild: 4)!.forced,
        isFalse,
      );
    });

    test('returns null when no build exists yet', () {
      expect(
        AppUpdateService.updateFrom({
          'latest': null,
          'minSupportedBuild': 0,
        }, installedBuild: 3),
        isNull,
      );
    });
  });

  test(
    'check() asks the backend route and compares the installed build',
    () async {
      final paths = <String>[];
      final service = AppUpdateService(
        api: _api(_latest(), paths: paths),
        platform: _FakePlatform(dir: dir, build: 3),
        isAndroid: true,
      );
      expect((await service.check())!.build, 5);
      expect(paths, ['/app/updates/latest']);
    },
  );

  test('check() does nothing off Android', () async {
    final paths = <String>[];
    final service = AppUpdateService(
      api: _api(_latest(), paths: paths),
      platform: _FakePlatform(dir: dir),
      isAndroid: false,
    );
    expect(await service.check(), isNull);
    expect(paths, isEmpty);
  });

  test(
    'download() fetches a fresh link, saves the APK and replaces old ones',
    () async {
      File('${dir.path}/insol8-2.apk').writeAsStringSync('old');
      final downloaded = <Uri>[];
      final progress = <double?>[];
      final service = AppUpdateService(
        api: _api(_latest()),
        platform: _FakePlatform(dir: dir),
        isAndroid: true,
        httpClient: MockClient.streaming((request, _) async {
          downloaded.add(request.url);
          return http.StreamedResponse(
            Stream.fromIterable([
              [1, 2],
              [3, 4],
            ]),
            200,
            contentLength: 4,
          );
        }),
      );
      final update = AppUpdateService.updateFrom(_latest(), installedBuild: 3)!;

      final path = await service.download(update, onProgress: progress.add);

      expect(File(path).parent.absolute.path, dir.absolute.path);
      expect(path, endsWith('insol8-5.apk'));
      expect(File(path).readAsBytesSync(), [1, 2, 3, 4]);
      expect(File('${dir.path}/insol8-2.apk').existsSync(), isFalse);
      expect(
        downloaded.single.toString(),
        'https://s3.test/builds/5/insol8-5.apk',
      );
      expect(progress, [0.5, 1.0]);
    },
  );

  test('download() reports a failed download', () async {
    final service = AppUpdateService(
      api: _api(_latest()),
      platform: _FakePlatform(dir: dir),
      isAndroid: true,
      httpClient: MockClient((_) async => http.Response('denied', 403)),
    );
    final update = AppUpdateService.updateFrom(_latest(), installedBuild: 3)!;
    expect(service.download(update), throwsA(isA<AppUpdateException>()));
  });

  group('AppUpdateDialog', () {
    Future<_FakePlatform> show(
      WidgetTester tester, {
      bool forced = false,
      bool canInstall = true,
    }) async {
      final platform = _FakePlatform(dir: dir, canInstall: canInstall);
      final service = AppUpdateService(
        api: _api(_latest()),
        platform: platform,
        isAndroid: true,
        httpClient: MockClient((_) async => http.Response('apk!', 200)),
      );
      final update = AppUpdate(
        build: 5,
        downloadUrl: 'https://s3.test/apk',
        forced: forced,
        version: 'v0.6.1',
        sizeBytes: 4,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateDialog(update: update, service: service),
          ),
        ),
      );
      return platform;
    }

    testWidgets('an optional update can be postponed', (tester) async {
      await show(tester);
      expect(find.text('Update available'), findsOneWidget);
      expect(find.textContaining('v0.6.1'), findsOneWidget);
      // Later on the left, Update on the right, on the same line.
      final later = tester.getCenter(find.text('Later'));
      final update = tester.getCenter(find.text('Update'));
      expect(later.dx, lessThan(update.dx));
      expect(later.dy, update.dy);
    });

    testWidgets('a forced update has no Later button', (tester) async {
      await show(tester, forced: true);
      expect(find.text('Update required'), findsOneWidget);
      expect(find.text('Later'), findsNothing);
    });

    testWidgets('asks for the install permission before downloading', (
      tester,
    ) async {
      final platform = await show(tester, canInstall: false);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(find.text('Allow app installs'), findsOneWidget);
      final settings = tester.getCenter(find.text('Open settings'));
      expect(settings.dx, lessThan(tester.getCenter(find.text('Continue')).dx));
      await tester.tap(find.text('Open settings'));
      expect(platform.settingsOpened, 1);
      expect(platform.installed, isEmpty);
    });

    testWidgets('downloads and opens the installer', (tester) async {
      final platform = await show(tester);
      await tester.runAsync(() async {
        await tester.tap(find.text('Update'));
        for (var i = 0; i < 50 && platform.installed.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(platform.installed.single, endsWith('insol8-5.apk'));
      expect(find.text('Install'), findsOneWidget);
    });
  });

  testWidgets('Settings no longer has its own Check for updates row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          authRepository: UnconfiguredAuthRepository(),
          branchRepository: const UnusedBranchRepository(),
          deviceRepository: const UnusedDeviceRepository(),
          subscriptionRepository: const FakeSubscriptionRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('About Us'), findsOneWidget);
    expect(find.text('Check for updates'), findsNothing);
  });

  group('About Us', () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: 'inSOL8',
        packageName: 'com.insol8.mobile',
        version: '0.6.3',
        buildNumber: '7',
        buildSignature: '',
      ),
    );

    Future<void> openAboutUs(
      WidgetTester tester, {
      bool isAndroid = true,
      int latestBuild = 3,
      bool offline = false,
    }) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = AppUpdateService(
        api: offline
            ? ApiClient(
                client: MockClient((_) async => throw http.ClientException('')),
                baseUrl: 'https://api.test',
                accessToken: () async => 'token',
              )
            : _api(_latest(build: latestBuild)),
        platform: _FakePlatform(dir: dir, build: 3),
        isAndroid: isAndroid,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsContentPage(
            type: SettingsContentType.aboutUs,
            authRepository: UnconfiguredAuthRepository(),
            subscriptionRepository: const FakeSubscriptionRepository(),
            appUpdateService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the installed version and that it is current', (
      tester,
    ) async {
      await openAboutUs(tester);
      expect(find.text('v0.6.3 (Build 7)'), findsOneWidget);
      expect(find.text('Up to date'), findsOneWidget);
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(
        find.text('You’re on the latest version (v0.6.3).'),
        findsOneWidget,
      );
    });

    testWidgets('says an update is available and opens it on tap', (
      tester,
    ) async {
      await openAboutUs(tester, latestBuild: 5);
      expect(find.text('v0.6.0 available'), findsOneWidget);
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text('Update available'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('offers a retry when the check fails', (tester) async {
      await openAboutUs(tester, offline: true);
      expect(find.text('Tap to try again'), findsOneWidget);
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t check for updates'), findsOneWidget);
    });

    testWidgets('hides Check for updates where updates do not work', (
      tester,
    ) async {
      await openAboutUs(tester, isAndroid: false);
      expect(find.text('Check for updates'), findsNothing);
      expect(find.text('v0.6.3 (Build 7)'), findsOneWidget);
    });

    testWidgets('What’s new lists versions and marks the installed one', (
      tester,
    ) async {
      await openAboutUs(tester);
      await tester.tap(find.text('What’s new'));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsOneWidget);
      expect(find.text('Installed'), findsOneWidget);
      final installedCard = find.ancestor(
        of: find.text('Installed'),
        matching: find.byType(Row),
      );
      expect(
        find.descendant(of: installedCard, matching: find.text('v0.6.3')),
        findsOneWidget,
      );
    });
  });

  test('release notes are newest first, one entry per version', () {
    final versions = releaseNotes.map((note) => note.version).toList();
    expect(versions.toSet().length, versions.length);
    List<int> parts(String v) => v.split('.').map(int.parse).toList();
    for (var i = 1; i < versions.length; i++) {
      final newer = parts(versions[i - 1]);
      final older = parts(versions[i]);
      final compare = [for (var j = 0; j < 3; j++) newer[j].compareTo(older[j])]
          .firstWhere((c) => c != 0, orElse: () => 0);
      expect(compare, 1, reason: '${versions[i - 1]} before ${versions[i]}');
    }
    expect(releaseNotes.every((note) => note.changes.isNotEmpty), isTrue);
  });

  group('AppUpdateListener (whole app, before sign-in)', () {
    Future<List<http.BaseRequest>> pumpApp(
      WidgetTester tester, {
      required int minSupported,
      GlobalKey<NavigatorState>? navigatorKey,
    }) async {
      final requests = <http.BaseRequest>[];
      final service = AppUpdateService(
        api: ApiClient(
          client: MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode({
                'success': true,
                'data': _latest(minSupported: minSupported),
              }),
              200,
            );
          }),
          baseUrl: 'https://api.test',
          accessToken: () async => fail('the update check must not sign in'),
        ),
        platform: _FakePlatform(dir: dir, build: 3),
        isAndroid: true,
      );
      final key = navigatorKey ?? GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          builder: (context, child) => AppUpdateListener(
            service: service,
            navigatorKey: key,
            child: child!,
          ),
          home: const Scaffold(body: Text('Get started')),
        ),
      );
      await tester.pumpAndSettle();
      return requests;
    }

    testWidgets(
      'shows a required update on the sign-in screens without a token',
      (tester) async {
        final requests = await pumpApp(tester, minSupported: 5);
        expect(find.text('Get started'), findsOneWidget);
        expect(find.text('Update required'), findsOneWidget);
        expect(find.text('Later'), findsNothing);
        expect(requests.single.url.path, '/app/updates/latest');
        expect(requests.single.headers.containsKey('authorization'), isFalse);
      },
    );

    testWidgets(
      'shows a required update again when a screen change closes it',
      (tester) async {
        final key = GlobalKey<NavigatorState>();
        await pumpApp(tester, minSupported: 5, navigatorKey: key);
        // A page replacing the top route (e.g. a redirect to login) removes the dialog.
        key.currentState!.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const Text('Login')),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Update required'), findsOneWidget);
      },
    );

    testWidgets('an optional update stays closed after Later', (tester) async {
      await pumpApp(tester, minSupported: 0);
      expect(find.text('Update available'), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Update available'), findsNothing);
    });
  });
}
