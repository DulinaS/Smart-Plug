import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// Centralized error handler that converts technical errors into user-friendly messages
class ErrorHandler {
  /// Converts DioException to user-friendly error message
  static String handleDioError(DioException e, {String? context}) {
    // Network-related errors
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection and try again.';
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server is taking too long to respond. Please try again later.';
    }

    if (e.type == DioExceptionType.sendTimeout) {
      return 'Failed to send request. Please check your internet connection.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Check for specific network errors
    if (e.error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }

    if (e.error is HttpException) {
      return 'Network error occurred. Please try again.';
    }

    // Handle HTTP status codes
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      // Try to extract error message from response
      String? serverMessage;
      if (responseData is Map<String, dynamic>) {
        serverMessage = responseData['message'] as String?;
      }

      switch (statusCode) {
        case 400:
          return serverMessage ??
              'Invalid request. Please check your input and try again.';
        case 401:
          return serverMessage ?? 'Session expired. Please login again.';
        case 403:
          return serverMessage ??
              'Access denied. You don\'t have permission to perform this action.';
        case 404:
          return serverMessage ?? '${context ?? 'Resource'} not found.';
        case 409:
          return serverMessage ??
              'This operation conflicts with existing data.';
        case 422:
          return serverMessage ??
              'Invalid data provided. Please check your input.';
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        case 500:
          return 'Server error occurred. Please try again later.';
        case 502:
          return 'Service temporarily unavailable. Please try again later.';
        case 503:
          return 'Service is currently unavailable. Please try again later.';
        case 504:
          return 'Server timeout. Please try again later.';
        default:
          if (statusCode != null && statusCode >= 500) {
            return 'Server error occurred. Please try again later.';
          }
          return serverMessage ?? 'An error occurred. Please try again.';
      }
    }

    // Handle cancellation
    if (e.type == DioExceptionType.cancel) {
      return 'Request was cancelled.';
    }

    // Generic fallback
    return 'Unable to complete request. Please check your connection and try again.';
  }

  /// Handles authentication-specific errors
  static String handleAuthError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      // Extract server message
      String? serverMessage;
      if (data is Map<String, dynamic>) {
        serverMessage = data['message'] as String?;
      }

      switch (statusCode) {
        case 400:
          return serverMessage ?? 'Please check your email and password.';
        case 401:
          return serverMessage ??
              'Invalid email or password. Please try again.';
        case 409:
          if (serverMessage?.toLowerCase().contains('already exists') ??
              false) {
            return 'An account with this email already exists.';
          }
          return serverMessage ?? 'User already exists.';
        case 422:
          return serverMessage ?? 'Invalid email or password format.';
        default:
          if (serverMessage != null) {
            // Check for specific auth errors
            if (serverMessage.contains('UserNotConfirmedException') ||
                serverMessage.toLowerCase().contains('not verified') ||
                serverMessage.toLowerCase().contains('not confirmed')) {
              return 'Please verify your email before logging in.';
            }
            if (serverMessage.contains('UserNotFoundException')) {
              return 'No account found with this email.';
            }
            if (serverMessage.contains('NotAuthorizedException')) {
              return 'Invalid email or password.';
            }
            if (serverMessage.contains('CodeMismatchException')) {
              return 'Invalid verification code. Please try again.';
            }
            if (serverMessage.contains('ExpiredCodeException')) {
              return 'Verification code has expired. Please request a new one.';
            }
            if (serverMessage.contains('LimitExceededException')) {
              return 'Too many attempts. Please try again later.';
            }
            if (serverMessage.contains('InvalidPasswordException')) {
              return 'Password must be at least 8 characters with uppercase, lowercase, and numbers.';
            }
            // Return cleaned server message (remove technical prefixes)
            return serverMessage
                .replaceAll('Exception', '')
                .replaceAll('Error:', '')
                .trim();
          }
      }
    }

    // Use generic DioError handler
    return handleDioError(e, context: 'Authentication');
  }

  /// Handles device-specific errors
  static String handleDeviceError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String? serverMessage;
      if (data is Map<String, dynamic>) {
        serverMessage = data['message'] as String?;
      }

      switch (statusCode) {
        case 404:
          return serverMessage ??
              'Device not found. Please check the device ID.';
        case 409:
          return serverMessage ??
              'Device is offline or busy. Please try again.';
        case 422:
          return serverMessage ?? 'Invalid device data provided.';
        default:
          if (serverMessage != null) return serverMessage;
      }
    }

    return handleDioError(e, context: 'Device');
  }

  /// Handles control/command errors
  static String handleControlError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      String? serverMessage;
      if (data is Map<String, dynamic>) {
        serverMessage = data['message'] as String?;
      }

      switch (statusCode) {
        case 404:
          return 'Device not found. Please refresh your device list.';
        case 409:
          return 'Device is currently offline or busy.';
        case 400:
          return serverMessage ?? 'Invalid command. Please try again.';
        default:
          if (serverMessage != null) return serverMessage;
      }
    }

    return handleDioError(e, context: 'Device control');
  }

  /// Generic error handler for any exception
  static String handleException(Object e, {String? context}) {
    if (e is DioException) {
      return handleDioError(e, context: context);
    }

    if (e is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }

    if (e is FormatException) {
      return 'Invalid data format. Please try again.';
    }

    if (e is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    // If it's already a user-friendly string, return it
    final errorString = e.toString();
    if (!errorString.contains('Exception') &&
        !errorString.contains('Error') &&
        !errorString.startsWith('type ')) {
      return errorString;
    }

    // Generic fallback
    return '${context != null ? '$context: ' : ''}An unexpected error occurred. Please try again.';
  }
}
