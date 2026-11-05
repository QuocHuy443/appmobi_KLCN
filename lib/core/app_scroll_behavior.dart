import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Cho phép kéo các danh sách cuộn bằng chuột trong bản web/desktop.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}
