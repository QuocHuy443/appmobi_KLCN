import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'auth_screen.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final PatientApiService _apiService = PatientApiService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String? _lastToken;
  bool _isLoadingMeta = false;
  bool _isSubmitting = false;
  bool _isLoadingMyAppointments = false;

  List<Map<String, dynamic>> _departments = [
    {'id': 1, 'ten_khoa': 'Khoa Nội Tổng Quát'},
    {'id': 2, 'ten_khoa': 'Khoa Tim Mạch'},
    {'id': 3, 'ten_khoa': 'Khoa Nhi'},
    {'id': 4, 'ten_khoa': 'Khoa Tai Mũi Họng'},
    {'id': 5, 'ten_khoa': 'Khoa Da Liễu'},
  ];

  List<Map<String, dynamic>> _doctors = [
    {
      'id': 1,
      'ho_ten': 'BS.CKII Nguyễn Văn An',
      'hoc_vi': 'BS.CKII',
      'chuyen_khoa_id': 1,
      'ten_khoa': 'Khoa Nội Tổng Quát',
      'gia_kham': 200000,
    },
    {
      'id': 2,
      'ho_ten': 'ThS.BS Trần Thị Bình',
      'hoc_vi': 'ThS.BS',
      'chuyen_khoa_id': 2,
      'ten_khoa': 'Khoa Tim Mạch',
      'gia_kham': 250000,
    },
  ];

  List<String> _slots = const [
    '07:30',
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
  ];
  List<String> _bookedSlots = [];
  List<Map<String, dynamic>> _myAppointments = [];

  int? _selectedKhoaId = 1;
  int? _selectedBacSiId = 1;
  int _selectedDateIndex = 0;
  String _selectedTimeSlot = '09:00';
  String _searchQuery = '';

  late final List<DateTime> _upcomingDates;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _upcomingDates = List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day).add(Duration(days: index + 1)),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authVm = context.watch<AuthViewModel>();
    final token = authVm.currentUser?.token;
    if (token != _lastToken) {
      _lastToken = token;
      if (token != null && token.isNotEmpty) {
        _loadBookingMeta();
        _loadMyAppointments(token);
      } else {
        setState(() {
          _myAppointments = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDateIso(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _weekdayLabel(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      default:
        return 'CN';
    }
  }

  Future<void> _loadBookingMeta() async {
    setState(() => _isLoadingMeta = true);
    try {
      final dateStr = _formatDateIso(_upcomingDates[_selectedDateIndex]);
      final data = await _apiService.getBookingMeta(
        date: dateStr,
        chuyenKhoaId: _selectedKhoaId,
        bacSiId: _selectedBacSiId,
      );
      if (!mounted) return;
      final depts = List<Map<String, dynamic>>.from(data['departments'] ?? []);
      final docs = List<Map<String, dynamic>>.from(data['doctors'] ?? []);
      final slots = List<String>.from(data['slots'] ?? _slots);
      final booked = List<String>.from(data['booked_slots'] ?? []);

      setState(() {
        if (depts.isNotEmpty) {
          _departments = depts;
          if (_selectedKhoaId != null &&
              !_departments.any((d) => d['id'] == _selectedKhoaId)) {
            _selectedKhoaId = _departments.first['id'] as int?;
          }
        }
        _doctors = docs;
        if (_doctors.isNotEmpty) {
          if (_selectedBacSiId == null ||
              !_doctors.any((doc) => doc['id'] == _selectedBacSiId)) {
            _selectedBacSiId = _doctors.first['id'] as int?;
          }
        } else {
          _selectedBacSiId = null;
        }
        _slots = slots;
        _bookedSlots = booked;
        if (_bookedSlots.contains(_selectedTimeSlot)) {
          final firstAvailable = _slots.firstWhere(
            (s) => !_bookedSlots.contains(s),
            orElse: () => _slots.isNotEmpty ? _slots.first : '09:00',
          );
          _selectedTimeSlot = firstAvailable;
        }
        _isLoadingMeta = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMeta = false);
    }
  }

  Future<void> _loadMyAppointments(String token) async {
    setState(() => _isLoadingMyAppointments = true);
    try {
      final list = await _apiService.getAppointments(token);
      if (!mounted) return;
      setState(() {
        _myAppointments = list;
        _isLoadingMyAppointments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMyAppointments = false);
    }
  }

  Future<void> _submitAppointment() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null || user.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập tài khoản bệnh nhân để đặt lịch khám.'),
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    if (_selectedKhoaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chuyên khoa.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dateStr = _formatDateIso(_upcomingDates[_selectedDateIndex]);
      await _apiService.createAppointment(
        token: user.token,
        chuyenKhoaId: _selectedKhoaId!,
        bacSiId: _selectedBacSiId,
        date: dateStr,
        time: _selectedTimeSlot,
        lyDo: _reasonController.text.trim().isEmpty
            ? 'Đặt lịch khám qua ứng dụng H2T Mobile'
            : _reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _reasonController.clear();
      await _loadBookingMeta();
      await _loadMyAppointments(user.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald500,
          content: Text('Đặt lịch khám thành công! Đã lưu vào cơ sở dữ liệu.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rose500,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _cancelAppointment(int id) async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    try {
      await _apiService.cancelAppointment(token: user.token, appointmentId: id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy lịch hẹn thành công.')),
      );
      await _loadMyAppointments(user.token);
      await _loadBookingMeta();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.rose500,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _showRescheduleDialog(Map<String, dynamic> appt) async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '09:00';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Đổi lịch hẹn khám',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bác sĩ: ${appt['bac_si'] ?? 'Bác sĩ chuyên khoa'}',
                    style: const TextStyle(fontSize: 13, color: AppColors.slate600),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Ngày mới: ${_formatDateIso(selectedDate)}'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSlot,
                    decoration: const InputDecoration(
                      labelText: 'Giờ khám mới',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _slots
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedSlot = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.medical600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lưu lịch mới'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      try {
        await _apiService.rescheduleAppointment(
          token: user.token,
          appointmentId: appt['id'] as int,
          date: _formatDateIso(selectedDate),
          time: selectedSlot,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.emerald500,
            content: Text('Đã dời lịch khám thành công!'),
          ),
        );
        await _loadMyAppointments(user.token);
        await _loadBookingMeta();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.rose500,
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _doctors.where((doc) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (doc['ho_ten'] ?? '').toString().toLowerCase();
      final dept = (doc['ten_khoa'] ?? '').toString().toLowerCase();
      return name.contains(q) || dept.contains(q);
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'Đặt Lịch Khám Bệnh',
            style: TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Tải lại dữ liệu từ máy chủ',
              onPressed: () {
                _loadBookingMeta();
                final token = context.read<AuthViewModel>().currentUser?.token;
                if (token != null && token.isNotEmpty) {
                  _loadMyAppointments(token);
                }
              },
              icon: const Icon(Icons.refresh, color: AppColors.medical600),
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.medical600,
            unselectedLabelColor: AppColors.slate500,
            indicatorColor: AppColors.medical600,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Đặt khám mới'),
              Tab(text: 'Lịch hẹn của tôi'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingForm(filteredDoctors),
            _buildMyAppointmentsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingForm(List<Map<String, dynamic>> filteredDoctors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                icon: FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 16,
                  color: AppColors.slate400,
                ),
                hintText: 'Tìm bác sĩ, chuyên khoa...',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.slate400),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1. Chọn chuyên khoa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800,
                ),
              ),
              if (_isLoadingMeta)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _departments.map((dept) {
                final id = dept['id'] as int?;
                final name = (dept['ten_khoa'] ?? 'Chuyên khoa').toString();
                return _buildSpecialtyChip(id, name);
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            '2. Chọn bác sĩ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 12),
          if (filteredDoctors.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200),
              ),
              child: const Text(
                'Không tìm thấy bác sĩ phù hợp trong chuyên khoa này.',
                style: TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
            )
          else
            ...filteredDoctors.map((doc) {
              final docId = doc['id'] as int?;
              final name = (doc['ho_ten'] ?? 'Bác sĩ').toString();
              final deptName = (doc['ten_khoa'] ?? '').toString();
              final priceNum = (doc['gia_kham'] ?? 200000);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildDoctorCard(
                  docId,
                  name,
                  deptName,
                  '4.9',
                  '${priceNum.toString()}đ',
                ),
              );
            }),
          const SizedBox(height: 24),

          const Text(
            '3. Chọn ngày & giờ khám',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_upcomingDates.length, (idx) {
                final d = _upcomingDates[idx];
                return _buildDateCard(
                  idx,
                  _weekdayLabel(d),
                  d.day.toString().padLeft(2, '0'),
                  'Th${d.month}',
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _slots.map((slot) {
              final isBooked = _bookedSlots.contains(slot);
              return _buildTimeSlot(slot, isDisabled: isBooked);
            }).toList(),
          ),
          const SizedBox(height: 24),

          const Text(
            '4. Triệu chứng / Lý do khám',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.slate200),
            ),
            child: TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Nhập triệu chứng hoặc nhu cầu khám (VD: Đau đầu, khám tổng quát...)',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.slate400),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.medical600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: Text(
                _isSubmitting ? 'Đang xử lý...' : 'Xác nhận đặt lịch',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMyAppointmentsList() {
    final user = context.watch<AuthViewModel>().currentUser;
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.calendarXmark,
                size: 44,
                color: AppColors.slate400,
              ),
              const SizedBox(height: 12),
              const Text(
                'Đăng nhập để xem và quản lý lịch hẹn khám của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.slate600, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.medical600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đăng nhập ngay'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingMyAppointments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myAppointments.isEmpty) {
      return const Center(
        child: Text(
          'Bạn chưa có lịch hẹn nào trong hệ thống.',
          style: TextStyle(color: AppColors.slate500, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _myAppointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appt = _myAppointments[index];
        final status = (appt['trang_thai'] ?? 'Chờ xác nhận').toString();
        final canModify = status == 'Chờ xác nhận' || status == 'Đã xác nhận';
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      (appt['bac_si'] ?? 'Bác sĩ chuyên khoa').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.slate800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'Đã hủy'
                          ? AppColors.rose500.withValues(alpha: 0.12)
                          : AppColors.medical50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status == 'Đã hủy'
                            ? AppColors.rose500
                            : AppColors.medical600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${appt['chuyen_khoa'] ?? ''} • Phòng: ${appt['phong'] ?? 'Phòng khám'}',
                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 15, color: AppColors.medical600),
                  const SizedBox(width: 6),
                  Text(
                    '${appt['gio_hen'] ?? ''} - Ngày ${appt['ngay_hen'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                ],
              ),
              if ((appt['ly_do'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Lý do: ${appt['ly_do']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
              ],
              if (canModify) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showRescheduleDialog(appt),
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Đổi lịch'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _cancelAppointment(appt['id'] as int),
                      style: TextButton.styleFrom(foregroundColor: AppColors.rose500),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Hủy lịch'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecialtyChip(int? id, String label) {
    final isSelected = _selectedKhoaId == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedKhoaId = id);
        _loadBookingMeta();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.medical600 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.medical600 : AppColors.slate200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(
    int? id,
    String name,
    String specialty,
    String rating,
    String price,
  ) {
    final isSelected = _selectedBacSiId == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBacSiId = id);
        _loadBookingMeta();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.medical50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.medical600 : AppColors.slate200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.userDoctor,
                  color: AppColors.slate500,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.solidStar,
                        size: 12,
                        color: AppColors.amber500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Phí khám: $price',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.medical600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.medical600 : AppColors.slate300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(int index, String day, String date, String month) {
    final isSelected = _selectedDateIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedDateIndex = index);
        _loadBookingMeta();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 65,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.medical600 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.medical600 : AppColors.slate200,
          ),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.medical100 : AppColors.slate400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.slate800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              month,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.medical100 : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time, {bool isDisabled = false}) {
    final isSelected = _selectedTimeSlot == time && !isDisabled;
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() => _selectedTimeSlot = time);
            },
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.slate100
              : (isSelected ? AppColors.medical50 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled
                ? AppColors.slate200
                : (isSelected ? AppColors.medical600 : AppColors.slate200),
          ),
        ),
        child: Center(
          child: Text(
            isDisabled ? '$time (Kín)' : time,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDisabled
                  ? AppColors.slate300
                  : (isSelected ? AppColors.medical600 : AppColors.slate700),
            ),
          ),
        ),
      ),
    );
  }
}
