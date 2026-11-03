@echo off
chcp 65001 >nul
if exist "D:\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat" (
  set "PATH=D:\flutter_windows_3.47.9-stable\flutter\bin;%PATH%"
  set "FLUTTER_CMD=D:\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat"
) else (
  set "FLUTTER_CMD=flutter"
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
