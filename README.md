# Ứng dụng Di động Bệnh nhân H2T Healthcare (`appmobi_KLCN`)

Ứng dụng di động đa nền tảng (**Flutter**) dành riêng cho **Bệnh nhân** thuộc hệ sinh thái **Hệ thống Quản lý Phòng khám Đa khoa H2T Healthcare**. Ứng dụng kết nối trực tiếp với Web Backend (**Python Flask**) tại thư mục `KLCN_QuanLyPhongKhamDaKhoa` và dùng chung Cơ sở dữ liệu **Microsoft SQL Server (`quan_ly_phong_kham`)**, bảo đảm toàn bộ dữ liệu khám bệnh, đặt lịch hẹn, viện phí, bảo hiểm y tế (BHYT), đơn thuốc, kết quả xét nghiệm và thông báo đều đồng bộ theo thời gian thực giữa ứng dụng di động và cổng web của phòng khám.

---

## 1. Tổng quan và Khả năng Nổi bật của Ứng dụng

Ứng dụng được thiết kế chuyên biệt cho bệnh nhân với giao diện Y tế hiện đại (chuẩn Material 3, bảng màu `Medical Emerald`), tối ưu thao tác trên màn hình cảm ứng điện thoại và máy tính bảng:

### 1.1. Cổng thông tin Phòng khám và Menu ngang 6 chuyên mục trên Trang chủ
Trang chủ đóng vai trò là cổng thông tin y tế công khai, cho phép người bệnh (kể cả khách chưa đăng nhập hoặc bệnh nhân đã đăng nhập) truy cập nhanh chóng qua thanh menu ngang:
* **Tổng quan**: Banner giới thiệu phòng khám, 3 cam kết chuẩn Bộ Y tế (100% Bác sĩ Chuyên khoa, Trang thiết bị hiện đại, Áp dụng BHYT thông tuyến), phím tắt dịch vụ nhanh, nhắc lịch khám sắp tới và các chuyên khoa, tin tức tiêu biểu.
* **Chuyên khoa**: Danh mục toàn bộ chuyên khoa điều trị từ CSDL SQL Server (Nội tổng quát, Ngoại khoa, Nhi khoa, Sản phụ khoa, Tai Mũi Họng, Răng Hàm Mặt, Mắt, Da liễu, Chẩn đoán hình ảnh...), hiển thị mô tả, số lượng bác sĩ đang trực, giá khám tiêu chuẩn và nút **Đặt khám khoa này** để đặt lịch trực tiếp.
* **Đội ngũ Bác sĩ**: Danh sách các Giáo sư, Tiến sĩ, Bác sĩ Chuyên khoa II giàu kinh nghiệm; tìm kiếm theo tên hoặc khoa; xem thông tin học vị, phòng khám, số năm công tác và nút **Đặt lịch với BS** chọn sẵn bác sĩ đó.
* **Bảng giá viện phí**: Danh mục kỹ thuật y tế niêm yết công khai theo quy định Bộ Y tế, lọc nhanh theo chuyên khoa, hiển thị rõ Giá gốc và Giá sau khi trừ mức giảm BHYT.
* **Tin tức và Cẩm nang**: Kho bài viết y học chính thống từ bảng `bai_viet` của SQL Server, lọc theo 10 chuyên mục y khoa, xem chi tiết bài viết (tự động cộng lượt xem trong CSDL) và gợi ý bài viết cùng chuyên mục.
* **Quy trình khám**: Hướng dẫn 4 bước khám bệnh chuẩn hóa của H2T Healthcare, các lưu ý cần chuẩn bị trước khi đi khám, hotline cấp cứu 1900 6868 và địa chỉ phòng khám.

