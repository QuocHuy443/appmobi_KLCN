@echo off
chcp 65001 >nul
title H2T Healthcare - Bảng Điều Khiển Khởi Chạy Ứng Dụng Bệnh Nhân

set "PYTHONIOENCODING=utf-8"

REM Xác định đường dẫn Flutter SDK
set "FLUTTER_CMD=flutter"
where flutter >nul 2>&1
if errorlevel 1 (
  if exist "D:\baitap\LapTrinhDiDong\flutter\bin\flutter.bat" (
    set "FLUTTER_CMD=D:\baitap\LapTrinhDiDong\flutter\bin\flutter.bat"
  )
)

:MENU
cls
echo.
echo    HỆ THỐNG QUẢN LÝ PHÒNG KHÁM ĐA KHOA H2T HEALTHCARE
echo           ỨNG DỤNG DI ĐỘNG BỆNH NHÂN (FLUTTER)
echo.
echo  Chọn chế độ khởi chạy hoặc kiểm tra:
echo.
echo    [1] Mở Cửa sổ Ứng dụng Native Windows (Khung 430x880) - Khuyên dùng
echo    [2] Mở Cửa sổ Web Mobile độc lập qua Chrome (Khung 430x880)
echo    [3] Phát máy chủ Wi-Fi LAN để mở trực tiếp trên Điện thoại thật
echo    [4] Chạy trên Thiết bị hoặc Máy ảo Android đang kết nối
echo    [5] Chạy chế độ Phát triển Debug Flutter (Hỗ trợ Hot-Reload)
echo    [6] Khởi động riêng Máy chủ Backend Flask API (Cổng 5000)
echo    [7] Dọn dẹp và Biên dịch lại toàn bộ ứng dụng (Clean và Rebuild)
echo    [8] Thoát
echo.

set /p OPTION="Nhập số lựa chọn của bạn [1-8, mặc định 1]: "
if "%OPTION%"=="" set OPTION=1

if "%OPTION%"=="1" goto OPTION_1
if "%OPTION%"=="2" goto OPTION_2
if "%OPTION%"=="3" goto OPTION_3
if "%OPTION%"=="4" goto OPTION_4
if "%OPTION%"=="5" goto OPTION_5
if "%OPTION%"=="6" goto OPTION_6
if "%OPTION%"=="7" goto OPTION_7
if "%OPTION%"=="8" goto OPTION_8
goto MENU

:CHECK_BACKEND
netstat -ano | findstr ":5000 " | findstr "LISTENING" >nul 2>&1
if errorlevel 1 (
  echo [Khởi động] Đang kích hoạt Máy chủ Backend Flask và SQL Server...
  if exist "%~dp0..\KLCN_QuanLyPhongKhamDaKhoa\app.py" (
    start "H2T Backend Flask Server" /min cmd /c "cd /d %~dp0..\KLCN_QuanLyPhongKhamDaKhoa && set PYTHONIOENCODING=utf-8 && python app.py"
    timeout /t 2 >nul
  )
)
exit /b 0

:OPTION_1
call :CHECK_BACKEND
echo.
if not exist "%~dp0build\windows\x64\runner\Release\appmobi.exe" (
  echo Đang biên dịch ứng dụng Native Windows lần đầu tiên...
  call "%FLUTTER_CMD%" build windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
)
echo Đang mở cửa sổ ứng dụng H2T Healthcare kích thước điện thoại 430x880...
cd /d "%~dp0build\windows\x64\runner\Release"
start appmobi.exe
echo.
echo Ứng dụng Native đã được khởi chạy thành công.
echo Nhấn phím bất kỳ để quay lại menu chính...
pause >nul
cd /d "%~dp0"
goto MENU

