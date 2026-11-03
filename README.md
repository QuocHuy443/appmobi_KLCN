Thông tin cấu trúc và tích hợp hiện tại: [CAU_TRUC_PROJECT.md](CAU_TRUC_PROJECT.md). API bệnh nhân không dùng dữ liệu mẫu khi lỗi kết nối. Các tài khoản và mô tả backend dưới đây chỉ có hiệu lực nếu backend đã được chuẩn bị tương ứng.

# 🏥 ỨNG DỤNG DI ĐỘNG BỆNH NHÂN — H2T HEALTHCARE (`appmobi_KLCN-main`)

Ứng dụng di động dành riêng cho **Bệnh nhân** thuộc đề tài Khóa luận Chuyên ngành **Hệ thống Quản lý Phòng khám Đa khoa H2T Healthcare**, sử dụng chung cơ sở dữ liệu **Microsoft SQL Server (`quan_ly_phong_kham`)** với hệ thống Website (`KLCN_QuanLyPhongKhamDaKhoa-main`).

---

## 📋 1. Tổng hợp các công việc & chức năng đã thực hiện bổ sung

### A. Phía Backend Web & Cơ sở dữ liệu SQL Server (`KLCN_QuanLyPhongKhamDaKhoa-main`)
1. **Khắc phục kết nối SQL Server & Tự động khởi tạo CSDL**:
   - Cập nhật `config.py`, `core/database.py`, `models/backup_model.py` và `scratch/seed_database.py` bổ sung `TrustServerCertificate=yes;`, tự động dò ODBC Driver (`18`, `17`, `SQL Server`) và hỗ trợ cả Windows Authentication lẫn SQL Authentication.
   - Tự động khởi tạo database `quan_ly_phong_kham` cùng 27 bảng từ `database/cosodulieu.sql` và nạp dữ liệu mẫu khi chạy `python scratch/seed_database.py`.
2. **Xây dựng cụm REST API dành riêng cho App Mobile Bệnh nhân (`controllers/mobile_patient_api.py`)**:
   - Bổ sung đầy đủ các API xác thực bằng Bearer Token (`/api/v1/mobile/patient/...`) và cấu hình CORS trong `app.py` để ứng dụng Flutter (Web/Chrome, Windows, Android Emulator) giao tiếp thời gian thực với SQL Server:
     - `GET /api/v1/mobile/patient/dashboard`: Lấy thông tin tổng quan bệnh nhân, thẻ BHYT, chỉ số sinh tồn mới nhất, lịch hẹn sắp tới và số thông báo chưa đọc.
     - `GET /api/v1/mobile/patient/booking-meta`: Lấy danh sách Chuyên khoa, Bác sĩ theo khoa và kiểm tra các khung giờ đã kín lịch trên SQL Server.
     - `GET / POST /api/v1/mobile/patient/appointments`: Xem danh sách lịch hẹn và Đặt lịch khám mới (tự sinh mã `LH...`, kiểm tra trùng lịch).
     - `POST /api/v1/mobile/patient/appointments/<id>/reschedule` & `/cancel`: Đổi ngày/giờ hẹn hoặc Hủy lịch hẹn trực tiếp từ App.
     - `GET /api/v1/mobile/patient/records`: Tra cứu Hồ sơ bệnh án điện tử (EMR), chẩn đoán ICD, lời dặn bác sĩ, đơn thuốc và chỉ số sinh tồn.
     - `POST /api/v1/mobile/patient/prescriptions/<id>/purchase-option`: Bệnh nhân chọn hình thức nhận thuốc (**"Mua tại bệnh viện"** hoặc **"Tự mua ngoài"**) lưu vào bảng `don_thuoc`.
     - `GET /api/v1/mobile/patient/lab-results`: Tra cứu kết quả Xét nghiệm huyết học, sinh hóa & Chẩn đoán hình ảnh (X-Quang, Siêu âm).
     - `GET /api/v1/mobile/patient/billing`: Tra cứu hóa đơn viện phí, tự động tính mức khấu trừ **BHYT 80%** và chi tiết từng khoản thu.
     - `GET / POST /api/v1/mobile/patient/notifications`: Xem thông báo y tế và đánh dấu đã đọc.
     - `GET / PUT /api/v1/mobile/patient/profile`: Xem và cập nhật Hồ sơ sức khỏe cá nhân, Số CCCD, Mã thẻ BHYT, Nhóm máu, Tiền sử dị ứng, Bệnh nền, Liên hệ khẩn cấp.
     - `GET / POST /api/v1/mobile/patient/feedbacks`: Gửi đánh giá chất lượng dịch vụ 5 sao và xem lịch sử góp ý.

---

