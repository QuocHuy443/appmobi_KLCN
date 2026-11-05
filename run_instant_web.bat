@echo off
chcp 65001 >nul
title H2T Healthcare - Khoi dong Nhanh (Instant Web)

set "PYTHONIOENCODING=utf-8"

echo =======================================================================
echo          HE THONG QUAN LY PHONG KHAM DA KHOA H2T HEALTHCARE
echo                 UNG DUNG DI DONG BENH NHAN (FLUTTER)
echo                   KHOI DONG TRONG 1 GIAY (INSTANT)
echo =======================================================================
echo.

REM 1. Kiem tra va tu dong bat Backend Flask neu cong 5000 chua chay
netstat -ano | findstr ":5000 " | findstr "LISTENING" >nul 2>&1
if errorlevel 1 (
  echo [1/2] May chu Backend cong 5000 chua bat. Dang tu dong khoi dong...
  if exist "%~dp0..\KLCN_QuanLyPhongKhamDaKhoa\app.py" (
    start "H2T Backend Flask Server" cmd /k "cd /d %~dp0..\KLCN_QuanLyPhongKhamDaKhoa && set PYTHONIOENCODING=utf-8 && python app.py"
    echo       Cho may chu Backend va SQL Server khoi tao trong 3 giay...
    timeout /t 3 >nul
  )
) else (
  echo [1/2] May chu Backend Flask va SQL Server da dang chay tai cong 5000.
)

REM 2. Kiem tra ban build web
if not exist "%~dp0build\web\index.html" (
  echo Ban build web chua co. Dang bien dich lan dau (mat khoang 1 phut)...
  call "D:\baitap\LapTrinhDiDong\flutter\bin\flutter.bat" build web --dart-define=API_BASE_URL=http://127.0.0.1:5000
)

REM 3. Mo ngay trinh duyet va phuc vu web
echo [2/2] Dang mo ung dung tren trinh duyet...
start http://localhost:8080

echo.
echo =======================================================================
echo May chu Ung dung dang phuc vu tai: http://localhost:8080
echo May chu Backend API dang chay tai:  http://127.0.0.1:5000
echo Nhan Ctrl+C de dung may chu nay khi khong dung nua.
echo =======================================================================
echo.

python -m http.server 8080 --directory "%~dp0build\web"

pause
