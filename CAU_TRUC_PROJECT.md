# Cấu trúc ứng dụng Flutter H2T Healthcare

## Luồng đang chạy

[lib/main.dart](lib/main.dart) tạo H2THealthcareApp, cung cấp FlutterSecureStorage, AuthRepository và AuthViewModel từ [auth_service.dart](lib/services/auth_service.dart). Khôi phục phiên dùng chính provider này. Không dùng lớp User hoặc AuthViewModel trong bộ domain/presentation cho luồng này.

Các route /login, /register mở [auth_screen.dart](lib/screens/auth_screen.dart); /home mở [main_navigation_screen.dart](lib/screens/main_navigation_screen.dart).

| Tab | Màn hình thực tế |
| --- | --- |
| Trang chủ | [home_screen.dart](lib/screens/home_screen.dart) |
| Đặt lịch | [appointment_screen.dart](lib/screens/appointment_screen.dart) |
| Hồ sơ | [medical_records_screen.dart](lib/screens/medical_records_screen.dart) |
| Tài khoản | [profile_screen.dart](lib/screens/profile_screen.dart) |

Trang chủ dùng [header_widget.dart](lib/widgets/header_widget.dart), [vip_card_widget.dart](lib/widgets/vip_card_widget.dart), [quick_services_widget.dart](lib/widgets/quick_services_widget.dart), [upcoming_appointment_widget.dart](lib/widgets/upcoming_appointment_widget.dart). Chuông và banner mở [notifications_screen.dart](lib/screens/notifications_screen.dart). Tiện ích nhanh mở bệnh án, [test_results_screen.dart](lib/screens/test_results_screen.dart) và [billing_screen.dart](lib/screens/billing_screen.dart); tài khoản cũng mở viện phí.

## Thư mục thực tế

```text
lib/
  main.dart
  core/
    app_colors.dart, app_theme.dart       # Giao diện của luồng main
    constants/, di/, theme/              # Bộ cũ, được giữ lại
  services/
    auth_service.dart
    patient_api_service.dart
    sound_service.dart                  # Conditional export
    sound_service_io.dart               # SystemSound và haptic
    sound_service_web.dart              # Web Audio qua JS interop
  screens/
    main_navigation_screen.dart
    auth_screen.dart, home_screen.dart, appointment_screen.dart
    medical_records_screen.dart, profile_screen.dart
    notifications_screen.dart, billing_screen.dart, test_results_screen.dart
    appointment/, auth/, billing/, home/, medical_records/
    notifications/, profile/, test_results/  # Bộ màn hình cũ, còn giữ
  widgets/
    header_widget.dart, vip_card_widget.dart
    quick_services_widget.dart, upcoming_appointment_widget.dart
    custom_button.dart, notification_badge_widget.dart, qr_modal_widget.dart
  domain/, data/, presentation/          # Kiến trúc khác, còn giữ
 test/
  auth_repository_contract_test.dart, widget_test.dart
  patient_api_integration_test.dart, notification_polling_test.dart
```

## Dữ liệu và thông báo

[patient_api_service.dart](lib/services/patient_api_service.dart) giữ đường dẫn /api/v1/mobile/patient/..., payload và Bearer token hiện có. Base URL tiếp tục lấy từ AuthRepositoryImpl.defaultBaseUrl và API_BASE_URL. Không thay backend. API bệnh nhân lỗi sẽ ném lỗi, không chuyển sang dữ liệu mẫu hoặc giả lập thao tác thành công. Phản hồi HTTP thành công nhưng success: false cũng được coi là thất bại. Mã BHYT và tiền bảo hiểm hiển thị từ dữ liệu trả về, không tự áp 80%.

Khung điều hướng kiểm tra thông báo mỗi 5 giây khi có phiên đăng nhập. Chỉ có một Timer định kỳ, chặn yêu cầu chồng nhau, hủy Timer/banner khi đăng xuất hoặc dispose, bỏ phản hồi của phiên cũ. Lần tải đầu làm mốc; ID đã thấy được giữ trong phiên để không phát lại âm thanh cho cùng thông báo. Banner tự đóng sau 6 giây. Các tab cập nhật dữ liệu mà giữ State và nội dung form.

