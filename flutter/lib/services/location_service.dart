import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  final ApiService _api;
  Timer? _timer;
  bool _isTracking = false;

  LocationService(this._api);

  bool get isTracking => _isTracking;

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> startTracking() async {
    if (_isTracking) return;
    final hasPermission = await requestPermissions();
    if (!hasPermission) throw Exception('Location permission denied');

    _isTracking = true;
    // Send immediately, then every 60 seconds
    await _sendLocation();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _sendLocation());
  }

  void stopTracking() {
    _isTracking = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _sendLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _api.updateLocation(position.latitude, position.longitude);
    } catch (e) {
      // Silently fail — network errors shouldn't crash the app
    }
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}