### B. Phía Ứng dụng Mobile Flutter (`appmobi_KLCN-main`)
1. **Xây dựng Dịch vụ kết nối API (`lib/services/patient_api_service.dart` & `lib/services/auth_service.dart`)**:
   - Kết nối toàn bộ luồng Đăng nhập, Đăng ký, Khôi phục phiên đăng nhập, Đăng xuất và 14 đầu mục API Bệnh nhân với SQL Server.
2. **Hoàn thiện & Kết nối dữ liệu thật cho toàn bộ 8 màn hình chức năng của Bệnh nhân (`lib/screens/`)**:
   - **Màn hình Đăng nhập / Đăng ký (`auth_screen.dart`)**: Đăng nhập bằng SĐT / Username hoặc Đăng ký tài khoản bệnh nhân mới đồng bộ ngay với Website.
   - **Màn hình Trang chủ (`home_screen.dart`)**: Hiển thị tên thật, Mã bệnh nhân (`BN...`), Thẻ thành viên VIP kèm huy hiệu `BHYT 80%`, Mã QR Check-in tại quầy, Bảng chỉ số sinh tồn gần nhất và Lịch khám sắp tới (cho phép Xem chi tiết / Đổi lịch / Hủy lịch ngay trên trang chủ).
   - **Màn hình Đặt lịch & Quản lý lịch hẹn (`appointment_screen.dart`)**:
     - Tab *Đặt khám mới*: Lọc bác sĩ theo chuyên khoa, hiển thị phí khám, khóa các khung giờ đã kín, nhập triệu chứng và đặt lịch.
     - Tab *Lịch hẹn của tôi*: Xem toàn bộ lịch hẹn, hỗ trợ **Đổi lịch** và **Hủy lịch**.
   - **Màn hình Hồ sơ bệnh án EMR & Đơn thuốc (`medical_records_screen.dart`)**:
     - Tab *Lịch sử khám & Đơn thuốc*: Xem chi tiết từng đợt khám, chẩn đoán của bác sĩ, kết quả cận lâm sàng, toa thuốc chi tiết và 2 nút chọn **"Mua tại bệnh viện"** / **"Tự mua ngoài"**.
     - Tab *Chỉ số sinh tồn*: Hiển thị Nhịp tim, Huyết áp, Cân nặng & Chiều cao, Nhiệt độ cơ thể từ bảng `chi_so_sinh_ton`.
   - **Màn hình Kết quả Xét nghiệm & CĐHA (`test_results_screen.dart`)**: Mới hoàn toàn — hiển thị danh sách phiếu xét nghiệm máu, siêu âm, X-quang, chỉ số kết luận và tên Kỹ thuật viên thực hiện.
   - **Màn hình Thanh toán Viện phí & BHYT (`billing_screen.dart`)**: Chia 2 tab *Cần thanh toán* và *Lịch sử*, hiển thị chi tiết từng dịch vụ, mức giảm trừ BHYT do API trả về, số tiền thực thu và hướng dẫn thanh toán VietQR.
   - **Màn hình Thông báo Y tế (`notifications_screen.dart`)**: Chia 3 tab (*Tất cả*, *Chưa đọc*, *Lịch khám & Y tế*), bấm vào thông báo hoặc nút *"Đánh dấu đã đọc"* để cập nhật trạng thái lên SQL Server.
   - **Màn hình Cá nhân & Hồ sơ Y tế (`profile_screen.dart`)**: Bổ sung biểu mẫu **Cập nhật Hồ sơ Y tế & Thẻ BHYT** (CCCD, BHYT, Nhóm máu, Dị ứng, Bệnh nền) và biểu mẫu **Đánh giá & Góp ý dịch vụ 5 sao**.
3. **Tái cấu trúc & Làm gọn thư mục dự án (`lib/`)**:
   - Luồng từ `lib/main.dart` dùng các màn hình phẳng trong `lib/screens/`. Các bộ `domain/`, `data/`, `presentation/` và màn hình thư mục con vẫn được giữ; xem [cấu trúc thực tế](CAU_TRUC_PROJECT.md). Script chạy không xóa mã nguồn.
   - Tích hợp sẵn cấu hình Flutter SDK (`D:\flutter_windows_3.47.9-stable\flutter`) và script chạy tự động `run_app.bat`.

---

## 📁 2. Sơ đồ cấu trúc thư mục (`lib/`)

