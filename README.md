# Ứng dụng Di động Bệnh nhân H2T Healthcare (`appmobi_KLCN`)

Ứng dụng đa nền tảng (**Flutter**) dành riêng cho **Bệnh nhân** trong hệ sinh thái **Hệ thống Quản lý Phòng khám Đa khoa H2T Healthcare**. Ứng dụng kết nối trực tiếp với Web Backend (**Python Flask**) tại thư mục `KLCN_QuanLyPhongKhamDaKhoa` và dùng chung Cơ sở dữ liệu **Microsoft SQL Server (`quan_ly_phong_kham`)**, đảm bảo mọi thao tác đặt lịch, tra cứu bệnh án, đơn thuốc, xét nghiệm, viện phí, thông báo và góp ý đều đồng nhất theo thời gian thực giữa ứng dụng di động và Cổng Bệnh nhân trên Web.

## 1. Kiến trúc hệ thống và Cơ sở dữ liệu dùng chung

Hệ thống hoạt động theo mô hình **Client – RESTful API – Shared SQL Server Database**:

* **Ứng dụng Bệnh nhân (`appmobi_KLCN`)**: Giao diện Flutter chuẩn Material 3, đồng bộ bố cục và bảng màu Y tế (`Medical Emerald`) với giao diện Web `templates/patient/*.html`.
* **Máy chủ Web và API (`KLCN_QuanLyPhongKhamDaKhoa`)**: Cung cấp đồng thời giao diện Web quản trị/bệnh nhân và hai Blueprint REST API dành cho di động (`mobile_auth_bp` và `mobile_patient_bp`) chạy tại cổng `5000`.
* **Cơ sở dữ liệu dùng chung (`quan_ly_phong_kham` trên SQL Server)**: Gồm 27 bảng quan hệ được định nghĩa tại `database/cosodulieu.sql`. Không sử dụng dữ liệu giả lập cục bộ khi mất kết nối để đảm bảo tính toàn vẹn dữ liệu y tế.

### Bảng đối chiếu nghiệp vụ Bệnh nhân giữa App Mobile, Web Portal và SQL Server

