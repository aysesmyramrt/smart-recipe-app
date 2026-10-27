import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_recipe_app/models/user_model.dart';
import 'package:smart_recipe_app/services/api_service.dart';
import 'package:smart_recipe_app/utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _api = ApiService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final data = await _api.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _persistToken(data);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.login(email: email, password: password);
    await _persistToken(data);
    // Also sign in to Firebase for client-side SDK usage
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await _firebaseAuth.signOut();
  }

  Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.userKey);
      if (raw == null) return null;
      return UserModel.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistToken(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, data['access_token'] as String);
    if (data['user'] != null) {
      await prefs.setString(AppConstants.userKey, json.encode(data['user']));
    }
  }
}
