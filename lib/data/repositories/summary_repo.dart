import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/http_client.dart';
import '../../core/config/env.dart';
import '../models/daily_summary.dart';

class SummaryRepository {
  final HttpClient _http;

  SummaryRepository(this._http);

  // date must be YYYY-MM-DD (UTC)
  Future<DailySummary?> getDailySummary({
    required String deviceId,
    required String date,
  }) async {
    try {
      final res = await _http.dio.post(
        AppConfig.daySummaryEndpoint,
        data: {'deviceId': deviceId, 'date': date},
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

      if (body is Map &&
          body['records'] is List &&
          (body['records'] as List).isNotEmpty) {
        final record = (body['records'] as List).first as Map<String, dynamic>;
        return DailySummary.fromRecord(record);
      }
      return null;
    } on DioException catch (e) {
      // Treat 404 / “No records” as no data (null), not a hard error
      final code = e.response?.statusCode ?? 0;
      final msg = e.response?.data?.toString().toLowerCase() ?? '';
      if (code == 404 || msg.contains('no records')) {
        return null;
      }
      rethrow;
    }
  }
}

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  final http = ref.read(httpClientProvider);
  return SummaryRepository(http);
});
