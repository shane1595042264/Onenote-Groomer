#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <ole2.h>
#include <iostream>

#include "flutter_window.h"
#include "utils.h"

// Global flag for COM initialization
static bool g_com_initialized = false;

// Cleanup handler
void CleanupHandler() {
  if (g_com_initialized) {
    CoUninitialize();
    g_com_initialized = false;
    std::cout << "COM uninitialized successfully" << std::endl;
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                     _In_ wchar_t *command_line, _In_ int show_command) {
  // Initialize COM for OneNote interop with proper error handling
  HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
  if (SUCCEEDED(hr)) {
    g_com_initialized = true;
    std::cout << "COM initialized successfully" << std::endl;
  } else if (hr == RPC_E_CHANGED_MODE) {
    // COM was already initialized with a different mode
    std::cout << "COM already initialized" << std::endl;
  } else {
    std::cerr << "Failed to initialize COM: 0x" << std::hex << hr << std::endl;
    return EXIT_FAILURE;
  }

  // Set up cleanup handler
  std::atexit(CleanupHandler);

  // Attach to console for debugging
  if (::AttachConsole(ATTACH_PARENT_PROCESS)) {
    FILE* unused;
    freopen_s(&unused, "CONOUT$", "w", stdout);
    freopen_s(&unused, "CONOUT$", "w", stderr);
  }

  // Initialize Flutter
  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  
  if (!window.Create(L"OneNote to Excel Converter", origin, size)) {
    CleanupHandler();
    return EXIT_FAILURE;
  }
  
  window.SetQuitOnClose(true);

  // Message loop
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // Cleanup will be called by atexit
  return EXIT_SUCCESS;
}