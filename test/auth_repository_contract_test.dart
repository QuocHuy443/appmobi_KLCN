import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:appmobi/data/repositories/auth_repository_impl.dart';
import 'package:appmobi/presentation/viewmodels/auth_viewmodel.dart';
import 'package:appmobi/domain/repositories/auth_repository.dart';
import 'package:appmobi/domain/entities/user.dart';

class FailingWriteStorage extends FlutterSecureStorage {
  @override
  Future<void> write(
      {required String key,
      required String? value,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    throw PlatformException(code: 'locked');
  }
}

class DeferredRepository implements AuthRepository {
  final result = Completer<User>();
  @override
  Future<User> login(String identifier, String password) => result.future;
  @override
  Future<void> logout() async {}
  @override
  Future<User?> restoreSession() async => null;
  @override
  Future<User> register(
          {required String name,
          required String phone,
          required String birthDate,
          required String gender,
          required String password,
          String email = ''}) =>
      throw UnimplementedError();
}

class ContractAdapter implements HttpClientAdapter {
  final List<RequestOptions> calls = [];
  Map<String, dynamic> Function(RequestOptions)? respond;
  int status = 200;
  DioExceptionType? failure;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(options);
    if (failure != null) {
      throw DioException(requestOptions: options, type: failure!);
    }
    final data = respond!(options);
    return ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FlutterSecureStorage storage;
  late ContractAdapter adapter;
  late AuthRepositoryImpl repository;
  late Dio dio;
  final now = DateTime.utc(2026, 10, 28);
  final expiry = now.millisecondsSinceEpoch ~/ 1000 + 3600;
  Map<String, dynamic> contract() => {
        'success': true,
        'access_token': 'unit-signed-token',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'expires_at': expiry,
        'user': {
          'account_id': 11,
          'patient_id': 101,
          'role': 'BENHNHAN',
          'name': 'Test Patient',
          'email': 'patient@example.test',
          'phone': '0912345678',
          'patient_code': 'BN_TEST'
        }
      };
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    adapter = ContractAdapter();
    adapter.respond = (request) =>
        request.path.endsWith('/logout') ? {'success': true} : contract();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001'))
      ..httpClientAdapter = adapter;
    repository =
        AuthRepositoryImpl(secureStorage: storage, dio: dio, now: () => now);
  });

  test('login/register share backend contract and distinct account/patient IDs',
      () async {
    final user = await repository.login('patient', 'Secret123!');
    expect(user.id, '101');
    expect(user.accountId, '11');
    expect(adapter.calls.last.path, '/api/v1/mobile/auth/login');
    final stored =
        jsonDecode((await storage.read(key: 'mobile_session_v1'))!) as Map;
    expect(stored['token'], 'unit-signed-token');
    expect(stored['expires_at'], expiry);
    expect(await storage.read(key: 'auth_token'), isNull);
    await repository.register(
        name: 'Test Patient',
        phone: '0912345678',
        birthDate: '1990-01-02',
        gender: 'Nam',
        password: 'Secret123!');
    expect(adapter.calls.last.path, '/api/v1/mobile/auth/register');
    expect(adapter.calls.last.data.toString(), contains('ngay_sinh'));
  });
  test('restore always calls me and sends bearer token', () async {
    await repository.login('patient', 'Secret123!');
    final user = await repository.restoreSession();
    expect(user?.accountId, '11');
    expect(adapter.calls.last.path, '/api/v1/mobile/auth/me');
    expect(adapter.calls.last.headers['Authorization'],
        'Bearer unit-signed-token');
  });
  test('expired local session never restores user', () async {
    await storage.write(
        key: 'mobile_session_v1',
        value: jsonEncode({'token': 'old', 'expires_at': expiry - 7200}));
    expect(await repository.restoreSession(), isNull);
    expect(adapter.calls, isEmpty);
    expect(await storage.read(key: 'mobile_session_v1'), isNull);
  });
  test('server expired/locked/wrong role clears secure session', () async {
    for (final status in [401, 403]) {
      adapter.status = 200;
      await repository.login('patient', 'Secret123!');
      adapter.status = status;
      adapter.respond = (_) => {
            'success': false,
            'error_code': 'ACCOUNT_UNAVAILABLE',
            'message': 'Unavailable'
          };
      await expectLater(
          repository.restoreSession(), throwsA(isA<AuthRepositoryException>()));
      expect(await storage.read(key: 'mobile_session_v1'), isNull);
      adapter.respond = (_) => contract();
    }
  });
  test('network timeout does not restore identity or erase retry credentials',
      () async {
    await repository.login('patient', 'Secret123!');
    adapter.failure = DioExceptionType.receiveTimeout;
    await expectLater(
        repository.restoreSession(),
        throwsA(isA<AuthRepositoryException>()
            .having((e) => e.code, 'code', 'TIMEOUT')));
    expect(await storage.read(key: 'mobile_session_v1'), isNotNull);
    expect(dio.options.connectTimeout, const Duration(seconds: 15));
    expect(dio.options.receiveTimeout, const Duration(seconds: 15));
    expect(dio.options.followRedirects, isFalse);
  });
  test('invalid IDs/role/expiry never produce a saved authenticated session',
      () async {
    for (final field in ['patient_id', 'account_id', 'role']) {
      adapter.respond = (_) {
        final data = contract();
        (data['user'] as Map)[field] = field == 'role' ? 'ADMIN' : 0;
        return data;
      };
      await expectLater(repository.login('patient', 'Secret123!'),
          throwsA(isA<AuthRepositoryException>()));
      expect(await storage.read(key: 'mobile_session_v1'), isNull);
    }
    adapter.respond = (_) => contract()..['expires_at'] = 1;
    await expectLater(repository.login('patient', 'Secret123!'),
        throwsA(isA<AuthRepositoryException>()));
  });
  test(
      'offline logout clears identity, queues token and retries server revocation',
      () async {
    final viewModel = AuthViewModel(authRepository: repository);
    await viewModel.login('patient', 'Secret123!');
    adapter.failure = DioExceptionType.connectionError;
    await viewModel.logout();
    expect(viewModel.currentUser, isNull);
    expect(viewModel.errorMessage, contains('Chưa kết nối'));
    expect(await storage.read(key: 'mobile_session_v1'), isNull);
    expect(await storage.read(key: 'mobile_pending_logout_v1'),
        contains('unit-signed-token'));
    adapter.failure = null;
    expect(await repository.restoreSession(), isNull);
    expect(adapter.calls.last.path, '/api/v1/mobile/auth/logout');
    expect(jsonDecode((await storage.read(key: 'mobile_pending_logout_v1'))!),
        isEmpty);
  });
  test('online logout revokes on backend before reporting completion',
      () async {
    await repository.login('patient', 'Secret123!');
    await repository.logout();
    expect(adapter.calls.last.path, '/api/v1/mobile/auth/logout');
    expect(await storage.read(key: 'mobile_session_v1'), isNull);
  });
  test('duplicate registration error preserves stable backend code', () async {
    adapter.status = 409;
    adapter.respond = (_) =>
        {'success': false, 'error_code': 'ACCOUNT_EXISTS', 'message': 'Exists'};
    await expectLater(
        repository.register(
            name: 'Test Patient',
            phone: '0912345678',
            birthDate: '1990-01-02',
            gender: 'Nam',
            password: 'Secret123!'),
        throwsA(isA<AuthRepositoryException>()
            .having((e) => e.code, 'code', 'ACCOUNT_EXISTS')
            .having((e) => e.statusCode, 'status', 409)));
  });
  test('secure storage failure never reports successful login', () async {
    final repo = AuthRepositoryImpl(
        secureStorage: FailingWriteStorage(), dio: dio, now: () => now);
    final model = AuthViewModel(authRepository: repo);
    await model.login('patient', 'Secret123!');
    expect(model.currentUser, isNull);
    expect(model.errorMessage, contains('secure storage'));
    expect(await storage.read(key: 'mobile_session_v1'), isNull);
  });
  test('late login response cannot overwrite a newer logout', () async {
    final repo = DeferredRepository();
    final model = AuthViewModel(authRepository: repo);
    final pending = model.login('patient', 'Secret123!');
    await model.logout();
    repo.result.complete(const User(
        id: '101',
        accountId: '11',
        name: 'Test',
        email: '',
        phone: '',
        patientCode: '',
        role: 'BENHNHAN',
        token: 'unit-token'));
    await pending;
    expect(model.currentUser, isNull);
    expect(model.isLoading, isFalse);
  });
}
