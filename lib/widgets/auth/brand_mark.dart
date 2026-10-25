import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 55});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/insol8_mark.svg',
      height: size,
      width: size * 41 / 69,
      fit: BoxFit.contain,
      semanticsLabel: 'inSOL8 logo',
    );
  }
}
