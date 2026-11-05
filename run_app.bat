@echo off
chcp 65001 >nul
title H2T Healthcare - Khoi dong Ung dung Benh nhan

set "PYTHONIOENCODING=utf-8"

if exist "D:\baitap\LapTrinhDiDong\flutter\bin\flutter.bat" (
  set "PATH=D:\baitap\LapTrinhDiDong\flutter\bin;%PATH%"
  set "FLUTTER_CMD=D:\baitap\LapTrinhDiDong\flutter\bin\flutter.bat"
) else if exist "D:\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat" (
  set "PATH=D:\flutter_windows_3.47.9-stable\flutter\bin;%PATH%"
  set "FLUTTER_CMD=D:\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat"
) else (
  set "FLUTTER_CMD=flutter"
)

echo =======================================================================
echo          HE THONG QUAN LY PHONG KHAM DA KHOA H2T HEALTHCARE
echo                 UNG DUNG DI DONG BENH NHAN (FLUTTER)
echo =======================================================================
echo.

REM 1. Kiem tra va tu dong bat Backend Flask neu cong 5000 chua chay
netstat -ano | findstr ":5000 " | findstr "LISTENING" >nul 2>&1
if errorlevel 1 (
  echo [1/3] May chu Backend cong 5000 chua bat. Dang tu dong khoi dong...
  if exist "%~dp0..\KLCN_QuanLyPhongKhamDaKhoa\app.py" (
    start "H2T Backend Flask Server" cmd /k "cd /d %~dp0..\KLCN_QuanLyPhongKhamDaKhoa && set PYTHONIOENCODING=utf-8 && python app.py"
    echo       Cho may chu Backend va SQL Server khoi tao trong 3 giay...
    timeout /t 3 >nul
  )
) else (
  echo [1/3] May chu Backend Flask va SQL Server da dang chay tai cong 5000.
)

REM 2. Dong bo thu vien Flutter
echo [2/3] Dong bo thu vien ung dung (flutter pub get)...
call "%FLUTTER_CMD%" pub get >nul 2>&1

REM 3. Khoi chay ung dung tren Google Chrome
echo [3/3] Dang mo ung dung tren trinh duyet Google Chrome...
echo       (Luu y: Lan dau bien dich se mat khoang 20-30 giay, trinh duyet se tu dong bat len)
echo.

call "%FLUTTER_CMD%" run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:5000

echo.
echo Ung dung da dong. Nhan phim bat ky de thoat...
pause >nul
