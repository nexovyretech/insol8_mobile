import 'dart:async';

import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';

/// "Didn’t get the code? Resend code", shown under every code entry (sign-up,
/// forgot password, adding an email or mobile number, creating a password).
///
/// A code was just sent when this appears, so it starts with a countdown
/// ("Resend code in 0:59") and only lets the user ask again once it ends.
/// This keeps people from hitting Cognito's sending limits (and our SMS
/// costs) by tapping repeatedly. [onResend] returns whether a new code went
/// out; only then does the countdown start again.
class ResendCodeLink extends StatefulWidget {
  const ResendCodeLink({
    super.key,
    required this.onResend,
    this.prefix = 'Didn’t get the code? ',
    this.cooldown = const Duration(seconds: 60),
  });

  final Future<bool> Function() onResend;
  final String prefix;
  final Duration cooldown;

  @override
  State<ResendCodeLink> createState() => _ResendCodeLinkState();
}

class _ResendCodeLinkState extends State<ResendCodeLink> {
  Timer? _timer;
  late int _secondsLeft;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = widget.cooldown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final sent = await widget.onResend();
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (sent) _startCountdown();
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontSize: 12);
    final waiting = _secondsLeft > 0;
    final time =
        '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(widget.prefix, style: style),
        if (waiting)
          Text(
            'Resend code in $time',
            style: style?.copyWith(
              color: AppColors.fieldHint,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          )
        else
          TextButton(
            onPressed: _sending ? null : _resend,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primary,
              textStyle: style,
            ),
            child: Text(_sending ? 'Sending…' : 'Resend code'),
          ),
      ],
    );
  }
}
