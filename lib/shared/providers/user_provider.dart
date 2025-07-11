import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_local_storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final UserLocalStorageService _storageService = UserLocalStorageService();

  UserModel? get user => _user;

  Future<void> loadUser() async {
    _user = await _storageService.loadUser();
    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    await _storageService.saveUser(user);
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    await _storageService.clearUser();
    notifyListeners();
  }
} 