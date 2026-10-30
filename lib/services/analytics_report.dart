import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:insol8_mobile/models/analytics_data.dart';

/// Builds the branded analytics PDF and opens the system sheet to save or
/// share it.
Future<void> shareAnalyticsReport({
  required AnalyticsData data,
  required AnalyticsPeriod period,
  DateTime? now,
}) async {
  final generatedAt = now ?? DateTime.now();
  final bytes = await buildAnalyticsReport(
    data: data,
    period: period,
    generatedAt: generatedAt,
    logoSvg: await rootBundle.loadString('assets/logo/insol8_mark.svg'),
    fonts: await _brandFonts(),
  );
  await Printing.sharePdf(
    bytes: bytes,
    filename:
        'insol8-analytics-${analyticsPeriodSlug(period)}-'
        '${_isoDate(generatedAt)}.pdf',
  );
}

// Sora is the app's typeface; fetched once and cached by the printing
// package. Offline, the report falls back to the built-in Helvetica.
Future<pw.ThemeData?> _brandFonts() async {
  try {
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.soraRegular(),
      bold: await PdfGoogleFonts.soraBold(),
    );
  } on Exception {
    return null;
  }
}

/// The report as PDF bytes. [fonts] and [logoSvg] are optional so the layout
/// can be built without assets or network access.
Future<Uint8List> buildAnalyticsReport({
  required AnalyticsData data,
  required AnalyticsPeriod period,
  required DateTime generatedAt,
  String? logoSvg,
  pw.ThemeData? fonts,
}) {
  final insights = AnalyticsInsights(data, period);
  final document = pw.Document(
    title: 'INSOL8 Analytics Report',
    author: 'Nexovyre',
    creator: 'INSOL8',
    subject: '${analyticsPeriodLabel(period)} analytics',
  );
  document.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 32, 40, 28),
        theme: fonts,
      ),
      header: (context) => context.pageNumber == 1
          ? _Header(logoSvg: logoSvg, period: period, generatedAt: generatedAt)
          : _RunningHeader(period: period),
      footer: (context) => _Footer(
        page: context.pageNumber,
        pages: context.pagesCount,
        generatedAt: generatedAt,
      ),
      build: (context) => [
        _Section(
          title: 'Executive summary',
          children: [_Paragraph(insights.summary)],
        ),
        _KpiRow(data: data),
        pw.SizedBox(height: 14),
        _Section(
          title: 'Loads dried by hour',
          caption: 'Finished jobs by start time, 8 AM to 5 PM',
          children: [
            _HourChart(values: data.loadsByHour),
            _Interpretation(insights.peakHour),
          ],
        ),
        _Section(
          title: 'Energy source',
          caption: 'Share of drying heat by source',
          children: [
            _EnergySplit(
              solar: data.solarHeatPercent,
              backup: data.backupHeatPercent,
            ),
            _Interpretation(insights.energySource),
          ],
        ),
        _Section(
          title: 'Drying time by hour',
          caption: 'Average minutes per finished job',
          children: [
            for (final duration in data.dryingTimeByPeriod)
              _BarRow(
                label: duration.label,
                value: duration.minutes.toDouble(),
                maxValue: _max(data.dryingTimeByPeriod.map((d) => d.minutes)),
                trailing: '${duration.minutes} min',
              ),
            _Interpretation(insights.dryingTime),
          ],
        ),
        _Section(
          title: 'Dryers compared',
          caption:
              'Finished jobs per dryer, top ${data.dryerComparisons.length}',
          children: [
            if (data.dryerComparisons.isEmpty)
              _Paragraph('No dryers are registered yet.')
            else
              for (final dryer in data.dryerComparisons)
                _BarRow(
                  label: dryer.name,
                  value: dryer.loads.toDouble(),
                  maxValue: _max(data.dryerComparisons.map((d) => d.loads)),
                  trailing:
                      '${dryer.loads} ${dryer.loads == 1 ? 'load' : 'loads'}',
                ),
            _Interpretation(insights.dryers),
          ],
        ),
      ],
    ),
  );
  return document.save();
}

/// Plain-language readings of the analytics, shared by the PDF and tests.
class AnalyticsInsights {
  AnalyticsInsights(this.data, this.period);

  final AnalyticsData data;
  final AnalyticsPeriod period;

  String get _when => switch (period) {
    AnalyticsPeriod.today => 'today',
    AnalyticsPeriod.thisWeek => 'this week',
    AnalyticsPeriod.thisMonth => 'this month',
  };