```text
lib/
├── main.dart                           # Khởi chạy ứng dụng, cấu hình Provider & Route
├── core/                               # 1. Cấu hình giao diện & bảng màu chung
│   ├── app_colors.dart                 # Bảng màu chủ đạo toàn ứng dụng
│   └── app_theme.dart                  # Cấu hình giao diện Sáng / Tối
├── services/                           # 2. Kết nối API Backend & Xác thực
│   ├── auth_service.dart               # Đăng nhập, Đăng ký, Lưu phiên & AuthViewModel
│   └── patient_api_service.dart        # Toàn bộ hàm gọi API Bệnh nhân kết nối SQL Server
├── screens/                            # 3. Toàn bộ 9 màn hình chính của Bệnh nhân
│   ├── main_navigation_screen.dart     # Khung điều hướng 4 Tab dưới đáy
│   ├── auth_screen.dart                # Màn hình Đăng nhập / Đăng ký tài khoản
│   ├── home_screen.dart                # Màn hình Trang chủ (Thẻ BHYT, Lịch hẹn, Tiện ích)
│   ├── appointment_screen.dart         # Màn hình Đặt lịch khám, Đổi lịch, Hủy lịch
│   ├── medical_records_screen.dart     # Màn hình Hồ sơ bệnh án EMR, Đơn thuốc & Sinh hiệu
│   ├── test_results_screen.dart        # Màn hình Kết quả Xét nghiệm & Chẩn đoán hình ảnh
│   ├── billing_screen.dart             # Màn hình Thanh toán viện phí & BHYT
│   ├── notifications_screen.dart       # Màn hình Thông báo y tế & Nhắc lịch khám
│   └── profile_screen.dart             # Màn hình Cá nhân, Cập nhật BHYT & Đánh giá 5 sao
└── widgets/                            # 4. Các khối giao diện con trên Trang chủ
    ├── header_widget.dart              # Thanh tiêu đề tên bệnh nhân + Chuông thông báo
    ├── vip_card_widget.dart            # Thẻ thành viên BHYT + Popup mã QR Check-in
    ├── quick_services_widget.dart      # 4 nút tắt tiện ích + Bảng chỉ số sinh tồn
    └── upcoming_appointment_widget.dart# Khung nhắc lịch khám sắp tới trên Trang chủ
```

---

## 🚀 3. Hướng dẫn cách chạy chương trình (Từng bước)

Để ứng dụng hoạt động đầy đủ với cơ sở dữ liệu thật, bạn cần mở song song **Backend Web (cổng 5000)** và **App Mobile Flutter**:

### Bước 1: Khởi chạy Backend Web & SQL Server
Mở cửa sổ Terminal tại thư mục dự án Web (`D:\KLCN_QuanLyPhongKhamDaKhoa-main\KLCN_QuanLyPhongKhamDaKhoa-main`):

```cmd
REM 1. Khởi tạo CSDL quan_ly_phong_kham và nạp dữ liệu mẫu (chỉ cần chạy lần đầu hoặc khi muốn reset dữ liệu)
python scratch/seed_database.py

REM 2. Bật máy chủ Flask Backend ở cổng 5000 (Giữ cửa sổ này luôn mở)
python app.py
```
> Khi màn hình hiện `Running on http://127.0.0.1:5000` là Backend đã sẵn sàng phục vụ cả Website và App Mobile.

---

### Bước 2: Khởi chạy App Mobile Flutter
Mở cửa sổ Terminal (`cmd`) tại thư mục dự án Mobile (`D:\appmobi_KLCN-main\appmobi_KLCN-main`) và gõ đúng **1 lệnh**:

```cmd
run_app.bat
```

*(Hoặc nếu muốn gõ từng lệnh thủ công trên Terminal)*:
```cmd
set PATH=D:\flutter_windows_3.47.9-stable\flutter\bin;%PATH%
flutter --no-version-check pub get
flutter --no-version-check run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

> **Mẹo xem giao diện khung điện thoại trên Chrome**:
> Khi cửa sổ Chrome mở lên, nhấn phím **`F12`** -> bấm biểu tượng **Điện thoại/Tablet** (`Toggle device toolbar` hoặc `Ctrl + Shift + M`) -> chọn khung **iPhone 14 Pro Max** hoặc **Pixel 7**.

---

## 🔑 4. Tài khoản Bệnh nhân mẫu để đăng nhập & kiểm thử

Bạn có thể tạo tài khoản mới tại màn hình **Đăng ký**, hoặc dùng ngay các tài khoản bệnh nhân có sẵn dữ liệu khám, xét nghiệm, đơn thuốc và BHYT trong SQL Server:

| Loại tài khoản | Số điện thoại / Username | Mật khẩu | Dữ liệu có sẵn |
|---|---|---|---|
| **Bệnh nhân 1 (Có BHYT 80%)** | `0901234561` *(hoặc `bn_1`)* | `123456` | Có lịch hẹn sắp tới, bệnh án EMR, đơn thuốc, kết quả xét nghiệm máu/X-quang, hóa đơn BHYT và thông báo y tế |
| **Bệnh nhân 2 (Không BHYT)** | `0901234562` *(hoặc `bn_2`)* | `123456` | Có lịch hẹn chờ tiếp nhận tại Khoa Nhi |
| **Bệnh nhân 3 (Có BHYT 80%)** | `0901234563` *(hoặc `bn_3`)* | `123456` | Hồ sơ bệnh nhân ngoại trú |
