$ErrorActionPreference = 'Stop'
$backend = 'D:\laptrinhdidong\khoaluan\KLCN_QuanLyPhongKhamDaKhoa'
function Edit($relative, $change) {
  $path = Join-Path $backend $relative
  $source = [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
  $updated = & $change $source
  [IO.File]::WriteAllText($path, $updated, [Text.UTF8Encoding]::new($false))
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'mobile_patient_controller.py') -Destination (Join-Path $backend 'controllers/mobile_patient_controller.py')
Edit 'app.py' { param($s)
  $s = $s.Replace('from controllers.mobile_auth_controller import mobile_auth_bp', "from controllers.mobile_auth_controller import mobile_auth_bp`nfrom controllers.mobile_patient_controller import mobile_patient_bp")
  $s.Replace('    app.register_blueprint(mobile_auth_bp)', "    app.register_blueprint(mobile_auth_bp)`n    app.register_blueprint(mobile_patient_bp)")
}
Edit 'core/mobile_auth.py' { param($s)
  $s.Replace("phone=user.get('sdt') or '', patient_code=user.get('ma_benh_nhan') or '')", "phone=user.get('sdt') or '', patient_code=user.get('ma_benh_nhan') or '',`n                profile_complete=bool(user.get('da_hoan_thien_ho_so')))")
}
Edit 'core/clinical_data.py' { param($s)
  $s = $s.Replace('from flask import has_request_context, session', 'from flask import has_request_context, session, g')
  $s.Replace("return has_request_context() and session.get('user', {}).get('vai_tro') == 'BENHNHAN'", "return has_request_context() and (getattr(g, 'authenticated_user', None) or session.get('user', {})).get('vai_tro') == 'BENHNHAN'")
}
Edit 'core/medical_media.py' { param($s)
  $s = $s.Replace('login_required, require_patient_access, positive_id', 'login_required, require_patient_access, positive_id, refresh_session_user')
  $s = $s.Replace("session['user']['vai_tro']", "refresh_session_user()['vai_tro']")
  $s.Replace("session['user'].get('patient_id')", "refresh_session_user().get('patient_id')")
}
Edit 'models/appointment_model.py' { param($s)
  [regex]::Replace($s, '(    @staticmethod\s+)(    def create\()', '$1    @serialized' + "`n" + '$2')
}
