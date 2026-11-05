# Hướng dẫn Cài đặt và Khởi chạy Ứng dụng Di động H2T Healthcare

Tài liệu này cung cấp toàn bộ quy trình thiết lập môi trường từ máy tính mới tinh chưa cài đặt bất kỳ công cụ nào, đến các phương thức khởi chạy đa nền tảng bằng Terminal dòng lệnh và tệp thực thi tự động.

Ứng dụng di động được xây dựng bằng Flutter, phục vụ riêng cho đối tượng bệnh nhân của Phòng khám Đa khoa Quốc tế H2T Healthcare, kết nối đồng bộ trực tiếp với hệ thống Backend Flask API và cơ sở dữ liệu Microsoft SQL Server.

## Phần 1: Cài đặt Môi trường từ Máy tính mới tinh

Nếu máy tính của bạn là máy mới hoặc chưa cài đặt các công cụ lập trình, hãy làm theo tuần tự các bước dưới đây.

### 1. Cài đặt Git
- Tải Git cho Windows tại trang chủ: https://git-scm.com/download/win
- Tiến hành cài đặt và giữ nguyên các tùy chọn mặc định.
- Kiểm tra cài đặt trong Terminal PowerShell:
```powershell
git --version
```

### 2. Cài đặt Python và Môi trường Backend
- Tải Python bản 3.10 hoặc 3.11 tại trang chủ: https://www.python.org/downloads/
- **Lưu ý quan trọng**: Khi chạy file cài đặt, nhớ tích chọn ô **"Add Python to PATH"** trước khi bấm Install.
- Cài đặt các thư viện phụ thuộc cho Backend Phòng khám:
```powershell
cd "d:\baitap\Khoa Luan\KLCN_QuanLyPhongKhamDaKhoa"
pip install flask flask-cors pyodbc pyjwt werkzeug
```
- Đảm bảo cơ sở dữ liệu SQL Server đã được cài đặt và dịch vụ SQL Server (MSSQLSERVER hoặc SQLEXPRESS) đang ở trạng thái Running.

### 3. Cài đặt Visual Studio (Dành cho việc chạy App Native trên Windows)
- Nếu bạn muốn chạy ứng dụng trực tiếp dưới dạng cửa sổ Native Windows mô phỏng điện thoại, cần cài Visual Studio:
- Tải Visual Studio Community: https://visualstudio.microsoft.com/vs/community/
- Trong trình cài đặt Visual Studio Installer, tích chọn khối công việc:
  - **Desktop development with C++** (Phát triển ứng dụng trên máy tính với C++)
- Hoàn tất cài đặt và khởi động lại máy tính nếu được yêu cầu.

### 4. Cài đặt Flutter SDK
- Tải bộ công cụ Flutter SDK mới nhất tại: https://docs.flutter.dev/get-started/install/windows
- Giải nén Flutter vào một thư mục không có dấu cách và không yêu cầu quyền Admin, ví dụ: `C:\src\flutter` hoặc `D:\baitap\LapTrinhDiDong\flutter`.
- Thêm đường dẫn `bin` của Flutter vào biến môi trường hệ thống PATH (ví dụ `D:\baitap\LapTrinhDiDong\flutter\bin`).
- Kiểm tra trạng thái môi trường bằng lệnh:
```powershell
flutter doctor
```

### 5. Cài đặt Android Studio và Tạo Máy ảo Android (AVD)
- Tải và cài đặt Android Studio: https://developer.android.com/studio
- Mở Android Studio > More Actions > SDK Manager:
  - Trong thẻ **SDK Platforms**: Tích chọn Android 13 (API 33) hoặc Android 14 (API 34).
  - Trong thẻ **SDK Tools**: Tích chọn **Android SDK Build-Tools**, **Android SDK Command-line Tools (latest)**, **Android Emulator** và **Android SDK Platform-Tools**.
  - Bấm Apply để tải về.
