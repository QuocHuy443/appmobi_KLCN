# Ứng dụng Di động Bệnh nhân H2T Healthcare (`appmobi_KLCN`)

Ứng dụng di động đa nền tảng (**Flutter**) dành riêng cho **Bệnh nhân** thuộc hệ sinh thái **Hệ thống Quản lý Phòng khám Đa khoa H2T Healthcare**. Ứng dụng kết nối trực tiếp với Web Backend (**Python Flask**) tại thư mục `KLCN_QuanLyPhongKhamDaKhoa` và dùng chung Cơ sở dữ liệu **Microsoft SQL Server (`quan_ly_phong_kham`)**, bảo đảm toàn bộ dữ liệu khám bệnh, đặt lịch hẹn, viện phí, bảo hiểm y tế (BHYT), đơn thuốc, kết quả xét nghiệm và thông báo đều đồng bộ theo thời gian thực giữa ứng dụng di động và cổng web của phòng khám.

---

## 1. Tổng quan và Khả năng nổi bật của Ứng dụng

Ứng dụng được thiết kế chuyên biệt cho bệnh nhân với giao diện Y tế hiện đại (chuẩn Material 3, bảng màu `Medical Emerald`), tối ưu thao tác trên màn hình cảm ứng điện thoại và máy tính bảng:

### 1.1. Cổng thông tin Phòng khám và Menu ngang 6 chuyên mục trên Trang chủ
Trang chủ đóng vai trò là cổng thông tin y tế công khai, cho phép người bệnh (kể cả khách chưa đăng nhập hoặc bệnh nhân đã đăng nhập) truy cập nhanh chóng qua thanh menu ngang:
* **Tổng quan**: Banner giới thiệu phòng khám, 3 cam kết chuẩn Bộ Y tế (100% Bác sĩ Chuyên khoa, Trang thiết bị hiện đại, Áp dụng BHYT thông tuyến), phím tắt dịch vụ nhanh, nhắc lịch khám sắp tới và các chuyên khoa, tin tức tiêu biểu.
* **Chuyên khoa**: Danh mục toàn bộ chuyên khoa điều trị từ CSDL SQL Server (Nội tổng quát, Ngoại khoa, Nhi khoa, Sản phụ khoa, Tai Mũi Họng, Răng Hàm Mặt, Mắt, Da liễu, Chẩn đoán hình ảnh...), hiển thị mô tả, số lượng bác sĩ đang trực, giá khám tiêu chuẩn và nút **Đặt khám khoa này** để đặt lịch trực tiếp.
* **Đội ngũ Bác sĩ**: Danh sách các Giáo sư, Tiến sĩ, Bác sĩ Chuyên khoa II giàu kinh nghiệm; tìm kiếm theo tên hoặc khoa; xem thông tin học vị, phòng khám, số năm công tác và nút **Đặt lịch với BS** chọn sẵn bác sĩ đó.
* **Bảng giá viện phí**: Danh mục kỹ thuật y tế niêm yết công khai theo quy định Bộ Y tế, lọc nhanh theo chuyên khoa, hiển thị rõ Giá gốc và Giá sau khi trừ mức giảm BHYT.
* **Tin tức và Cẩm nang**: Kho bài viết y học chính thống từ bảng `bai_viet` của SQL Server, lọc theo 10 chuyên mục y khoa, xem chi tiết bài viết (tự động cộng lượt xem trong CSDL) và gợi ý bài viết cùng chuyên mục.
* **Quy trình khám**: Hướng dẫn 4 bước khám bệnh chuẩn hóa của H2T Healthcare, các lưu ý cần chuẩn bị trước khi đi khám, hotline cấp cứu 1900 6868 và địa chỉ phòng khám.

