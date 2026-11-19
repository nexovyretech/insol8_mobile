import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:insol8_mobile/models/billing.dart';

/// Who the receipt is for, from the signed-in profile.
class ReceiptCustomer {
  const ReceiptCustomer({required this.name, this.email, this.mobile});

  final String name;
  final String? email;
  final String? mobile;
}

/// Builds the branded receipt PDF and opens the system sheet to save or
/// share it.
Future<void> shareReceipt({
  required PaymentRecord payment,
  required ReceiptCustomer customer,
  DateTime? now,
}) async {
  final bytes = await buildReceiptPdf(
    payment: payment,
    customer: customer,
    generatedAt: now ?? DateTime.now(),
    logoSvg: await rootBundle.loadString('assets/logo/insol8_mark.svg'),
    fonts: await _brandFonts(),
  );
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'insol8-${payment.receiptNumber.toLowerCase()}.pdf',
  );
}

// Sora, as in the analytics report; Helvetica when offline.
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

/// The receipt as PDF bytes, in the same brand style as the analytics report.
/// [fonts] and [logoSvg] are optional so it can be built without assets.
Future<Uint8List> buildReceiptPdf({
  required PaymentRecord payment,
  required ReceiptCustomer customer,
  required DateTime generatedAt,
  String? logoSvg,
  pw.ThemeData? fonts,
}) {
  final document = pw.Document(
    title: 'INSOL8 Receipt ${payment.receiptNumber}',
    author: 'Nexovyre',
    creator: 'INSOL8',
    subject: payment.description,
  );
  final paidOn = payment.paidAt;
  final period = switch ((payment.periodStart, payment.periodEnd)) {
    (final start?, final end?) => '${_date(start)} to ${_date(end)}',
    _ => payment.isUpgrade ? 'Rest of the current period' : 'One month',
  };
  document.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 32, 40, 28),
        theme: fonts,
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _Header(
            logoSvg: logoSvg,
            receiptNumber: payment.receiptNumber,
            issuedOn: paidOn,
          ),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _Block(
                  title: 'Billed to',
                  lines: [customer.name, ?customer.email, ?customer.mobile],
                  emphasizeFirst: true,
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: _Block(
                  title: 'Payment',
                  lines: [
                    if (paidOn != null) 'Paid on ${_dateTime(paidOn)}',
                    'Via ${payment.paymentMethodName} (PayMongo)',
                    'Reference ${payment.referenceNumber}',
                    if (payment.paymentId != null)
                      'Payment ID ${payment.paymentId}',
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          _ItemsTable(
            description: payment.description,
            detail: payment.planName,
            period: period,
            amount: _php(payment.amountCentavos),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _PaidStamp(),
              pw.Spacer(),
              _Totals(amount: _php(payment.amountCentavos)),
            ],
          ),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _cream,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _border),
            ),
            child: pw.Text(
              'Thank you for using INSOL8. This receipt confirms your '
              'subscription payment, received through PayMongo. It is an '
              'acknowledgement of payment, not an official receipt. For '
              'billing questions, contact the INSOL8 support team with the '
              'reference number above.',
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: _body,
                lineSpacing: 2,
              ),
            ),
          ),
          _Footer(generatedAt: generatedAt),
        ],
      ),
    ),
  );
  return document.save();
}

// Brand palette, matching AppColors and the analytics report.
const _orange = PdfColor.fromInt(0xFFF26738);
const _cream = PdfColor.fromInt(0xFFFFF7F1);
const _border = PdfColor.fromInt(0xFFFFE4D5);
const _ink = PdfColor.fromInt(0xFF35170F);
const _body = PdfColor.fromInt(0xFF674E45);
const _muted = PdfColor.fromInt(0xFFB99D8F);
const _green = PdfColor.fromInt(0xFF2E8B57);

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

String _date(DateTime value) {
  final local = value.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_date(local)}, $hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}

// "PHP" rather than the peso sign, which the fallback font lacks.
String _php(int centavos) => formatPeso(centavos).replaceFirst('₱', 'PHP ');

class _Header extends pw.StatelessWidget {
  _Header({
    required this.logoSvg,
    required this.receiptNumber,
    required this.issuedOn,
  });

