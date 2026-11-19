import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:insol8_mobile/models/billing.dart';
import 'package:insol8_mobile/models/user_profile.dart';
import 'package:insol8_mobile/pages/settings/billing/payment_history_page.dart';
import 'package:insol8_mobile/services/auth_repository.dart';
import 'package:insol8_mobile/services/receipt_pdf.dart';
import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';
import 'package:insol8_mobile/utils/display_format.dart';
import 'package:insol8_mobile/utils/phone_number.dart';
import 'package:insol8_mobile/widgets/app_page_header.dart';
import 'package:insol8_mobile/widgets/auth/primary_button.dart';

/// One payment's receipt, as a receipt card, with Download PDF.
class ReceiptPage extends StatefulWidget {
  const ReceiptPage({
    super.key,
    required this.payment,
    required this.authRepository,
  });

  final PaymentRecord payment;
  final AuthRepository authRepository;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  UserProfile? _profile;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    widget.authRepository
        .loadProfile()
        .then((profile) {
          if (mounted) setState(() => _profile = profile);
        })
        .catchError((Object _) {});
  }

  Future<void> _download() async {
    final profile = _profile;
    setState(() => _downloading = true);
    try {
      await shareReceipt(
        payment: widget.payment,
        customer: ReceiptCustomer(
          name: profile?.fullName ?? 'INSOL8 customer',
          email: profile?.email,
          mobile: switch (profile?.mobileNumber) {
            final number? => formatPhilippineMobile(number),
            null => null,
          },
        ),
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn’t create the PDF. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final paidAt = payment.paidAt;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.pageHeaderTop),
              AppInnerPageHeader(
                title: 'Receipt',
                onBack: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1235170F),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand header, like the PDF.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/logo/insol8_mark.svg',
                                  height: 30,
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'INSOL8',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                    Text(
                                      'Created by Nexovyre',
                                      style: TextStyle(
                                        color: AppColors.fieldHint,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'RECEIPT',
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      payment.receiptNumber,
                                      style: const TextStyle(
                                        color: AppColors.body,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(height: 3, color: AppColors.primary),
                          // Amount.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                            child: Column(
                              children: [
                                const PaidChip(),
                                const SizedBox(height: 10),
                                Text(
                                  formatPeso(payment.amountCentavos),
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  payment.description,
                                  style: const TextStyle(
                                    color: AppColors.body,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const _DashedDivider(),
                          _DetailRow(
                            icon: Icons.event_available_outlined,
                            label: 'Paid on',
                            value: paidAt == null ? '—' : formatDate(paidAt),
                          ),
                          _DetailRow(
                            icon: Icons.date_range_outlined,
                            label: 'Billing period',
                            value: switch ((
                              payment.periodStart,
                              payment.periodEnd,
                            )) {
                              (final start?, final end?) =>
                                '${formatDate(start)} – ${formatDate(end)}',
                              _ => 'One month',
                            },
                          ),
                          _DetailRow(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Payment method',
                            value: payment.paymentMethodName,
                          ),
                          _DetailRow(
                            icon: Icons.tag_rounded,
                            label: 'Reference',
                            value: payment.referenceNumber,
                            small: true,
                          ),
                          if (_profile case final profile?)
                            _DetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Billed to',
                              value: profile.fullName,
                            ),
                          const _DashedDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                            child: Row(
                              children: [
                                const Text(
                                  'Total paid',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formatPeso(payment.amountCentavos),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Paid through PayMongo. Download the PDF to keep a copy '
                      'or share it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.fieldHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PrimaryButton(
                label: 'Download PDF',
                isLoading: _downloading,
                onPressed: _download,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.sectionLabel),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: AppColors.body, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The torn-receipt line between sections.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: 4,
                height: 1.2,
                color: AppColors.dashboardBorder,
              ),
          ],
        );
      },
    ),
  );
}