### 1.2. Hồ sơ của tôi (Quản lý Bệnh nhân tập trung)
Toàn bộ thông tin cá nhân và dữ liệu y tế được quy hoạch gọn gàng trong tab **Hồ sơ của tôi**:
* **Thẻ VIP Bệnh nhân điện tử**: Tích hợp số thẻ BHYT, nhóm máu, mã bệnh nhân và mã QR Check-in để quét tại quầy tiếp đón.
* **Hồ sơ thông tin định danh**: Số CCCD, Ngày sinh, Giới tính, Số điện thoại, Thẻ BHYT, Nhóm máu, Tiền sử bệnh/dị ứng và Thông tin người thân liên hệ khẩn cấp.
* **Chỉ số sinh tồn lưu trữ từ lần khám gần nhất**: Đóng vai trò tham khảo lịch sử khám bệnh từ CSDL (Mạch, Huyết áp, SpO2, Nhiệt độ, Chiều cao, Cân nặng, Chỉ số BMI).

### 1.3. Đặt lịch khám thông minh theo Ca trực và Ma trận giờ
* Phân chia 3 ca trực trong ngày (Sáng: 07:30 - 11:30, Chiều: 13:00 - 17:00, Tối: 17:30 - 20:30) với các khung giờ 30 phút.
* Tự động khóa các khung giờ không có ca trực hoặc đã kín chỗ theo thời gian thực từ CSDL `lich_lam_viec` và `lich_hen`.
* Hỗ trợ chọn bác sĩ cụ thể hoặc để phòng khám tự phân công theo chuyên khoa.

### 1.4. Quản lý Lịch hẹn toàn diện
* Tìm kiếm lịch hẹn theo mã hẹn, tên bác sĩ, chuyên khoa.
* Lọc theo trạng thái: `Tất cả`, `Chờ duyệt`, `Đã xác nhận`, `Đã khám`, `Đã hủy`.
* Nhận diện lịch hẹn do bác sĩ chỉ định tái khám (`Bác sĩ hẹn mới`).
* Hỗ trợ đổi ngày giờ khám theo ma trận ca trực hoặc hủy lịch hẹn kèm lý do.

### 1.5. Bệnh án điện tử (EMR) và Đơn thuốc điện tử
* Tra cứu lịch sử các đợt khám bệnh, chẩn đoán bệnh theo mã ICD-10, triệu chứng, kết luận điều trị và lời dặn của bác sĩ.
* Danh sách thuốc chi tiết (tên thuốc, hàm lượng, cách dùng, số lượng, đơn giá).
* Cho phép người bệnh chủ động lựa chọn hình thức nhận thuốc: `Mua tại bệnh viện` hoặc `Tự mua ngoài`.

### 1.6. Kết quả Xét nghiệm và Chẩn đoán hình ảnh
* Thống kê tổng số chỉ định, số kết quả đã hoàn tất và số đợt khám.
* Phân loại theo nhóm `Xét nghiệm` và `Chẩn đoán hình ảnh`.
* Xem chi tiết chỉ số đo lường, khoảng tham chiếu, kết luận của bác sĩ và xem ảnh kết quả cận lâm sàng có hỗ trợ phóng to/thu nhỏ.

### 1.7. Hóa đơn Viện phí và Khấu trừ BHYT
* Tự động tính toán mức khấu trừ BHYT 80% đối với bệnh nhân có thẻ BHYT hợp lệ.
* Phân tách hóa đơn `Cần thanh toán` và `Lịch sử hóa đơn`.
* Xem chi tiết từng khoản mục viện phí và hướng dẫn thanh toán tiện lợi qua mã VietQR hoặc quầy thu ngân.

### 1.8. Thông báo Thời gian thực và Điều hướng Thông minh
* Đồng bộ chuông thông báo định kỳ mỗi 10 giây từ CSDL.
* Phân loại thông báo theo 4 nhóm chuyên biệt.
* Chạm vào thông báo để tự động chuyển tiếp đến đúng màn hình nghiệp vụ tương ứng (lịch hẹn, bệnh án, hóa đơn hoặc xét nghiệm).

