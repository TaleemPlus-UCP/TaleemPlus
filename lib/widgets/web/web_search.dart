import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/web/web_theme.dart';
import 'web_nav_items.dart';

/// Topbar quick-navigation search: fuzzy-matches the current role's sidebar
/// destinations by label and jumps straight to them on selection. Screens
/// that already have their own in-page list filter (e.g. user management's
/// name/roll search) keep that as the source of truth for filtering their
/// own data — this box is for *navigating* the app, not re-implementing
/// every screen's filter logic.
class WebQuickSearch extends StatefulWidget {
  final List<WebNavSection> navSections;

  const WebQuickSearch({super.key, required this.navSections});

  @override
  State<WebQuickSearch> createState() => _WebQuickSearchState();
}

class _WebQuickSearchState extends State<WebQuickSearch> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  List<WebNavItem> _matches = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _removeOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<WebNavItem> get _allItems =>
      widget.navSections.expand((s) => s.items).toList();

  void _onChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _matches = q.isEmpty
          ? []
          : _allItems.where((i) => i.label.toLowerCase().contains(q)).toList();
    });
    _syncOverlay();
  }

  void _syncOverlay() {
    _removeOverlay();
    if (_matches.isEmpty || !_focusNode.hasFocus) return;
    _overlay = OverlayEntry(
      builder: (overlayCtx) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 46),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: overlayCtx.appColors.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _matches.length,
                itemBuilder: (_, i) {
                  final item = _matches[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(item.icon,
                        size: 18, color: overlayCtx.appColors.textSecondary),
                    title: Text(item.label,
                        style: TextStyle(
                            fontSize: 13, color: overlayCtx.appColors.textPrimary)),
                    onTap: () {
                      _controller.clear();
                      _focusNode.unfocus();
                      setState(() => _matches = []);
                      item.onTap();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: 320,
        height: 40,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onTap: _syncOverlay,
          onTapOutside: (_) => _focusNode.unfocus(),
          style: TextStyle(fontSize: 13, color: context.appColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search or jump to...',
            hintStyle: TextStyle(fontSize: 13, color: context.appColors.textMuted),
            prefixIcon: Icon(Icons.search_rounded,
                size: 18, color: context.appColors.textMuted),
            filled: true,
            fillColor: context.webColors.scrollTrack,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}