Header nghe bộ đếm chưa đọc; số 0 thay thế số cũ. Các dạng da_xem/da_doc boolean, số hoặc chuỗi 1 được chuẩn hóa. Chỉ cập nhật trạng thái đọc sau khi API thành công. Âm thanh web đóng AudioContext sau khi phát, có thể bị trình duyệt chặn trước tương tác người dùng.

## Dọn mã nguồn

Đã hợp nhất và xóa 10 bản Dart ở gốc: appointment_screen.dart, billing_screen.dart, medical_records_screen.dart, notifications_screen.dart, main_navigation_screen.dart, header_widget.dart, patient_api_service.dart, sound_service.dart, sound_service_io.dart, sound_service_web.dart.

Các phần dữ liệu mẫu, cập nhật lạc quan trước khi API thành công, suy đoán tiền BHYT và suy đoán ID đơn thuốc từ ID bệnh án không được mang sang. File đích giữ API thật và xử lý lỗi.

Giữ nguyên các thư mục domain, data, presentation, màn hình thư mục con và các widget cũ: chúng còn tham chiếu nhau và chứa chức năng riêng; việc không nằm trong import graph của main chưa đủ căn cứ xóa. Không trộn provider của hai bộ. [run_app.bat](run_app.bat) không còn lệnh xóa thư mục/file nguồn khi chạy.

## Kiểm tra

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Kiểm thử API dùng adapter giả ở ranh giới HTTP để kiểm tra hợp đồng và lỗi; không phải xác minh backend thật. Kiểm thử widget kiểm tra luồng khách, vòng đời polling, chống phát âm lặp, phản hồi muộn sau đăng xuất và dispose. Chưa xác minh trên thiết bị, backend thật hoặc âm thanh trình duyệt thật.

## Danh sách file thay đổi

- Màn hình: [appointment_screen.dart](lib/screens/appointment_screen.dart), [billing_screen.dart](lib/screens/billing_screen.dart), [medical_records_screen.dart](lib/screens/medical_records_screen.dart), [notifications_screen.dart](lib/screens/notifications_screen.dart), [main_navigation_screen.dart](lib/screens/main_navigation_screen.dart).
- Nơi gọi và sửa lỗi giao diện cũ được kiểm thử phát hiện: [home_screen.dart](lib/screens/home_screen.dart), [profile_screen.dart](lib/screens/profile_screen.dart), [auth_screen.dart](lib/screens/auth_screen.dart). Xử lý lỗi tải ảnh, Material cho menu ListTile và xuống dòng trên màn hình xác thực.
- Widget/service: [header_widget.dart](lib/widgets/header_widget.dart), [patient_api_service.dart](lib/services/patient_api_service.dart), [sound_service.dart](lib/services/sound_service.dart), [sound_service_io.dart](lib/services/sound_service_io.dart), [sound_service_web.dart](lib/services/sound_service_web.dart).
- Kiểm thử thêm: [patient_api_integration_test.dart](test/patient_api_integration_test.dart), [notification_polling_test.dart](test/notification_polling_test.dart).
- Tài liệu và khởi chạy: tài liệu này, [README.md](README.md), [run_app.bat](run_app.bat).

Giữ nguyên main.dart, cấu hình API_BASE_URL, auth_service.dart, backend và các bộ kiến trúc cũ. Các cảnh báo phân tích ở presentation và màn hình thư mục con đã tồn tại trước tích hợp; không chỉnh hàng loạt các phần này.

### Kết quả xác minh sau dọn

- flutter test --no-pub: 16/16 kiểm thử qua.
- flutter analyze --no-pub: 0 error, 1 warning và 23 info đã có trước trong lib; lệnh trả exit code 1 do các chẩn đoán này. Không phát sinh chẩn đoán mới còn tồn tại từ phần tích hợp. Các lỗi của bản Dart gốc đã biến mất sau hợp nhất và xóa bản gốc.
- flutter build web --debug --no-pub: thành công, xác minh nhánh export web và JS interop. Kiểm tra thử Wasm của Flutter cảnh báo dependency flutter_secure_storage_web hiện dùng dart:html/js_util; đây không phải xác minh build Wasm.
- git diff --check: không có lỗi whitespace; Git chỉ nhắc chuyển đổi LF/CRLF trên Windows.
- Không chạy ứng dụng trên thiết bị, không kết nối backend thật và chưa nghe thử âm thanh trên trình duyệt/thiết bị.