  final String? logoSvg;
  final String receiptNumber;
  final DateTime? issuedOn;

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
                'RECEIPT',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                receiptNumber,
                style: const pw.TextStyle(fontSize: 9, color: _body),
              ),
              if (issuedOn != null)
                pw.Text(
                  'Issued ${_date(issuedOn!)}',
                  style: const pw.TextStyle(fontSize: 9, color: _body),
                ),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Container(height: 3, color: _orange),
      pw.SizedBox(height: 18),
    ],
  );
}

class _Label extends pw.StatelessWidget {
  _Label(this.text);

  final String text;

  @override
  pw.Widget build(pw.Context context) => pw.Row(
    children: [
      pw.Container(width: 3, height: 10, color: _orange),
      pw.SizedBox(width: 6),
      pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}

class _Block extends pw.StatelessWidget {
  _Block({
    required this.title,
    required this.lines,
    this.emphasizeFirst = false,
  });

  final String title;
  final List<String> lines;
  final bool emphasizeFirst;

  @override
  pw.Widget build(pw.Context context) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _Label(title),
      pw.SizedBox(height: 7),
      for (var index = 0; index < lines.length; index++)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(
            lines[index],
            style: index == 0 && emphasizeFirst
                ? pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  )
                : const pw.TextStyle(fontSize: 9, color: _body),
          ),
        ),
    ],
  );
}

class _ItemsTable extends pw.StatelessWidget {
  _ItemsTable({
    required this.description,
    required this.detail,
    required this.period,
    required this.amount,
  });

  final String description;
  final String detail;
  final String period;
  final String amount;

  pw.Widget _cell(
    String text, {
    bool header = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: pw.Text(
      text,
      textAlign: align,
      style: header
          ? pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 0.6,
            )
          : const pw.TextStyle(fontSize: 9.5, color: _ink),
    ),
  );

  @override
  pw.Widget build(pw.Context context) => pw.Table(
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(2.4),
      2: pw.FlexColumnWidth(1.4),
    },
    border: const pw.TableBorder(
      bottom: pw.BorderSide(color: _border),
      horizontalInside: pw.BorderSide(color: _border),
    ),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _orange),
        children: [
          _cell('DESCRIPTION', header: true),
          _cell('BILLING PERIOD', header: true),
          _cell('AMOUNT', header: true, align: pw.TextAlign.right),
        ],
      ),
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  detail,
                  style: const pw.TextStyle(fontSize: 8, color: _muted),
                ),
              ],
            ),
          ),
          _cell(period),
          _cell(amount, align: pw.TextAlign.right),
        ],
      ),
    ],
  );
}

class _Totals extends pw.StatelessWidget {
  _Totals({required this.amount});

  final String amount;

  pw.Widget _row(String label, String value, {bool total = false}) => pw.Row(
    children: [
      pw.SizedBox(
        width: 90,
        child: pw.Text(
          label,
          style: total
              ? pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                )
              : const pw.TextStyle(fontSize: 9, color: _body),
        ),
      ),
      pw.SizedBox(
        width: 100,
        child: pw.Text(
          value,
          textAlign: pw.TextAlign.right,
          style: total
              ? pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _orange,
                )
              : const pw.TextStyle(fontSize: 9, color: _ink),
        ),
      ),
    ],
  );

  @override
  pw.Widget build(pw.Context context) => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _cream,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      children: [
        _row('Subtotal', amount),
        pw.SizedBox(height: 4),
        _row('Tax', 'PHP 0.00'),
        pw.Divider(color: _border, height: 14),
        _row('Total paid', amount, total: true),
      ],
    ),
  );
}

class _PaidStamp extends pw.StatelessWidget {
  @override
  pw.Widget build(pw.Context context) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _green, width: 1.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(
      'PAID',
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _green,
        letterSpacing: 3,
      ),
    ),
  );
}

class _Footer extends pw.StatelessWidget {
  _Footer({required this.generatedAt});

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
          'INSOL8 · Created by Nexovyre · Generated ${_dateTime(generatedAt)}',
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
        pw.Spacer(),
        pw.Text(
          'Page 1 of 1',
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
      ],
    ),
  );
}
