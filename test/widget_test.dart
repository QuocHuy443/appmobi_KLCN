import 'package:flutter_test/flutter_test.dart';
import 'package:appmobi/main.dart';

void main() {
  testWidgets('Khách có thể mở và thoát khỏi luồng xác thực',
      (WidgetTester tester) async {
    await tester.pumpWidget(const H2THealthcareApp());
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsWidgets);

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);
    expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);

    await tester.tap(find.text('Đăng nhập / Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Thoát về trang chủ'), findsOneWidget);

    await tester.ensureVisible(find.text('Đăng ký ngay'));
    await tester.tap(find.text('Đăng ký ngay'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản bệnh nhân'), findsOneWidget);

    await tester.ensureVisible(find.text('Thoát về trang chủ'));
    await tester.tap(find.text('Thoát về trang chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Trang chủ'), findsWidgets);
  });
}
