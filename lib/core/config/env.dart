class AppConfig {
  // Your friend's API base URL
  static const String apiBaseUrl =
      'https://a2app1cssi.execute-api.us-east-1.amazonaws.com/dev';

  // Get these values from your friend
  static const String cognitoUserPoolId =
      'us-east-1_xxxxxxxxx'; // From your friend
  static const String cognitoClientId =
      'xxxxxxxxxxxxxxxxxxxxxxxxxx'; // From your friend
  static const String awsRegion = 'us-east-1';

  // API endpoints from your friend's backend
  static const String latestReadingEndpoint = '/latest-reading';
  static const String controlEndpoint = '/control';

  // Add other endpoints as your friend provides them
  static const String authEndpoint = '/auth'; // If exists
  static const String devicesEndpoint = '/devices'; // If exists
  static const String telemetryEndpoint = '/telemetry'; // If exists
}