| Phân hệ trên App | Màn hình Flutter | Giao diện Web tương ứng | Bảng SQL Server sử dụng | Mô tả nghiệp vụ chi tiết |
| :--- | :--- | :--- | :--- | :--- |
| **Xác thực và Hồ sơ lần đầu** | `auth_screen.dart`, `personal_profile_screen.dart` | `auth/login.html`, `patient/complete_profile.html` | `nguoi_dung`, `benh_nhan` | Đăng nhập bằng Tên đăng nhập hoặc Số điện thoại, đăng ký tài khoản bệnh nhân mới, lưu phiên Bearer Token bền vững và bắt buộc hoàn thiện hồ sơ lần đầu nếu thiếu thông tin cơ bản. |
| **Trang chủ Bệnh nhân và Cổng thông tin Phòng khám** | `home_screen.dart` | `home.html`, `patient/dashboard.html` | `benh_nhan`, `lich_hen`, `phieu_kham`, `thong_bao`, `banner`, `chuyen_khoa`, `dich_vu`, `bai_viet` | Kết hợp tinh gọn Trang chủ Web và Bảng điều khiển Bệnh nhân: thẻ thành viên BHYT và nhóm máu, banner phòng khám, 6 tiện ích sức khỏe nhanh, lịch hẹn sắp tới, khung tra cứu nhanh bảng giá dịch vụ theo chuyên khoa và danh sách tin tức/cẩm nang y khoa mới nhất. |
| **Tra cứu Bảng giá Dịch vụ và Viện phí** | `pricing_screen.dart` | `pricing.html` | `dich_vu`, `chuyen_khoa` | Tra cứu công khai toàn bộ bảng giá khám bệnh, xét nghiệm, chẩn đoán hình ảnh theo từng chuyên khoa; tìm kiếm nhanh tên dịch vụ; hiển thị rõ Giá gốc (chưa BHYT) và Giá sau giảm BHYT kèm nút Đặt khám trực tiếp. |
| **Tin tức và Cẩm nang Y khoa** | `articles_screen.dart` | `articles.html`, `article_detail.html` | `bai_viet`, `nhan_vien` | Đọc tin tức phòng khám, cẩm nang y tế và hướng dẫn khám bệnh; tìm kiếm và lọc theo 10 chuyên mục y khoa; xem chi tiết bài viết (tự động cộng lượt xem `luot_xem` trong CSDL) và danh sách bài viết liên quan. |
| **Đặt lịch khám theo Ca trực và Ma trận giờ** | `appointment_booking_form.dart` | `patient/booking.html` | `chuyen_khoa`, `dich_vu`, `bac_si`, `lich_lam_viec`, `ca_lam_viec`, `phong_kham`, `lich_hen` | Quy trình đặt lịch 4 bước: (1) Chọn chuyên khoa và loại hình khám kèm bảng giá; (2) Chọn ngày khám và khung giờ 30 phút chia theo 3 Ca trực (Sáng, Chiều, Tối), tự động khóa giờ không có ca trực hoặc đã kín chỗ; (3) Chọn bác sĩ trực trong ca hoặc để hệ thống tự phân công; (4) Nhập triệu chứng và xem thẻ tóm tắt phiếu hẹn trước khi xác nhận. |
| **Quản lý Lịch hẹn của tôi** | `appointment_screen.dart` | `patient/appointments.html` | `lich_hen`, `bac_si`, `chuyen_khoa`, `phong_kham`, `dich_vu` | Tìm kiếm theo mã hẹn/bác sĩ/chuyên khoa, lọc theo trạng thái (`Tất cả`, `Chờ duyệt`, `Đã xác nhận`, `Đã khám`, `Đã hủy`), nhận diện lịch hẹn do bác sĩ tạo (`Bác sĩ hẹn mới`), xem chi tiết, đổi ngày giờ khám theo ma trận ca trực và hủy lịch hẹn. |
| **Bệnh án điện tử (EMR) và Đơn thuốc** | `medical_records_screen.dart` | `patient/records.html`, `patient/prescriptions.html` | `phieu_kham`, `don_thuoc`, `chi_tiet_don_thuoc`, `thuoc`, `chi_dinh_cls` | Tra cứu lịch sử các đợt khám, chẩn đoán ICD-10, triệu chứng, kết luận điều trị, lời dặn bác sĩ, lịch hẹn tái khám, danh sách thuốc chi tiết và lựa chọn hình thức nhận thuốc (`Mua tại bệnh viện` hoặc `Tự mua ngoài`). |
| **Kết quả Xét nghiệm và CĐHA** | `test_results_screen.dart` | `patient/lab_results.html` | `chi_dinh_cls`, `ket_qua_cls`, `dich_vu`, `phieu_kham` | Thống kê tổng chỉ định, số kết quả đã hoàn thành và số đợt khám; tìm kiếm và lọc theo nhóm (`Xét nghiệm`, `Chẩn đoán hình ảnh`); xem chỉ số, khoảng tham chiếu, kết luận và xem ảnh kết quả cận lâm sàng có hỗ trợ phóng to. |
| **Thanh toán Viện phí và BHYT** | `billing_screen.dart` | `patient/billing.html` | `hoa_don`, `chi_tiet_hoa_don`, `benh_nhan` | Phân tách hóa đơn `Cần thanh toán` và `Lịch sử`, tự động hiển thị mức khấu trừ BHYT 80% (nếu bệnh nhân có thẻ BHYT hợp lệ), chi tiết từng khoản mục thu và hướng dẫn thanh toán qua VietQR hoặc quầy thu ngân. |
| **Thông báo Thời gian thực** | `notifications_screen.dart`, `notification_navigation.dart` | `patient/notifications.html`, `components/header.html` | `thong_bao` | Tự động đồng bộ chuông thông báo định kỳ mỗi 10 giây, tìm kiếm và lọc thông báo theo 4 nhóm (`Tất cả`, `Lịch hẹn và Tái khám`, `Kết quả và Khám bệnh`, `Viện phí và Đơn thuốc`), đánh dấu đã đọc từng mục hoặc tất cả, và điều hướng trực tiếp đến đúng màn hình nghiệp vụ theo trường `lien_ket`. |
| **Tài khoản và Góp ý Phản hồi** | `profile_screen.dart`, `feedback_screen.dart` | `patient/profile.html`, `patient/feedbacks.html` | `nguoi_dung`, `benh_nhan`, `gop_y_phan_hoi` | Cập nhật thông tin hành chính, tiền sử dị ứng/bệnh lý, liên hệ người thân, tải ảnh đại diện (từ thiết bị hoặc URL HTTPS), gửi đánh giá 1 đến 5 sao theo chủ đề/phiếu khám và theo dõi phản hồi từ Ban Quản lý Phòng khám. |

