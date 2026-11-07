import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/schedule.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ConductorApi {
  ConductorApi({String? baseUrl})
    : baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  static final instance = ConductorApi();
  final String baseUrl;
  String? _token;
  Driver? driver;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null || base.scheme != 'https' || base.host.isEmpty) {
      throw const ApiException(
        'Falta configurar la dirección HTTPS del servicio.',
      );
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      return await (() async {
        final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');
        final request = await client.openUrl(method, uri);
        request.followRedirects = false;
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        if (_token != null) {
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Bearer $_token',
          );
        }
        if (data != null) {
          request.headers.contentType = ContentType.json;
          request.write(jsonEncode(data));
        }
        final response = await request.close();
        final raw = await utf8.decoder.bind(response).join();
        Map<String, dynamic> json;
        try {
          json = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          throw const ApiException(
            'El servicio devolvió una respuesta inválida.',
          );
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (response.statusCode == 401) signOut();
          throw ApiException(
            json['message'] as String? ?? 'No se pudo completar la solicitud.',
            status: response.statusCode,
          );
        }
        return json;
      })().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ApiException(
        'El servicio está demorando. Intenta nuevamente.',
      );
    } on SocketException {
      throw const ApiException(
        'No se pudo conectar. Revisa tu conexión a internet.',
      );
    } on HandshakeException {
      throw const ApiException('No se pudo establecer una conexión segura.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> signIn(String username, String password) async {
    final json = await _request(
      'POST',
      '/login',
      data: {'username': username.trim(), 'password': password},
    );
    _token = json['token'] as String;
    driver = Driver.fromJson(json['driver'] as Map<String, dynamic>);
  }

  void signOut() {
    _token = null;
    driver = null;
  }

  Future<void> logout() async {
    if (_token != null) await _request('POST', '/logout');
    signOut();
  }

  Future<List<Schedule>> schedules() async {
    final json = await _request('GET', '/schedules');
    driver = Driver.fromJson(json['driver'] as Map<String, dynamic>);
    return (json['schedules'] as List)
        .map((item) => Schedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduleDetail> detail(Schedule schedule) async =>
      ScheduleDetail.fromJson(
        await _request(
          'GET',
          '/schedules/${schedule.id}?date=${schedule.serviceDate}',
        ),
      );

  Future<ScheduleDetail> start(Schedule schedule) async =>
      ScheduleDetail.fromJson(
        await _request(
          'POST',
          '/schedules/${schedule.id}/start',
          data: {'date': schedule.serviceDate},
        ),
      );
}