### 1.9. Đánh giá và Góp ý Dịch vụ
* Gửi nhận xét và đánh giá từ 1 đến 5 sao theo từng chủ đề hoặc gắn trực tiếp với phiếu khám cụ thể.
* Theo dõi trạng thái tiếp nhận và nội dung phản hồi từ Ban Quản lý Phòng khám.

---

## 2. Kiến trúc Hệ thống và Cơ sở dữ liệu dùng chung

Hệ thống hoạt động theo mô hình **Client – RESTful API – Shared SQL Server Database**:

* **Client Di động (`appmobi_KLCN`)**: Ứng dụng Flutter đa nền tảng, quản lý trạng thái bằng `Provider`, giao tiếp mạng qua `Dio`, lưu trữ phiên bảo mật bằng `flutter_secure_storage`.
* **Backend Web (`KLCN_QuanLyPhongKhamDaKhoa`)**: Máy chủ Python Flask cung cấp các Blueprint API tại cổng `5000` (`mobile_auth_bp`, `mobile_patient_bp` và các API công khai trong `home_controller.py`).
* **Cơ sở dữ liệu Microsoft SQL Server (`quan_ly_phong_kham`)**: Gồm 27 bảng quan hệ được định nghĩa tại `database/cosodulieu.sql`, bảo đảm tính nhất quán dữ liệu y tế, không dùng dữ liệu giả lập cục bộ.

### Bảng đối chiếu nghiệp vụ giữa App Mobile, Web Portal và SQL Server

| Phân hệ nghiệp vụ | Màn hình Flutter | Giao diện Web tương ứng | Bảng SQL Server sử dụng |
| :--- | :--- | :--- | :--- |
| **Xác thực và Hồ sơ lần đầu** | `auth_screen.dart`, `personal_profile_screen.dart` | `auth/login.html`, `patient/complete_profile.html` | `nguoi_dung`, `benh_nhan` |
| **Trang chủ Cổng thông tin** | `home_screen.dart` | `home.html`, `patient/dashboard.html` | `banner`, `chuyen_khoa`, `bac_si`, `dich_vu`, `bai_viet`, `lich_hen` |
| **Tra cứu Bảng giá Viện phí** | `pricing_screen.dart` | `pricing.html` | `dich_vu`, `chuyen_khoa` |
| **Tin tức và Cẩm nang Y khoa** | `articles_screen.dart` | `articles.html`, `article_detail.html` | `bai_viet`, `nhan_vien` |
| **Đặt lịch khám theo Ca trực** | `appointment_booking_form.dart` | `patient/booking.html` | `chuyen_khoa`, `dich_vu`, `bac_si`, `lich_lam_viec`, `ca_lam_viec`, `phong_kham`, `lich_hen` |
| **Quản lý Lịch hẹn của tôi** | `appointment_screen.dart` | `patient/appointments.html` | `lich_hen`, `bac_si`, `chuyen_khoa`, `phong_kham`, `dich_vu` |
| **Bệnh án EMR và Đơn thuốc** | `medical_records_screen.dart` | `patient/records.html`, `patient/prescriptions.html` | `phieu_kham`, `don_thuoc`, `chi_tiet_don_thuoc`, `thuoc`, `chi_dinh_cls` |
| **Kết quả Xét nghiệm và CĐHA** | `test_results_screen.dart` | `patient/lab_results.html` | `chi_dinh_cls`, `ket_qua_cls`, `dich_vu`, `phieu_kham` |
| **Hóa đơn và Khấu trừ BHYT** | `billing_screen.dart` | `patient/billing.html` | `hoa_don`, `chi_tiet_hoa_don`, `benh_nhan` |
| **Thông báo Thời gian thực** | `notifications_screen.dart`, `notification_navigation.dart` | `patient/notifications.html`, `components/header.html` | `thong_bao` |
| **Hồ sơ cá nhân và Góp ý** | `profile_screen.dart`, `feedback_screen.dart` | `patient/profile.html`, `patient/feedbacks.html` | `nguoi_dung`, `benh_nhan`, `gop_y_phan_hoi` |

