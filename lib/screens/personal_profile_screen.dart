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

  static final _forbiddenChars = RegExp(r'[<>{}\[\]$%^*=~`|\\;]|--');
  static final _vietnameseNamePattern = RegExp(
    r'^[a-zA-Zàáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ'
    r'ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ\s]+$',
  );
  static final _vnPhonePattern = RegExp(r'^(03|05|07|08|09)\d{8}$');
  static final _cccdPattern = RegExp(r'^\d{12}$');
  static final _bhytPattern = RegExp(r'^\d{10}$');
  static final _emailPattern =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  bool _isRequired(String key) {
    if (key == 'ho_ten' || key == 'ngay_sinh') return true;
    if (!widget.onboarding &&
        (key == 'sdt' || key == 'cccd' || key == 'dia_chi')) {
      return true;
    }
    return false;
  }

  String? _validate(String key, String? raw) {
    final value = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (_isRequired(key) && value.isEmpty) {
      if (key == 'cccd') return 'Vui lòng nhập số Căn cước công dân (CCCD)!';
      if (key == 'dia_chi') return 'Vui lòng nhập địa chỉ chi tiết!';
      if (key == 'ngay_sinh') return 'Vui lòng chọn ngày sinh!';
      return '${_labels[key]} không được để trống!';
    }
    if (value.isEmpty) return null;

    if (key == 'ho_ten' || key == 'nguoi_than_ho_ten') {
      final label = key == 'ho_ten' ? 'Họ và tên' : 'Họ tên người thân';
      if (value.length < 2 || value.length > 100) {
        return '$label phải có độ dài từ 2 đến 100 ký tự!';
      }
      if (RegExp(r'\d').hasMatch(value)) {
        return '$label không được chứa chữ số!';
      }
      if (_forbiddenChars.hasMatch(value) ||
          !_vietnameseNamePattern.hasMatch(value)) {
        return '$label chỉ được chứa chữ cái tiếng Việt và khoảng trắng, không chứa số hay ký tự lạ!';
      }
    }

    if (key == 'sdt' || key == 'nguoi_than_sdt') {
      final label =
          key == 'sdt' ? 'Số điện thoại' : 'Số điện thoại người thân';
      if (!_vnPhonePattern.hasMatch(value)) {
        return '$label không đúng định dạng (10 số, bắt đầu bằng 03, 05, 07, 08, 09)!';
      }
    }

    if (key == 'cccd') {
      if (RegExp(r'[a-zA-Z]').hasMatch(value)) {
        return 'Số CCCD phải hoàn toàn là chữ số, không chứa chữ cái!';
      }
      if (!_cccdPattern.hasMatch(value)) {
        return 'Số CCCD phải bao gồm đúng 12 chữ số, không chứa chữ hoặc ký tự lạ!';
      }
      if (value.split('').toSet().length == 1) {
        return 'Số CCCD không hợp lệ (không thể là các chữ số lặp lại)!';
      }
    }

    if (key == 'bhyt') {
      if (RegExp(r'[a-zA-Z]').hasMatch(value)) {
        return 'Mã số thẻ BHYT phải đúng số lượng số và không có chữ!';
      }
      if (!_bhytPattern.hasMatch(value)) {
        return 'Mã số thẻ BHYT phải gồm đúng 10 chữ số, không chứa chữ hay ký tự lạ!';
      }
      if (value.split('').toSet().length == 1 && value[0] == '0') {
        return 'Mã số thẻ BHYT không hợp lệ (không thể là chuỗi số 0)!';
      }
    }

    if (key == 'email') {
      if (value.length > 100) {
        return 'Địa chỉ email không vượt quá 100 ký tự!';
      }
      if (!_emailPattern.hasMatch(value)) {
        return 'Địa chỉ email không đúng định dạng (ví dụ: h2t@healthcare.vn)!';
      }
    }

    if (key == 'dia_chi') {
      if (value.length < 5 || value.length > 255) {
        return 'Địa chỉ cư trú phải có độ dài từ 5 đến 255 ký tự!';
      }
      if (_forbiddenChars.hasMatch(value)) {
        return 'Địa chỉ chứa ký tự đặc biệt lạ không hợp lệ!';
      }
    }

    if (key == 'ngay_sinh') {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
        return 'Định dạng ngày sinh không hợp lệ (YYYY-MM-DD)!';
      }
      final date = DateTime.tryParse(value);
      if (date == null || date.toIso8601String().substring(0, 10) != value) {
        return 'Định dạng ngày sinh không hợp lệ (YYYY-MM-DD)!';
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (date.isAfter(today)) {
        return 'Ngày sinh không thể lớn hơn ngày hiện tại!';
      }
      final hadBirthday = today.month > date.month ||
          (today.month == date.month && today.day >= date.day);
      final age = today.year - date.year - (hadBirthday ? 0 : 1);
      if (age > 130) {
        return 'Ngày sinh không hợp lệ (tuổi không vượt quá 130)!';
      }
    }

    if (key == 'username') {
      if (value.contains(' ')) {
        return 'Tên đăng nhập không được chứa khoảng cách!';
      }
      if (value.length < 3 ||
          value.length > 50 ||
          _forbiddenChars.hasMatch(value)) {
        return 'Tên đăng nhập phải từ 3 đến 50 ký tự và không chứa ký tự lạ!';
      }
    }

    if ([
      'di_ung',
      'tien_su_benh',
      'tien_su_gia_dinh',
      'nguoi_than_quan_he',
      'ghi_chu_nhom_mau',
    ].contains(key)) {
      if (_forbiddenChars.hasMatch(value)) {
        return '${_labels[key]} chứa ký tự đặc biệt lạ không hợp lệ!';
      }
    }

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
          if (widget.onboarding)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Vui lòng xác nhận Họ và tên (*), Ngày sinh (*) và Giới tính (*). Các thông tin bổ sung không bắt buộc và có thể hoàn thiện sau.',
              ),
            ),
          if (!widget.onboarding) ...[
            Center(child: CircleAvatar(radius: 44, backgroundColor: AppColors.medical50, backgroundImage: avatar == null ? null : NetworkImage(avatar), onBackgroundImageError: avatar == null ? null : (_, __) {}, child: avatar == null ? const Icon(Icons.person, size: 40) : null)),
            Wrap(alignment: WrapAlignment.center, children: [TextButton.icon(onPressed: _uploading ? null : _avatar, icon: const Icon(Icons.upload), label: Text(_uploading ? 'Đang tải ảnh...' : 'Chọn ảnh')), TextButton(onPressed: _uploading ? null : () => _avatar(fromUrl: true), child: const Text('Dùng URL'))]),
            const Text('Ảnh raster tối đa 8 MiB. Backend kiểm tra và nén ảnh; không hỗ trợ SVG.'),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Các trường đánh dấu Bắt buộc (*) gồm Họ và tên, Số điện thoại, Ngày sinh, Giới tính, Căn cước công dân và Địa chỉ cư trú.',
                style: TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
            ),
          ],
          for (final entry in _labels.entries) if (!(widget.onboarding && entry.key == 'username')) Padding(
            padding: const EdgeInsets.only(top: 14), child: TextFormField(
              controller: _fields[entry.key], readOnly: widget.onboarding && entry.key == 'sdt',
              maxLength: ['cccd', 'bhyt', 'sdt', 'nguoi_than_sdt'].contains(entry.key) ? (entry.key == 'cccd' ? 12 : 10) : null,
              maxLines: ['di_ung','tien_su_benh','tien_su_gia_dinh'].contains(entry.key) ? 3 : 1,
              decoration: InputDecoration(
                labelText: entry.value,
                helperText: _isRequired(entry.key)
                    ? 'Bắt buộc (*)'
                    : (widget.onboarding && entry.key == 'sdt'
                        ? 'Đã xác thực khi tạo tài khoản'
                        : null),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => _validate(entry.key, value))),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(initialValue: _gender, decoration: const InputDecoration(labelText: 'Giới tính', helperText: 'Bắt buộc (*)'), items: ['Nam','Nữ'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _gender = v!)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(initialValue: _blood, decoration: const InputDecoration(labelText: 'Nhóm máu'), items: _bloodTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _blood = v!)),
          if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_error!.replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 24),
          FilledButton(onPressed: _saving || _uploading ? null : _save, child: Text(_saving ? 'Đang lưu...' : widget.onboarding ? 'Hoàn thiện hồ sơ' : 'Lưu thông tin')),
        ])),
    );
  }
}