## 2. Danh sách REST API kết nối với Web Backend

Ứng dụng giao tiếp với Backend Flask qua các endpoint chuẩn dưới đây:

* **Cổng thông tin Công khai (`/api/v1/mobile/public`)**:
  * `GET /api/v1/mobile/public/home`: Dữ liệu Trang chủ phòng khám tinh gọn (banner, chuyên khoa, bác sĩ, bảng giá tiêu biểu, tin tức và cẩm nang y tế).
  * `GET /api/v1/mobile/public/pricing`: Toàn bộ bảng giá dịch vụ và viện phí nhóm theo chuyên khoa kèm mức giảm BHYT.
  * `GET /api/v1/mobile/public/articles`: Danh sách bài viết và cẩm nang y khoa có lọc theo chuyên mục và tìm kiếm từ khóa.
  * `GET /api/v1/mobile/public/articles/<slug>`: Chi tiết bài viết y khoa theo `slug`, tự động tăng lượt xem và trả về bài viết liên quan.
* **Xác thực (`/api/v1/mobile/auth`)**:
  * `POST /api/v1/mobile/auth/login`: Đăng nhập bệnh nhân và nhận Bearer Token.
  * `POST /api/v1/mobile/auth/register`: Đăng ký tài khoản bệnh nhân mới.
  * `GET /api/v1/mobile/auth/me`: Kiểm tra phiên đăng nhập hiện tại.
  * `POST /api/v1/mobile/auth/logout`: Đăng xuất và thu hồi phiên.
