/// OrionDioInterceptor
///
/// Usage:
/// ```
/// Dio dio = Dio()
///   ..interceptors.add(OrionDioInterceptor());
/// ```
///
/// - Will automatically track request/response/errors per screen.
/// - Make sure OrionNetworkTracker.currentScreenName is always correct.
/// - Used with OrionScreenTracker + OrionFlutterPlugin.
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orion_flutter/orion_network_tracker.dart';

class OrionDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
    debugPrint("🟡 OrionDioInterceptor - onRequest: ${options.method} ${options.uri}");
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint("🟢 OrionDioInterceptor - onResponse: ${response.requestOptions.uri}");
    _track(
      response.requestOptions,
      response.statusCode ?? -1,
      payload: response.data,
      contentType: response.headers[HttpHeaders.contentTypeHeader]?.first,
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode ?? -1;
    debugPrint("🔴 OrionDioInterceptor - onError: [${err.requestOptions.method}] ${err.requestOptions.uri} | ${err.message}");
    _track(
      err.requestOptions,
      statusCode,
      error: err.message,
      contentType: err.response?.headers[HttpHeaders.contentTypeHeader]?.first,
    );
    super.onError(err, handler);
  }

  void _track(RequestOptions options, int statusCode,
      {String? error, dynamic payload, String? contentType}) {
    final startTime = options.extra['startTime'] as int?;
    final endTime = DateTime.now().millisecondsSinceEpoch;

    if (startTime == null) {
      debugPrint("⚠️ OrionDioInterceptor - Missing startTime for ${options.uri}");
      return;
    }

    final duration = endTime - startTime;
    final screen = OrionNetworkTracker.currentScreenName ?? "UnknownScreen";

    final payloadSize = _getPayloadSize(payload);

    debugPrint("📦 OrionDioInterceptor - Tracking network request:");
    debugPrint("🔹 OrionDioInterceptor Screen: $screen");
    debugPrint("🔹 OrionDioInterceptor URL: ${options.uri}");
    debugPrint("🔹 OrionDioInterceptor Method: ${options.method}");
    debugPrint("🔹 OrionDioInterceptor Status: $statusCode");
    debugPrint("🔹 OrionDioInterceptor Duration: ${duration}ms");
    debugPrint("🔹 OrionDioInterceptor Payload size: $payloadSize");
    debugPrint("🔹 OrionDioInterceptor ResponseType: ${options.responseType}");
    debugPrint("🔹 OrionDioInterceptor Error: ${error ?? 'none'}");

    OrionNetworkTracker.addRequest(screen, {
      "method": options.method,
      "url": options.uri.toString(),
      "statusCode": statusCode,
      "startTime": startTime,
      "endTime": endTime,
      "duration": duration,
      "payloadSize": payloadSize,
      "contentType": contentType,
      "responseType": options.responseType.toString(),
      "errorMessage": error,
    });
  }

  int? _getPayloadSize(dynamic data) {
    if (data == null) return null;
    if (data is List<int>) return data.length;
    if (data is String) return data.length;
    if (data is Map || data is List) return data.toString().length;
    return null;
  }
}