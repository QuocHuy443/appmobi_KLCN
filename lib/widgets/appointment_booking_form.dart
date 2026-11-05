import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'request_error.dart';

class AppointmentBookingForm extends StatefulWidget {
  const AppointmentBookingForm({
    super.key,
    this.appointment,
    this.initialDepartmentId,
    this.initialDoctorId,
    required this.onSaved,
  });

  final Map<String, dynamic>? appointment;
  final int? initialDepartmentId;
  final int? initialDoctorId;
  final VoidCallback onSaved;

  @override
  State<AppointmentBookingForm> createState() => _AppointmentBookingFormState();
}

class _AppointmentBookingFormState extends State<AppointmentBookingForm> {
  final _api = PatientApiService();
  final _reason = TextEditingController();
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _shifts = [];
  Map<String, dynamic> _slotSummary = {};
  Map<String, dynamic> _doctorSlotStates = {};
  List<String> _slots = [];
  int? _department;
  int? _doctor;
  int? _service;
  String? _slot;
  String? _error;
  String? _token;
  DateTime _date = DateTime.now();
  bool _loading = false;
  bool _sending = false;
  int _request = 0;

  bool get _editing => widget.appointment != null;
  String get _day => _date.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    if (appointment != null) {
      _department = appointment['chuyen_khoa_id'] as int?;
      _doctor = appointment['bac_si_id'] as int?;
      _date = DateTime.now().add(const Duration(days: 1));
      _reason.text = (appointment['ly_do_kham'] ?? appointment['ly_do'] ?? '').toString();
    } else {
      if (widget.initialDepartmentId != null) {
        _department = widget.initialDepartmentId;
      }
      if (widget.initialDoctorId != null) {
        _doctor = widget.initialDoctorId;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (_token != token) {
      _token = token;
      _slots = [];
      _error = null;
      if (token != null) _loadMeta();
    }
  }

  @override
  void dispose() {
    ++_request;
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    final token = _token;
    if (token == null) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getBookingMeta(
        token: token,
        date: _day,
        chuyenKhoaId: _department,
        bacSiId: _doctor,
      );
      if (!mounted || request != _request || _token != token) return;
      final matrix = data['matrix'] is Map
          ? Map<String, dynamic>.from(data['matrix'] as Map)
          : <String, dynamic>{};
      final rawShifts = matrix['shifts'] is List ? matrix['shifts'] as List : const [];
      setState(() {
        _departments = List<Map<String, dynamic>>.from(
            data['departments'] ?? data['specialties'] ?? []);
        _department ??= data['department_id'] as int? ??
            (_departments.isNotEmpty ? _departments.first['id'] as int? : null);
        _doctors = List<Map<String, dynamic>>.from(data['doctors'] ?? []);
        if (_doctor != null && !_doctors.any((d) => d['id'] == _doctor)) {
          _doctor = null;
        }
        _services = List<Map<String, dynamic>>.from(data['exam_services'] ?? []);
        if (_service != null && !_services.any((s) => s['id'] == _service)) {
          _service = null;
        }
        _slots = List<String>.from(data['slots'] ?? []);
        _shifts = rawShifts
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _slotSummary = matrix['slot_summary'] is Map
            ? Map<String, dynamic>.from(matrix['slot_summary'] as Map)
            : {};
        _doctorSlotStates = matrix['doctor_slot_states'] is Map
            ? Map<String, dynamic>.from(matrix['doctor_slot_states'] as Map)
            : {};
        if (!_slots.contains(_slot)) _slot = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted && request == _request && _token == token) {
        setState(() {
          _error = '$e';
          _loading = false;
          _slots = [];
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_sending || _loading || _slot == null || _department == null || _token == null) {
      return;
    }
    final token = _token!;
    if (context.read<AuthViewModel>().currentUser?.profileComplete != true) return;
    if (_reason.text.trim().length > 2000) {
      setState(() => _error = 'Lý do khám tối đa 2000 ký tự.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (_editing) {
        await _api.rescheduleAppointment(
          token: token,
          appointmentId: widget.appointment!['id'] as int,
          date: _day,
          time: _slot,
          bacSiId: _doctor,
          lyDo: _reason.text.trim(),
        );
      } else {
        await _api.createAppointment(
          token: token,
          chuyenKhoaId: _department!,
          bacSiId: _doctor,
          examServiceId: _service,
          date: _day,
          time: _slot,
          lyDo: _reason.text.trim(),
        );
      }
      if (!mounted || _token != token) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald500,
          content: Text(
            _editing
                ? 'Đã đổi lịch hẹn thành công.'
                : 'Đã gửi yêu cầu đặt lịch. Vui lòng chờ tiếp đón xác nhận.',
          ),
        ),
      );
      if (!_editing) {
        _reason.clear();
        _slot = null;
      }
      widget.onSaved();
      if (mounted && !_editing) await _loadMeta();
    } catch (e) {
      if (mounted && _token == token) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _selectedDepartmentName() {
    final dep = _departments.where((d) => d['id'] == _department).firstOrNull;
    if (dep == null) return 'Chưa chọn chuyên khoa';
    return (dep['ten_khoa'] ?? dep['ten_chuyen_khoa'] ?? 'Chuyên khoa').toString();
  }

  String _selectedServiceName() {
    final srv = _services.where((s) => s['id'] == _service).firstOrNull;
    if (srv == null) return 'Khám tiêu chuẩn khoa';
    return (srv['ten_dich_vu'] ?? 'Khám tiêu chuẩn khoa').toString();
  }

  String _selectedDoctorName() {
    final doc = _doctors.where((d) => d['id'] == _doctor).firstOrNull;
    if (doc == null) return 'Để phòng khám tự phân công';
    final full = doc['full_name']?.toString();
    if (full != null && full.isNotEmpty) return full;
    final degree = (doc['hoc_vi'] ?? 'BS').toString();
    final name = (doc['ho_ten'] ?? doc['ten_bac_si'] ?? '').toString();
    return '$degree. $name'.trim();
  }

  num _estimatedFee() {
    final srv = _services.where((s) => s['id'] == _service).firstOrNull;
    if (srv != null && srv['don_gia'] != null) {
      return srv['don_gia'] is num
          ? srv['don_gia'] as num
          : (num.tryParse('${srv['don_gia']}') ?? 150000);
    }
    final dep = _departments.where((d) => d['id'] == _department).firstOrNull;
    if (dep != null && dep['gia_kham_mac_dinh'] != null) {
      return dep['gia_kham_mac_dinh'] is num
          ? dep['gia_kham_mac_dinh'] as num
          : (num.tryParse('${dep['gia_kham_mac_dinh']}') ?? 150000);
    }
    return 150000;
  }

  String _slotStatus(String time) {
    if (!_slots.contains(time)) {
      if (_doctor != null) {
        final docStates = _doctorSlotStates['$_doctor'];
        if (docStates is Map && docStates[time] is Map) {
          return (docStates[time]['status'] ?? 'off_duty').toString();
        }
      }
      final summary = _slotSummary[time];
      if (summary is Map) {
        return (summary['status'] ?? 'off_duty').toString();
      }
      return 'unavailable';
    }
    if (_doctor != null) {
      final docStates = _doctorSlotStates['$_doctor'];
      if (docStates is Map && docStates[time] is Map) {
        return (docStates[time]['status'] ?? 'available').toString();
      }
    }
    final summary = _slotSummary[time];
    if (summary is Map) {
      return (summary['status'] ?? 'available').toString();
    }
    return 'available';
  }

  Widget _buildStepHeader(String stepNumber, String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.medical600,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotChip(String s) {
    final isAvailable = _slots.contains(s);
    final isSelected = _slot == s;
    final status = _slotStatus(s);
    final isPending = isAvailable && status == 'pending';
    final isBooked = !isAvailable && status == 'booked';

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.medical700
                  : !isAvailable
                      ? (isBooked ? AppColors.rose500 : AppColors.slate300)
                      : isPending
                          ? AppColors.amber500
                          : AppColors.emerald500,
            ),
          ),
          const SizedBox(width: 6),
          Text(s),
        ],
      ),
      selected: isSelected,
      selectedColor: AppColors.medical100,
      backgroundColor: isAvailable
          ? (isPending ? Colors.amber.shade50 : Colors.white)
          : AppColors.slate100,
      disabledColor: AppColors.slate100,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected
            ? AppColors.medical700
            : isAvailable
                ? AppColors.slate800
                : AppColors.slate400,
      ),
      onSelected: (!isAvailable || _loading || _sending)
          ? null
          : (_) => setState(() => _slot = (_slot == s ? null : s)),
    );
  }

  Widget _buildSlotsSection() {
    if (_shifts.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final shift in _shifts) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled,
                      size: 15, color: AppColors.medical600),
                  const SizedBox(width: 6),
                  Text(
                    (shift['name'] ?? 'Ca khám').toString(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<String>.from(shift['slots'] ?? [])
                  .map(_buildSlotChip)
                  .toList(),
            ),
          ],
          if (_slots.isEmpty && !_loading && _error == null)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Chưa có khung giờ có thể đặt. Hãy chọn ngày hoặc bác sĩ khác.',
                style: TextStyle(color: AppColors.rose500, fontSize: 12.5),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_loading && _error == null && _slots.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Chưa có khung giờ có thể đặt. Hãy chọn ngày hoặc bác sĩ khác.',
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _slots.map(_buildSlotChip).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner giới thiệu giống Web
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.medical50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.medical100),
          ),
          child: Row(
            children: [
              const FaIcon(FontAwesomeIcons.shieldHalved,
                  color: AppColors.medical600, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editing ? 'Thay đổi thời gian hẹn khám' : 'Chọn lịch khám',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    const Text(
                      'Đặt trước giữ chỗ, chủ động thời gian và tiếp đón nhanh tại quầy.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.slate600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bước 1: Chọn chuyên khoa và dịch vụ khám
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.slate200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  '1',
                  'Chọn chuyên khoa khám',
                  subtitle: 'Chọn khoa và gói khám chuyên ngành phù hợp',
                ),
                DropdownButtonFormField<int>(
                  key: ValueKey('dept_$_department'),
                  initialValue: _departments.any((d) => d['id'] == _department)
                      ? _department
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Chuyên khoa',
                    border: OutlineInputBorder(),
                  ),
                  items: _departments
                      .map((d) => DropdownMenuItem(
                            value: d['id'] as int,
                            child: Text(
                              '${d['ten_khoa'] ?? d['ten_chuyen_khoa']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: _editing || _loading || _sending
                      ? null
                      : (id) {
                          setState(() {
                            _department = id;
                            _doctor = null;
                            _service = null;
                            _slot = null;
                          });
                          _loadMeta();
                        },
                ),
                if (!_editing && _departments.length > 1) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _departments.map((d) {
                      final id = d['id'] as int;
                      final selected = _department == id;
                      return ActionChip(
                        backgroundColor:
                            selected ? AppColors.medical600 : AppColors.slate50,
                        side: BorderSide(
                          color: selected
                              ? AppColors.medical600
                              : AppColors.slate200,
                        ),
                        label: Text(
                          '${d['ten_khoa'] ?? d['ten_chuyen_khoa']}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColors.slate700,
                          ),
                        ),
                        onPressed: _loading || _sending
                            ? null
                            : () {
                                if (_department == id) return;
                                setState(() {
                                  _department = id;
                                  _doctor = null;
                                  _service = null;
                                  _slot = null;
                                });
                                _loadMeta();
                              },
                      );
                    }).toList(),
                  ),
                ],
                if (!_editing) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    key: ValueKey('service_${_department}_$_service'),
                    initialValue: _service,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Loại khám / Dịch vụ',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Khám tiêu chuẩn khoa'),
                      ),
                      ..._services.map((s) => DropdownMenuItem(
                            value: s['id'] as int,
                            child: Text(
                              '${s['ten_dich_vu']} — ${patientMoney(s['don_gia'])}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged:
                        _sending ? null : (v) => setState(() => _service = v),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Bước 2: Chọn ngày và khung giờ khám
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.slate200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  '2',
                  'Chọn ngày và khung giờ khám dự kiến',
                  subtitle: 'Nhấp vào giờ trống để chọn, nhấp lại để bỏ chọn',
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sending
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date.isBefore(today) ? today : _date,
                                  firstDate: today,
                                  lastDate: today.add(const Duration(days: 365)),
                                );
                                if (!mounted || picked == null) return;
                                setState(() {
                                  _date = picked;
                                  _slot = null;
                                });
                                await _loadMeta();
                              },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text('Ngày khám: ${patientDate(_day)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final item in [
                      ('Hôm nay', today),
                      ('Ngày mai', tomorrow),
                      ('Ngày kia', dayAfter),
                    ])
                      ChoiceChip(
                        label: Text(item.$1, style: const TextStyle(fontSize: 11.5)),
                        selected: _day == item.$2.toIso8601String().substring(0, 10),
                        selectedColor: AppColors.medical100,
                        onSelected: _loading || _sending
                            ? null
                            : (_) {
                                setState(() {
                                  _date = item.$2;
                                  _slot = null;
                                });
                                _loadMeta();
                              },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Chú thích trạng thái khung giờ giống bản Web
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _legendDot(AppColors.emerald500, 'Khả dụng'),
                    _legendDot(AppColors.medical600, 'Đang chọn'),
                    _legendDot(AppColors.amber500, 'Chờ duyệt'),
                    _legendDot(AppColors.slate300, 'Không có ca / Đã kín'),
                  ],
                ),
                const SizedBox(height: 8),
                if (_loading) const LinearProgressIndicator(),
                _buildSlotsSection(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Bước 3: Chọn bác sĩ khám tiếp nhận
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.slate200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  '3',
                  'Bác sĩ khám tiếp nhận',
                  subtitle: 'Chọn bác sĩ trực chuyên khoa hoặc để hệ thống phân công',
                ),
                DropdownButtonFormField<int>(
                  key: ValueKey('doctor_${_department}_$_doctor'),
                  initialValue:
                      _doctors.any((d) => d['id'] == _doctor) ? _doctor : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Bác sĩ',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Hệ thống phân công bác sĩ phù hợp'),
                    ),
                    ..._doctors.map((d) => DropdownMenuItem(
                          value: d['id'] as int,
                          child: Text(
                            '${d['hoc_vi'] ?? ''} ${d['ho_ten'] ?? d['ten_bac_si']}'
                                .trim(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: _loading || _sending
                      ? null
                      : (v) {
                          setState(() {
                            _doctor = v;
                            _slot = null;
                          });
                          _loadMeta();
                        },
                ),
                if (_doctors.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ..._doctors.map((d) {
                    final docId = d['id'] as int;
                    final isSelected = _doctor == docId;
                    final room = (d['ten_phong'] ?? 'Phòng chuyên khoa').toString();
                    final exp = d['kinh_nghiem'] != null
                        ? '${d['kinh_nghiem']} năm kinh nghiệm'
                        : 'Bác sĩ chuyên khoa';
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _loading || _sending
                            ? null
                            : () {
                                setState(() {
                                  _doctor = isSelected ? null : docId;
                                  _slot = null;
                                });
                                _loadMeta();
                              },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.medical50
                                : AppColors.slate50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.medical500
                                  : AppColors.slate200,
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.medical100,
                                child: FaIcon(
                                  FontAwesomeIcons.userDoctor,
                                  size: 14,
                                  color: AppColors.medical700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${d['hoc_vi'] ?? 'BS'} ${d['ho_ten'] ?? d['ten_bac_si'] ?? ''}'
                                          .trim(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.slate800,
                                      ),
                                    ),
                                    Text(
                                      '$room • $exp',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: AppColors.medical600, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Bước 4: Triệu chứng và ghi chú
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.slate200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepHeader(
                  '4',
                  'Mô tả triệu chứng và Ghi chú y tế',
                  subtitle: 'Giúp bác sĩ nắm bắt tình trạng sức khỏe trước khi khám',
                ),
                TextField(
                  controller: _reason,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Lý do khám',
                    hintText:
                        'Mô tả các triệu chứng đang gặp phải (ví dụ: đau đầu, sốt nhẹ, khó tiêu...)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Thẻ tóm tắt Thông tin phiếu hẹn giống cột phải trên Web
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.medical100, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.receipt,
                        size: 15, color: AppColors.medical600),
                    SizedBox(width: 8),
                    Text(
                      'Thông tin phiếu hẹn',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (user != null) ...[
                  _summaryRow('Người khám:', user.name),
                  _summaryRow('Mã bệnh nhân:', user.patientCode),
                ],
                _summaryRow('Chuyên khoa:', _selectedDepartmentName()),
                if (!_editing)
                  _summaryRow('Loại hình khám:', _selectedServiceName()),
                _summaryRow(
                  'Thời gian khám:',
                  '${_slot ?? 'Chưa chọn giờ'} • ${patientDate(_day)}',
                ),
                _summaryRow('Bác sĩ khám:', _selectedDoctorName()),
                _summaryRow('Trạng thái ban đầu:', 'Chờ xét duyệt'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giá khám niêm yết (dự kiến):',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate700,
                      ),
                    ),
                    Text(
                      patientMoney(_estimatedFee()),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.medical700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '* Phí khám và mức giảm BHYT (nếu có) được đối soát tại quầy tiếp đón khi đến khám.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_error != null) RequestError(message: _error!, onRetry: _loadMeta),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _sending || _loading || _slot == null ? null : _submit,
            icon: const Icon(Icons.event_available),
            label: Text(
              _sending
                  ? 'Đang gửi...'
                  : _editing
                      ? 'Lưu lịch mới'
                      : 'Gửi yêu cầu đặt lịch',
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Khả năng đặt lịch có thể thay đổi. Hệ thống sẽ kiểm tra lại ca trực và xung đột khi gửi yêu cầu.',
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: AppColors.slate600),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.slate500),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