- Chấp nhận các điều khoản giấy phép Android bằng lệnh trong Terminal:
```powershell
flutter doctor --android-licenses
```
(Nhập `y` cho tất cả các câu hỏi).
- Tạo máy ảo điện thoại (AVD):
  - Trong Android Studio, mở **Virtual Device Manager** (Device Manager).
  - Bấm **Create Device**, chọn dòng điện thoại mong muốn (ví dụ Pixel 7 Pro hoặc Pixel 6).
  - Chọn phiên bản hệ điều hành Android (khuyến nghị Android 13 Tiramisu hoặc 14 UpsideDownCake).
  - Đặt tên máy ảo và bấm **Finish**.

## Phần 2: Khởi động Hệ thống Máy chủ Backend API

Ứng dụng di động yêu cầu hệ thống Backend Flask hoạt động để cung cấp dữ liệu bác sĩ, chuyên khoa, lịch khám và kết quả xét nghiệm.

Mở một cửa sổ Terminal riêng và chạy các lệnh sau:
```powershell
cd "d:\baitap\Khoa Luan\KLCN_QuanLyPhongKhamDaKhoa"
python app.py
```
Máy chủ sẽ lắng nghe tại cổng `http://127.0.0.1:5000`.

Bạn có thể kiểm tra nhanh trạng thái máy chủ bằng cách mở trình duyệt hoặc chạy lệnh:
```powershell
curl http://127.0.0.1:5000/api/patient/public/home
```
Nếu nhận về dữ liệu JSON chứa banners, chuyên khoa và bác sĩ thì máy chủ đã sẵn sàng 100%.

## Phần 3: Hướng dẫn Khởi chạy Ứng dụng bằng Dòng lệnh Terminal

Mở Terminal tại thư mục ứng dụng di động:
```powershell
cd "d:\baitap\Khoa Luan\appmobi_KLCN"
```
Trước khi chạy lần đầu, tải các gói thư viện cần thiết:
```powershell
flutter pub get
```

### Phương thức 1: Chạy Cửa sổ Ứng dụng Native Windows (Khung 430x880)
Đây là phương thức nhanh, mượt và tiện lợi nhất trên máy tính Windows. Ứng dụng khởi chạy bằng mã máy C++ nguyên bản, tự động căn giữa màn hình với kích thước chuẩn điện thoại `430 x 880`.

- **Chạy chế độ Debug (hỗ trợ Hot-Reload bằng phím r)**:
```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
```
- **Biên dịch bản Release tối ưu hóa tốc độ**:
```powershell
flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
```
Sau khi biên dịch xong, bạn có thể chạy trực tiếp tệp:
`build\windows\x64\runner\Release\appmobi.exe`

### Phương thức 2: Chạy trên Máy ảo Android (Android Emulator AVD)
1. Liệt kê danh sách các máy ảo đang có trên máy tính:
```powershell
flutter emulators
```
2. Khởi chạy máy ảo lên màn hình:
```powershell
flutter emulators --launch <ten_may_ao>
```
3. Kiểm tra danh sách thiết bị nhận diện:
```powershell
flutter devices
```
4. Khởi chạy ứng dụng lên máy ảo:
```powershell
flutter run -d <id_thiet_bi> --dart-define=API_BASE_URL=http://10.0.2.2:5000
```
*Lưu ý về địa chỉ mạng*: Máy ảo Android sử dụng địa chỉ mạng đặc biệt `10.0.2.2` để truy cập ngược về dịch vụ `127.0.0.1` của máy tính thật.

### Phương thức 3: Kết nối và Chạy trực tiếp trên Điện thoại Thật qua Cáp USB
1. Trên điện thoại Android thật:
   - Vào Cài đặt > Thông tin điện thoại > Chạm liên tục 7 lần vào mục **Số bản dựng (Build Number)** để kích hoạt Chế độ nhà phát triển.
   - Quay lại Cài đặt > Hệ thống > Tùy chọn nhà phát triển > Bật mục **Gỡ lỗi qua USB (USB Debugging)**.
