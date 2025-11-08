import 'package:champions_gym_app/shared/widgets/app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';

class AdminUserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel user;
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const AdminUserAppBar({
    super.key,
    required this.user,
    required this.title,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios_outlined,
          color: Colors.grey[700],
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [AppBarTitle(title: title)],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
