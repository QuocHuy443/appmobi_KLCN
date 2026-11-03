import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/patient_format.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import 'request_error.dart';

class AppointmentBookingForm extends StatefulWidget {
  const AppointmentBookingForm({super.key, this.appointment, required this.onSaved});
  final Map<String, dynamic>? appointment;
  final VoidCallback onSaved;
  @override
  State<AppointmentBookingForm> createState() => _AppointmentBookingFormState();
}

class _AppointmentBookingFormState extends State<AppointmentBookingForm> {
  final _api = PatientApiService();
  final _reason = TextEditingController();
  List<Map<String,dynamic>> _departments = [], _doctors = [], _services = [];
  List<String> _slots = [];
  int? _department, _doctor, _service;
  String? _slot, _error, _token;
  DateTime _date = DateTime.now();
  bool _loading = false, _sending = false;
  int _request = 0;
  bool get _editing => widget.appointment != null;
  String get _day => _date.toIso8601String().substring(0,10);
  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    if (appointment != null) {
      _department = appointment['chuyen_khoa_id'] as int?;
      _doctor = appointment['bac_si_id'] as int?;
      _date = DateTime.now().add(const Duration(days: 1));
      _reason.text = (appointment['ly_do_kham'] ?? '').toString();
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context.watch<AuthViewModel>().currentUser?.token;
    if (_token != token) {
      _token = token; _slots = []; _error = null;
      if (token != null) _loadMeta();
    }
  }
  @override
  void dispose() { ++_request; _reason.dispose(); super.dispose(); }
  Future<void> _loadMeta() async {
    final token = _token;
    if (token == null) return;
    final request = ++_request;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getBookingMeta(token: token, date: _day, chuyenKhoaId: _department, bacSiId: _doctor);
      if (!mounted || request != _request || _token != token) return;
      setState(() {
        _departments = List<Map<String,dynamic>>.from(data['departments'] ?? data['specialties'] ?? []);
        _department ??= data['department_id'] as int?;
        _doctors = List<Map<String,dynamic>>.from(data['doctors'] ?? []);
        if (_doctor != null && !_doctors.any((d) => d['id'] == _doctor)) _doctor = null;
        _services = List<Map<String,dynamic>>.from(data['exam_services'] ?? []);
        if (_service != null && !_services.any((s) => s['id'] == _service)) _service = null;
        _slots = List<String>.from(data['slots'] ?? []);
        if (!_slots.contains(_slot)) _slot = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted && request == _request && _token == token) setState(() { _error = '$e'; _loading = false; _slots = []; });
    }
  }
  Future<void> _submit() async {
    if (_sending || _loading || _slot == null || _department == null || _token == null) return;
    final token = _token!;
    if (context.read<AuthViewModel>().currentUser?.profileComplete != true) return;
    if (_reason.text.trim().length > 2000) { setState(() => _error='Lý do khám tối đa 2000 ký tự.'); return; }
    setState(() { _sending = true; _error = null; });
    try {
      if (_editing) {
        await _api.rescheduleAppointment(token: token, appointmentId: widget.appointment!['id'] as int,
          date: _day, time: _slot, bacSiId: _doctor, lyDo: _reason.text.trim());
      } else {
        await _api.createAppointment(token: token, chuyenKhoaId: _department!, bacSiId: _doctor,
          examServiceId: _service, date: _day, time: _slot, lyDo: _reason.text.trim());
      }
      if (!mounted || _token != token) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editing ? 'Đã đổi lịch hẹn.' : 'Đã gửi yêu cầu đặt lịch. Vui lòng chờ xác nhận.')));
      if (!_editing) { _reason.clear(); _slot = null; }
      widget.onSaved();
      if (mounted && !_editing) await _loadMeta();
    } catch (e) {
      if (mounted && _token == token) setState(() => _error='$e');
    } finally { if (mounted) setState(() => _sending=false); }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Chọn lịch khám', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    DropdownButtonFormField<int>(key: ValueKey('dept_$_department'), initialValue: _departments.any((d) => d['id'] == _department) ? _department : null, isExpanded: true,
      decoration: const InputDecoration(labelText: 'Chuyên khoa', border: OutlineInputBorder()),
      items: _departments.map((d) => DropdownMenuItem(value: d['id'] as int, child: Text('${d['ten_khoa'] ?? d['ten_chuyen_khoa']}', overflow: TextOverflow.ellipsis))).toList(),
      onChanged: _editing || _loading || _sending ? null : (id) { setState(() { _department=id; _doctor=null; _service=null; _slot=null; }); _loadMeta(); }),
    const SizedBox(height: 14),
    if (!_editing) ...[
      DropdownButtonFormField<int>(key: ValueKey('service_${_department}_$_service'), initialValue: _service, isExpanded: true,
        decoration: const InputDecoration(labelText: 'Loại khám / Dịch vụ', border: OutlineInputBorder()),
        items: [const DropdownMenuItem<int>(value:null, child: Text('Khám tiêu chuẩn khoa')), ..._services.map((s) => DropdownMenuItem(value:s['id'] as int, child: Text('${s['ten_dich_vu']} — ${patientMoney(s['don_gia'])}', overflow: TextOverflow.ellipsis)))],
        onChanged: _sending ? null : (v) => setState(() => _service=v)),
      const SizedBox(height: 14),
    ],
    OutlinedButton.icon(onPressed: _sending ? null : () async {
      final now = DateTime.now();
      final picked = await showDatePicker(context:context, initialDate:_date, firstDate:DateTime(now.year,now.month,now.day), lastDate:now.add(const Duration(days:365)));
      if (!mounted || picked==null) return;
      setState(() { _date=picked; _slot=null; }); await _loadMeta();
    }, icon: const Icon(Icons.calendar_today), label: Text('Ngày khám: ${patientDate(_day)}')),
    const SizedBox(height: 14),
    DropdownButtonFormField<int>(key: ValueKey('doctor_${_department}_$_doctor'), initialValue:_doctors.any((d) => d['id'] == _doctor) ? _doctor : null, isExpanded:true,
      decoration: const InputDecoration(labelText:'Bác sĩ', border:OutlineInputBorder()),
      items:[const DropdownMenuItem<int>(value:null,child:Text('Hệ thống phân công bác sĩ phù hợp')), ..._doctors.map((d)=>DropdownMenuItem(value:d['id'] as int,child:Text('${d['hoc_vi'] ?? ''} ${d['ho_ten'] ?? d['ten_bac_si']}',overflow:TextOverflow.ellipsis)))],
      onChanged:_loading || _sending ? null : (v) { setState(() { _doctor=v; _slot=null; }); _loadMeta(); }),
    const SizedBox(height: 18),
    if (_loading) const LinearProgressIndicator(),
    if (!_loading && _error==null && _slots.isEmpty) const Padding(padding:EdgeInsets.symmetric(vertical:16),child:Text('Chưa có khung giờ có thể đặt. Hãy chọn ngày hoặc bác sĩ khác.')),
    Wrap(spacing:8,runSpacing:8,children:_slots.map((s)=>ChoiceChip(label:Text(s),selected:_slot==s,selectedColor:AppColors.medical100,onSelected:_loading || _sending ? null : (_) => setState(()=>_slot=s))).toList()),
    const SizedBox(height:18),
    TextField(controller:_reason,maxLines:3,maxLength:2000,decoration:const InputDecoration(labelText:'Lý do khám',border:OutlineInputBorder())),
    if (_error!=null) RequestError(message:_error!,onRetry:_loadMeta),
    FilledButton(onPressed:_sending || _loading || _slot==null ? null : _submit,child:Text(_sending?'Đang gửi...':_editing?'Lưu lịch mới':'Gửi yêu cầu đặt lịch')),
    const SizedBox(height:12),
    const Text('Khả năng đặt lịch có thể thay đổi. Backend sẽ kiểm tra lại ca trực và xung đột khi gửi yêu cầu.',style:TextStyle(fontSize:12,color:AppColors.slate500)),
  ]);
}