* **Nghiệp vụ Bệnh nhân (`/api/v1/mobile/patient`)**:
  * `GET /api/v1/mobile/patient/dashboard`: Dữ liệu tổng quan trang chủ bệnh nhân.
  * `GET /api/v1/mobile/patient/booking-meta`: Danh mục chuyên khoa, dịch vụ khám, bác sĩ, khung giờ và ma trận ca trực (`booking_matrix`) theo ngày và chuyên khoa.
  * `GET /api/v1/mobile/patient/appointments`: Danh sách toàn bộ lịch hẹn của bệnh nhân.
  * `POST /api/v1/mobile/patient/appointments`: Tạo lịch hẹn khám mới.
  * `PUT /api/v1/mobile/patient/appointments/<id>`: Đổi ngày giờ lịch hẹn.
  * `POST /api/v1/mobile/patient/appointments/<id>/cancel`: Hủy lịch hẹn.
  * `GET /api/v1/mobile/patient/medical-records`: Hồ sơ bệnh án điện tử, chỉ số sinh tồn và đơn thuốc.
  * `POST /api/v1/mobile/patient/prescriptions/<id>/purchase-option`: Chọn hình thức nhận thuốc (`hospital` hoặc `outside`).
  * `GET /api/v1/mobile/patient/lab-results`: Danh sách kết quả xét nghiệm và chẩn đoán hình ảnh đã duyệt.
  * `GET /api/v1/mobile/patient/lab-results/<id>/image`: Tải ảnh kết quả cận lâm sàng.
  * `GET /api/v1/mobile/patient/billing`: Danh sách hóa đơn viện phí và thông tin BHYT.
  * `POST /api/v1/mobile/patient/billing/<id>/payment-instructions`: Lấy thông tin hướng dẫn thanh toán hóa đơn.
  * `GET /api/v1/mobile/patient/notifications`: Danh sách thông báo và số lượng chưa đọc.
  * `POST /api/v1/mobile/patient/notifications/read`: Đánh dấu đã đọc một thông báo hoặc tất cả thông báo.
  * `GET` và `PUT /api/v1/mobile/patient/profile`: Xem và cập nhật hồ sơ cá nhân bệnh nhân.
  * `POST /api/v1/mobile/patient/complete-profile`: Hoàn thiện hồ sơ bệnh nhân lần đầu.
  * `POST /api/v1/mobile/patient/profile/avatar`: Tải lên ảnh đại diện bệnh nhân.
  * `GET` và `POST /api/v1/mobile/patient/feedbacks`: Xem lịch sử góp ý và gửi phản hồi mới.

## 3. Cấu trúc thư mục dự án

Dự án đã được làm sạch toàn bộ các thư mục thừa, chỉ giữ lại kiến trúc cốt lõi rõ ràng và dễ bảo trì:

```text
appmobi_KLCN/
├── android/                                # Cấu hình biên dịch Android
├── ios/                                    # Cấu hình biên dịch iOS
├── web/                                    # Cấu hình biên dịch Web
├── windows/                                # Cấu hình biên dịch Windows Desktop
├── lib/
│   ├── main.dart                           # Điểm khởi chạy ứng dụng và cấu hình Provider
│   ├── core/
│   │   ├── app_colors.dart                 # Bảng màu chuẩn Y tế H2T Healthcare
│   │   └── patient_format.dart             # Định dạng ngày giờ và tiền tệ VNĐ
│   ├── services/
│   │   ├── auth_service.dart               # Quản lý phiên đăng nhập và Bearer Token
│   │   ├── patient_api_service.dart        # Kết nối REST API và đồng bộ thông báo thời gian thực
│   │   └── notification_navigation.dart    # Điều hướng thông minh từ liên kết thông báo
│   ├── screens/
│   │   ├── main_navigation_screen.dart     # Khung điều hướng chính và kiểm tra hồ sơ lần đầu
│   │   ├── main_layout.dart                # Thanh điều hướng 4 phân hệ chính và bộ lắng nghe thông báo
│   │   ├── auth_screen.dart                # Màn hình Đăng nhập và Đăng ký bệnh nhân
│   │   ├── home_screen.dart                # Trang chủ kết hợp Bảng điều khiển Bệnh nhân, Bảng giá và Tin tức
│   │   ├── pricing_screen.dart             # Tra cứu Bảng giá Dịch vụ và Viện phí kèm mức giảm BHYT
│   │   ├── articles_screen.dart            # Chuyên mục Tin tức, Cẩm nang Y khoa và Đọc bài viết chi tiết
│   │   ├── appointment_screen.dart         # Đặt lịch khám mới và Quản lý lịch hẹn của tôi
│   │   ├── medical_records_screen.dart     # Hồ sơ bệnh án điện tử, Đơn thuốc và Sinh hiệu
│   │   ├── test_results_screen.dart        # Kết quả Xét nghiệm và Chẩn đoán hình ảnh
│   │   ├── billing_screen.dart             # Thanh toán Viện phí và Khấu trừ BHYT
│   │   ├── notifications_screen.dart       # Trung tâm Thông báo phân loại theo danh mục
│   │   ├── profile_screen.dart             # Menu Tài khoản cá nhân và tiện ích
│   │   ├── personal_profile_screen.dart    # Cập nhật thông tin cá nhân, BHYT, tiền sử và ảnh đại diện
│   │   └── feedback_screen.dart            # Hòm thư Góp ý và Phản hồi chất lượng dịch vụ
│   └── widgets/
│       ├── appointment_booking_form.dart   # Biểu mẫu đặt lịch 4 bước theo ca trực và ma trận giờ
│       ├── header_widget.dart              # Thanh tiêu đề trang chủ, hotline và chuông thông báo
│       ├── vip_card_widget.dart            # Thẻ thông tin BHYT và nhóm máu
│       ├── quick_services_widget.dart      # Lưới tiện ích sức khỏe và bảng chỉ số sinh tồn
│       ├── upcoming_appointment_widget.dart# Thẻ lịch khám sắp tới trên trang chủ
│       └── request_error.dart              # Khung hiển thị lỗi kết nối và nút thử lại
├── test/                                   # Bộ 18 bài kiểm thử tự động (Unit, Contract và Widget Tests)
├── pubspec.yaml                            # Khai báo thư viện và tài nguyên
├── run_app.bat                             # Script tự động bật Backend Flask và chạy App trên Chrome
└── README.md                               # Tài liệu hướng dẫn cài đặt và vận hành
```

