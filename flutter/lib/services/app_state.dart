import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'location_service.dart';

class AppState extends ChangeNotifier {
  final ApiService api = ApiService();
  late final LocationService locationService = LocationService(api);

  Map<String, dynamic>? _profile;
  bool _isLoggedIn = false;
  bool _isOpenToConnect = false;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOpenToConnect => _isOpenToConnect;

  Future<void> tryAutoLogin() async {
    final token = await api.getToken();
    if (token != null) {
      try {
        _profile = await api.getMyProfile();
        _isLoggedIn = true;
        _isOpenToConnect = _profile?['is_open_to_connect'] ?? false;
        if (_isOpenToConnect) {
          await locationService.startTracking();
        }
        notifyListeners();
      } catch (_) {
        await api.clearToken();
      }
    }
  }

  Future<void> login(String email, String password) async {
    await api.login(email, password);
    _profile = await api.getMyProfile();
    _isLoggedIn = true;
    _isOpenToConnect = _profile?['is_open_to_connect'] ?? false;
    if (_isOpenToConnect) {
      await locationService.startTracking();
    }
    notifyListeners();
  }

  Future<void> logout() async {
    locationService.stopTracking();
    await api.clearToken();
    _profile = null;
    _isLoggedIn = false;
    _isOpenToConnect = false;
    notifyListeners();
  }

  Future<void> toggleVisibility() async {
    final result = await api.toggleVisibility();
    _isOpenToConnect = result['is_open_to_connect'];
    if (_profile != null) {
      _profile!['is_open_to_connect'] = _isOpenToConnect;
    }
    if (_isOpenToConnect) {
      await locationService.startTracking();
    } else {
      locationService.stopTracking();
    }
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    _profile = await api.getMyProfile();
    _isOpenToConnect = _profile?['is_open_to_connect'] ?? false;
    notifyListeners();
  }
}
