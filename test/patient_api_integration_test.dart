import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appmobi/services/patient_api_service.dart';
import 'auth_repository_contract_test.dart' show ContractAdapter;

void main() {
  late ContractAdapter adapter;
  late PatientApiService api;
  setUp(() {
    adapter = ContractAdapter()..respond = (_) => {'success': true};
    api = PatientApiService(
        dio: Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = adapter);
    PatientApiService.resetNotifications('token');
  });

  test('API errors never become sample data or successful mutations', () async {
    for (final code in [401, 403, 404, 405, 500, 502]) {
      adapter.status = code;
      adapter.respond = (_) => {'success': false, 'message': 'Rejected'};
      await expectLater(api.getDashboard('token'), throwsException);
      await expectLater(api.getNotifications('token'), throwsException);
      await expectLater(
          api.createAppointment(
              token: 'token',
              chuyenKhoaId: 1,
              date: '2026-11-10',
              time: '08:00',
              lyDo: 'Test'),
          throwsException);
      await expectLater(
          api.rescheduleAppointment(token: 'token', appointmentId: 7),
          throwsException);
      await expectLater(api.cancelAppointment(token: 'token', appointmentId: 7),
          throwsException);
      await expectLater(
          api.choosePrescriptionPurchaseOption(
              token: 'token', prescriptionId: 8, option: 'hospital'),
          throwsException);
      await expectLater(api.updateProfile(token: 'token'), throwsException);
      await expectLater(
          api.submitFeedback(token: 'token', noiDung: 'Test'), throwsException);
    }
    adapter.status = 200;
    await expectLater(api.cancelAppointment(token: 'token', appointmentId: 7),
        throwsException);
    adapter.failure = DioExceptionType.connectionError;
    await expectLater(api.getBookingMeta(), throwsException);
    await expectLater(api.getBilling('token'), throwsException);
    await expectLater(api.getMedicalRecords('token'), throwsException);
    expect(adapter.calls.last.headers['Authorization'], 'Bearer token');
  });

  test('read flags and live zero agree, failed writes preserve count',
      () async {
    adapter.respond = (_) => {
          'notifications': [
            {'id': 1, 'da_doc': true},
            {'id': 2, 'da_doc': '1'},
            {'id': 3, 'da_xem': 1},
            {'id': 4, 'da_doc': 0},
          ]
        };
    final items = await api.getNotifications('token');
    expect(items.where(PatientApiService.isNotificationRead).length, 3);
    expect(PatientApiService.unreadCountNotifier.value, 1);
    adapter.status = 500;
    await expectLater(
        api.markNotificationRead(token: 'token', id: 4), throwsException);
    expect(PatientApiService.unreadCountNotifier.value, 1);
    adapter.status = 200;
    adapter.respond = (_) => {'success': true, 'notifications': []};
    await api.markNotificationRead(token: 'token', markAll: true);
    expect(PatientApiService.unreadCountNotifier.value, 0);
    final write = adapter.calls.firstWhere((r) => r.method == 'POST');
    expect(write.path, '/api/v1/mobile/patient/notifications/read');
    expect(write.data, {'notification_id': 4});
  });

  test('late notifications cannot restore badge after logout', () async {
    final pending = Completer<List<Map<String, dynamic>>>();
    // Gate the response before it reaches the existing adapter.
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter;
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final items = await pending.future;
      handler.resolve(
          Response(requestOptions: options, data: {'notifications': items}));
    }));
    final request = PatientApiService(dio: dio).getNotifications('token');
    await Future<void>.delayed(Duration.zero);
    PatientApiService.resetNotifications(null);
    pending.complete([
      {'id': 10, 'da_doc': 0}
    ]);
    await request;
    expect(PatientApiService.unreadCountNotifier.value, 0);
  });
}
