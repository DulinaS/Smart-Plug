import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../models/telemetry.dart';

class TelemetryRepository {
  final HttpClient _httpClient;

  TelemetryRepository(this._httpClient);

  Future<List<TelemetryReading>> getTelemetryData(
    String deviceId,
    DateTime startTime,
    DateTime endTime, {
    String interval = '1m',
  }) async {
    try {
      final response = await _httpClient.dio.get(
        '/devices/$deviceId/telemetry',
        queryParameters: {
          'from': startTime.toIso8601String(),
          'to': endTime.toIso8601String(),
          'interval': interval,
        },
      );

      final List<dynamic> data = response.data['telemetry'];
      return data.map((json) => TelemetryReading.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UsageSummary> getUsageSummary(
    String deviceId,
    String range, // 'today', 'week', 'month'
  ) async {
    try {
      final response = await _httpClient.dio.get(
        '/devices/$deviceId/summary',
        queryParameters: {'range': range},
      );

      return UsageSummary.fromJson(response.data['summary']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCostSummary(
    String deviceId,
    String range,
  ) async {
    try {
      final response = await _httpClient.dio.get(
        '/devices/$deviceId/cost',
        queryParameters: {'range': range},
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBillingEstimate(String month) async {
    try {
      final response = await _httpClient.dio.get(
        '/billing/estimate',
        queryParameters: {'month': month},
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 404) {
      return 'Data not found';
    } else if (e.response?.statusCode == 400) {
      return 'Invalid date range';
    } else {
      return 'Failed to load telemetry data';
    }
  }
}

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return TelemetryRepository(httpClient);
});