### 1.2. Hệ thống Chuyển động và Hoạt ảnh Hiện đại (Animation System)
Lấy cảm hứng từ các hiệu ứng chuyển động mượt mà của hệ thống Web H2T Healthcare (`custom.css`), ứng dụng di động được trang bị thư viện hoạt ảnh chuyên nghiệp độc quyền tại [lib/core/app_animations.dart](file:///d:/baitap/Khoa%20Luan/appmobi_KLCN/lib/core/app_animations.dart):
* **Đường cong chuyển động cao cấp**: Sử dụng đường cong Cubic chuẩn mực `Cubic(0.22, 1.0, 0.36, 1.0)` mang lại cảm giác đầm, êm ái và sang trọng.
* **Thời lượng chuyển động chuẩn y khoa**: Thiết lập 550ms cho các chuyển động chính và 380ms cho việc chuyển đổi phân mục, tạo nhịp điệu nhẹ nhàng, không gây mỏi mắt cho người bệnh.
* **Hiệu ứng trượt và mờ dần so le (Staggered Entrance)**: Các khối nội dung trên trang chủ (Banner, Chỉ số cam kết, Lưới dịch vụ, Lịch sắp tới, Chuyên khoa, Tin tức) xuất hiện tuần tự với độ trễ từ 40ms đến 380ms.
* **Phản hồi chạm co giãn nhẹ (Scale Tap Effect)**: Các nút bấm và thẻ dịch vụ phản hồi tức thì với độ co giãn nhẹ `0.97` khi chạm, tạo sự chân thực và trực quan.
* **Chuyển tab nội dung mượt mà (Tab Transition)**: Toàn bộ quá trình chuyển đổi giữa 6 phân mục trên trang chủ diễn ra êm ái nhờ hiệu ứng kết hợp giữa độ mờ và độ trượt nhẹ.

### 1.3. Hồ sơ của tôi (Quản lý Bệnh nhân tập trung)
Toàn bộ thông tin cá nhân và dữ liệu y tế được quy hoạch gọn gàng trong tab **Hồ sơ của tôi**:
* **Thẻ VIP Bệnh nhân điện tử**: Tích hợp số thẻ BHYT, nhóm máu, mã bệnh nhân và mã QR Check-in để quét tại quầy tiếp đón.
* **Hồ sơ thông tin định danh**: Số CCCD, Ngày sinh, Giới tính, Số điện thoại, Thẻ BHYT, Nhóm máu, Tiền sử bệnh, dị ứng và Thông tin người thân liên hệ khẩn cấp.
* **Chỉ số sinh tồn lưu trữ từ lần khám gần nhất**: Đóng vai trò tham khảo lịch sử khám bệnh từ CSDL (Mạch, Huyết áp, SpO2, Nhiệt độ, Chiều cao, Cân nặng, Chỉ số BMI).

### 1.4. Đặt lịch khám thông minh theo Ca trực và Ma trận giờ
* Phân chia 3 ca trực trong ngày (Sáng: 07:30 - 11:30, Chiều: 13:00 - 17:00, Tối: 17:30 - 20:30) với các khung giờ 30 phút.
* Tự động khóa các khung giờ không có ca trực hoặc đã kín chỗ theo thời gian thực từ CSDL `lich_lam_viec` và `lich_hen`.
* Hỗ trợ chọn bác sĩ cụ thể hoặc để phòng khám tự phân công theo chuyên khoa.

### 1.5. Quản lý Lịch hẹn toàn diện
* Tìm kiếm lịch hẹn theo mã hẹn, tên bác sĩ, chuyên khoa.
* Lọc theo trạng thái: `Tất cả`, `Chờ duyệt`, `Đã xác nhận`, `Đã khám`, `Đã hủy`.
* Nhận diện lịch hẹn do bác sĩ chỉ định tái khám (`Bác sĩ hẹn mới`).
* Hỗ trợ đổi ngày giờ khám theo ma trận ca trực hoặc hủy lịch hẹn kèm lý do.

### 1.6. Bệnh án điện tử (EMR) và Đơn thuốc điện tử
* Tra cứu lịch sử các đợt khám bệnh, chẩn đoán bệnh theo mã ICD-10, triệu chứng, kết luận điều trị và lời dặn của bác sĩ.
* Danh sách thuốc chi tiết (tên thuốc, hàm lượng, cách dùng, số lượng, đơn giá).
* Cho phép người bệnh chủ động lựa chọn hình thức nhận thuốc: `Mua tại bệnh viện` hoặc `Tự mua ngoài`.

### 1.7. Kết quả Xét nghiệm và Chẩn đoán hình ảnh
* Thống kê tổng số chỉ định, số kết quả đã hoàn tất và số đợt khám.
* Phân loại theo nhóm `Xét nghiệm` và `Chẩn đoán hình ảnh`.
* Xem chi tiết chỉ số đo lường, khoảng tham chiếu, kết luận của bác sĩ và xem ảnh kết quả cận lâm sàng có hỗ trợ phóng to, thu nhỏ.

### 1.8. Hóa đơn Viện phí và Khấu trừ BHYT
* Tự động tính toán mức khấu trừ BHYT 80% đối với bệnh nhân có thẻ BHYT hợp lệ.
* Phân tách hóa đơn `Cần thanh toán` và `Lịch sử hóa đơn`.
* Xem chi tiết từng khoản mục viện phí và hướng dẫn thanh toán tiện lợi qua mã VietQR hoặc quầy thu ngân.

### 1.9. Thông báo Thời gian thực và Điều hướng Thông minh
* Đồng bộ chuông thông báo định kỳ mỗi 10 giây từ CSDL.
* Phân loại thông báo theo 4 nhóm chuyên biệt.
* Chạm vào thông báo để tự động chuyển tiếp đến đúng màn hình nghiệp vụ tương ứng (lịch hẹn, bệnh án, hóa đơn hoặc xét nghiệm).

### 1.10. Đánh giá và Góp ý Dịch vụ
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

## 3. Cấu trúc Thư mục Dự án

```text
appmobi_KLCN/
├── android/                                # Mã nguồn cấu hình biên dịch Android
├── ios/                                    # Mã nguồn cấu hình biên dịch iOS
├── web/                                    # Mã nguồn cấu hình biên dịch Web
├── windows/                                # Mã nguồn cấu hình biên dịch Windows Desktop
├── lib/
│   ├── main.dart                           # Điểm khởi chạy ứng dụng và Provider
│   ├── core/
│   │   ├── app_animations.dart             # Thư viện hoạt ảnh chuyển động hiện đại
│   │   ├── app_colors.dart                 # Bảng màu chuẩn Y tế H2T Healthcare
│   │   ├── app_theme.dart                  # Cấu hình giao diện và phông chữ
│   │   └── patient_format.dart             # Định dạng tiền tệ VNĐ và ngày giờ
│   ├── services/
│   │   ├── auth_service.dart               # Quản lý phiên đăng nhập và Bearer Token
│   │   ├── patient_api_service.dart        # Kết nối REST API và đồng bộ chuông thông báo
│   │   ├── notification_navigation.dart    # Điều hướng thông minh theo liên kết thông báo
│   │   ├── session_events.dart             # Xử lý sự kiện đăng xuất và hết hạn phiên
│   │   ├── sound_service.dart              # Phát âm thanh thông báo
│   │   ├── sound_service_io.dart           # Xử lý âm thanh trên nền tảng Native
│   │   └── sound_service_web.dart          # Xử lý âm thanh trên nền tảng Web
│   ├── screens/
│   │   ├── main_navigation_screen.dart     # Khung điều hướng gốc và hiệu ứng chuyển tab
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
├── run_app.bat                             # Bảng điều khiển khởi chạy đa năng trung tâm
├── HUONG_DAN_CAI_DAT_VA_CHAY.md            # Tài liệu chi tiết cài đặt và chạy từ con số 0
└── README.md                               # Tài liệu tổng quan dự án
```

---

## 4. Hướng dẫn Khởi chạy Nhanh

### Phương thức Khuyên dùng: Bảng điều khiển `run_app.bat`

Nhấp đúp chuột vào tệp [run_app.bat](file:///d:/baitap/Khoa%20Luan/appmobi_KLCN/run_app.bat) để mở menu khởi chạy tiện lợi:

* **Tùy chọn [1]**: Mở Cửa sổ Ứng dụng Native Windows (Cửa sổ 430x880 căn giữa màn hình) - Trải nghiệm mượt mà nhất.
* **Tùy chọn [2]**: Mở Cửa sổ Web Mobile độc lập qua Chrome (Khung dọc không có thanh địa chỉ).
* **Tùy chọn [3]**: Phát máy chủ Wi-Fi LAN để mở trực tiếp trên Điện thoại thật thông qua trình duyệt điện thoại.
* **Tùy chọn [4]**: Khởi chạy trực tiếp lên Thiết bị hoặc Máy ảo Android đang kết nối.
* **Tùy chọn [5]**: Chạy chế độ Phát triển Debug Flutter (Hỗ trợ phím r để Hot-Reload).
* **Tùy chọn [6]**: Khởi động riêng Máy chủ Backend Flask API (Cổng 5000).
* **Tùy chọn [7]**: Dọn dẹp và Biên dịch lại toàn bộ ứng dụng (Clean và Rebuild).
* **Tùy chọn [8]**: Thoát.

### Hướng dẫn Cài đặt Toàn diện từ Máy tính Mới tinh

Đối với máy tính mới chưa cài đặt môi trường (Git, Python, Visual Studio C++, Flutter SDK, Android Studio, AVD, USB Debugging) hoặc muốn khởi chạy chuyên sâu bằng Terminal dòng lệnh, vui lòng xem tài liệu chi tiết tại:

[HUONG_DAN_CAI_DAT_VA_CHAY.md](file:///d:/baitap/Khoa%20Luan/appmobi_KLCN/HUONG_DAN_CAI_DAT_VA_CHAY.md)

---

## 5. Tài khoản Bệnh nhân Mẫu để Kiểm tra

* **Tên đăng nhập / Số điện thoại**: `bn_1` hoặc `0901234561`
* **Mật khẩu**: `123456`
* Hoặc có thể nhấn **Đăng ký ngay** trên màn hình Đăng nhập của ứng dụng để tự tạo tài khoản bệnh nhân mới trực tiếp vào SQL Server.

---

## 6. Kiểm thử Chất lượng Mã nguồn

Dự án duy trì tiêu chuẩn kỹ thuật nghiêm ngặt:
* **Kiểm tra tĩnh Flutter**: `flutter analyze` đạt 0 issues.
* **Kiểm thử tự động Flutter**: `flutter test` vượt qua 18/18 bài kiểm thử.
* **Kiểm thử tự động Backend**: `test_mobile_patient_api.py` vượt qua 14/14 bài kiểm thử.
