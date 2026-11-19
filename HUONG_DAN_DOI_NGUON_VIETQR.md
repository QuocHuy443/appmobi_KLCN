# Hướng dẫn Thay đổi Tài khoản Nhận Tiền VietQR

Tài liệu này hướng dẫn chi tiết cách thay đổi ngân hàng, số tài khoản và tên chủ tài khoản nhận tiền thanh toán viện phí qua mã VietQR cho cả hệ thống Web và Ứng dụng Di động H2T Healthcare.

## 1. Cấu hình hiện tại của hệ thống

Hiện tại hệ thống đang lấy nguồn nhận tiền ưu tiên từ **Backend Flask** rồi trả xuống cho **App Mobile** hiển thị và tạo mã QR:

* **Ngân hàng (`BANK_ID`)**: `MB` (Ngân hàng Quân đội - MB Bank, mã BIN `970422`)
* **Số tài khoản (`BANK_ACCOUNT_NO`)**: `0774603405`
* **Chủ tài khoản (`BANK_ACCOUNT_NAME`)**: `PHAM QUOC HUY`
* **Nội dung chuyển khoản tự động**: `H2T<id_hoa_don>` (ví dụ `H2T105`)

## 2. Cách 1: Đổi nhanh bằng Biến môi trường (Không cần sửa mã nguồn)

Nếu chỉ muốn đổi tài khoản nhận tiền trên máy đang chạy Backend, bạn chỉ cần đặt 3 biến môi trường trước khi khởi động máy chủ Flask:

### Trên PowerShell
```powershell
cd "d:\baitap\Khoa Luan\KLCN_QuanLyPhongKhamDaKhoa"
$env:BANK_ID = "VCB"
$env:BANK_ACCOUNT_NO = "0123456789"
$env:BANK_ACCOUNT_NAME = "NGUYEN VAN A"
python app.py
```

### Trên Command Prompt (CMD)
```bat
cd /d "d:\baitap\Khoa Luan\KLCN_QuanLyPhongKhamDaKhoa"
set BANK_ID=VCB
set BANK_ACCOUNT_NO=0123456789
set BANK_ACCOUNT_NAME=NGUYEN VAN A
python app.py
```

