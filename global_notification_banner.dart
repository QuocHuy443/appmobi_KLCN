import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_animations.dart';
import '../screens/notifications_screen.dart';
import '../services/sound_service.dart';

/// Displays an in-app notification toast above every route in the Navigator.
class GlobalNotificationBanner extends StatefulWidget {
  const GlobalNotificationBanner({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  static final ValueNotifier<Map<String, dynamic>?> activeToast =
      ValueNotifier<Map<String, dynamic>?>(null);
  static Timer? _dismissTimer;

  static void show(Map<String, dynamic> notif) {
    _dismissTimer?.cancel();
    SoundService.playNotificationSound();
    activeToast.value = Map<String, dynamic>.from(notif);
    _dismissTimer = Timer(const Duration(seconds: 8), dismiss);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (activeToast.value != null) {
      activeToast.value = null;
    }
  }

  @override
  State<GlobalNotificationBanner> createState() =>
      _GlobalNotificationBannerState();
}

class _GlobalNotificationBannerState extends State<GlobalNotificationBanner> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: GlobalNotificationBanner.activeToast,
      builder: (context, toast, _) {
        if (toast == null) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: AppSlideFade(
              key: ValueKey(toast['id'] ?? toast['tieu_de']),
              direction: SlideDirection.fromTop,
              distance: 28,
              duration: AppAnimations.slow,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      GlobalNotificationBanner.dismiss();
                      widget.navigatorKey.currentState?.push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2825),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFF134E4A), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E)
                                          .withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF2DD4BF),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.solidBell,
                                        color: Colors.amber,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (toast['tieu_de'] ??
                                                        'Thông báo hệ thống')
                                                    .toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2DD4BF)
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Mới',
                                                style: TextStyle(
                                                  color: Color(0xFF2DD4BF),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (toast['noi_dung'] ?? '').toString(),
                                          style: const TextStyle(
                                            color: Color(0xFFCBD5E1),
                                            fontSize: 11.5,
                                            height: 1.35,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        const Row(
                                          children: [
                                            Icon(Icons.touch_app,
                                                size: 12,
                                                color: Color(0xFF2DD4BF)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Chạm để xem chi tiết thông báo',
                                              style: TextStyle(
                                                color: Color(0xFF2DD4BF),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white54, size: 18),
                                    onPressed: GlobalNotificationBanner.dismiss,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 3,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF2DD4BF),
                                    Color(0xFF0F766E),
                                    Color(0xFF0D9488),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
