# Đối chiếu bệnh nhân web và mobile

Khảo sát 03/11/2026 từ import graph của `lib/main.dart`, các controller thực sự đăng ký trong `app.py`, template `templates/patient` và model chung. Giữ toàn bộ thay đổi chưa commit có sẵn.

| Web | Màn hình app | API mobile patient | Thiếu lúc khảo sát |
| --- | --- | --- | --- |
| Đăng nhập/đăng ký | AuthScreen | `/auth/login`, `/auth/register`, `/auth/me`, `/auth/logout` | Loại bỏ fallback giả; hết phiên; cờ hoàn thiện |
| complete_profile.html | CompleteProfileScreen | GET `/profile`, POST `/complete-profile` | Chưa có màn hình/API/cổng điều hướng |
| dashboard.html | HomeScreen | GET `/dashboard` | Chưa đăng ký blueprint; đồng bộ hồ sơ/QR |
| booking.html, appointments.html | AppointmentScreen | GET `/booking-meta`, GET/POST `/appointments`, POST `/:id/reschedule`, `/:id/cancel` | Ma trận bác sĩ/ca/giờ, loại khám, tái kiểm tra xung đột, dùng model hủy/đổi chung |
| records.html | MedicalRecordsScreen | GET `/records`, POST `/prescriptions/:id/purchase-option` | Chỉ công bố CLS đã duyệt, nội dung đúng schema, API bảo vệ quyền |
| lab_results.html | TestResultsScreen | GET `/lab-results`, GET `/:id/image` | Schema kết quả và ảnh y tế có xác thực |
| billing.html | BillingScreen | GET `/billing`, POST `/billing/:id/instructions` | Hướng dẫn thu ngân thật, không QR/ngân hàng mẫu |
| profile.html | PersonalProfileScreen | GET/PUT `/profile`, POST `/profile/avatar` | Biểu mẫu đầy đủ, avatar, đồng bộ tên/tài khoản |
| feedbacks.html | FeedbackScreen | GET/POST `/feedbacks` | Lịch sử đầy đủ, trạng thái, phản hồi, phiếu khám liên quan |
| notifications.html | NotificationsScreen | GET `/notifications`, POST `/notifications/read` | Chuẩn hóa bộ lọc/đường dẫn nội dung liên quan |

Bản `mobile_patient_api.py` tại gốc backend chưa được đăng ký và khác schema/model đang chạy; không dùng nó làm nguồn chuẩn. Triển khai controller mới trong `controllers`, giữ nguyên hợp đồng đường dẫn hiện app gọi, dùng Bearer đã xác minh và ID bệnh nhân từ server. Không thêm schema/migration/seed.

Phạm vi kiểm thử và trạng thái bàn giao được cập nhật khi hoàn tất; bảng này ghi các khoảng thiếu ban đầu, không khẳng định E2E.