2. Dùng cáp USB cắm nối điện thoại với máy tính. Trên màn hình điện thoại, chọn **Cho phép gỡ lỗi USB từ máy tính này**.
3. Mở Terminal kiểm tra kết nối:
```powershell
adb devices
```
(Nếu thiết bị hiện trạng thái `device` là kết nối thành công).
4. Khởi chạy ứng dụng lên điện thoại:
```powershell
flutter run -d <id_thiet_bi> --dart-define=API_BASE_URL=http://<dia_chi_ip_may_tinh>:5000
```
Trong đó `<dia_chi_ip_may_tinh>` là IP mạng Wi-Fi của máy tính (ví dụ `192.168.1.15`).

### Phương thức 4: Kết nối Điện thoại Thật Không dây qua Mạng Wi-Fi (ADB qua Wi-Fi)
1. Cắm cáp USB một lần đầu tiên để cấu hình cổng mạng:
```powershell
adb tcpip 5555
```
2. Rút cáp USB ra. Xem địa chỉ IP của điện thoại trong phần Cài đặt Wi-Fi (ví dụ `192.168.1.35`).
3. Kết nối không dây:
```powershell
adb connect 192.168.1.35:5555
```
4. Kiểm tra lại bằng lệnh `flutter devices`, sau đó chạy:
```powershell
flutter run -d 192.168.1.35:5555 --dart-define=API_BASE_URL=http://<dia_chi_ip_may_tinh>:5000
```

### Phương thức 5: Chạy dạng Ứng dụng Web Mobile trên Trình duyệt Chrome
Nếu không muốn cài đặt máy ảo Android, bạn có thể chạy ngay trên Chrome với khung nhìn điện thoại:
```powershell
flutter run -d chrome --web-renderer canvaskit --dart-define=API_BASE_URL=http://127.0.0.1:5000
```
Hoặc biên dịch gói tĩnh và mở bằng cửa sổ Chrome không có thanh điều hướng:
```powershell
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:5000
python -m http.server 8080 --directory "build\web"
```
Mở cửa sổ Chrome khung điện thoại độc lập:
```powershell
start chrome --app=http://localhost:8080 --window-size=430,880
```

## Phần 4: Khởi chạy Nhanh bằng Menu Tự động [run_app.bat]

