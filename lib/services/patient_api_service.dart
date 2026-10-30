import 'package:dio/dio.dart';
import 'auth_service.dart';

class _LocalPatientDataStore {
  static final Map<String, dynamic> profile = {
    'id': 1,
    'ma_bn': 'BN0001',
    'ho_ten': 'Trần Thị Hương',
    'sdt': '0901234561',
    'email': 'huong.tran@gmail.com',
    'ngay_sinh': '1992-05-14',
    'gioi_tinh': 'Nữ',
    'dia_chi': '140 Lê Trọng Tấn, Phường Tây Thạnh, Quận Tân Phú, TP.HCM',
    'so_cccd': '079192001234',
    'so_the_bhyt': 'DN4797912345678',
    'nhom_mau': 'O+',
    'di_ung': 'Dị ứng nhẹ với Paracetamol liều cao',
    'benh_nen': 'Viêm mũi dị ứng thời tiết',
    'lien_he_khan_cap': '0909888777 (Chồng - Nguyễn Minh Quân)',
  };

  static Map<String, dynamic> syncedProfile() {
    final active = LocalAuthStore.activeUser;
    if (active != null) {
      profile['id'] = int.tryParse(active.id) ?? 1;
      profile['ma_bn'] = active.patientCode;
      profile['ho_ten'] = active.name;
      profile['sdt'] = active.phone;
      if (active.email.isNotEmpty) {
        profile['email'] = active.email;
      }
      final acc = LocalAuthStore.findAccount(active.phone);
      if (acc != null) {
        profile['ngay_sinh'] ??= acc['birth_date'];
        profile['gioi_tinh'] ??= acc['gender'];
      }
    }
    return Map<String, dynamic>.from(profile);
  }

  static final List<Map<String, dynamic>> specialties = [
    {
      'id': 1,
      'ten_chuyen_khoa': 'Khoa Nội Tổng Quát',
      'mo_ta':
          'Khám và điều trị các bệnh lý nội khoa, tim mạch, tiêu hóa, hô hấp'
    },
    {
      'id': 2,
      'ten_chuyen_khoa': 'Khoa Ngoại Tổng Hợp',
      'mo_ta': 'Khám ngoại khoa, tiểu phẫu, chấn thương chỉnh hình'
    },
    {
      'id': 3,
      'ten_chuyen_khoa': 'Khoa Nhi',
      'mo_ta': 'Khám và tư vấn dinh dưỡng, bệnh lý trẻ em'
    },
    {
      'id': 4,
      'ten_chuyen_khoa': 'Khoa Tai Mũi Họng',
      'mo_ta': 'Nội soi và điều trị bệnh lý Tai - Mũi - Họng'
    },
  ];

  static final List<Map<String, dynamic>> doctors = [
    {
      'id': 1,
      'ho_ten': 'Nguyễn Văn Khoa',
      'hoc_vi': 'ThS.BS',
      'chuyen_khoa_id': 1,
      'ten_chuyen_khoa': 'Khoa Nội Tổng Quát',
      'gia_kham': 200000,
      'phong_kham': 'P.101 - Tầng 1',
    },
    {
      'id': 2,
      'ho_ten': 'Lê Thị Minh Châu',
      'hoc_vi': 'BS.CKII',
      'chuyen_khoa_id': 1,
      'ten_chuyen_khoa': 'Khoa Nội Tổng Quát',
      'gia_kham': 250000,
      'phong_kham': 'P.102 - Tầng 1',
    },
    {
      'id': 3,
      'ho_ten': 'Trần Quốc Bảo',
      'hoc_vi': 'TS.BS',
      'chuyen_khoa_id': 2,
      'ten_chuyen_khoa': 'Khoa Ngoại Tổng Hợp',
      'gia_kham': 250000,
      'phong_kham': 'P.201 - Tầng 2',
    },
    {
      'id': 4,
      'ho_ten': 'Phạm Thu Hà',
      'hoc_vi': 'ThS.BS',
      'chuyen_khoa_id': 3,
      'ten_chuyen_khoa': 'Khoa Nhi',
      'gia_kham': 200000,
      'phong_kham': 'P.105 - Tầng 1',
    },
    {
      'id': 5,
      'ho_ten': 'Hoàng Đức Anh',
      'hoc_vi': 'BS.CKI',
      'chuyen_khoa_id': 4,
      'ten_chuyen_khoa': 'Khoa Tai Mũi Họng',
      'gia_kham': 180000,
      'phong_kham': 'P.203 - Tầng 2',
    },
  ];