Khi đặt biến môi trường này, hàm `payment_details` tại [core/payment.py](file:///d:/baitap/Khoa%20Luan/KLCN_QuanLyPhongKhamDaKhoa/core/payment.py#L26-L42) sẽ tự động tạo link ảnh QR mới và gửi toàn bộ thông tin mới về cho App Mobile mà không cần biên dịch lại ứng dụng Flutter.

## 3. Cách 2: Đổi mặc định vĩnh viễn trong mã nguồn

Để thay đổi thông tin mặc định lâu dài cho cả Web và App Mobile, cần cập nhật 2 nơi sau:

### Bước 1: Sửa cấu hình Backend (Nguồn chính thức)
Mở tệp [config.py](file:///d:/baitap/Khoa%20Luan/KLCN_QuanLyPhongKhamDaKhoa/config.py#L8-L12) và sửa 3 dòng mặc định:

```python
BANK_ID = os.environ.get('BANK_ID', 'VCB').strip().upper()
BANK_ACCOUNT_NO = os.environ.get('BANK_ACCOUNT_NO', '0123456789').strip()
BANK_ACCOUNT_NAME = os.environ.get('BANK_ACCOUNT_NAME', 'NGUYEN VAN A').strip()
```

Lưu ý quy chuẩn bắt buộc trong [bank_ready](file:///d:/baitap/Khoa%20Luan/KLCN_QuanLyPhongKhamDaKhoa/core/payment.py#L17-L23):
* `BANK_ID`: Chữ in hoa hoặc mã số từ 2 đến 12 ký tự (ví dụ `MB`, `VCB`, `TCB`, `BIDV`, `ACB`, `970422`).
* `BANK_ACCOUNT_NO`: Chỉ chứa chữ số từ 6 đến 25 ký tự, không có dấu cách hoặc dấu gạch ngang.
* `BANK_ACCOUNT_NAME`: Nên viết chữ in hoa không dấu tiếng Việt để tương thích tốt với các ứng dụng ngân hàng.

### Bước 2: Sửa giá trị dự phòng và bảng mã BIN trên App Mobile
Mở tệp [lib/screens/payment_qr_screen.dart](file:///d:/baitap/Khoa%20Luan/appmobi_KLCN/lib/screens/payment_qr_screen.dart#L35-L37) và cập nhật 3 hằng số dự phòng cho khớp với Backend (dùng khi tạo QR ngoại tuyến hoặc trường thông tin từ API bị trống):

```dart
static const String _fallbackBankId = 'VCB';
static const String _fallbackAccountNo = '0123456789';
static const String _fallbackAccountName = 'NGUYEN VAN A';
```

Nếu bạn đổi sang một ngân hàng chưa có trong danh sách viết tắt tại hàm [`_bankBin`](file:///d:/baitap/Khoa%20Luan/appmobi_KLCN/lib/screens/payment_qr_screen.dart#L103-L133), có thể làm một trong hai cách:
* Đặt thẳng `BANK_ID` là mã BIN 6 chữ số của ngân hàng (ví dụ `'970422'` cho MB, `'970436'` cho Vietcombank).
* Hoặc bổ sung cặp `'MA_NGAN_HANG': 'MA_BIN_6_SO'` vào bảng `bins` trong hàm `_bankBin`.

### Bảng mã viết tắt và mã BIN ngân hàng đã hỗ trợ sẵn

| Ngân hàng | Mã viết tắt (`BANK_ID`) | Mã BIN |
| :--- | :--- | :--- |
| MB Bank (Quân đội) | `MB` hoặc `MBBANK` | `970422` |
| Vietcombank | `VCB` hoặc `VIETCOMBANK` | `970436` |
| Techcombank | `TCB` hoặc `TECHCOMBANK` | `970407` |
| BIDV | `BIDV` | `970418` |
| VietinBank | `ICB`, `CTG` hoặc `VIETINBANK` | `970415` |
| ACB | `ACB` | `970416` |
| VPBank | `VPB` hoặc `VPBANK` | `970432` |
| TPBank | `TPB` hoặc `TPBANK` | `970423` |
| Sacombank | `STB` hoặc `SACOMBANK` | `970403` |
| VIB | `VIB` | `970441` |
| SHB | `SHB` | `970443` |
| MSB | `MSB` | `970426` |
| HDBank | `HDB` | `970437` |
| OCB | `OCB` | `970448` |
| Agribank | `AGRIBANK` hoặc `VBA` | `970405` |

## 4. Cấu hình đối soát tự động qua Webhook (Tùy chọn)

Khi hiển thị mã QR trên App hoặc Web, hệ thống tự động thăm dò trạng thái thanh toán của hóa đơn cứ mỗi 3 giây qua `GET /api/payment/status/<invoice_id>`. Để hệ thống tự động đánh dấu hóa đơn `Đã thanh toán` ngay khi tiền về tài khoản:

1. Đăng ký dịch vụ nhận thông báo biến động số dư qua Webhook (ví dụ SePay hoặc Casso) gắn với số tài khoản nhận tiền mới ở trên.
2. Trỏ địa chỉ Webhook về cổng máy chủ của phòng khám:
   `https://<ten-mien-cong-khai>/api/payment/webhook`
3. Đặt biến môi trường khóa bảo mật khớp với khóa khai báo trên SePay hoặc Casso:
   ```powershell
   $env:PAYMENT_WEBHOOK_SECRET = "khoa_bi_mat_webhook_cua_ban"
   ```
4. Khi Webhook gửi giao dịch vào, hàm `webhook()` tại [controllers/payment_controller.py](file:///d:/baitap/Khoa%20Luan/KLCN_QuanLyPhongKhamDaKhoa/controllers/payment_controller.py#L59-L89) sẽ kiểm tra hai điều kiện bắt buộc trước khi gạch nợ hóa đơn:
   * Số tài khoản nhận trong giao dịch phải trùng khớp hoàn toàn với `BANK_ACCOUNT_NO` đang cấu hình.
   * Nội dung chuyển khoản chứa đúng mã tham chiếu `H2T<id_hoa_don>` và số tiền chuyển vào bằng đúng số tiền thực thu của hóa đơn.

## 5. Kiểm tra lại sau khi thay đổi

1. Khởi động lại máy chủ Backend Flask (`python app.py`) để nạp giá trị `BANK_ID`, `BANK_ACCOUNT_NO`, `BANK_ACCOUNT_NAME` mới.
2. Nếu có chỉnh sửa trong `lib/screens/payment_qr_screen.dart`, chạy lại lệnh biên dịch bản phát hành Windows hoặc Web (hoặc chọn mục `[7]` trong [run_app.bat](file:///d:/baitap/Khoa%20Luan/appmobi_KLCN/run_app.bat)):
   ```powershell
   cd "d:\baitap\Khoa Luan\appmobi_KLCN"
   flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
   flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:5000
   ```
3. Mở mục **Hóa đơn và viện phí** trên ứng dụng, chọn một hóa đơn `Chưa thanh toán`, nhấn **Thanh toán VietQR** và dùng ứng dụng ngân hàng quét thử mã QR để xác nhận hiển thị đúng tên chủ tài khoản, số tài khoản, số tiền và nội dung chuyển khoản mới.
