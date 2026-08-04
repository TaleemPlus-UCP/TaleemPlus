import 'package:flutter/widgets.dart';

/// Width breakpoints for the Flutter-Web-only SaaS redesign.
///
/// These are only ever consulted from behind a `kIsWeb` check at each
/// screen's `build()` — mobile builds never evaluate them (dead-code
/// eliminated), so they cannot affect the mobile app.
class WebBreakpoints {
  WebBreakpoints._();

  /// Below this width, even on web (a narrow mobile browser), screens fall
  /// back to the existing mobile layout — already responsive by
  /// construction, and keeps behavior identical to the phone app on phones
  /// visiting the site.
  static const double compact = 700;

  /// Sidebar auto-collapses to an icon-only rail below this width.
  static const double medium = 1100;

  /// The content column stops growing past this width and centers itself
  /// instead, so ultra-wide monitors don't get one giant stretched column.
  static const double expanded = 1600;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compact && w < medium;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;
}