---

## 3. Danh mục REST API kết nối với Web Backend

### Nhóm Cổng thông tin Công khai (`/api/v1/mobile/public`)
* `GET /api/v1/mobile/public/home`: Dữ liệu Trang chủ tinh gọn (banner, chuyên khoa, bác sĩ, bảng giá tiêu biểu, tin tức và cẩm nang).
* `GET /api/v1/mobile/public/pricing`: Toàn bộ bảng giá dịch vụ và viện phí kèm mức giảm BHYT.
* `GET /api/v1/mobile/public/articles`: Danh sách tin tức và cẩm nang y khoa có lọc theo chuyên mục và tìm kiếm từ khóa.
* `GET /api/v1/mobile/public/articles/<slug>`: Chi tiết bài viết theo `slug`, tự động cộng lượt xem và trả về bài viết liên quan.

### Nhóm Xác thực (`/api/v1/mobile/auth`)
* `POST /api/v1/mobile/auth/login`: Đăng nhập bệnh nhân bằng Tên đăng nhập hoặc Số điện thoại, trả về Bearer Token.
* `POST /api/v1/mobile/auth/register`: Đăng ký tài khoản bệnh nhân mới trực tiếp vào SQL Server.
* `GET /api/v1/mobile/auth/me`: Kiểm tra trạng thái phiên và quyền bệnh nhân.
* `POST /api/v1/mobile/auth/logout`: Thu hồi Bearer Token trên máy chủ và xóa phiên an toàn.

### Nhóm Nghiệp vụ Bệnh nhân (`/api/v1/mobile/patient`)
* `GET /api/v1/mobile/patient/dashboard`: Dữ liệu bảng điều khiển bệnh nhân và lịch hẹn sắp tới.
* `GET /api/v1/mobile/patient/booking-meta`: Dữ liệu ma trận đặt lịch theo chuyên khoa, bác sĩ và ca trực.
* `GET /api/v1/mobile/patient/appointments`: Danh sách toàn bộ lịch hẹn của bệnh nhân.
* `POST /api/v1/mobile/patient/appointments`: Tạo lịch hẹn khám mới.
* `POST /api/v1/mobile/patient/appointments/<id>/reschedule`: Đổi ngày giờ lịch hẹn theo ca trực.
* `POST /api/v1/mobile/patient/appointments/<id>/cancel`: Hủy lịch hẹn kèm lý do.
* `GET /api/v1/mobile/patient/records`: Hồ sơ bệnh án điện tử, chỉ số sinh tồn và danh sách đơn thuốc.
* `POST /api/v1/mobile/patient/prescriptions/<id>/purchase-option`: Cập nhật lựa chọn nhận thuốc (`Mua tại bệnh viện` hoặc `Tự mua ngoài`).
* `GET /api/v1/mobile/patient/lab-results`: Danh sách kết quả xét nghiệm và cận lâm sàng đã có kết luận.
* `GET /api/v1/mobile/patient/lab-results/<id>/image`: Tải ảnh chụp kết quả xét nghiệm/CĐHA.
* `GET /api/v1/mobile/patient/billing`: Danh sách hóa đơn viện phí và thông tin BHYT.
* `POST /api/v1/mobile/patient/billing/<id>/instructions`: Hướng dẫn thanh toán hóa đơn viện phí.
* `GET /api/v1/mobile/patient/notifications`: Danh sách thông báo và số lượng chưa đọc.
* `POST /api/v1/mobile/patient/notifications/read`: Đánh dấu đã đọc thông báo.
* `GET` và `PUT /api/v1/mobile/patient/profile`: Tra cứu và cập nhật hồ sơ cá nhân bệnh nhân.
* `POST /api/v1/mobile/patient/complete-profile`: Hoàn thiện hồ sơ bệnh nhân bắt buộc sau đăng ký.
* `POST /api/v1/mobile/patient/profile/avatar`: Tải lên ảnh đại diện bệnh nhân.
* `GET` và `POST /api/v1/mobile/patient/feedbacks`: Lịch sử đánh giá và gửi phản hồi mới cho phòng khám.

