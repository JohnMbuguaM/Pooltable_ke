import 'package:flutter/material.dart';

/// Premium page transition for ChalkMan app
/// Uses a combination of fade and subtle scale animation
class PremiumPageRoute<T> extends PageRoute<T> {
  PremiumPageRoute({
    required this.builder,
    super.settings,
    this.duration = const Duration(milliseconds: 350),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Primary animation (entering)
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    final scaleIn = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    // Secondary animation (exiting)
    final fadeOut = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeIn,
    ));

    return FadeTransition(
      opacity: fadeIn,
      child: FadeTransition(
        opacity: fadeOut,
        child: ScaleTransition(
          scale: scaleIn,
          child: child,
        ),
      ),
    );
  }
}

/// Slide transition from bottom (for modals and sheets)
class SlideUpPageRoute<T> extends PageRoute<T> {
  SlideUpPageRoute({
    required this.builder,
    super.settings,
    this.duration = const Duration(milliseconds: 300),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}

/// Quick scale fade for dialogs
class ScaleFadePageRoute<T> extends PageRoute<T> {
  ScaleFadePageRoute({
    required this.builder,
    super.settings,
    this.duration = const Duration(milliseconds: 250),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ));

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}