:OPTION_2
call :CHECK_BACKEND
echo.
netstat -ano | findstr ":8080 " | findstr "LISTENING" >nul 2>&1
if errorlevel 1 (
  if not exist "%~dp0build\web\index.html" (
    echo Đang biên dịch bản Web lần đầu tiên...
    call "%FLUTTER_CMD%" build web --dart-define=API_BASE_URL=http://127.0.0.1:5000
  )
  start "H2T Mobile Web Server" /min cmd /c "cd /d %~dp0build\web && python -m http.server 8080"
  timeout /t 1 >nul
)
echo Đang mở ứng dụng Web Mobile trên trình duyệt Chrome...
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
  start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --app=http://localhost:8080 --window-size=430,880 --window-position=500,50
) else (
  start http://localhost:8080
)
echo.
echo Cửa sổ Web Mobile đã mở thành công.
echo Nhấn phím bất kỳ để quay lại menu chính...
pause >nul
goto MENU

:OPTION_3
call :CHECK_BACKEND
echo.
echo Đang lấy địa chỉ IP mạng nội bộ của máy tính...
set "LOCAL_IP="
for /f "tokens=4" %%a in ('route print ^| findstr "0.0.0.0.*0.0.0.0" ^| findstr /v "127.0.0.1"') do (
  if not defined LOCAL_IP set "LOCAL_IP=%%a"
)
if "%LOCAL_IP%"=="" set "LOCAL_IP=127.0.0.1"

echo.
echo HƯỚNG DẪN KẾT NỐI VÀ TRẢI NGHIỆM TRÊN ĐIỆN THOẠI THẬT:
echo 1. Kết nối điện thoại và máy tính vào cùng một mạng Wi-Fi.
echo 2. Mở trình duyệt trên điện thoại (Safari hoặc Chrome) và truy cập:
echo    http://%LOCAL_IP%:8080
echo 3. Nhấn tổ hợp Ctrl+C tại đây để dừng máy chủ khi hoàn tất.
echo.

if not exist "%~dp0build\web\index.html" (
  echo Đang biên dịch gói Web lần đầu...
  call "%FLUTTER_CMD%" build web --dart-define=API_BASE_URL=http://%LOCAL_IP%:5000
)

python -m http.server 8080 --directory "%~dp0build\web"
goto MENU

:OPTION_4
call :CHECK_BACKEND
echo.
echo Đang tìm kiếm các thiết bị và máy ảo Android đang kết nối...
call "%FLUTTER_CMD%" devices
echo.
echo Khởi chạy ứng dụng lên thiết bị mặc định...
call "%FLUTTER_CMD%" run --dart-define=API_BASE_URL=http://10.0.2.2:5000
echo.
echo Nhấn phím bất kỳ để quay lại menu chính...
pause >nul
goto MENU

:OPTION_5
call :CHECK_BACKEND
echo.
echo Đang khởi động chế độ Debug Native Windows (Hỗ trợ phím r để Hot-Reload)...
call "%FLUTTER_CMD%" run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
echo.
echo Nhấn phím bất kỳ để quay lại menu chính...
pause >nul
goto MENU

:OPTION_6
echo.
echo Đang khởi động Máy chủ Backend Flask và kết nối SQL Server...
cd /d "%~dp0..\KLCN_QuanLyPhongKhamDaKhoa"
python app.py
cd /d "%~dp0"
goto MENU

:OPTION_7
echo.
echo Đang làm sạch và biên dịch lại toàn bộ ứng dụng...
call "%FLUTTER_CMD%" clean
call "%FLUTTER_CMD%" pub get
echo.
echo Đang biên dịch lại ứng dụng Windows...
call "%FLUTTER_CMD%" build windows --dart-define=API_BASE_URL=http://127.0.0.1:5000
echo.
echo Đang biên dịch lại ứng dụng Web...
call "%FLUTTER_CMD%" build web --dart-define=API_BASE_URL=http://127.0.0.1:5000
echo.
echo Quá trình biên dịch hoàn tất!
echo Nhấn phím bất kỳ để quay lại menu chính...
pause >nul
goto MENU

:OPTION_8
echo Tạm biệt!
exit /b 0