---

## 4. Cấu trúc Thư mục Dự án

```text
appmobi_KLCN/
├── android/                                # Mã nguồn cấu hình biên dịch Android
├── ios/                                    # Mã nguồn cấu hình biên dịch iOS
├── web/                                    # Mã nguồn cấu hình biên dịch Web
├── windows/                                # Mã nguồn cấu hình biên dịch Windows Desktop
├── lib/
│   ├── main.dart                           # Điểm khởi chạy ứng dụng và Provider
│   ├── core/
│   │   ├── app_colors.dart                 # Bảng màu chuẩn Y tế H2T Healthcare
│   │   └── patient_format.dart             # Định dạng tiền tệ VNĐ và ngày giờ
│   ├── services/
│   │   ├── auth_service.dart               # Quản lý phiên đăng nhập và Bearer Token
│   │   ├── patient_api_service.dart        # Kết nối REST API và đồng bộ chuông thông báo
│   │   ├── notification_navigation.dart    # Điều hướng thông minh theo liên kết thông báo
│   │   └── session_events.dart             # Xử lý sự kiện đăng xuất và hết hạn phiên
│   ├── screens/
│   │   ├── main_navigation_screen.dart     # Khung điều hướng gốc và chặn hồ sơ chưa hoàn thiện
│   │   ├── main_layout.dart                # Thanh điều hướng 4 tab chính (Trang chủ, Lịch khám, Hồ sơ bệnh án, Tài khoản)
│   │   ├── auth_screen.dart                # Đăng nhập và Đăng ký bệnh nhân
│   │   ├── home_screen.dart                # Trang chủ Cổng thông tin y tế với menu ngang 6 chuyên mục
│   │   ├── pricing_screen.dart             # Tra cứu Bảng giá Dịch vụ và Viện phí có mức giảm BHYT
│   │   ├── articles_screen.dart            # Tin tức, Cẩm nang Y khoa và Đọc chi tiết bài viết
│   │   ├── appointment_screen.dart         # Đặt lịch khám mới và Quản lý lịch hẹn
│   │   ├── medical_records_screen.dart     # Bệnh án điện tử EMR và Đơn thuốc
│   │   ├── test_results_screen.dart        # Kết quả Xét nghiệm và Chẩn đoán hình ảnh
│   │   ├── billing_screen.dart             # Hóa đơn Viện phí và Khấu trừ BHYT
│   │   ├── notifications_screen.dart       # Trung tâm Thông báo phân loại theo nhóm
│   │   ├── profile_screen.dart             # Hồ sơ của tôi (Thẻ VIP BHYT, QR Check-in, chỉ số sinh tồn)
│   │   ├── personal_profile_screen.dart    # Cập nhật thông tin định danh, BHYT và ảnh đại diện
│   │   └── feedback_screen.dart            # Gửi góp ý và theo dõi phản hồi
│   └── widgets/
│       ├── appointment_booking_form.dart   # Form đặt lịch 4 bước theo ca trực và ma trận giờ
│       ├── header_widget.dart              # Header trang chủ, hotline và chuông thông báo
│       ├── vip_card_widget.dart            # Thẻ VIP Bệnh nhân và mã QR Check-in
│       ├── upcoming_appointment_widget.dart# Thẻ lịch khám sắp tới
│       └── request_error.dart              # Khung thông báo lỗi kết nối và nút thử lại
├── test/                                   # Toàn bộ 18 bài kiểm thử tự động
├── pubspec.yaml                            # Khai báo gói thư viện và tài nguyên
├── run_app.bat                             # Script menu khởi chạy đa nền tảng và kiểm thử
└── README.md                               # Tài liệu hướng dẫn sử dụng và cài đặt
```

