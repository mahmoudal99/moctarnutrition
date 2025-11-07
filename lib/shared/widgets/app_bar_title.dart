import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  String title;

  AppBarTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.heading4.copyWith(
        fontSize: 18
      ),
    );
  }
}