  String get summary {
    final saved =
        'Dryers saved ${formatKwh(data.energySavedKwh)} of electricity, '
        'worth about ${formatPhp(data.moneySavedPhp)}.';
    if (data.loadsDried == 0) {
      return 'No drying jobs finished $_when. $saved';
    }
    return '${data.loadsDried} ${data.loadsDried == 1 ? 'load was' : 'loads were'} '
        'dried $_when, taking ${formatHours(data.averageDryingHours)} on '
        'average. $saved';
  }

  String get peakHour {
    final total = data.loadsByHour.fold<double>(0, (a, b) => a + b);
    if (total == 0) return 'No jobs started between 8 AM and 5 PM $_when.';
    final peak = data.loadsByHour.reduce((a, b) => a > b ? a : b);
    final index = data.loadsByHour.indexOf(peak);
    final share = (peak / total * 100).round();
    return 'The busiest hour was ${chartHourLabel(index)}, with '
        '${peak.round()} ${peak == 1 ? 'load' : 'loads'} ($share% of the '
        'day-time jobs). Plan staff and dryer availability around this hour.';
  }

  String get energySource {
    final solar = data.solarHeatPercent;
    if (solar == null) {
      return 'Not enough drying data yet to estimate where the heat came from.';
    }
    if (solar >= 70) {
      return '$solar% of the drying heat came free from the sun. The dryers '
          'are running mostly on solar energy.';
    }
    if (solar >= 40) {
      return 'Solar supplied $solar% of the heat and backup heat the rest. '
          'Running more loads around midday would raise the solar share.';
    }
    return 'Backup heat supplied ${100 - solar}% of the heat. Moving loads to '
        'sunnier hours, 10 AM to 2 PM, would cut electricity use.';
  }

  String get dryingTime {
    int minutesOf(String label) => data.dryingTimeByPeriod
        .firstWhere(
          (d) => d.label == label,
          orElse: () => const AnalyticsDuration(label: '', minutes: 0),
        )
        .minutes;
    final midday = minutesOf('Midday');
    final other = minutesOf('Other');
    if (midday == 0 && other == 0) return 'No finished jobs to compare yet.';
    if (midday == 0) return 'No jobs were started from 10 AM to 2 PM $_when.';
    if (other == 0) return 'All finished jobs $_when were started at midday.';
    if (midday < other) {
      final faster = ((other - midday) / other * 100).round();
      return 'Midday loads dried in $midday min, $faster% faster than other '
          'hours ($other min), because the sun is strongest from 10 AM to 2 PM.';
    }
    if (midday > other) {
      return 'Midday loads took $midday min, longer than other hours '
          '($other min). Cloudy weather or heavier loads may explain this.';
    }
    return 'Loads took $midday min on average at any time of day.';
  }

  String get dryers {
    final dryers = data.dryerComparisons;
    if (dryers.isEmpty) return 'Add a dryer to compare usage.';
    final total = dryers.fold<int>(0, (sum, d) => sum + d.loads);
    if (total == 0) return 'None of the dryers finished a job $_when.';
    final top = dryers.first;
    final idle = dryers.where((d) => d.loads == 0).length;
    final share = (top.loads / total * 100).round();
    final busiest = dryers.length == 1
        ? '${top.name} handled all $total jobs.'
        : '${top.name} was the busiest dryer with $share% of the jobs shown.';
    return idle == 0
        ? busiest
        : '$busiest $idle ${idle == 1 ? 'dryer was' : 'dryers were'} idle; '
              'spreading loads evenly reduces wear.';
  }
}

String analyticsPeriodLabel(AnalyticsPeriod period) => switch (period) {
  AnalyticsPeriod.today => 'Today',
  AnalyticsPeriod.thisWeek => 'This Week',
  AnalyticsPeriod.thisMonth => 'This Month',
};

String analyticsPeriodSlug(AnalyticsPeriod period) => switch (period) {
  AnalyticsPeriod.today => 'today',
  AnalyticsPeriod.thisWeek => 'this-week',
  AnalyticsPeriod.thisMonth => 'this-month',
};

/// The chart's bars run hourly from 8 AM.
String chartHourLabel(int index) {
  final hour = index + 8;
  final display = hour % 12 == 0 ? 12 : hour % 12;
  return '$display ${hour < 12 ? 'AM' : 'PM'}';
}

/// The dates the period covers; weeks start on Monday, as on the server.
String periodRange(AnalyticsPeriod period, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final start = switch (period) {
    AnalyticsPeriod.today => today,
    AnalyticsPeriod.thisWeek => today.subtract(
      Duration(days: today.weekday - 1),
    ),
    AnalyticsPeriod.thisMonth => DateTime(now.year, now.month),
  };
  return start == today
      ? _longDate(today)
      : '${_months[start.month - 1]} ${start.day} - ${_longDate(today)}';
}

