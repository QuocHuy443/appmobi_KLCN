import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:appmobi/screens/forgot_password_screen.dart';
import 'package:appmobi/screens/home_screen.dart';
import 'package:appmobi/services/auth_service.dart';
import 'package:appmobi/services/patient_api_service.dart';
import 'package:appmobi/widgets/upcoming_appointment_widget.dart';
import 'auth_repository_contract_test.dart' show ContractAdapter;

class _StubAuthRepository implements AuthRepository {
  @override
  Future<User> login(String identifier, String password) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<User> register({
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String password,
    String email = '',
  }) =>
      throw UnimplementedError();

  @override
  Future<User?> restoreSession() async => null;
}

void main() {
  testWidgets(
      'UpcomingAppointmentWidget renders department fallback and formatted date in card and dialog',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UpcomingAppointmentWidget(
            appointment: {
              'ma_lich_hen': 'LH-001',
              'ten_chuyen_khoa': 'Tim mạch',
              'ten_bac_si': 'BS. Nguyễn Văn A',
              'ngay_hen': '2026-11-25',
              'gio_hen_short': '08:30',
              'trang_thai': 'Đã xác nhận',
              'ly_do': 'Khám định kỳ',
            },
          ),
        ),
      ),
    );

    expect(find.text('Tim mạch'), findsOneWidget);
    expect(find.textContaining('25/11/2026'), findsOneWidget);

    await tester.tap(find.text('Chi tiết'));
    await tester.pumpAndSettle();

    expect(find.text('Tim mạch'), findsWidgets);
    expect(find.text('25/11/2026'), findsOneWidget);
    expect(find.text('BS. Nguyễn Văn A'), findsOneWidget);
  });

  testWidgets(
      'ForgotPasswordScreen displays H2T Healthcare branding and email/OTP guidance',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(authRepository: _StubAuthRepository()),
        child: const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );

    expect(find.text('H2T Care'), findsNothing);
    expect(find.text('H2T Healthcare'), findsNWidgets(2));
    expect(find.textContaining('chưa cập nhật email'), findsOneWidget);
  });

  testWidgets(
      'HomeScreen renders public feedbacks safely without null or overflow errors',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = ContractAdapter()
      ..respond = (_) => {
            'success': true,
            'banners': [],
            'departments': [],
            'doctors': [],
            'pricing_preview': [],
            'articles': [],
            'handbooks': [],
            'categories': [],
            'feedbacks': [
              {
                'ten_benh_nhan':
                    'Nguyễn Thị Hương Giang Rất Dài Để Kiểm Tra Tràn Dòng',
                'diem_danh_gia': '5',
                'chu_de': 'Chất lượng khám bệnh và thái độ phục vụ',
                'noi_dung': 'Bác sĩ tư vấn tận tình, quy trình nhanh gọn.',
                'ngay_tao': '2026-11-18',
              },
              {
                'ten_benh_nhan': null,
                'diem_danh_gia': null,
                'chu_de': null,
                'noi_dung': null,
                'ngay_tao': null,
              },
            ],
          };
    final api = PatientApiService(
      dio: Dio(BaseOptions(baseUrl: 'http://127.0.0.1:5000'))
        ..httpClientAdapter = adapter,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(authRepository: _StubAuthRepository()),
        child: MaterialApp(
          home: HomeScreen(api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đánh giá từ bệnh nhân'), findsOneWidget);
    expect(
      find.text('Nguyễn Thị Hương Giang Rất Dài Để Kiểm Tra Tràn Dòng'),
      findsOneWidget,
    );
    expect(find.text('Bệnh nhân'), findsOneWidget);
    expect(find.text('Bác sĩ tư vấn tận tình, quy trình nhanh gọn.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
