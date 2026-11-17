import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isLoggedIn;

  String get userId => id;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
    this.isLoggedIn = false,
  });
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kUserId = 'auth_user_id';
  static const _kUserName = 'auth_user_name';
  static const _kUserEmail = 'auth_user_email';
  static const _kIsAdmin = 'auth_is_admin';
  static const _kIsLoggedIn = 'auth_is_logged_in';

  AppUser? _cachedUser;

  static AppUser get currentUser =>
      instance._cachedUser ??
      const AppUser(id: 'guest', name: 'Guest User', email: '', isLoggedIn: false, isAdmin: false);

  static Future<AppUser> getUser() => instance.getCurrentUser();

  Future<AppUser> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser!;
    final sp = await SharedPreferences.getInstance();
    final isLoggedIn = sp.getBool(_kIsLoggedIn) ?? false;
    final id = sp.getString(_kUserId) ?? _generateUserId();
    final name = sp.getString(_kUserName) ?? (isLoggedIn ? 'Fitness User' : 'Guest User');
    final email = sp.getString(_kUserEmail) ?? '';
    final isAdmin = sp.getBool(_kIsAdmin) ?? false;

    if (!sp.containsKey(_kUserId)) {
      await sp.setString(_kUserId, id);
    }

    _cachedUser = AppUser(
      id: id,
      name: name,
      email: email,
      isAdmin: isAdmin,
      isLoggedIn: isLoggedIn,
    );
    return _cachedUser!;
  }

  static Future<void> login({
    required String name,
    String email = '',
    bool isAdmin = false,
  }) =>
      instance._loginInternal(name: name, email: email, isAdmin: isAdmin);

  Future<void> _loginInternal({
    required String name,
    String email = '',
    bool isAdmin = false,
  }) async {
    final sp = await SharedPreferences.getInstance();
    var id = sp.getString(_kUserId);
    if (id == null || id.isEmpty) {
      id = _generateUserId();
      await sp.setString(_kUserId, id);
    }
    final cleanName = name.trim().isEmpty ? 'Fitness User' : name.trim();
    await sp.setString(_kUserName, cleanName);
    await sp.setString(_kUserEmail, email.trim());
    await sp.setBool(_kIsAdmin, isAdmin);
    await sp.setBool(_kIsLoggedIn, true);

    _cachedUser = AppUser(
      id: id,
      name: cleanName,
      email: email.trim(),
      isAdmin: isAdmin,
      isLoggedIn: true,
    );
  }

  static Future<void> logout() => instance._logoutInternal();

  Future<void> _logoutInternal() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kIsLoggedIn, false);
    await sp.setBool(_kIsAdmin, false);
    await sp.setString(_kUserName, 'Guest User');
    await sp.setString(_kUserEmail, '');
    _cachedUser = AppUser(
      id: sp.getString(_kUserId) ?? _generateUserId(),
      name: 'Guest User',
      email: '',
      isAdmin: false,
      isLoggedIn: false,
    );
  }

  static String _generateUserId() {
    final rnd = Random();
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(9999)}';
  }

  static final List<String> _kRandomNames = [
    'FitExplorer',
    'AvocadoRunner',
    'SunnyKettlebell',
    'ZenGymnast',
    'MightyOats',
    'SwiftPacer',
    'ActiveKoala',
    'HealthyFalcon',
    'IronStride',
    'FreshSprint',
    'GreenSmoothie',
    'PeakChallenger',
    'DailyMover',
  ];

  static String getRandomName() {
    final rnd = Random();
    final base = _kRandomNames[rnd.nextInt(_kRandomNames.length)];
    final num = rnd.nextInt(90) + 10;
    return '$base$num';
  }
}
