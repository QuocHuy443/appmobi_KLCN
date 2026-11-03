import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../services/patient_api_service.dart';
import '../widgets/request_error.dart';

class CompleteProfileScreen extends StatelessWidget {
  const CompleteProfileScreen({super.key, this.apiService});
  final PatientApiService? apiService;
  @override
  Widget build(BuildContext context) => PersonalProfileScreen(onboarding: true, apiService: apiService);
}

class PersonalProfileScreen extends StatefulWidget {
  const PersonalProfileScreen({super.key, this.onboarding = false, this.apiService});
  final bool onboarding;
  final PatientApiService? apiService;
  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  late final _api = widget.apiService ?? PatientApiService();
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  static const _labels = {
    'username': 'Tên đăng nhập', 'ho_ten': 'Họ và tên', 'sdt': 'Số điện thoại',
    'ngay_sinh': 'Ngày sinh (YYYY-MM-DD)', 'email': 'Email', 'cccd': 'Căn cước công dân',
    'bhyt': 'Mã số BHYT', 'dia_chi': 'Địa chỉ cư trú', 'ghi_chu_nhom_mau': 'Ghi chú nhóm máu',
    'di_ung': 'Tiền sử dị ứng', 'tien_su_benh': 'Tiền sử bệnh lý', 'tien_su_gia_dinh': 'Tiền sử gia đình',
    'nguoi_than_ho_ten': 'Họ tên người thân', 'nguoi_than_sdt': 'Số điện thoại người thân',
    'nguoi_than_quan_he': 'Quan hệ người thân',
  };
  String _gender = 'Nam';
  String _blood = 'Chưa rõ';
  List<String> _bloodTypes = [];
  Map<String, dynamic> _patient = {};
  bool _loading = true, _saving = false, _uploading = false;
  String? _error;
  String? _token;