---

## 5. Yêu cầu Môi trường

1. **Cơ sở dữ liệu Microsoft SQL Server**:
   * Đã cài đặt SQL Server và khởi tạo CSDL `quan_ly_phong_kham` bằng script `database/cosodulieu.sql` (kèm `database/seed_full_data.sql` nếu muốn nạp dữ liệu mẫu) trong thư mục `KLCN_QuanLyPhongKhamDaKhoa`.
   * Cấu hình kết nối SQL Server tại `KLCN_QuanLyPhongKhamDaKhoa/config.py` (`DB_SERVER`, `DB_NAME = 'quan_ly_phong_kham'`, `DB_USER`, `DB_PASSWORD`).
2. **Backend Web (`KLCN_QuanLyPhongKhamDaKhoa`)**:
   * Python phiên bản 3.10 trở lên và các gói phụ thuộc: `pip install -r requirements.txt`.
3. **Flutter SDK**:
   * Flutter SDK phiên bản 3.x trở lên (đường dẫn máy: `D:\baitap\LapTrinhDiDong\flutter\bin\flutter.bat`).

---

## 6. Hướng dẫn Khởi chạy trên Máy tính (PC / Laptop)

### Bước 1: Khởi động máy chủ Backend Web Flask (Cổng 5000)

Mở cửa sổ PowerShell hoặc CMD, di chuyển vào thư mục dự án Web và khởi động:

```powershell
cd "D:\baitap\Khoa Luan\KLCN_QuanLyPhongKhamDaKhoa"
python app.py
```

> Máy chủ Flask sẽ lắng nghe tại địa chỉ `http://0.0.0.0:5000`, sẵn sàng phục vụ cả máy tính nội bộ và điện thoại kết nối qua mạng LAN Wi-Fi.

### Bước 2: Chạy ứng dụng trên Máy tính

#### Cách 1: Sử dụng Menu tự động `run_app.bat` (Đơn giản nhất)
Nhấp đúp chuột vào file `run_app.bat` tại thư mục `d:\baitap\Khoa Luan\appmobi_KLCN` hoặc chạy qua terminal:

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
.\run_app.bat
```

Script sẽ tự động:
1. Kiểm tra và tự động khởi động máy chủ Backend nếu chưa bật.
2. Hiển thị menu cho phép chọn chạy trên Google Chrome (phím 1), Windows Desktop (phím 2), thiết bị Android (phím 3), xuất file APK (phím 4), hoặc chạy kiểm thử (phím 5).

#### Cách 2: Chạy trực tiếp bằng dòng lệnh Flutter

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
flutter pub get

# Chạy trên trình duyệt Google Chrome
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000

# Hoặc chạy dưới dạng ứng dụng Windows Desktop
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

---

## 7. Hướng dẫn Cài đặt và Khởi chạy trên Điện thoại

Ứng dụng hỗ trợ cả **Máy ảo Android Emulator** và **Điện thoại Android vật lý thật**:

### Trường hợp 1: Chạy trên Máy ảo Android Emulator (Android Studio)

Trên máy ảo Android Emulator, địa chỉ `10.0.2.2` được hệ điều hành Android tự động ánh xạ về `127.0.0.1` của máy tính. Mã nguồn ứng dụng đã cài đặt sẵn cơ chế tự động nhận diện `10.0.2.2:5000` khi chạy trên Android Emulator.

1. Mở **Android Studio** -> mở mục **Virtual Device Manager** và khởi động máy ảo Android (AVD).
2. Bảo đảm Backend Flask đang chạy tại cổng `5000` trên máy tính.
3. Mở terminal tại thư mục `appmobi_KLCN` và thực hiện:

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
flutter pub get
flutter run
```

