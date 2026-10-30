@echo off
chcp 65001 >nul
if exist "D:\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat" (
  set "PATH=D:\flutter_windows_3.47.9-stable\flutter\bin;%PATH%"
  set "FLUTTER_CMD=D:\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat"
) else (
  set "FLUTTER_CMD=flutter"
)

REM Tu dong xoa cac thu muc va file cu bi trung lap trong lib/
for %%D in (
  "lib\data"
  "lib\domain"
  "lib\presentation"
  "lib\core\constants"
  "lib\core\di"
  "lib\core\theme"
  "lib\screens\appointment"
  "lib\screens\auth"
  "lib\screens\billing"
  "lib\screens\home"
  "lib\screens\medical_records"
  "lib\screens\notifications"
  "lib\screens\profile"
  "lib\screens\test_results"
) do (
  if exist "%%~D" rmdir /s /q "%%~D" 2>nul
)
for %%F in (
  "lib\widgets\custom_button.dart"
  "lib\widgets\notification_badge_widget.dart"
  "lib\widgets\qr_modal_widget.dart"
) do (
  if exist "%%~F" del /f /q "%%~F" 2>nul
)

REM Tu dong khoi dong Backend Web neu co tren may
if exist "D:\KLCN_QuanLyPhongKhamDaKhoa-main\KLCN_QuanLyPhongKhamDaKhoa-main\app.py" (
  netstat -ano | findstr ":5000 " | findstr "LISTENING" >nul 2>&1
  if errorlevel 1 (
    echo [0/2] Dang tu dong bat Backend Flask + SQL Server o cong 5000...
    start "H2T Backend Server" /min cmd /c "cd /d D:\KLCN_QuanLyPhongKhamDaKhoa-main\KLCN_QuanLyPhongKhamDaKhoa-main && python app.py"
  )
)

echo ===================================================
echo   KHOI DONG UNG DUNG BENH NHAN H2T HEALTHCARE
echo ===================================================
echo [1/2] Dang tai thu vien cho project (flutter pub get)...
call "%FLUTTER_CMD%" --no-version-check pub get

echo.
echo [2/2] Dang mo ung dung tren trinh duyet Chrome...
call "%FLUTTER_CMD%" --no-version-check run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
pause
