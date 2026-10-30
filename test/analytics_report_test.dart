import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insol8_mobile/models/analytics_data.dart';
import 'package:insol8_mobile/services/analytics_report.dart';

const _data = AnalyticsData(
  loadsDried: 12,
  averageDryingHours: 1.25,
  moneySavedPhp: 1234.5,
  energySavedKwh: 98.4,
  loadsByHour: [0, 1, 2, 4, 1, 1, 2, 1, 0, 0],
  solarHeatPercent: 76,
  backupHeatPercent: 24,
  dryingTimeByPeriod: [
    AnalyticsDuration(label: 'Midday', minutes: 60),
    AnalyticsDuration(label: 'Other', minutes: 80),
  ],
  dryerComparisons: [
    AnalyticsDryerComparison(name: 'Dryer A', loads: 9),
    AnalyticsDryerComparison(name: 'Dryer B', loads: 3),
    AnalyticsDryerComparison(name: 'Dryer C', loads: 0),
  ],
);

void main() {
  test('builds a PDF with the logo', () async {
    final bytes = await buildAnalyticsReport(
      data: _data,
      period: AnalyticsPeriod.thisWeek,
      generatedAt: DateTime(2026, 10, 29, 14, 5),
      logoSvg: File('assets/logo/insol8_mark.svg').readAsStringSync(),
    );
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });

  test('builds a report with no data yet', () async {
    final bytes = await buildAnalyticsReport(
      data: const AnalyticsData(
        loadsDried: 0,
        averageDryingHours: 0,
        moneySavedPhp: 0,
        energySavedKwh: 0,
        loadsByHour: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        solarHeatPercent: null,
        backupHeatPercent: null,
        dryingTimeByPeriod: [],
        dryerComparisons: [],
      ),
      period: AnalyticsPeriod.today,
      generatedAt: DateTime(2026, 10, 29),
    );
    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('interprets the data for the period', () {
    final insights = AnalyticsInsights(_data, AnalyticsPeriod.thisWeek);
    expect(
      insights.summary,
      '12 loads were dried this week, taking 1 hr 15 min on average. '
      'Dryers saved 98.4 kWh of electricity, worth about PHP 1,234.50.',
    );
    expect(
      insights.peakHour,
      startsWith('The busiest hour was 11 AM, with 4 loads'),
    );
    expect(insights.energySource, startsWith('76% of the drying heat'));
    expect(insights.dryingTime, contains('25% faster'));
    expect(insights.dryers, contains('Dryer A was the busiest dryer with 75%'));
    expect(insights.dryers, contains('1 dryer was idle'));
  });

  test('labels afternoon hours and period ranges', () {
    expect(chartHourLabel(0), '8 AM');
    expect(chartHourLabel(4), '12 PM');
    expect(chartHourLabel(9), '5 PM');
    final thursday = DateTime(2026, 10, 29);
    expect(periodRange(AnalyticsPeriod.today, thursday), 'Oct 29, 2026');
    expect(
      periodRange(AnalyticsPeriod.thisWeek, thursday),
      'Oct 26 - Oct 29, 2026',
    );
    expect(
      periodRange(AnalyticsPeriod.thisMonth, thursday),
      'Oct 1 - Oct 29, 2026',
    );
  });
}