  static final List<Map<String, dynamic>> appointments = [
    {
      'id': 101,
      'ma_lich_hen': 'LH2026103101',
      'chuyen_khoa_id': 1,
      'ten_chuyen_khoa': 'Khoa Nội Tổng Quát',
      'bac_si_id': 1,
      'ten_bac_si': 'Nguyễn Văn Khoa',
      'hoc_vi': 'ThS.BS',
      'ten_phong': 'P.101 - Tầng 1',
      'ngay_hen': '2026-11-02',
      'gio_hen': '08:30',
      'ly_do': 'Tái khám kiểm tra huyết áp và xét nghiệm máu định kỳ',
      'trang_thai': 'Đã xác nhận',
    },
    {
      'id': 100,
      'ma_lich_hen': 'LH2026101502',
      'chuyen_khoa_id': 1,
      'ten_chuyen_khoa': 'Khoa Nội Tổng Quát',
      'bac_si_id': 1,
      'ten_bac_si': 'Nguyễn Văn Khoa',
      'hoc_vi': 'ThS.BS',
      'ten_phong': 'P.101 - Tầng 1',
      'ngay_hen': '2026-10-15',
      'gio_hen': '09:00',
      'ly_do': 'Đau đầu nhẹ, mệt mỏi khi thay đổi thời tiết',
      'trang_thai': 'Đã hoàn thành',
    },
  ];

  static final List<Map<String, dynamic>> records = [
    {
      'id': 501,
      'ma_phieu': 'PK2026101501',
      'ngay_kham': '15/10/2026 09:30',
      'ten_bac_si': 'Nguyễn Văn Khoa',
      'hoc_vi': 'ThS.BS',
      'ten_chuyen_khoa': 'Khoa Nội Tổng Quát',
      'ten_phong': 'P.101 - Tầng 1',
      'trieu_chung':
          'Đau đầu vùng thái dương, mệt mỏi nhẹ, ăn ngủ kém 3 ngày nay',
      'chan_doan':
          'J30.4 - Viêm mũi dị ứng thời tiết kèm suy nhược cơ thể nhẹ',
      'ket_luan':
          'Điều trị nội khoa 5 ngày, nghỉ ngơi hợp lý, uống đủ 2 lít nước/ngày',
      'loi_dan':
          'Uống thuốc đúng giờ sau ăn. Tái khám sau 2 tuần hoặc khi có sốt cao.',
      'trang_thai': 'Hoàn thành',
      'mach': 76,
      'huyet_ap': '118/76',
      'nhiet_do': 36.7,
      'can_nang': 54.5,
      'chieu_cao': 162,
      'spo2': 98,
      'lab_orders': [
        {
          'ten_dich_vu':
              'Tổng phân tích tế bào máu ngoại vi (Công thức máu)',
          'ket_qua': 'WBC: 6.8 G/L, RBC: 4.5 T/L, HGB: 135 g/L, PLT: 245 G/L',
          'ket_luan': 'Các chỉ số huyết học trong giới hạn bình thường',
          'trang_thai': 'Đã có kết quả',
        },
        {
          'ten_dich_vu': 'Chụp X-Quang ngực thẳng kỹ thuật số',
          'ket_qua': 'Trường phổi hai bên sáng đều, bóng tim không to',
          'ket_luan': 'Tim phổi bình thường',
          'trang_thai': 'Đã có kết quả',
        },
      ],
      'prescription': {
        'id': 301,
        'ma_don_thuoc': 'DT2026101501',
        'ghi_chu': 'Uống sau ăn no, kiêng đồ lạnh',
        'hinh_thuc_mua': 'Mua tại bệnh viện',
        'trang_thai_duyet': 'Đã cấp phát',
        'items': [
          {
            'ten_thuoc': 'Loratadin 10mg (Chống dị ứng)',
            'so_luong': 10,
            'don_vi': 'Viên',
            'lieu_dung': 'Ngày uống 1 lần, mỗi lần 1 viên sau ăn tối',
            'gia': 3500,
          },
          {
            'ten_thuoc': 'Vitamin C 500mg (Tăng đề kháng)',
            'so_luong': 10,
            'don_vi': 'Viên',
            'lieu_dung': 'Ngày uống 2 lần sáng/trưa, mỗi lần 1 viên',
            'gia': 2500,
          },
        ],
      },
    },
  ];

