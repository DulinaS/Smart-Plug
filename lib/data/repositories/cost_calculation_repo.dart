import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/config/env.dart';
import '../../core/utils/error_handler.dart';
import '../models/cost_calculation.dart';

class CostCalculationRepository {
  final HttpClient _http;

  CostCalculationRepository(this._http);

  /// Calculate cost for a device within a date range
  /// [deviceId] - The device ID (e.g., "LivingRoomESP32")
  /// [startDate] - Start date in YYYY-MM-DD format
  /// [endDate] - End date in YYYY-MM-DD format
  Future<CostCalculationResult> calculateCost({
    required String deviceId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _http.dio.post(
        AppConfig.costCalculateEndpoint,
        data: {
          'deviceId': deviceId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      dynamic body = res.data;

      // Unwrap common API Gateway shapes
      if (body is String) {
        body = json.decode(body);
      }
      if (body is Map && body['body'] != null) {
        body = body['body'];
        if (body is String) body = json.decode(body);
      }

      // The response has a 'data' field containing the actual result
      if (body is Map && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;
        return CostCalculationResult.fromJson(data);
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw ErrorHandler.handleDeviceError(e);
    } catch (e) {
      throw ErrorHandler.handleException(e, context: 'Calculate cost');
    }
  }
}

// Provider for the repository
final costCalculationRepositoryProvider = Provider<CostCalculationRepository>((
  ref,
) {
  return CostCalculationRepository(ref.watch(httpClientProvider));
});
