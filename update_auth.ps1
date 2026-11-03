$ErrorActionPreference='Stop'
$p=Join-Path $PSScriptRoot 'lib/services/auth_service.dart'
$s=[IO.File]::ReadAllText($p).Replace("`r`n","`n")
$s=$s.Replace("import 'dart:convert';", "import 'dart:convert';`nimport 'dart:async';`nimport 'session_events.dart';")
$a=$s.IndexOf('class LocalAuthStore {'); $b=$s.IndexOf('class AuthRepositoryImpl', $a)
$s=$s.Remove($a,$b-$a)
$s=$s.Replace('  final bool _enableLocalFallback;'+"`n",'')
$s=$s.Replace("_now = now ?? DateTime.now,`n        _enableLocalFallback = dio == null {", '_now = now ?? DateTime.now {')
# Remove conditional fallback blocks with balanced braces, preserving genuine error paths.
while($s.Contains('    if (_enableLocalFallback')) {
  $a=$s.IndexOf('    if (_enableLocalFallback'); $brace=$s.IndexOf('{',$a); $depth=1; $b=$brace+1
  while($depth -gt 0) { if($s[$b] -eq '{'){$depth++}; if($s[$b] -eq '}'){$depth--}; $b++ }
  $s=$s.Remove($a,$b-$a)
}
$s=[regex]::Replace($s,'(?m)^\s*LocalAuthStore\.activeUser = .*?;\n','')
# User changes remain inside the same architecture.
$s=$s.Replace('  final String token;', '  final String token;'+"`n  final bool profileComplete;")
$s=$s.Replace('    required this.token,', '    required this.token,'+"`n    this.profileComplete = true,")
$s=$s.Replace("      token: token,`n    );", "      token: token,`n      profileComplete: user['profile_complete'] == true,`n    );")
$s=$s.Replace("  });`n}`n`nabstract class AuthRepository", @'
  });

  User copyWith({String? name, String? email, String? phone, bool? profileComplete}) => User(
    id: id, accountId: accountId, name: name ?? this.name, email: email ?? this.email,
    phone: phone ?? this.phone, patientCode: patientCode, role: role, token: token,
    profileComplete: profileComplete ?? this.profileComplete);
}

abstract class AuthRepository
'@)
$s=$s.Replace(': _authRepository = authRepository;', @'
: _authRepository = authRepository {
    SessionEvents.rejected.addListener(_sessionRejected);
  }

  Map<String, dynamic> _profile = {};
  Map<String, dynamic> get profile => Map.unmodifiable(_profile);

  void updatePatientProfile(String token, Map<String, dynamic> profile) {
    if (_currentUser?.token != token) return;
    _profile = Map.from(profile);
    _currentUser = _currentUser!.copyWith(name: profile['ho_ten']?.toString(),
      email: profile['email']?.toString(), phone: profile['sdt']?.toString(),
      profileComplete: profile['profile_complete'] == true);
    notifyListeners();
  }

  void _sessionRejected() {
    final event = SessionEvents.rejected.value;
    if (event == null || _currentUser?.token != event.token) return;
    if (event.profileRequired) {
      _currentUser = _currentUser!.copyWith(profileComplete: false);
      notifyListeners();
      return;
    }
    ++_sessionOperation;
    _currentUser = null;
    _profile = {};
    _isInitialized = true;
    _isLoading = false;
    _errorMessage = 'Phiên đăng nhập đã hết hạn hoặc bị vô hiệu hóa. Vui lòng đăng nhập lại.';
    notifyListeners();
    unawaited(_authRepository.logout().catchError((Object _) {}));
  }

  @override
  void dispose() {
    SessionEvents.rejected.removeListener(_sessionRejected);
    super.dispose();
  }
'@)
$s=$s.Replace('    _currentUser = null;'+"`n    try {`n      await _authRepository.logout();", '    _currentUser = null;'+"`n    _profile = {};`n    notifyListeners();`n    try {`n      await _authRepository.logout();")
[IO.File]::WriteAllText($p,$s,[Text.UTF8Encoding]::new($false))
