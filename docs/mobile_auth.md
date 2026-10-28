# Mobile auth

Hợp đồng Backend và cấu hình MSSQL test an toàn: [Mobile auth v1](../../../KLCN_QuanLyPhongKhamDaKhoa/docs/mobile_auth_contract.md).

Không dùng tài khoản demo trong README cũ làm bằng chứng đăng nhập. API_BASE_URL phải trỏ đến Backend được phép; release dùng HTTPS. Debug emulator mặc định http://10.0.2.2:5000, server MSSQL test riêng được hướng dẫn ở cổng 5001.

```powershell
flutter --no-version-check test --no-pub test/auth_repository_contract_test.dart test/widget_test.dart
flutter --no-version-check analyze --no-pub lib/data/repositories/auth_repository_impl.dart lib/presentation/viewmodels/auth_viewmodel.dart lib/screens/profile/profile_screen.dart test/auth_repository_contract_test.dart
flutter run --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:5001
```

Không cần pub get/upgrade cho thay đổi này. Không tự cài Android SDK hoặc chạy clean. Lệnh run cần SDK/thiết bị đã có, Backend test được xác nhận và schema test phù hợp. Hiện Android build bị chặn do thiếu Android SDK; bundle host Windows đã biên dịch được. Unit test dùng Dio/secure-storage mock không chứng minh Keychain/Keystore, đăng nhập E2E hoặc MSSQL thật.

Files: [AuthRepositoryImpl](../lib/data/repositories/auth_repository_impl.dart), [AuthViewModel](../lib/presentation/viewmodels/auth_viewmodel.dart), [ProfileScreen](../lib/screens/profile/profile_screen.dart), [repository tests](../test/auth_repository_contract_test.dart). Android main/debug manifest chỉ thêm quyền Internet, tắt backup và cho HTTP ở debug; không tắt TLS.
