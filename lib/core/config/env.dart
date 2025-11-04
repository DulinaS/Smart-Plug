class AppConfig {
  static const String apiBaseUrl = '';

  // Auth/login service
  static const String authBaseUrl =
      'https://so29fkbs68.execute-api.us-east-1.amazonaws.com/dev';

  // Device Service (IoT) — NOT used by the app in Option B (kept here for reference/admin tools)
  // static const String deviceBaseUrl = '...'; // unused in the app

  // Control/data endpoints if you still use them elsewhere
  static const String controlBaseUrl =
      'https://iqb73k9a2h.execute-api.us-east-1.amazonaws.com/device';
  static const String dataBaseUrl =
      'https://glpv8i3uvc.execute-api.us-east-1.amazonaws.com/devices';

  // User Device Service (used by the app)
  // POST {base}           -> link device to user
  // POST {base}/get       -> list user devices
  static const String userDeviceBaseUrl =
      'https://ot7ogb06pf.execute-api.us-east-1.amazonaws.com/user-device';

  static const String scheduleBaseUrl =
      'https://6b2vmyctvb.execute-api.us-east-1.amazonaws.com/dev';

  // Convenience endpoints (optional)
  static const String latestReadingEndpoint = '$dataBaseUrl/latest';
  static const String controlEndpoint = '$controlBaseUrl/command';
}