  static final List<Map<String, dynamic>> labResults = [
    {
      'id': 701,
      'ma_phieu': 'XN2026101501',
      'ten_dich_vu': 'Tổng phân tích tế bào máu ngoại vi (Công thức máu)',
      'loai_dich_vu': 'Xét nghiệm Huyết học',
      'ngay_chi_dinh': '15/10/2026 09:40',
      'ngay_tra_ket_qua': '15/10/2026 10:15',
      'bac_si_chi_dinh': 'ThS.BS Nguyễn Văn Khoa',
      'ktv_thuc_hien': 'CN.XN Đặng Văn Hùng',
      'ket_qua':
          'WBC: 6.8 G/L (BT: 4-10) | RBC: 4.5 T/L | HGB: 135 g/L | PLT: 245 G/L',
      'ket_luan': 'Các chỉ số huyết học trong giới hạn bình thường',
      'trang_thai': 'Đã có kết quả',
      'file_ket_qua': '',
    },
    {
      'id': 702,
      'ma_phieu': 'CDHA2026101502',
      'ten_dich_vu': 'Chụp X-Quang ngực thẳng kỹ thuật số',
      'loai_dich_vu': 'Chẩn đoán hình ảnh',
      'ngay_chi_dinh': '15/10/2026 09:45',
      'ngay_tra_ket_qua': '15/10/2026 10:25',
      'bac_si_chi_dinh': 'ThS.BS Nguyễn Văn Khoa',
      'ktv_thuc_hien': 'BS.CĐHA Vũ Minh Đức',
      'ket_qua':
          'Hai phế trường sáng, góc sườn hoành hai bên nhọn, bóng tim không to.',
      'ket_luan': 'Hình ảnh tim phổi trong giới hạn bình thường',
      'trang_thai': 'Đã có kết quả',
      'file_ket_qua': '',
    },
  ];

  static final List<Map<String, dynamic>> invoices = [
    {
      'id': 801,
      'ma_hoa_don': 'HD2026101501',
      'loai_hoa_don': 'Viện phí Khám & Cận lâm sàng',
      'ngay_lap': '15/10/2026 10:35',
      'tong_tien': 450000,
      'muc_bhyt_chi_tra': 360000,
      'thuc_thu': 90000,
      'trang_thai': 'Đã thanh toán',
      'phuong_thuc': 'Chuyển khoản VietQR',
      'items': [
        {
          'ten_dich_vu': 'Khám Nội Tổng Quát (ThS.BS Nguyễn Văn Khoa)',
          'so_luong': 1,
          'don_gia': 200000,
          'thanh_tien': 200000
        },
        {
          'ten_dich_vu': 'Tổng phân tích tế bào máu ngoại vi',
          'so_luong': 1,
          'don_gia': 120000,
          'thanh_tien': 120000
        },
        {
          'ten_dich_vu': 'Chụp X-Quang ngực thẳng kỹ thuật số',
          'so_luong': 1,
          'don_gia': 130000,
          'thanh_tien': 130000
        },
      ],
    },
    {
      'id': 802,
      'ma_hoa_don': 'HDT2026110201',
      'loai_hoa_don': 'Tạm ứng lịch khám ngày 02/11/2026',
      'ngay_lap': '30/10/2026 14:20',
      'tong_tien': 200000,
      'muc_bhyt_chi_tra': 160000,
      'thuc_thu': 40000,
      'trang_thai': 'Chưa thanh toán',
      'phuong_thuc': 'VietQR / Quầy thu ngân',
      'items': [
        {
          'ten_dich_vu': 'Khám Nội Tổng Quát (ThS.BS Nguyễn Văn Khoa)',
          'so_luong': 1,
          'don_gia': 200000,
          'thanh_tien': 200000
        },
      ],
    },
  ];

