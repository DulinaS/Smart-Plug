class AppConfig {
  static const String apiBaseUrl = '';

  // Auth/login service
  static const String authBaseUrl =
      'https://so29fkbs68.execute-api.us-east-1.amazonaws.com/dev';

  // Control/data endpoints
  static const String controlBaseUrl =
      'https://iqb73k9a2h.execute-api.us-east-1.amazonaws.com/device';
  static const String dataBaseUrl =
      'https://glpv8i3uvc.execute-api.us-east-1.amazonaws.com/devices';

  // User Device Service
  static const String userDeviceBaseUrl =
      'https://ot7ogb06pf.execute-api.us-east-1.amazonaws.com/user-device';

  static const String scheduleBaseUrl =
      'https://6b2vmyctvb.execute-api.us-east-1.amazonaws.com/dev';

  // Convenience endpoints
  static const String latestReadingEndpoint = '$dataBaseUrl/latest';
  static const String controlEndpoint = '$controlBaseUrl/command';

  // NEW: Daily summary endpoint (POST { deviceId, date: YYYY-MM-DD })
  static const String daySummaryEndpoint = '$dataBaseUrl/day';
}
