import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:insol8_mobile/theme/app_colors.dart';
import 'package:insol8_mobile/theme/app_spacing.dart';

class OnboardingLoadingMark extends StatefulWidget {
  const OnboardingLoadingMark({super.key});

  @override
  State<OnboardingLoadingMark> createState() => _OnboardingLoadingMarkState();
}

class _OnboardingLoadingMarkState extends State<OnboardingLoadingMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          return Transform.rotate(
            angle: progress * math.pi * 2,
            child: Stack(
              children: [
                _animatedDot(left: 3, top: 21, index: 0, progress: progress),
                _animatedDot(right: 3, top: 7, index: 1, progress: progress),
                _animatedDot(right: 3, bottom: 5, index: 2, progress: progress),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _animatedDot({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required int index,
    required double progress,
  }) {
    final phase = (progress + index / 3) % 1;
    final colorProgress = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    final color = Color.lerp(
      AppColors.primary,
      const Color(0xFFFFB18E),
      colorProgress,
    );
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class OnboardingTrustNote extends StatelessWidget {
  const OnboardingTrustNote({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // Shrink-wraps, and lets the text wrap, so two notes fit side by side on
    // narrow phones instead of overflowing to the right.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 12),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Scrollable content with the action buttons pinned to the bottom, so the
/// main button is always on screen however tall the content is (small
/// phones, larger text, or an open keyboard). On tall screens it looks like
/// a Spacer layout: content at the top (or centred) and actions at the bottom.
class OnboardingStickyLayout extends StatelessWidget {
  const OnboardingStickyLayout({
    super.key,
    this.header,
    required this.content,
    required this.actions,
    this.centerContent = false,
    this.fillViewport = false,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  /// Stays fixed above the scrolling content (e.g. a back/skip bar).
  final Widget? header;
  final List<Widget> content;
  final List<Widget> actions;
  final bool centerContent;

  /// Lets [content] use Expanded/Spacer to fill spare height on tall screens
  /// while still scrolling on short ones.
  final bool fillViewport;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?header,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _wrap(
                  Column(
                    mainAxisAlignment: centerContent
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    crossAxisAlignment: crossAxisAlignment,
                    children: content,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...actions,
      ],
    );
  }

  Widget _wrap(Widget column) =>
      fillViewport ? IntrinsicHeight(child: column) : column;
}

class OnboardingSectionLabel extends StatelessWidget {
  const OnboardingSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.fieldHint,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class OnboardingGradientButton extends StatelessWidget {
  const OnboardingGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.height = 54,
    this.borderRadius = 14,
    this.fontSize = 14,
    this.gradientColors = const [AppColors.primary, AppColors.primaryDark],
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final double height;
  final double borderRadius;
  final double fontSize;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEnabled ? null : AppColors.disabled,
          gradient: isEnabled ? LinearGradient(colors: gradientColors) : null,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: Colors.white, fontSize: fontSize),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 12),
                    Icon(trailingIcon, color: Colors.white, size: 19),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.child,
    required this.showBack,
    this.showGradient = true,
    this.headerSlotHeight = 42,
    this.onBack,
  });

  final Widget child;
  final bool showBack;
  final bool showGradient;
  final double headerSlotHeight;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: showGradient
          ? const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 1.04),
                radius: 1.15,
                colors: [Color(0xFFFFD1B9), AppColors.background],
                stops: [0, 0.78],
              ),
            )
          : const BoxDecoration(color: AppColors.background),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.pageVertical,
          AppSpacing.pageHorizontal,
          AppSpacing.pageVertical,
        ),
        child: Column(
          children: [
            SizedBox(
              height: headerSlotHeight,
              child: showBack
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: onBack,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        icon: const Icon(Icons.arrow_back_ios_new, size: 19),
                        color: AppColors.ink,
                        tooltip: 'Back',
                      ),
                    )
                  : null,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

BoxDecoration onboardingCardDecoration() => BoxDecoration(
  color: const Color(0xFFFFF7F2),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: const Color(0xFFFFE6D8)),
  boxShadow: const [
    BoxShadow(color: Color(0x0A8A3618), blurRadius: 8, offset: Offset(0, 3)),
  ],
);
