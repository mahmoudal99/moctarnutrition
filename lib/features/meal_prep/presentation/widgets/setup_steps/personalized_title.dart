import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';

class PersonalizedTitle extends StatelessWidget {
  final String? userName;
  final String title;
  final String? fallbackTitle;
  final TextStyle? style;
  final TextAlign? textAlign;

  const PersonalizedTitle({
    super.key,
    this.userName,
    required this.title,
    this.fallbackTitle,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? AppTextStyles.bodyMedium;
    final finalStyle = defaultStyle.copyWith(fontWeight: FontWeight.w600);

    if (userName != null && userName!.isNotEmpty) {
      final nameIndex = title.indexOf('{name}');
      if (nameIndex != -1) {
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: title.substring(0, nameIndex),
                style: defaultStyle,
              ),
              TextSpan(
                text: userName,
                style: finalStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: title.substring(nameIndex + 6),
                style: defaultStyle,
              ),
            ],
          ),
          textAlign: textAlign ?? TextAlign.start,
        );
      }
    }

    // Fallback case
    return Text(
      fallbackTitle ?? title.replaceAll('{name}', 'your'),
      style: finalStyle,
      textAlign: textAlign ?? TextAlign.start,
    );
  }
}
