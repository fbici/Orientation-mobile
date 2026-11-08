import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:orientia/core/models/academic_models.dart';
import 'package:orientia/core/network/api_client.dart';
import 'package:orientia/core/network/session_store.dart';

class MemorySessions implements SessionStore {
  String? value;
  int clears = 0, writes = 0;
  MemorySessions([this.value]);
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String text) async {
    writes++;
    value = text;
  }

  @override
  Future<void> clear() async {
    clears++;
    value = null;
  }
}

Json sessionData(
        {String user = '11111111-1111-4111-8111-111111111111',
        String access = 'access-one',
        String refresh = 'rt1-test-one'}) =>
    {
      'accessToken': access,
      'refreshToken': refresh,
      'expiresIn': 900,
      'tokenType': 'Bearer',
      'user': {
        'id': user,
        'firstName': 'Candidat de test',
        'email': 'synthetic@example.test',
        'roles': ['CANDIDAT'],
        'tenantId': '22222222-2222-4222-8222-222222222222'
      }
    };
ResponseBody jsonResponse(Object? data, [int status = 200]) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
typedef Handler = FutureOr<ResponseBody> Function(
    RequestOptions options, Stream<Uint8List>? stream);

class TestTransport implements HttpClientAdapter {
  final Handler handler;
  final calls = <RequestOptions>[];
  TestTransport(this.handler);
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    return handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

ApiClient clientFor(Handler server, {Handler? auth, MemorySessions? store}) {
  final transport = TestTransport(server),
      authentication =
          TestTransport(auth ?? (r, s) => jsonResponse(sessionData()));
  return ApiClient(
      dio: Dio()..httpClientAdapter = transport,
      authDio: Dio()..httpClientAdapter = authentication,
      storage: store ?? MemorySessions(),
      baseUrl: 'https://api.example.test');
}
