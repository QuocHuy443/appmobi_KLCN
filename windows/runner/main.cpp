#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Duong dan tuyet doi thu muc data ke ben file appmobi.exe
  wchar_t buffer[MAX_PATH];
  GetModuleFileNameW(nullptr, buffer, MAX_PATH);
  std::wstring exe_path(buffer);
  std::wstring::size_type pos = exe_path.find_last_of(L"\\/");
  std::wstring data_path = (pos != std::wstring::npos) ? (exe_path.substr(0, pos) + L"\\data") : L"data";

  flutter::DartProject project(data_path);

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // Khung hinh dien thoai (430 x 880) can giua man hinh
  int screen_width = GetSystemMetrics(SM_CXSCREEN);
  int screen_height = GetSystemMetrics(SM_CYSCREEN);
  int win_width = 430;
  int win_height = 880;
  if (win_height > screen_height - 60) {
    win_height = screen_height - 60;
  }
  int pos_x = (screen_width - win_width) / 2;
  int pos_y = (screen_height - win_height) / 2;

  Win32Window::Point origin(pos_x > 0 ? pos_x : 20, pos_y > 0 ? pos_y : 20);
  Win32Window::Size size(win_width, win_height);
  if (!window.Create(L"H2T Healthcare - Bệnh Nhân", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  window.Show();

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
