import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'session_events.dart';

class PatientApiService {
  static final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static String? notificationToken;
  static int _notificationRevision = 0;

  static void resetNotifications(String? token) {
    notificationToken = token;
    _notificationRevision++;
    unreadCountNotifier.value = 0;
  }

  static bool isNotificationRead(Map<String, dynamic> item) =>
      [true, 1, '1'].contains(item['da_xem']) ||
      [true, 1, '1'].contains(item['da_doc']);

  static void _publishNotifications(
      String token, int revision, List<Map<String, dynamic>> items) {
    if (notificationToken == token && revision == _notificationRevision) {
      unreadCountNotifier.value =
          items.where((n) => !isNotificationRead(n)).length;
    }
  }

  final Dio _dio;

  PatientApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AuthRepositoryImpl.defaultBaseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
            )) {
    _dio.options.followRedirects = false;
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final uri = options.uri;
      if (uri.userInfo.isNotEmpty || !['http', 'https'].contains(uri.scheme) ||
          (kReleaseMode && uri.scheme != 'https')) {
        handler.reject(DioException(requestOptions: options, message: 'Backend phải dùng HTTPS trong bản phát hành.'));
      } else {
        handler.next(options);
      }
    }, onError: (error, handler) {
      final authorization = error.requestOptions.headers['Authorization']?.toString() ?? '';
      final data = error.response?.data;
      if (authorization.startsWith('Bearer ') &&
          (error.response?.statusCode == 401 || data is Map && data['error_code'] == 'PROFILE_REQUIRED')) {
        SessionEvents.reject(authorization.substring(7), profileRequired: data is Map && data['error_code'] == 'PROFILE_REQUIRED');
      }
      handler.next(error);
    }, onResponse: (response, handler) {
      if (response.data is Map && response.data['success'] == false) {
        handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse));
      } else {
        if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(response.requestOptions.method)) {
          dataRevision.value++;
        }
        handler.next(response);
      }
    }));
  }

  Options _authOptions(String? token) {
    if (token == null || token.isEmpty) {
      throw ArgumentError('Missing authentication token');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
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
      final res = await _dio.get(
        '/api/v1/mobile/patient/dashboard',
        options: _authOptions(token),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getBookingMeta({
    String? token,
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
        options: token == null ? null : _authOptions(token),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments(String token) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/appointments',
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final list = (data['appointments'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> createAppointment({
    required String token,
    required int chuyenKhoaId,
    int? bacSiId,
    int? examServiceId,
    String? ngayHen,
    String? date,
    String? gioHen,
    String? time,
    required String lyDo,
  }) async {
    final targetDate = ngayHen ?? date ?? '';
    final targetTime = gioHen ?? time ?? '';
    try {
      final res = await _dio.post(
        '/api/v1/mobile/patient/appointments',
        data: {
          'chuyen_khoa_id': chuyenKhoaId,
          'bac_si_id': bacSiId,
          if (examServiceId != null) 'exam_service_id': examServiceId,
          'ngay_hen': targetDate,
          'gio_hen': targetTime,
          'ly_do': lyDo,
        },
        options: _authOptions(token),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
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
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<String> cancelAppointment({
    required String token,
    required int appointmentId,
    String? reason,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/mobile/patient/appointments/$appointmentId/cancel',
        data: {'reason': reason ?? 'Hủy lịch từ App Mobile'},
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return (data['message'] as String?) ?? 'Đã hủy lịch hẹn!';
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getMedicalRecords(String token) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/records',
        options: _authOptions(token),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
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
      final res = await _dio.post(
        '/api/v1/mobile/patient/prescriptions/$targetId/purchase-option',
        data: {'option': normalizedOption},
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return (data['message'] as String?) ?? 'Đã cập nhật lựa chọn mua thuốc!';
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getLabResults(String token) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/lab-results',
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final list = (data['results'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getBilling(String token) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/billing',
        options: _authOptions(token),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String token, {String tab = 'all', bool unreadOnly = false}) async {
    final revision = ++_notificationRevision;
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/notifications',
        queryParameters: {if (tab != 'all') 'tab': tab, if (unreadOnly) 'unread': '1'},
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final list = (data['notifications'] as List?) ?? [];
      final items =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      for (final item in items) {
        item['da_xem'] = isNotificationRead(item);
      }
      _publishNotifications(token, revision, items);
      if (notificationToken == token && revision == _notificationRevision && data['unread_count'] is int) {
        unreadCountNotifier.value = data['unread_count'] as int;
      }
      return items;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> markNotificationRead({
    required String token,
    int? notificationId,
    int? id,
    bool markAll = false,
  }) async {
    final targetId = markAll ? null : (notificationId ?? id);
    try {
      await _dio.post(
        '/api/v1/mobile/patient/notifications/read',
        data: {
          if (targetId != null) 'notification_id': targetId,
        },
        options: _authOptions(token),
      );
      if (notificationToken == token) await getNotifications(token);
      return;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/profile',
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['patient'] is Map) {
        return Map<String, dynamic>.from(data['patient'] as Map);
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
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
      final res = await _dio.put(
        '/api/v1/mobile/patient/profile',
        data: body,
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return (data['message'] as String?) ?? 'Cập nhật hồ sơ thành công!';
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<List<Map<String, dynamic>>> getFeedbacks(String token) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/feedbacks',
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final list = (data['feedbacks'] as List?) ?? [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<String> submitFeedback({
    required String token,
    String? chuDe,
    int? diemDanhGia,
    int? soSao,
    int? encounterId,
    required String noiDung,
  }) async {
    final stars = diemDanhGia ?? soSao ?? 5;
    final topic = chuDe ?? 'Đánh giá từ App Mobile';
    try {
      final res = await _dio.post(
        '/api/v1/mobile/patient/feedbacks',
        data: {
          'chu_de': topic,
          'diem_danh_gia': stars,
          'noi_dung': noiDung,
          if (encounterId != null) 'phieu_kham_id': encounterId,
        },
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return (data['message'] as String?) ?? 'Gửi đánh giá thành công!';
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getProfileBundle(String token) async {
    try {
      final response = await _dio.get('/api/v1/mobile/patient/profile', options: _authOptions(token));
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) { throw Exception(_extractError(e)); }
  }

  Future<void> completeProfile(String token, Map<String, dynamic> profile) async {
    try {
      await _dio.post('/api/v1/mobile/patient/complete-profile', data: profile, options: _authOptions(token));
    } on DioException catch (e) { throw Exception(_extractError(e)); }
  }

  Future<void> uploadAvatar(String token, {Uint8List? bytes, String? filename, String? url}) async {
    if (bytes != null && (bytes.isEmpty || bytes.length > 8 * 1024 * 1024)) {
      throw Exception('Ảnh phải có dung lượng từ 1 byte đến 8 MiB.');
    }
    try {
      final form = FormData.fromMap({
        if (bytes != null) 'avatar_file': MultipartFile.fromBytes(bytes, filename: filename ?? 'avatar.jpg'),
        if (url != null) 'avatar_url': url,
      });
      await _dio.post('/api/v1/mobile/patient/profile/avatar', data: form, options: _authOptions(token));
    } on DioException catch (e) { throw Exception(_extractError(e)); }
  }

  Future<Map<String, dynamic>> paymentInstructions(String token, int invoiceId) async {
    try {
      final response = await _dio.post('/api/v1/mobile/patient/billing/$invoiceId/instructions', options: _authOptions(token));
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) { throw Exception(_extractError(e)); }
  }

  Future<Uint8List> getLabImage(String token, int resultId) async {
    try {
      final response = await _dio.get<List<int>>('/api/v1/mobile/patient/lab-results/$resultId/image',
        options: _authOptions(token)..responseType = ResponseType.bytes);
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) { throw Exception(_extractError(e)); }
  }

  static String? avatarUrl(dynamic path) {
    if (path is! String || !path.startsWith('/static/uploads/benh_nhan/') ||
        path.contains('..') || path.contains('%') || path.contains('\\')) { return null; }
    return Uri.parse(AuthRepositoryImpl.defaultBaseUrl).resolve(path).toString();
  }

  static String? mediaUrl(dynamic path) {
    if (path is! String) return null;
    final clean = path.trim();
    if (clean.isEmpty || clean.contains('..') || clean.contains('\\')) return null;
    if (clean.startsWith('http://') || clean.startsWith('https://')) return clean;
    if (clean.startsWith('/static/')) {
      return Uri.parse(AuthRepositoryImpl.defaultBaseUrl).resolve(clean).toString();
    }
    return null;
  }

  Future<Map<String, dynamic>> getPublicHome() async {
    try {
      final res = await _dio.get('/api/v1/mobile/public/home');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getPublicPricing() async {
    try {
      final res = await _dio.get('/api/v1/mobile/public/pricing');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getPublicArticles({
    String? category,
    String? search,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (category != null && category.trim().isNotEmpty) {
        query['category'] = category.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      final res = await _dio.get(
        '/api/v1/mobile/public/articles',
        queryParameters: query,
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getPublicArticleDetail(String slug) async {
    try {
      final res = await _dio.get('/api/v1/mobile/public/articles/$slug');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> getAppointmentDetail(
    String token,
    int appointmentId,
  ) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/appointments/$appointmentId',
        options: _authOptions(token),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['appointment'] is Map) {
        return Map<String, dynamic>.from(data['appointment'] as Map);
      }
      return data;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> exportBillingCsv(String token) async {
    try {
      final res = await _dio.get(
        '/api/v1/mobile/patient/billing/export-csv',
        options: _authOptions(token),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> sendForgotPasswordOtp(String identifier) async {
    try {
      final res = await _dio.post(
        '/api/v1/mobile/auth/forgot-password/send-otp',
        data: {'identifier': identifier.trim()},
        options: Options(receiveTimeout: const Duration(seconds: 45)),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<String> resetForgotPassword({
    required String identifier,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/mobile/auth/forgot-password/reset',
        data: {
          'identifier': identifier.trim(),
          'otp_code': otpCode.trim(),
          'new_password': newPassword,
        },
        options: Options(receiveTimeout: const Duration(seconds: 45)),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return (data['message'] as String?) ??
          'Đặt lại mật khẩu thành công. Vui lòng đăng nhập.';
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String identifier,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post(
        '/api/v1/mobile/auth/change-password',
        data: {
          'identifier': identifier.trim(),
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }
}
