import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Represents geographical coordinates with accuracy and timestamp.
class LocationCoordinates {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final String locationName;
  final bool isFallback;

  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.locationName,
    this.isFallback = false,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'locationName': locationName,
        'isFallback': isFallback,
      };

  @override
  String toString() =>
      'LocationCoordinates($latitude, $longitude, name: $locationName, fallback: $isFallback)';
}

/// Service providing device GPS coordinates with graceful fallback to
/// primary Indian aquaculture zones (Bhimavaram / Nellore, AP).
class LocationService {
  /// Default Aquaculture Hub Coordinates: Bhimavaram, West Godavari, Andhra Pradesh.
  static const double defaultLatitude = 16.5449;
  static const double defaultLongitude = 81.5212;
  static const String defaultLocationName = 'Bhimavaram, AP';

  /// Secondary Aquaculture Hub Coordinates: Nellore, Andhra Pradesh.
  static const double nelloreLatitude = 14.4426;
  static const double nelloreLongitude = 79.9865;
  static const String nelloreLocationName = 'Nellore, AP';

  /// Surat Aquaculture Hub: Gujarat.
  static const double suratLatitude = 21.1702;
  static const double suratLongitude = 72.8311;
  static const String suratLocationName = 'Surat, GJ';

  LocationCoordinates? _overrideLocation;
  LocationCoordinates? _cachedLocation;
  DateTime? _lastGpsCheck;

  LocationService({LocationCoordinates? mockLocation})
      : _overrideLocation = mockLocation;

  @visibleForTesting
  void setMockLocation(LocationCoordinates? mock) {
    _overrideLocation = mock;
  }

  /// Retrieves the current device location via GPS or returns standard aquaculture fallback.
  Future<LocationCoordinates> getCurrentLocation({bool forceRefresh = false}) async {
    if (_overrideLocation != null) {
      return _overrideLocation!;
    }

    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return _buildFallback();
    }

    if (!forceRefresh && _cachedLocation != null && _lastGpsCheck != null) {
      if (DateTime.now().difference(_lastGpsCheck!) < const Duration(minutes: 5)) {
        return _cachedLocation!;
      }
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!serviceEnabled) {
        return _buildFallback('Location Services Disabled (Bhimavaram, AP)');
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          return _buildFallback('Location Permission Denied (Bhimavaram, AP)');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _buildFallback('Location Permission Denied (Bhimavaram, AP)');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      ).timeout(const Duration(seconds: 3));

      final district = await _resolveDistrict(position.latitude, position.longitude);

      final loc = LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        accuracy: position.accuracy,
        locationName: district,
        isFallback: false,
      );

      _cachedLocation = loc;
      _lastGpsCheck = DateTime.now();
      return loc;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocationService: Failed to get GPS position ($e), using default fallback.');
      }
      return _buildFallback();
    }
  }

  LocationCoordinates _buildFallback([String locationName = defaultLocationName]) {
    return LocationCoordinates(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      altitude: 5.0,
      accuracy: 50.0,
      locationName: locationName,
      isFallback: true,
    );
  }

  /// Resolves the human-readable district/hub based on geographic coordinates.
  Future<String> _resolveDistrict(double lat, double lon) async {
    // Proximity checks for prominent aquaculture hubs
    if ((lat - defaultLatitude).abs() < 0.6 && (lon - defaultLongitude).abs() < 0.6) {
      return 'Bhimavaram, West Godavari';
    }
    if ((lat - nelloreLatitude).abs() < 0.8 && (lon - nelloreLongitude).abs() < 0.8) {
      return 'Nellore, Andhra Pradesh';
    }
    if ((lat - 16.9891).abs() < 0.6 && (lon - 82.2475).abs() < 0.6) {
      return 'Kakinada, East Godavari';
    }
    if ((lat - 16.1876).abs() < 0.6 && (lon - 81.1389).abs() < 0.6) {
      return 'Machilipatnam, Krishna';
    }
    if ((lat - suratLatitude).abs() < 1.0 && (lon - suratLongitude).abs() < 1.0) {
      return 'Surat, Gujarat';
    }

    // Attempt lightweight reverse geocode via OpenStreetMap Nominatim
    try {
      final res = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon'),
        headers: {'User-Agent': 'PrawnGuardApp/1.0'},
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final district = address['state_district'] ?? address['county'] ?? address['city'] ?? address['town'];
          final state = address['state'] ?? 'India';
          if (district != null) {
            return '$district, $state';
          }
        }
      }
    } catch (_) {}

    return '${lat.toStringAsFixed(3)}°N, ${lon.toStringAsFixed(3)}°E';
  }

  /// Returns current coordinates as a simple map with 'lat' and 'lon'.
  Future<Map<String, double>> getCurrentCoordinates() async {
    final location = await getCurrentLocation();
    return {
      'lat': location.latitude,
      'lon': location.longitude,
      'latitude': location.latitude,
      'longitude': location.longitude,
    };
  }

  /// Returns the human-readable name of the current aquaculture location.
  Future<String> getCurrentLocationName() async {
    final location = await getCurrentLocation();
    return location.locationName;
  }
}
