import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/appointment_booking_form.dart';
import '../widgets/request_error.dart';
import 'auth_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({
    super.key,
    this.refreshVersion = 0,
    this.initialTab = 0,
    this.initialDepartmentId,
    this.initialDoctorId,
  });

  final int refreshVersion;
  final int initialTab;
  final int? initialDepartmentId;
  final int? initialDoctorId;

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _api = PatientApiService();
  final _searchController = TextEditingController();
  String? _token;
  String? _error;
  String _statusFilter = 'all';
  String _searchQuery = '';
  List<Map<String, dynamic>> _appointments = [];
  bool _loading = false;
  bool _acting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (_token != token) {
      _token = token;
      _appointments = [];
      _error = null;
      if (token != null) _load(token);
    }
  }

  @override
  void didUpdateWidget(covariant AppointmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion && _token != null) {
      _load(_token!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load(String token) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getAppointments(token);
      if (!mounted || _token != token) return;
      setState(() {
        _appointments = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted && _token == token) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  String _normalizeStatusCode(Map<String, dynamic> a) {
    final code = (a['status_code'] ?? '').toString().toLowerCase();
    if (['waiting', 'confirmed', 'completed', 'cancelled'].contains(code)) {
      return code;
    }
    final status = (a['trang_thai'] ?? '').toString();
    if ([
      'Chờ xác nhận',
      'Chờ xét duyệt',
      'Chờ duyệt',
      'Chờ tiếp nhận',
      'waiting'
    ].contains(status)) {
      return 'waiting';
    }
    if ([
      'Đã duyệt',
      'Đã xác nhận',
      'Đã tiếp nhận',
      'Đang chờ khám',
      'Đang khám'
    ].contains(status)) {
      return 'confirmed';
    }
    if (['Đã khám', 'Hoàn thành', 'Đã hoàn thành'].contains(status)) {
      return 'completed';
    }
    if (['Đã hủy', 'cancelled'].contains(status)) {
      return 'cancelled';
    }
    return 'waiting';
  }

  Future<void> _cancel(Map<String, dynamic> appointment) async {
    if (_acting || _token == null) return;
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lịch hẹn?'),
        content: TextField(
          controller: reason,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Lý do hủy (tùy chọn)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lịch'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (confirmed != true || !mounted || _token == null) return;
    final token = _token!;
    setState(() => _acting = true);
    try {
      await _api.cancelAppointment(
        token: token,
        appointmentId: appointment['id'] as int,
        reason: text,
      );
      if (!mounted || _token != token) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy lịch hẹn.')),
      );
      await _load(token);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reschedule(Map<String, dynamic> appointment) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Đổi lịch hẹn')),
          body: AppointmentBookingForm(
            appointment: appointment,
            onSaved: () => Navigator.pop(context, true),
          ),
        ),
      ),
    );
    if (changed == true && mounted && _token != null) _load(_token!);
  }

  Future<void> _showDetailDialog(Map<String, dynamic> initialAppt) async {
    Map<String, dynamic> a = initialAppt;
    final token = _token;
    final apptId = (initialAppt['id'] as num?)?.toInt();
    if (token != null && apptId != null) {
      try {
        final fresh = await _api.getAppointmentDetail(token, apptId);
        if (fresh.isNotEmpty) {
          a = {...initialAppt, ...fresh};
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final code = (a['ma_lich_hen'] ?? a['ma_hen'] ?? '').toString();
    final dept =
        (a['ten_khoa'] ?? a['khoa'] ?? a['ten_chuyen_khoa'] ?? '').toString();
    final doctor =
        (a['bac_si'] ?? a['ten_bac_si'] ?? 'Phòng khám phân công').toString();
    final room =
        (a['ten_phong'] ?? a['phong'] ?? 'Quầy tiếp đón phân bổ').toString();
    final reason = (a['ly_do_kham'] ?? a['ly_do'] ?? '').toString();
    final cancelReason = (a['ly_do_huy'] ?? '').toString();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Phiếu hẹn #$code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine('Trạng thái:', '${a['trang_thai'] ?? ''}'),
            _detailLine('Chuyên khoa:', dept),
            _detailLine('Bác sĩ:', doctor),
            _detailLine('Phòng khám:', room),
            _detailLine('Ngày khám:', patientDate(a['ngay_hen'])),
            _detailLine(
                'Giờ hẹn:', '${a['gio_hen_short'] ?? a['gio_hen'] ?? ''}'),
            if (reason.isNotEmpty) _detailLine('Lý do khám:', reason),
            if (cancelReason.isNotEmpty)
              _detailLine('Lý do hủy:', cancelReason),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> a) {
    final status = (a['trang_thai'] ?? '').toString();
    final statusCode = _normalizeStatusCode(a);
    final pending = statusCode == 'waiting';
    final confirmed = statusCode == 'confirmed';
    final completed = statusCode == 'completed';
    final rawDate = (a['ngay_hen'] ?? '').toString().split(' ').first;
    final rawTime = (a['gio_hen'] ?? a['gio_hen_short'] ?? '').toString();
    final time = rawTime.length < 5
        ? null
        : DateTime.tryParse('$rawDate ${rawTime.substring(0, 5)}');
    final future = time != null && time.isAfter(DateTime.now());
    final dateParts = rawDate.split('-');
    final yearStr = dateParts.isNotEmpty ? dateParts[0] : '';
    final monthStr = dateParts.length >= 2 ? 'Th${dateParts[1]}' : 'Th--';
    final dayStr = dateParts.length >= 3 ? dateParts[2] : '--';

    final code = (a['ma_lich_hen'] ?? a['ma_hen'] ?? '').toString();
    final dept =
        (a['ten_khoa'] ?? a['khoa'] ?? a['ten_chuyen_khoa'] ?? '').toString();
    final rawDoctor = (a['bac_si'] ?? a['ten_bac_si'] ?? '').toString();
    final hasAssignedDoctor = rawDoctor.isNotEmpty &&
        rawDoctor != 'Bác sĩ chuyên khoa' &&
        rawDoctor != 'Đang sắp xếp bác sĩ phù hợp';
    final room =
        (a['ten_phong'] ?? a['phong'] ?? 'Tiếp đón phân bổ').toString();
    final reason = (a['ly_do_kham'] ?? a['ly_do'] ?? '').toString();
    final cancelReason = (a['ly_do_huy'] ?? '').toString();
    final isDoctorScheduled = a['is_doctor_scheduled'] == true;

    final (Color badgeBg, Color badgeText) = switch (statusCode) {
      'waiting' => (Colors.amber.shade50, Colors.amber.shade800),
      'confirmed' => (Colors.teal.shade50, AppColors.medical700),
      'completed' => (Colors.blue.shade50, Colors.blue.shade700),
      _ => (AppColors.slate100, AppColors.slate600),
    };

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khối hiển thị ngày tháng năm giống bản Web
                Container(
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.medical50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.medical100),
                  ),
                  child: Column(
                    children: [
                      Text(
                        monthStr,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.medical700,
                        ),
                      ),
                      Text(
                        dayStr,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        yearStr,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.medical50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$code',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.medical700,
                              ),
                            ),
                          ),
                          Text(
                            '${a['gio_hen_short'] ?? a['gio_hen'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeText,
                              ),
                            ),
                          ),
                          if (isDoctorScheduled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Bác sĩ hẹn mới',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dept,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasAssignedDoctor
                            ? 'Bác sĩ: $rawDoctor • Phòng: $room'
                            : 'Bác sĩ: Phòng khám phân công • Phòng: $room',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.slate600,
                        ),
                      ),
                      Text(
                        'Ngày: ${patientDate(a['ngay_hen'])} • ${a['gio_hen'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Lý do: $reason',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.slate600,
                ),
              ),
            ],
            if (cancelReason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Lý do hủy: $cancelReason',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.rose500,
                ),
              ),
            ],
            if (confirmed)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Lịch đã duyệt: không thể đổi lịch.',
                  style: TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
              ),
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDetailDialog(a),
                  icon: const Icon(Icons.info_outline, size: 17),
                  label: const Text('Chi tiết'),
                ),
                if (future && pending)
                  TextButton.icon(
                    onPressed: _acting ? null : () => _reschedule(a),
                    icon: const Icon(Icons.edit_calendar, size: 17),
                    label: const Text('Đổi lịch'),
                  ),
                if (future && (pending || confirmed) && !completed)
                  TextButton.icon(
                    onPressed: _acting ? null : () => _cancel(a),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 17, color: AppColors.rose500),
                    label: const Text(
                      'Hủy lịch',
                      style: TextStyle(color: AppColors.rose500),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredAppointments() {
    return _appointments.where((a) {
      if (_statusFilter != 'all' && _normalizeStatusCode(a) != _statusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final combined = [
          a['ma_lich_hen'],
          a['ma_hen'],
          a['ten_khoa'],
          a['khoa'],
          a['bac_si'],
          a['ten_bac_si'],
          a['ly_do_kham'],
          a['ly_do'],
        ].where((e) => e != null).join(' ').toLowerCase();
        if (!combined.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final waitingCount =
        _appointments.where((a) => _normalizeStatusCode(a) == 'waiting').length;
    final confirmedCount = _appointments
        .where((a) => _normalizeStatusCode(a) == 'confirmed')
        .length;
    final completedCount = _appointments
        .where((a) => _normalizeStatusCode(a) == 'completed')
        .length;
    final cancelledCount = _appointments
        .where((a) => _normalizeStatusCode(a) == 'cancelled')
        .length;
    final filtered = _filteredAppointments();

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          title: const Text('Đặt lịch khám bệnh'),
          actions: [
            if (_token != null)
              IconButton(
                tooltip: 'Làm mới lịch hẹn',
                onPressed: _loading ? null : () => _load(_token!),
                icon: const Icon(Icons.refresh, color: AppColors.medical600),
              ),
          ],
          bottom: TabBar(
            labelColor: AppColors.medical600,
            unselectedLabelColor: AppColors.slate500,
            indicatorColor: AppColors.medical600,
            tabs: [
              const Tab(text: 'Đặt lịch mới'),
              Tab(text: 'Lịch hẹn của tôi (${_appointments.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AppointmentBookingForm(
              initialDepartmentId: widget.initialDepartmentId,
              initialDoctorId: widget.initialDoctorId,
              onSaved: () {
                if (_token != null) _load(_token!);
              },
            ),
            _token == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.calendarPlus,
                            size: 46,
                            color: AppColors.medical600,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Vui lòng đăng nhập để xem và quản lý lịch hẹn của bạn.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(),
                              ),
                            ),
                            child: const Text('Đăng nhập'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(_token!),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Thanh tìm kiếm và lọc trạng thái giống bản Web
                        TextField(
                          controller: _searchController,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.trim()),
                          decoration: InputDecoration(
                            hintText:
                                'Tìm theo mã hẹn, bác sĩ, chuyên khoa...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.slate200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.slate200),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final tab in [
                                ('all', 'Tất cả (${_appointments.length})'),
                                ('waiting', 'Chờ duyệt ($waitingCount)'),
                                ('confirmed', 'Đã xác nhận ($confirmedCount)'),
                                ('completed', 'Đã khám ($completedCount)'),
                                ('cancelled', 'Đã hủy ($cancelledCount)'),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      tab.$2,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    selected: _statusFilter == tab.$1,
                                    selectedColor: AppColors.medical100,
                                    onSelected: (_) =>
                                        setState(() => _statusFilter = tab.$1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_loading) const LinearProgressIndicator(),
                        if (_error != null)
                          RequestError(
                            message: _error!,
                            onRetry: () => _load(_token!),
                          ),
                        if (!_loading && _error == null && filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                _appointments.isEmpty
                                    ? 'Bạn chưa có lịch hẹn nào.'
                                    : 'Không tìm thấy lịch hẹn phù hợp với bộ lọc.',
                                style: const TextStyle(
                                  color: AppColors.slate500,
                                ),
                              ),
                            ),
                          ),
                        ...filtered.map(_card),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
