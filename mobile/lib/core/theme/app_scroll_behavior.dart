import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// [AppScrollBehavior] eliminates the Android 12+ stretch overscroll distortion
/// (`StretchingOverscrollIndicator`) and provides fluid, elastic iOS-style
/// [BouncingScrollPhysics] across the entire Raize platform.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Returning child directly bypasses StretchingOverscrollIndicator and
    // GlowingOverscrollIndicator, eliminating unwanted Android UI stretching.
    return child;
  }
}

