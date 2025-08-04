import 'package:flutter/material.dart';
import 'package:champions_gym_app/shared/models/user_model.dart';
import 'package:champions_gym_app/core/constants/app_constants.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/admin_bottom_navigation.dart';
import 'package:champions_gym_app/features/admin/presentation/widgets/floating_admin_screen_wrapper.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_user_profile_screen.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_user_checkins_screen.dart';
import 'package:champions_gym_app/features/admin/presentation/screens/admin_user_meal_plan_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;

  const AdminUserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  String? _mealPlanId;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _mealPlanId = widget.user.mealPlanId;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingAdminScreenWrapper(
      currentIndex: _currentIndex,
      onIndexChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return AdminUserProfileScreen(
          user: widget.user,
          mealPlanId: _mealPlanId,
          onMealPlanCreated: _refreshMealPlanId,
        );
      case 1:
        return AdminUserCheckinsScreen(user: widget.user);
      case 2:
        return AdminUserMealPlanScreen(
          user: widget.user,
          mealPlanId: _mealPlanId,
          onMealPlanCreated: _refreshMealPlanId,
        );
      default:
        return AdminUserProfileScreen(
          user: widget.user,
          mealPlanId: _mealPlanId,
          onMealPlanCreated: _refreshMealPlanId,
        );
    }
  }

  void _refreshMealPlanId() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .get();
    setState(() {
      _mealPlanId = userDoc.data()?['mealPlanId'] as String?;
    });
  }
}