  @override
  void initState() {
    super.initState();
    for (final key in _labels.keys) { _fields[key] = TextEditingController(); }
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _load(); });
  }
  @override
  void dispose() { for (final field in _fields.values) { field.dispose(); } super.dispose(); }

  bool _active(String token) => mounted && context.read<AuthViewModel>().currentUser?.token == token;

  Future<void> _load() async {
    final token = context.read<AuthViewModel>().currentUser?.token;
    if (token == null) return;
    _token = token;
    setState(() { _loading = true; _error = null; });
    try {
      final bundle = await _api.getProfileBundle(token);
      if (!mounted || !_active(token)) return;
      final patient = Map<String, dynamic>.from(bundle['patient'] as Map);
      final catalogs = bundle['catalogs'] as Map? ?? {};
      for (final key in _fields.keys) {
        _fields[key]!.text = (patient[key] ?? '').toString();
      }
      _fields['ngay_sinh']!.text = _fields['ngay_sinh']!.text.split(' ').first;
      setState(() {
        _patient = patient;
        _gender = ['Nam', 'Nữ'].contains(patient['gioi_tinh']) ? patient['gioi_tinh'] : 'Nam';
        _bloodTypes = List<String>.from(catalogs['nhom_mau'] ?? []);
        _blood = (patient['nhom_mau'] ?? 'Chưa rõ').toString();
        if (!_bloodTypes.contains(_blood)) _bloodTypes.insert(0, _blood);
        _loading = false;
      });
    } catch (error) { if (_active(token)) setState(() { _error = '$error'; _loading = false; }); }
  }

  String? _validate(String key, String? raw) {
    final value = raw?.trim() ?? '';
    final required = key == 'ho_ten' || key == 'ngay_sinh';
    if (required && value.isEmpty) return 'Vui lòng nhập ${_labels[key]!.toLowerCase()}';
    if (value.isEmpty) return null;
    if (['sdt', 'nguoi_than_sdt'].contains(key) && !RegExp(r'^(03|05|07|08|09)\d{8}$').hasMatch(value)) return 'Số di động Việt Nam gồm 10 chữ số';
    if (key == 'cccd' && (!RegExp(r'^\d{12}$').hasMatch(value) || value.split('').toSet().length == 1)) return 'CCCD gồm 12 số hợp lệ';
    if (key == 'bhyt' && (!RegExp(r'^\d{10}$').hasMatch(value) || value == '0000000000')) return 'BHYT gồm đúng 10 số hợp lệ';
    if (key == 'email' && (value.length > 100 || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value))) return 'Email không hợp lệ';
    if (['ho_ten', 'nguoi_than_ho_ten'].contains(key) && (value.length < 2 || value.length > 100 || RegExp(r'[0-9<>\[\]{}]').hasMatch(value))) return 'Họ tên từ 2–100 ký tự, không chứa số/ký tự lạ';
    if (key == 'dia_chi' && (value.length < 5 || value.length > 255)) return 'Địa chỉ từ 5–255 ký tự';
    if (key == 'ngay_sinh') {
      final date = DateTime.tryParse(value);
      if (date == null || date.toIso8601String().substring(0,10) != value || date.isAfter(DateTime.now()) || DateTime.now().year - date.year > 130) return 'Ngày sinh không hợp lệ';
    }
    if (key == 'username' && (value.length < 3 || value.length > 50 || value.contains(' '))) return 'Tên đăng nhập từ 3–50 ký tự, không có khoảng trắng';
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final token = _token;
    if (token == null) return;
    setState(() { _saving = true; _error = null; });
    final data = {for (final entry in _fields.entries) entry.key: entry.value.text.trim(), 'gioi_tinh': _gender, 'nhom_mau': _blood};
    if (widget.onboarding) data.remove('username');
    try {
      if (widget.onboarding) { await _api.completeProfile(token, data); }
      else { await _api.updateProfile(token: token, profileData: data); }
      final profile = await _api.getProfile(token);
      if (!mounted || !_active(token)) return;
      context.read<AuthViewModel>().updatePatientProfile(token, profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu thông tin cá nhân.')));
      if (!widget.onboarding) Navigator.pop(context, true);
    } catch (error) {
      if (_active(token)) setState(() { _error = '$error'; });
    } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _avatar({bool fromUrl = false}) async {
    if (_uploading || _token == null) return;
    final token = _token!;
    setState(() { _uploading = true; _error = null; });
    try {
      if (fromUrl) {
        final controller = TextEditingController();
        final url = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Nhập URL ảnh HTTPS'),
          content: TextField(controller: controller, decoration: const InputDecoration(helperText: 'Nguồn ảnh phải được backend cho phép.')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Dùng ảnh'))]));
        controller.dispose();
        if (url == null || url.isEmpty || !mounted || !_active(token)) return;
        if (Uri.tryParse(url)?.scheme != 'https') throw Exception('Vui lòng nhập URL HTTPS hợp lệ.');
        setState(() => _uploading = true);
        await _api.uploadAvatar(token, url: url);
      } else {
        final file = await openFile(acceptedTypeGroups: [const XTypeGroup(label: 'Ảnh', extensions: ['jpg','jpeg','png','webp','gif','bmp','tif','tiff'])]);
        if (file == null || !mounted || !_active(token)) return;
        if (await file.length() > 8 * 1024 * 1024) throw Exception('Ảnh vượt quá 8 MiB.');
        final bytes = await file.readAsBytes();
        if (!mounted || !_active(token)) return;
        setState(() => _uploading = true);
        await _api.uploadAvatar(token, bytes: bytes, filename: file.name);
      }
      final profile = await _api.getProfile(token);
      if (!mounted || !_active(token)) return;
      setState(() => _patient = profile);
      context.read<AuthViewModel>().updatePatientProfile(token, profile);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật ảnh đại diện.')));
    } catch (error) { if (_active(token)) setState(() => _error = '$error'); }
    finally { if (mounted) setState(() => _uploading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = PatientApiService.avatarUrl(_patient['avatar']);
    return Scaffold(
      appBar: AppBar(title: Text(widget.onboarding ? 'Hoàn thiện hồ sơ lần đầu' : 'Thông tin cá nhân'),
        automaticallyImplyLeading: !widget.onboarding,
        actions: [if (widget.onboarding) TextButton(onPressed: _saving ? null : () => context.read<AuthViewModel>().logout(), child: const Text('Đăng xuất'))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _patient.isEmpty && _error != null
        ? Center(child: RequestError(message: _error!, onRetry: _load))
        : Form(key: _form, child: ListView(padding: const EdgeInsets.all(20), children: [
          if (widget.onboarding) const Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Vui lòng xác nhận họ tên, ngày sinh và giới tính. Các thông tin bổ sung có thể hoàn thiện sau.')),
          if (!widget.onboarding) ...[
            Center(child: CircleAvatar(radius: 44, backgroundColor: AppColors.medical50, backgroundImage: avatar == null ? null : NetworkImage(avatar), onBackgroundImageError: avatar == null ? null : (_, __) {}, child: avatar == null ? const Icon(Icons.person, size: 40) : null)),
            Wrap(alignment: WrapAlignment.center, children: [TextButton.icon(onPressed: _uploading ? null : _avatar, icon: const Icon(Icons.upload), label: Text(_uploading ? 'Đang tải ảnh...' : 'Chọn ảnh')), TextButton(onPressed: _uploading ? null : () => _avatar(fromUrl: true), child: const Text('Dùng URL'))]),
            const Text('Ảnh raster tối đa 8 MiB. Backend kiểm tra và nén ảnh; không hỗ trợ SVG.'),
          ],
          for (final entry in _labels.entries) if (!(widget.onboarding && entry.key == 'username')) Padding(
            padding: const EdgeInsets.only(top: 14), child: TextFormField(
              controller: _fields[entry.key], readOnly: widget.onboarding && entry.key == 'sdt',
              maxLength: ['cccd', 'bhyt', 'sdt', 'nguoi_than_sdt'].contains(entry.key) ? (entry.key == 'cccd' ? 12 : 10) : null,
              maxLines: ['di_ung','tien_su_benh','tien_su_gia_dinh'].contains(entry.key) ? 3 : 1,
              decoration: InputDecoration(labelText: entry.value, border: const OutlineInputBorder()),
              validator: (value) => _validate(entry.key, value))),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(initialValue: _gender, decoration: const InputDecoration(labelText: 'Giới tính'), items: ['Nam','Nữ'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _gender = v!)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(initialValue: _blood, decoration: const InputDecoration(labelText: 'Nhóm máu'), items: _bloodTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _blood = v!)),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_error!.replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 24),
          FilledButton(onPressed: _saving || _uploading ? null : _save, child: Text(_saving ? 'Đang lưu...' : widget.onboarding ? 'Hoàn thiện hồ sơ' : 'Lưu thông tin')),
        ])),
    );
  }
}