String formatHours(double hours) {
  final minutes = (hours * 60).round();
  if (minutes < 60) return '$minutes min';
  final whole = minutes ~/ 60;
  final hr = whole == 1 ? 'hr' : 'hrs';
  final rest = minutes % 60;
  return rest == 0 ? '$whole $hr' : '$whole $hr $rest min';
}

String formatKwh(double kwh) => '${_grouped(kwh, kwh < 10 ? 2 : 1)} kWh';

// "PHP" rather than the peso sign, which the fallback font lacks.
String formatPhp(double php) => 'PHP ${_grouped(php, 2)}';

String _grouped(double value, int decimals) {
  final parts = value.toStringAsFixed(decimals).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _longDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

String _isoDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _timestamp(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_longDate(date)}, $hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}

double _max(Iterable<int> values) =>
    values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b).toDouble();

// Brand palette, matching AppColors.
const _orange = PdfColor.fromInt(0xFFF26738);
const _orangeDark = PdfColor.fromInt(0xFFE95425);
const _orangeLight = PdfColor.fromInt(0xFFFFCFB8);
const _cream = PdfColor.fromInt(0xFFFFF7F1);
const _border = PdfColor.fromInt(0xFFFFE4D5);
const _ink = PdfColor.fromInt(0xFF35170F);
const _body = PdfColor.fromInt(0xFF674E45);
const _muted = PdfColor.fromInt(0xFFB99D8F);

class _Header extends pw.StatelessWidget {
  _Header({
    required this.logoSvg,
    required this.period,
    required this.generatedAt,
  });

  final String? logoSvg;
  final AnalyticsPeriod period;
  final DateTime generatedAt;

  @override
  pw.Widget build(pw.Context context) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoSvg != null) ...[
            pw.SvgImage(svg: logoSvg!, height: 44),
            pw.SizedBox(width: 12),
          ],
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INSOL8',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: _orange,
                  letterSpacing: 2,
                ),
              ),
              pw.Text(
                'Created by Nexovyre',
                style: const pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ANALYTICS REPORT',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${analyticsPeriodLabel(period)} · '
                '${periodRange(period, generatedAt)}',
                style: const pw.TextStyle(fontSize: 9, color: _body),
              ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Container(height: 3, color: _orange),
      pw.SizedBox(height: 14),
    ],
  );
}

class _RunningHeader extends pw.StatelessWidget {
  _RunningHeader({required this.period});

  final AnalyticsPeriod period;

  @override
  pw.Widget build(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 16),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _orange, width: 1.5)),
    ),
    child: pw.Row(
      children: [
        pw.Text(
          'INSOL8',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _orange,
            letterSpacing: 1.5,
          ),
        ),
        pw.Spacer(),
        pw.Text(
          'Analytics Report · ${analyticsPeriodLabel(period)}',
          style: const pw.TextStyle(fontSize: 8, color: _body),
        ),
      ],
    ),
  );
}

class _Footer extends pw.StatelessWidget {
  _Footer({required this.page, required this.pages, required this.generatedAt});

  final int page;
  final int pages;
  final DateTime generatedAt;

  @override
  pw.Widget build(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 14),
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _border)),
    ),
    child: pw.Row(
      children: [
        pw.Text(
          'INSOL8 · Created by Nexovyre · Generated ${_timestamp(generatedAt)}',
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
        pw.Spacer(),
        pw.Text(
          'Page $page of $pages',
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
      ],
    ),
  );
}

class _Section extends pw.StatelessWidget {
  _Section({required this.title, this.caption, required this.children});

  final String title;
  final String? caption;
  final List<pw.Widget> children;

  @override
  pw.Widget build(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 13),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(width: 3, height: 12, color: _orange),
            pw.SizedBox(width: 7),
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
                letterSpacing: 1,
              ),
            ),
            if (caption != null) ...[
              pw.Spacer(),
              pw.Text(
                caption!,
                style: const pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 9),
        ...children,
      ],
    ),
  );
}

class _Paragraph extends pw.StatelessWidget {
  _Paragraph(this.text);

  final String text;

  @override
  pw.Widget build(pw.Context context) => pw.Text(
    text,
    style: const pw.TextStyle(fontSize: 10, color: _body, lineSpacing: 3),
  );
}

/// The reading of a chart, set apart in a cream callout.
class _Interpretation extends pw.StatelessWidget {
  _Interpretation(this.text);