---

### Trường hợp 2: Chạy trực tiếp trên Điện thoại Thật (Cắm cáp USB hoặc Wi-Fi)

Khi chạy trên điện thoại thật, điện thoại và máy tính cần kết nối **chung một mạng Wi-Fi**, và điện thoại sẽ gọi API qua **địa chỉ IP LAN của máy tính**:

#### Bước 2.1: Lấy địa chỉ IPv4 LAN của máy tính
Mở PowerShell trên máy tính và chạy lệnh:

```powershell
ipconfig
```

Tìm dòng **IPv4 Address** của card mạng Wi-Fi đang kết nối (ví dụ: `192.168.1.15`).

#### Bước 2.2: Mở cổng 5000 trên tường lửa Windows Firewall
Để Windows không chặn các kết nối từ điện thoại vào máy chủ Flask, chạy lệnh sau trong PowerShell (bằng quyền Administrator):

```powershell
New-NetFirewallRule -DisplayName "H2T Flask Backend 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

#### Bước 2.3: Bật chế độ Gỡ lỗi USB trên Điện thoại
1. Trên điện thoại Android, vào **Cài đặt** -> **Thông tin điện thoại** -> Chạm 7 lần vào mục **Số bản dựng (Build Number)** để kích hoạt quyền Nhà phát triển.
2. Vào **Cài đặt cho nhà phát triển** -> Bật mục **Gỡ lỗi qua USB (USB Debugging)**.
3. Cắm cáp USB kết nối điện thoại vào máy tính (chọn "Luôn cho phép gỡ lỗi từ máy tính này" trên màn hình điện thoại).

#### Bước 2.4: Khởi chạy ứng dụng lên Điện thoại
Kiểm tra danh sách thiết bị đã nhận:

```powershell
flutter devices
```

Khởi chạy ứng dụng lên điện thoại với IP LAN của máy tính (thay `192.168.1.15` bằng IP thực tế ở Bước 2.1):

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"
flutter run --dart-define=API_BASE_URL=http://192.168.1.15:5000
```

---

### Trường hợp 3: Xuất file cài đặt APK độc lập để cài lên nhiều Điện thoại

Nếu muốn đóng gói thành file cài đặt độc lập để gửi qua Zalo, Google Drive hoặc sao chép vào bộ nhớ điện thoại để cài đặt mà không cần máy tính:

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"

# Biên dịch file APK Release kèm địa chỉ máy chủ Flask LAN
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.15:5000
```

Sau khi quá trình biên dịch hoàn tất, file cài đặt APK nằm tại đường dẫn:
```text
build\app\outputs\flutter-apk\app-release.apk
```

Chép file `app-release.apk` vào điện thoại, mở file trên điện thoại và chọn **Cài đặt (Install)** để sử dụng.

---

## 8. Tài khoản Mẫu và Kiểm thử Tự động

### Tài khoản Bệnh nhân có sẵn trong Cơ sở dữ liệu mẫu
* **Tên đăng nhập / Số điện thoại**: `bn_1` hoặc `0901234561`
* **Mật khẩu**: `123456`
* Hoặc có thể nhấn **Đăng ký ngay** trên màn hình Đăng nhập của ứng dụng để tự tạo tài khoản bệnh nhân mới trực tiếp vào SQL Server.

### Chạy Kiểm tra Chất lượng Mã nguồn và Bộ Kiểm thử Tự động

Mã nguồn được duy trì ở tiêu chuẩn cao nhất, không có cảnh báo và vượt qua 100% các bài test:

```powershell
cd "D:\baitap\Khoa Luan\appmobi_KLCN"

# 1. Kiểm tra tĩnh mã nguồn (phải đạt 'No issues found!')
flutter analyze --no-pub

# 2. Chạy toàn bộ 18 bài kiểm thử tự động (Unit Tests, Contract Tests, Widget Tests)
flutter test --no-pub
```