## 4. Yêu cầu môi trường trước khi cài đặt

1. **Cơ sở dữ liệu Microsoft SQL Server**:
   * Đã cài đặt SQL Server và chạy script `database/cosodulieu.sql` (kèm `database/seed_full_data.sql` nếu cần dữ liệu mẫu) trong thư mục dự án Web `KLCN_QuanLyPhongKhamDaKhoa` để khởi tạo CSDL `quan_ly_phong_kham`.
   * Kiểm tra thông số kết nối SQL Server trong file `KLCN_QuanLyPhongKhamDaKhoa/config.py` (`DB_SERVER`, `DB_NAME = 'quan_ly_phong_kham'`, `DB_USER`, `DB_PASSWORD`).
2. **Backend Web (`KLCN_QuanLyPhongKhamDaKhoa`)**:
   * Đã cài đặt Python 3.10 trở lên và các thư viện trong `requirements.txt` (`flask`, `pyodbc`, `werkzeug`, `pillow`).
3. **Flutter SDK**:
   * Flutter SDK phiên bản 3.x trở lên (ví dụ trên máy hiện tại: `D:\baitap\LapTrinhDiDong\flutter\bin\flutter.bat`).

## 5. Hướng dẫn khởi chạy Backend và Ứng dụng trên Máy tính (PC / Laptop)

### Bước 1: Khởi chạy máy chủ Backend Flask (Cổng 5000)

Mở PowerShell hoặc Command Prompt, di chuyển tới thư mục dự án Web và chạy `app.py`:

```powershell
cd "D:\baitap\Khoa Luan\KLCN_QuanLyPhongKhamDaKhoa"
python app.py
```

> Máy chủ Flask mặc định lắng nghe trên `http://0.0.0.0:5000` (cho phép cả máy tính cục bộ `127.0.0.1:5000` và điện thoại trong cùng mạng Wi-Fi truy cập).

### Bước 2: Chạy ứng dụng trên Máy tính

