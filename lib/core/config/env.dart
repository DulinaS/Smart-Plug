class AppConfig {
  // Keep your existing values...
  static const String apiBaseUrl = '';

  static const String authBaseUrl =
      'https://so29fkbs68.execute-api.us-east-1.amazonaws.com/dev';
  static const String deviceBaseUrl =
      'https://ay5bnhzpve.execute-api.us-east-1.amazonaws.com/dev';
  static const String controlBaseUrl =
      'https://iqb73k9a2h.execute-api.us-east-1.amazonaws.com/device';
  static const String dataBaseUrl =
      'https://glpv8i3uvc.execute-api.us-east-1.amazonaws.com/devices';
  static const String scheduleBaseUrl =
      'https://6b2vmyctvb.execute-api.us-east-1.amazonaws.com/dev';
  static const String userDeviceBaseUrl =
      'https://ot7ogb06pf.execute-api.us-east-1.amazonaws.com/user-device';

  // Convenience endpoints (existing)
  static const String latestReadingEndpoint = '$dataBaseUrl/latest';
  static const String controlEndpoint = '$controlBaseUrl/command';
}
