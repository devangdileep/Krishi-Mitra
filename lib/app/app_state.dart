import 'package:flutter/widgets.dart';

import '../models/models.dart';
import '../services/local_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.store)
      : _darkThemeEnabled = store.darkThemeEnabled,
        _onboardingCompleted = store.onboardingCompleted,
        _selectedLanguage = store.selectedLanguage,
        _user = store.getLoggedInUser(),
        _userLocationName = store.userLocationName,
        _userLat = store.userLat,
        _userLng = store.userLng;

  final LocalStore store;
  bool _darkThemeEnabled;
  bool _onboardingCompleted;
  String _selectedLanguage;
  UserProfile? _user;
  String? _userLocationName;
  double? _userLat;
  double? _userLng;

  bool get darkThemeEnabled => _darkThemeEnabled;
  bool get onboardingCompleted => _onboardingCompleted;
  String get selectedLanguage => _selectedLanguage;
  UserProfile? get user => _user;
  String? get userLocationName => _userLocationName;
  double? get userLat => _userLat;
  double? get userLng => _userLng;

  Future<void> setDarkTheme(bool value) async {
    _darkThemeEnabled = value;
    notifyListeners();
    await store.setDarkThemeEnabled(value);
  }

  Future<void> setLanguage(String code) async {
    _selectedLanguage = code;
    notifyListeners();
    await store.setSelectedLanguage(code);
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();
    await store.setOnboardingCompleted(true);
  }

  Future<void> setUser(UserProfile user) async {
    _user = user;
    notifyListeners();
    await store.saveLoggedInUser(user);
  }

  Future<void> updateUser(UserProfile user) => setUser(user);

  Future<void> setUserLocation(String name, double lat, double lng) async {
    _userLocationName = name;
    _userLat = lat;
    _userLng = lng;
    notifyListeners();
    await store.setUserLocationName(name);
    await store.setUserLat(lat);
    await store.setUserLng(lng);
  }

  Future<void> deleteLocalAccount(int userId) async {
    _user = null;
    notifyListeners();
    await store.clearUserData(userId);
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
    await store.clearLoggedInUser();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope missing');
    return scope!.notifier!;
  }
}
