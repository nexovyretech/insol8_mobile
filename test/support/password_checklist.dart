import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/widgets/error_banner.dart';

/// The icon on a password checklist line: a check once met, a cross while
/// not, a plain circle before anything is typed.
IconData? checklistIcon(WidgetTester tester, String label) {
  final line = find.ancestor(of: find.text(label), matching: find.byType(Row));
  return tester
      .widget<Icon>(
        find.descendant(of: line.first, matching: find.byType(Icon)),
      )
      .icon;
}

/// A message shown in the app's error banner (fields keep a hidden copy of
/// their error, so a plain text finder sees it twice).
Finder inErrorBanner(String message) =>
    find.descendant(of: find.byType(ErrorBanner), matching: find.text(message));