#### Cách 1: Chạy tự động bằng file `run_app.bat` (Nhanh nhất)
Nhấp đúp chuột vào file `run_app.bat` tại thư mục `d:\baitap\Khoa Luan\appmobi_KLCN` hoặc chạy trong terminal:

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
.\run_app.bat
```

Script sẽ tự động kiểm tra cổng `5000`, bật Backend Flask nếu chưa chạy, tải thư viện `flutter pub get` và mở ứng dụng trên trình duyệt **Google Chrome**.

#### Cách 2: Chạy bằng dòng lệnh trên Trình duyệt Chrome hoặc Ứng dụng Windows Desktop

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
flutter pub get

# Chạy trên trình duyệt Google Chrome
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000

# Hoặc chạy dưới dạng ứng dụng Windows Desktop
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

## 6. Hướng dẫn cài đặt và chạy trên Điện thoại (Máy ảo Android và Điện thoại thật)

### Trường hợp A: Chạy trên Máy ảo Android Emulator (Android Studio)

Trên máy ảo Android Emulator, địa chỉ `10.0.2.2` được ánh xạ trực tiếp về `127.0.0.1` của máy tính chủ. Ứng dụng đã tự động cấu hình mặc định `http://10.0.2.2:5000` cho nền tảng Android:

1. Mở **Android Studio** -> **Virtual Device Manager** và khởi động một máy ảo Android (AVD).
2. Đảm bảo Backend Flask đang chạy ở cổng `5000` trên máy tính.
3. Mở terminal tại thư mục `appmobi_KLCN` và chạy:

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

### Trường hợp B: Chạy trực tiếp trên Điện thoại Android thật (Kết nối chung mạng Wi-Fi)

Khi chạy trên điện thoại thật, điện thoại cần gọi về **địa chỉ IPv4 LAN** của máy tính đang chạy Backend Flask:

#### Bước 1: Lấy địa chỉ IPv4 của máy tính
Mở PowerShell trên máy tính và chạy:

```powershell
ipconfig
```

Tìm dòng **IPv4 Address** thuộc mạng Wi-Fi đang kết nối (ví dụ: `192.168.1.15`).

#### Bước 2: Mở cổng 5000 trên Windows Firewall (nếu lần đầu kết nối từ điện thoại)
Chạy lệnh sau trong PowerShell (quyền Administrator) để cho phép điện thoại gọi vào cổng `5000`:

```powershell
New-NetFirewallRule -DisplayName "H2T Flask Backend 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

#### Bước 3: Kết nối điện thoại và chạy ứng dụng
1. Bật **Chế độ nhà phát triển (Developer Options)** và **Gỡ lỗi USB (USB Debugging)** trên điện thoại Android, sau đó cắm cáp USB vào máy tính (hoặc dùng Wireless Debugging).
2. Kiểm tra thiết bị đã nhận diện bằng lệnh `flutter devices`.
3. Chạy ứng dụng với địa chỉ IP LAN của máy tính (thay `192.168.1.15` bằng IP thực tế ở Bước 1):

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
flutter run -d <MA_THIET_BI_DIEN_THOAI> --dart-define=API_BASE_URL=http://192.168.1.15:5000
```

#### Bước 4 (Tùy chọn): Xuất file cài đặt `.apk` để cài đặt độc lập lên điện thoại
Nếu muốn đóng gói thành file `.apk` để gửi qua Zalo/Google Drive hoặc chép vào điện thoại cài đặt trực tiếp:

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.15:5000
```

Sau khi biên dịch hoàn tất, file cài đặt nằm tại:
`build/app/outputs/flutter-apk/app-release.apk`

## 7. Tài khoản Bệnh nhân mẫu và Kiểm thử tự động

### Tài khoản Bệnh nhân mẫu trong CSDL (`quan_ly_phong_kham`)
* **Tên đăng nhập / Số điện thoại**: `bn_1` hoặc `0901234561`
* **Mật khẩu**: `123456`
* Ngoài ra có thể nhấn **Đăng ký ngay** ngay trên màn hình đăng nhập của ứng dụng để tạo tài khoản bệnh nhân mới trực tiếp vào SQL Server.

### Chạy phân tích mã nguồn và kiểm thử tự động

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"

# Kiểm tra chất lượng mã nguồn (Static Analysis)
flutter analyze --no-pub

# Chạy toàn bộ 18 bài kiểm thử tự động (Unit, API Contract và Widget Tests)
flutter test --no-pub
```