  static final List<Map<String, dynamic>> notifications = [
    {
      'id': 901,
      'tieu_de': 'Nhắc lịch hẹn khám sắp tới',
      'noi_dung':
          'Bạn có lịch hẹn khám tại Khoa Nội Tổng Quát (P.101) với ThS.BS Nguyễn Văn Khoa vào lúc 08:30 ngày 02/11/2026.',
      'loai': 'LICH_HEN',
      'da_doc': 0,
      'thoi_gian': '30/10/2026 08:00',
    },
    {
      'id': 902,
      'tieu_de': 'Đã có kết quả Xét nghiệm & X-Quang',
      'noi_dung':
          'Kết quả xét nghiệm máu và chụp X-Quang ngực thẳng của đợt khám PK2026101501 đã được cập nhật lên ứng dụng.',
      'loai': 'KET_QUA_CLS',
      'da_doc': 0,
      'thoi_gian': '15/10/2026 10:25',
    },
    {
      'id': 903,
      'tieu_de': 'Đơn thuốc DT2026101501 đã cấp phát',
      'noi_dung':
          'Kho dược đã hoàn tất cấp phát đơn thuốc DT2026101501. Chúc bạn mau chóng bình phục!',
      'loai': 'DON_THUOC',
      'da_doc': 1,
      'thoi_gian': '15/10/2026 10:45',
    },
  ];

  static final List<Map<String, dynamic>> feedbacks = [
    {
      'id': 1,
      'chu_de': 'Khám chữa bệnh & Bác sĩ',
      'diem_danh_gia': 5,
      'noi_dung':
          'Bác sĩ Nguyễn Văn Khoa tư vấn rất tận tình, thủ tục BHYT nhanh gọn.',
      'ngay_gui': '16/10/2026 11:20',
      'phan_hoi_admin':
          'Cảm ơn quý bệnh nhân đã tin tưởng Phòng khám Đa khoa H2T Healthcare!',
    },
  ];
}

class PatientApiService {
  final Dio _dio;

  PatientApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AuthRepositoryImpl.defaultBaseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
            ));

  Options _authOptions(String? token) {
    if (token == null || token.isEmpty) {
      return Options();
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  bool _shouldUseLocalFallback(DioException e) {
    final code = e.response?.statusCode;
    return e.response == null || code == 404 || code == 405 || code == 502;
  }

  String _extractError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Thao tác chưa hoàn tất, vui lòng thử lại.';
    }
    return error.toString();
  }

  Future<Map<String, dynamic>> getDashboard(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/dashboard',
          options: _authOptions(token),
        );
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (_) {}

    final upcoming = _LocalPatientDataStore.appointments
        .where((a) =>
            a['trang_thai'] != 'Đã hủy' && a['trang_thai'] != 'Đã hoàn thành')
        .toList();
    final unread = _LocalPatientDataStore.notifications
        .where((n) => n['da_doc'] == 0 || n['da_doc'] == false)
        .length;
    return {
      'success': true,
      'patient': _LocalPatientDataStore.syncedProfile(),
      'upcoming_appointment': upcoming.isNotEmpty ? upcoming.first : null,
      'latest_vitals': {
        'mach': 76,
        'huyet_ap': '118/76',
        'nhiet_do': 36.7,
        'can_nang': 54.5,
        'chieu_cao': 162,
        'spo2': 98,
        'ngay_do': '15/10/2026',
      },
      'unread_notifications': unread,
    };
  }

  Future<Map<String, dynamic>> getBookingMeta({
    String? date,
    int? chuyenKhoaId,
    int? bacSiId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (date != null && date.isNotEmpty) query['date'] = date;
      if (chuyenKhoaId != null) query['chuyen_khoa_id'] = chuyenKhoaId;
      if (bacSiId != null) query['bac_si_id'] = bacSiId;
      final res = await _dio.get(
        '/api/v1/mobile/patient/booking-meta',
        queryParameters: query,
      );
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      final filteredDoctors = chuyenKhoaId == null
          ? _LocalPatientDataStore.doctors
          : _LocalPatientDataStore.doctors
              .where((d) => d['chuyen_khoa_id'] == chuyenKhoaId)
              .toList();
      final bookedSlots = _LocalPatientDataStore.appointments
          .where((a) =>
              a['trang_thai'] != 'Đã hủy' &&
              (date == null || a['ngay_hen'] == date) &&
              (bacSiId == null || a['bac_si_id'] == bacSiId))
          .map((a) => a['gio_hen'].toString())
          .toList();
      return {
        'success': true,
        'specialties': _LocalPatientDataStore.specialties,
        'doctors': filteredDoctors,
        'booked_slots': bookedSlots,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/appointments',
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        final list = (data['appointments'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return _LocalPatientDataStore.appointments
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> createAppointment({
    required String token,
    required int chuyenKhoaId,
    int? bacSiId,
    String? ngayHen,
    String? date,
    String? gioHen,
    String? time,
    required String lyDo,
  }) async {
    final targetDate = ngayHen ?? date ?? '';
    final targetTime = gioHen ?? time ?? '';
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.post(
          '/api/v1/mobile/patient/appointments',
          data: {
            'chuyen_khoa_id': chuyenKhoaId,
            'bac_si_id': bacSiId,
            'ngay_hen': targetDate,
            'gio_hen': targetTime,
            'ly_do': lyDo,
          },
          options: _authOptions(token),
        );
        return Map<String, dynamic>.from(res.data as Map);
      }
    } on DioException catch (e) {
      if (!_shouldUseLocalFallback(e)) {
        throw Exception(_extractError(e));
      }
    }

    final spec = _LocalPatientDataStore.specialties.firstWhere(
      (s) => s['id'] == chuyenKhoaId,
      orElse: () => _LocalPatientDataStore.specialties.first,
    );
    final doc = _LocalPatientDataStore.doctors.firstWhere(
      (d) =>
          (bacSiId != null && d['id'] == bacSiId) ||
          d['chuyen_khoa_id'] == chuyenKhoaId,
      orElse: () => _LocalPatientDataStore.doctors.first,
    );
    final newId = 100 + _LocalPatientDataStore.appointments.length + 1;
    final newItem = {
      'id': newId,
      'ma_lich_hen': 'LH2026$newId',
      'chuyen_khoa_id': chuyenKhoaId,
      'ten_chuyen_khoa': spec['ten_chuyen_khoa'],
      'bac_si_id': doc['id'],
      'ten_bac_si': doc['ho_ten'],
      'hoc_vi': doc['hoc_vi'],
      'ten_phong': doc['phong_kham'],
      'ngay_hen': targetDate,
      'gio_hen': targetTime,
      'ly_do': lyDo,
      'trang_thai': 'Chờ tiếp nhận',
    };
    _LocalPatientDataStore.appointments.insert(0, newItem);
    return {
      'success': true,
      'message': 'Đặt lịch khám thành công!',
      'appointment': newItem,
    };
  }

  Future<String> rescheduleAppointment({
    required String token,
    required int appointmentId,
    String? ngayHen,
    String? date,
    String? gioHen,
    String? time,
    String? lyDo,
    int? bacSiId,
  }) async {
    final targetDate = ngayHen ?? date ?? '';
    final targetTime = gioHen ?? time ?? '';
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.post(
          '/api/v1/mobile/patient/appointments/$appointmentId/reschedule',
          data: {
            'ngay_hen': targetDate,
            'gio_hen': targetTime,
            if (lyDo != null) 'ly_do': lyDo,
            if (bacSiId != null) 'bac_si_id': bacSiId,
          },
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        return (data['message'] as String?) ?? 'Đổi lịch khám thành công!';
      }
    } on DioException catch (e) {
      if (!_shouldUseLocalFallback(e)) {
        throw Exception(_extractError(e));
      }
    }

    for (final item in _LocalPatientDataStore.appointments) {
      if (item['id'] == appointmentId) {
        item['ngay_hen'] = targetDate;
        item['gio_hen'] = targetTime;
        if (lyDo != null && lyDo.isNotEmpty) item['ly_do'] = lyDo;
        break;
      }
    }
    return 'Đổi lịch khám thành công!';
  }

  Future<String> cancelAppointment({
    required String token,
    required int appointmentId,
    String? reason,
  }) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.post(
          '/api/v1/mobile/patient/appointments/$appointmentId/cancel',
          data: {'reason': reason ?? 'Hủy lịch từ App Mobile'},
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        return (data['message'] as String?) ?? 'Đã hủy lịch hẹn!';
      }
    } on DioException catch (e) {
      if (!_shouldUseLocalFallback(e)) {
        throw Exception(_extractError(e));
      }
    }

    for (final item in _LocalPatientDataStore.appointments) {
      if (item['id'] == appointmentId) {
        item['trang_thai'] = 'Đã hủy';
        break;
      }
    }
    return 'Đã hủy lịch hẹn thành công!';
  }

  Future<Map<String, dynamic>> getMedicalRecords(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/records',
          options: _authOptions(token),
        );
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (_) {}

    return {
      'success': true,
      'records': _LocalPatientDataStore.records,
      'latest_vitals': {
        'mach': 76,
        'huyet_ap': '118/76',
        'nhiet_do': 36.7,
        'can_nang': 54.5,
        'chieu_cao': 162,
        'spo2': 98,
        'ngay_do': '15/10/2026',
      },
    };
  }

  Future<String> choosePrescriptionPurchaseOption({
    required String token,
    int? prescriptionId,
    int? donThuocId,
    required String option,
  }) async {
    final targetId = prescriptionId ?? donThuocId ?? 0;
    final normalizedOption =
        (option == 'hospital' || option == 'Mua tại bệnh viện')
            ? 'Mua tại bệnh viện'
            : 'Tự mua ngoài';
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.post(
          '/api/v1/mobile/patient/prescriptions/$targetId/purchase-option',
          data: {'option': normalizedOption},
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        return (data['message'] as String?) ??
            'Đã cập nhật lựa chọn mua thuốc!';
      }
    } on DioException catch (e) {
      if (!_shouldUseLocalFallback(e)) {
        throw Exception(_extractError(e));
      }
    }

    for (final rec in _LocalPatientDataStore.records) {
      final pres = rec['prescription'];
      if (pres is Map && (pres['id'] == targetId || targetId == 0)) {
        pres['hinh_thuc_mua'] = normalizedOption;
      }
    }
    return 'Đã cập nhật hình thức nhận thuốc: $normalizedOption';
  }

  Future<List<Map<String, dynamic>>> getLabResults(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/lab-results',
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        final list = (data['results'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return _LocalPatientDataStore.labResults
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> getBilling(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/billing',
          options: _authOptions(token),
        );
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (_) {}
    final p = _LocalPatientDataStore.syncedProfile();
    final hasBhyt = (p['so_the_bhyt'] ?? '').toString().isNotEmpty;
    return {
      'success': true,
      'has_bhyt': hasBhyt,
      'so_the_bhyt': p['so_the_bhyt'] ?? '',
      'invoices': _LocalPatientDataStore.invoices,
    };
  }

  Future<List<Map<String, dynamic>>> getNotifications(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/notifications',
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        final list = (data['notifications'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return _LocalPatientDataStore.notifications
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> markNotificationRead({
    required String token,
    int? notificationId,
    int? id,
    bool markAll = false,
  }) async {
    final targetId = markAll ? null : (notificationId ?? id);
    try {
      if (!token.startsWith('local-token-')) {
        await _dio.post(
          '/api/v1/mobile/patient/notifications/read',
          data: {
            if (targetId != null) 'notification_id': targetId,
          },
          options: _authOptions(token),
        );
        return;
      }
    } catch (_) {}

    for (final n in _LocalPatientDataStore.notifications) {
      if (targetId == null || n['id'] == targetId) {
        n['da_doc'] = 1;
      }
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/profile',
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        if (data['patient'] is Map) {
          return Map<String, dynamic>.from(data['patient'] as Map);
        }
        return data;
      }
    } catch (_) {}
    return _LocalPatientDataStore.syncedProfile();
  }

  Future<String> updateProfile({
    required String token,
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? payload,
  }) async {
    final body = Map<String, dynamic>.from(profileData ?? payload ?? {});
    body['cccd'] ??= body['so_cccd'];
    body['bhyt'] ??= body['so_the_bhyt'];
    body['tien_su_benh'] ??= body['benh_nen'];
    body['nguoi_than_sdt'] ??= body['lien_he_khan_cap'];
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.put(
          '/api/v1/mobile/patient/profile',
          data: body,
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        return (data['message'] as String?) ?? 'Cập nhật hồ sơ thành công!';
      }
    } on DioException catch (e) {
      if (!_shouldUseLocalFallback(e)) {
        throw Exception(_extractError(e));
      }
    }

    if (body['ho_ten'] != null) {
      _LocalPatientDataStore.profile['ho_ten'] = body['ho_ten'];
    }
    if (body['ngay_sinh'] != null) {
      _LocalPatientDataStore.profile['ngay_sinh'] = body['ngay_sinh'];
    }
    if (body['gioi_tinh'] != null) {
      _LocalPatientDataStore.profile['gioi_tinh'] = body['gioi_tinh'];
    }
    if (body['dia_chi'] != null) {
      _LocalPatientDataStore.profile['dia_chi'] = body['dia_chi'];
    }
    if (body['cccd'] != null) {
      _LocalPatientDataStore.profile['so_cccd'] = body['cccd'];
    }
    if (body['bhyt'] != null) {
      _LocalPatientDataStore.profile['so_the_bhyt'] = body['bhyt'];
    }
    if (body['nhom_mau'] != null) {
      _LocalPatientDataStore.profile['nhom_mau'] = body['nhom_mau'];
    }
    if (body['di_ung'] != null) {
      _LocalPatientDataStore.profile['di_ung'] = body['di_ung'];
    }
    if (body['tien_su_benh'] != null) {
      _LocalPatientDataStore.profile['benh_nen'] = body['tien_su_benh'];
    }
    if (body['nguoi_than_sdt'] != null) {
      _LocalPatientDataStore.profile['lien_he_khan_cap'] =
          body['nguoi_than_sdt'];
    }
    return 'Cập nhật hồ sơ y tế & thẻ BHYT thành công!';
  }

  Future<List<Map<String, dynamic>>> getFeedbacks(String token) async {
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.get(
          '/api/v1/mobile/patient/feedbacks',
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        final list = (data['feedbacks'] as List?) ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return _LocalPatientDataStore.feedbacks
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<String> submitFeedback({
    required String token,
    String? chuDe,
    int? diemDanhGia,
    int? soSao,
    required String noiDung,
  }) async {
    final stars = diemDanhGia ?? soSao ?? 5;
    final topic = chuDe ?? 'Đánh giá từ App Mobile';
    try {
      if (!token.startsWith('local-token-')) {
        final res = await _dio.post(
          '/api/v1/mobile/patient/feedbacks',
          data: {
            'chu_de': topic,
            'diem_danh_gia': stars,
            'noi_dung': noiDung,
          },
          options: _authOptions(token),
        );
        final data = Map<String, dynamic>.from(res.data as Map);
        return (data['message'] as String?) ?? 'Gửi đánh giá thành công!';
      }
    } on DioException catch (e) {
      if (!_shouldUseLocalFallback(e)) {
        throw Exception(_extractError(e));
      }
    }

    _LocalPatientDataStore.feedbacks.insert(0, {
      'id': _LocalPatientDataStore.feedbacks.length + 1,
      'chu_de': topic,
      'diem_danh_gia': stars,
      'noi_dung': noiDung,
      'ngay_gui': 'Vừa xong',
      'phan_hoi_admin': '',
    });
    return 'Cảm ơn bạn đã gửi đánh giá dịch vụ!';
  }
}