  final String text;

  @override
  pw.Widget build(pw.Context context) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: const pw.BoxDecoration(
      color: _cream,
      border: pw.Border(left: pw.BorderSide(color: _orange, width: 2)),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(fontSize: 8.5, color: _body, lineSpacing: 2),
        children: [
          pw.TextSpan(
            text: 'Insight  ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: _orangeDark,
            ),
          ),
          pw.TextSpan(text: text),
        ],
      ),
    ),
  );
}

class _KpiRow extends pw.StatelessWidget {
  _KpiRow({required this.data});

  final AnalyticsData data;

  @override
  pw.Widget build(pw.Context context) => pw.Row(
    children: [
      for (final (index, (label, value)) in [
        ('Loads dried', '${data.loadsDried}'),
        ('Avg. drying time', formatHours(data.averageDryingHours)),
        ('Energy saved', formatKwh(data.energySavedKwh)),
        ('Money saved', formatPhp(data.moneySavedPhp)),
      ].indexed) ...[
        if (index > 0) pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: pw.BoxDecoration(
              color: _cream,
              border: pw.Border.all(color: _border),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 6.5, color: _muted),
                ),
                pw.SizedBox(height: 5),
                pw.FittedBox(
                  child: pw.Text(
                    value,
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: _orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

class _HourChart extends pw.StatelessWidget {
  _HourChart({required this.values});

  final List<double> values;

  static const _height = 76.0;

  @override
  pw.Widget build(pw.Context context) {
    final peak = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final scale = peak == 0 ? 1.0 : peak;
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < values.length; index++)
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      values[index].round().toString(),
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: values[index] == peak && peak > 0
                            ? _orangeDark
                            : _body,
                        fontWeight: values[index] == peak && peak > 0
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Container(
                      // A sliver of bar keeps empty hours visible.
                      height: (values[index] / scale * _height).clamp(
                        2,
                        _height,
                      ),
                      decoration: pw.BoxDecoration(
                        color: values[index] == peak && peak > 0
                            ? _orange
                            : _orangeLight,
                        borderRadius: const pw.BorderRadius.vertical(
                          top: pw.Radius.circular(3),
                        ),
                      ),
                    ),
                    pw.Container(height: 0.6, color: _border),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      chartHourLabel(index),
                      style: const pw.TextStyle(fontSize: 6.5, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EnergySplit extends pw.StatelessWidget {
  _EnergySplit({required this.solar, required this.backup});

  final int? solar;
  final int? backup;

  @override
  pw.Widget build(pw.Context context) {
    final solar = this.solar;
    final backup = this.backup;
    if (solar == null || backup == null) {
      return pw.Container(height: 14, color: _cream);
    }
    pw.Widget legend(PdfColor color, String label) => pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(width: 8, height: 8, color: color),
        pw.SizedBox(width: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _body)),
      ],
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.ClipRRect(
          horizontalRadius: 4,
          verticalRadius: 4,
          child: pw.Row(
            children: [
              if (solar > 0)
                pw.Expanded(
                  flex: solar,
                  child: pw.Container(height: 14, color: _orange),
                ),
              if (backup > 0)
                pw.Expanded(
                  flex: backup,
                  child: pw.Container(height: 14, color: _orangeLight),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            legend(_orange, 'Free solar heat  $solar%'),
            legend(_orangeLight, 'Backup heat  $backup%'),
          ],
        ),
      ],
    );
  }
}

class _BarRow extends pw.StatelessWidget {
  _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.trailing,
  });

  final String label;
  final double value;
  final double maxValue;
  final String trailing;

  @override
  pw.Widget build(pw.Context context) {
    final fraction = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
              style: const pw.TextStyle(fontSize: 8.5, color: _ink),
            ),
          ),
          pw.Expanded(
            child: pw.ClipRRect(
              horizontalRadius: 3,
              verticalRadius: 3,
              child: pw.Container(
                height: 10,
                color: _cream,
                alignment: pw.Alignment.centerLeft,
                child: fraction == 0
                    ? null
                    : pw.Row(
                        children: [
                          pw.Expanded(
                            flex: (fraction * 1000).round(),
                            child: pw.Container(height: 10, color: _orange),
                          ),
                          if (fraction < 1)
                            pw.Expanded(
                              flex: ((1 - fraction) * 1000).round(),
                              child: pw.SizedBox(),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          pw.SizedBox(
            width: 56,
            child: pw.Text(
              trailing,
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8.5, color: _body),
            ),
          ),
        ],
      ),
    );
  }
}
