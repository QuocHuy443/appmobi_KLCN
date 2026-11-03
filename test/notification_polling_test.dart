import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobi/screens/main_navigation_screen.dart';
import 'package:appmobi/services/auth_service.dart';
import 'package:appmobi/services/patient_api_service.dart';
import 'auth_repository_contract_test.dart' show DeferredRepository;

class PollingApi extends PatientApiService {
  int calls = 0;
  Completer<List<Map<String, dynamic>>>? pending;
  List<Map<String, dynamic>> items = [
    {'id': 1, 'da_doc': 0}
  ];

  @override
  Future<List<Map<String, dynamic>>> getNotifications(String token, {String tab = 'all', bool unreadOnly = false}) async {
    calls++;
    if (pending != null) return pending!.future;
    return items;
  }
}

void main() {
  testWidgets(
      'poll once, deduplicate sound, discard logout response, dispose timers',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var sounds = 0;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemSound.play') sounds++;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final repository = DeferredRepository();
    final auth = AuthViewModel(authRepository: repository);
    final login = auth.login('test', 'secret');
    repository.result.complete(const User(
        id: '101',
        accountId: '11',
        name: 'Test',
        email: '',
        phone: '',
        patientCode: 'BN101',
        role: 'BENHNHAN',
        token: 'token'));
    await login;
    final api = PollingApi();
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(home: MainNavigationScreen(apiService: api))));
    await tester.pump();
    expect(api.calls, 1);
    expect(sounds, 0); // Existing notifications are only a baseline.
    api.items = [
      {'id': 1, 'da_doc': 0},
      {'id': '2', 'da_doc': 0, 'tieu_de': 'New'}
    ];
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(sounds, 1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(sounds, 1);
    api.pending = Completer<List<Map<String, dynamic>>>();
    await tester.pump(const Duration(seconds: 5));
    final calls = api.calls;
    await tester.pump(const Duration(seconds: 15));
    expect(api.calls, calls); // No overlapping requests.
    await auth.logout();
    api.pending!.complete([
      {'id': 3, 'da_doc': 0}
    ]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(sounds, 1);
    expect(api.calls, calls);
    expect(PatientApiService.unreadCountNotifier.value, 0);
    api.pending = null;
    await auth.login('test', 'secret');
    await tester.pump();
    await tester.pump();
    final beforeDispose = api.calls;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(api.calls, beforeDispose);
    expect(tester.takeException(), isNull);
  });
}
