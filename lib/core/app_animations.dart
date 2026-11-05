import 'dart:async';
import 'package:flutter/material.dart';

// He thong hoat anh chuyen dong hien dai va sang trong cho ung dung
class AppAnimations {
  // Thoi luong hoat anh chuan muc: cham rai, muot ma va hien dai
  static const Duration slow = Duration(milliseconds: 550);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration fast = Duration(milliseconds: 180);

  // Duong cong chuyen dong cubic-bezier tuong thich phong cach web (0.22, 1.0, 0.36, 1.0)
  static const Curve modernCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve smoothOut = Curves.easeOutCubic;
  static const Curve smoothInOut = Curves.easeInOutCubic;
}

// Huong xuat hien cua hoat anh
enum SlideDirection { fromRight, fromBottom, fromLeft, fromTop }

// Widget xuat hien truot va mo dan voi do tre tuy chinh
class AppSlideFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final SlideDirection direction;
  final double distance;
  final Curve curve;

  const AppSlideFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppAnimations.slow,
    this.direction = SlideDirection.fromRight,
    this.distance = 28.0,
    this.curve = AppAnimations.modernCurve,
  });

  @override
  State<AppSlideFade> createState() => _AppSlideFadeState();
}

class _AppSlideFadeState extends State<AppSlideFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _offsetAnimation;
  Timer? _delayTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Offset startOffset;
    switch (widget.direction) {
      case SlideDirection.fromRight:
        startOffset = Offset(widget.distance, 0);
        break;
      case SlideDirection.fromBottom:
        startOffset = Offset(0, widget.distance);
        break;
      case SlideDirection.fromLeft:
        startOffset = Offset(-widget.distance, 0);
        break;
      case SlideDirection.fromTop:
        startOffset = Offset(0, -widget.distance);
        break;
    }

    _offsetAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (!_disposed && mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _offsetAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// Widget phan hoi cham cham co gian nhe khi bam
class AppScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double scaleDown;

  const AppScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.scaleDown = 0.97,
  });

  @override
  State<AppScaleTap> createState() => _AppScaleTapState();
}

class _AppScaleTapState extends State<AppScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// Chuyen canh tab chuyen noi dung muot ma kieu web
class AppTabTransition extends StatelessWidget {
  final Widget child;
  final Key? switchKey;
  final Duration duration;

  const AppTabTransition({
    super.key,
    required this.child,
    this.switchKey,
    this.duration = AppAnimations.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppAnimations.modernCurve,
      switchOutCurve: Curves.easeInQuad,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppAnimations.modernCurve,
        ));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: switchKey ?? ValueKey(child.hashCode),
        child: child,
      ),
    );
  }
}
