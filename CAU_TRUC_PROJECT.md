# SƠ ĐỒ CẤU TRÚC PROJECT FLUTTER ĐÃ GỘP GỌN (`appmobi_KLCN-main`)

Toàn bộ mã nguồn ứng dụng Bệnh nhân trong **`lib/`** đã được gom lại thành **4 thư mục phẳng, không còn thư mục con lồng nhau hoặc file trùng lặp**:

```text
lib/
├── main.dart                           # Khởi chạy ứng dụng, cấu hình Provider & Route
│
├── core/                               # 1. Cấu hình giao diện & bảng màu chung (2 file)
│   ├── app_colors.dart                 # Bảng màu chủ đạo toàn ứng dụng
│   └── app_theme.dart                  # Cấu hình giao diện Sáng / Tối
│
├── services/                           # 2. Kết nối API Backend & Xác thực (2 file)
│   ├── auth_service.dart               # Đăng nhập, Đăng ký, Lưu phiên & AuthViewModel
│   └── patient_api_service.dart        # Toàn bộ API Bệnh nhân kết nối SQL Server
│
├── screens/                            # 3. Toàn bộ 9 màn hình chính (nằm chung 1 thư mục)
│   ├── main_navigation_screen.dart     # Khung điều hướng 4 Tab dưới đáy
│   ├── auth_screen.dart                # Màn hình Đăng nhập / Đăng ký tài khoản
│   ├── home_screen.dart                # Màn hình Trang chủ (Thẻ BHYT, Lịch hẹn, Tiện ích)
│   ├── appointment_screen.dart         # Màn hình Đặt lịch khám, Đổi lịch, Hủy lịch
│   ├── medical_records_screen.dart     # Màn hình Hồ sơ bệnh án EMR, Đơn thuốc & Sinh hiệu
│   ├── test_results_screen.dart        # Màn hình Kết quả Xét nghiệm & Chẩn đoán hình ảnh
│   ├── billing_screen.dart             # Màn hình Thanh toán viện phí & Khấu trừ 80% BHYT
│   ├── notifications_screen.dart       # Màn hình Thông báo y tế & Nhắc lịch khám
│   └── profile_screen.dart             # Màn hình Cá nhân, Cập nhật BHYT & Đánh giá 5 sao
│
└── widgets/                            # 4. Các khối giao diện con trên Trang chủ (4 file)
    ├── header_widget.dart              # Thanh tiêu đề tên bệnh nhân + Chuông thông báo
    ├── vip_card_widget.dart            # Thẻ thành viên BHYT + Popup mã QR Check-in
    ├── quick_services_widget.dart      # 4 nút tắt tiện ích + Bảng chỉ số sinh tồn
    └── upcoming_appointment_widget.dart# Khung nhắc lịch khám sắp tới trên Trang chủ
```