Để không cần phải gõ các câu lệnh dài dòng trong Terminal, dự án cung cấp sẵn tệp điều khiển trung tâm:
[run_app.bat](file:///d:/baitap/Khoa%20Luan/appmobi_KLCN/run_app.bat)

Nhấp đúp chuột vào tệp `run_app.bat`, giao diện menu điều khiển sẽ xuất hiện:
```text
   HỆ THỐNG QUẢN LÝ PHÒNG KHÁM ĐA KHOA H2T HEALTHCARE
          ỨNG DỤNG DI ĐỘNG BỆNH NHÂN (FLUTTER)

 Chọn chế độ khởi chạy hoặc kiểm tra:

   [1] Mở Cửa sổ Ứng dụng Native Windows (Khung 430x880) - Khuyên dùng
   [2] Mở Cửa sổ Web Mobile độc lập qua Chrome (Khung 430x880)
   [3] Phát máy chủ Wi-Fi LAN để mở trực tiếp trên Điện thoại thật
   [4] Chạy trên Thiết bị hoặc Máy ảo Android đang kết nối
   [5] Chạy chế độ Phát triển Debug Flutter (Hỗ trợ Hot-Reload)
   [6] Khởi động riêng Máy chủ Backend Flask API (Cổng 5000)
   [7] Dọn dẹp và Biên dịch lại toàn bộ ứng dụng (Clean và Rebuild)
   [8] Thoát
```
- Khi chọn **[1]**, script sẽ tự động kiểm tra xem cổng 5000 của Backend đã chạy chưa; nếu chưa sẽ tự động kích hoạt Backend ngầm, sau đó mở ngay cửa sổ ứng dụng Native Windows giữa màn hình.
- Khi chọn **[3]**, script sẽ tự động dò tìm địa chỉ IP mạng nội bộ của bạn và in ra đường link (ví dụ `http://192.168.88.18:8080`), bạn chỉ cần lấy điện thoại kết nối cùng mạng Wi-Fi và truy cập vào link là có thể trải nghiệm ngay lập tức.

## Phần 5: Hướng dẫn Khắc phục Sự cố Thường gặp

### 1. Lỗi "flutter is not recognized as an internal or external command"
- Nguyên nhân: Thư mục `bin` của Flutter SDK chưa được thêm vào biến môi trường PATH của hệ điều hành.
- Cách xử lý: Mở Start menu > gõ "Environment Variables" > chọn "Edit the system environment variables" > Bấm nút "Environment Variables" > Tìm dòng "Path" trong mục "User variables" hoặc "System variables" > Bấm "Edit" > Bấm "New" và dán đường dẫn thư mục `bin` của Flutter vào (ví dụ `D:\baitap\LapTrinhDiDong\flutter\bin`). Khởi động lại Terminal.

### 2. Máy ảo Android không kết nối được tới Backend (Báo lỗi mạng)
- Nguyên nhân: Trong máy ảo Android, `localhost` hoặc `127.0.0.1` đại diện cho chính máy ảo đó chứ không phải máy tính chạy backend.
- Cách xử lý: Khi chạy trên máy ảo Android, luôn truyền biến:
  `--dart-define=API_BASE_URL=http://10.0.2.2:5000`

### 3. Điện thoại thật không tải được dữ liệu khi kết nối qua Wi-Fi
- Nguyên nhân: Tường lửa Windows (Windows Defender Firewall) đang chặn cổng kết nối vào máy tính từ bên ngoài.
- Cách xử lý: Mở PowerShell với quyền Administrator và cho phép mở cổng 5000 và 8080:
```powershell
netsh advfirewall firewall add rule name="H2T_Backend_Port" dir=in action=allow protocol=TCP localport=5000
netsh advfirewall firewall add rule name="H2T_MobileWeb_Port" dir=in action=allow protocol=TCP localport=8080
```

### 4. Cổng 5000 bị chiếm dụng bởi tiến trình khác
- Kiểm tra tiến trình đang chiếm cổng:
```powershell
netstat -ano | findstr ":5000 "
```
- Tắt tiến trình đó (thay `<PID>` bằng số PID hiển thị ở cột cuối):
```powershell
taskkill /PID <PID> /F
```

## Phần 6: Kiểm thử và Đảm bảo Chất lượng Mã nguồn

Dự án duy trì bộ kiểm thử tự động toàn diện cho cả ứng dụng Flutter và dịch vụ Backend:

1. **Phân tích tĩnh Flutter (Static Analysis)**:
```powershell
flutter analyze
```
*(Yêu cầu đạt chuẩn 0 issues).*

2. **Kiểm thử tự động Flutter (18/18 Unit và Widget Tests)**:
```powershell
flutter test
```
*(Bao gồm kiểm thử xác thực, phiên đăng nhập, phân quyền, cấu trúc dữ liệu bệnh nhân và chuyển đổi giao diện).*

3. **Kiểm thử tự động Backend API (14/14 Endpoint Tests)**:
```powershell
python -m unittest discover -s "d:\baitap\Khoa Luan\KLCN_QuanLyPhongKhamDaKhoa\tests" -p "test_mobile_patient_api.py"
```
*(Bao gồm kiểm thử đầy đủ các chức năng xem hồ sơ, đặt lịch khám, hủy lịch, thanh toán viện phí, lịch sử bệnh án và thông báo).*
