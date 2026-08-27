import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One number in an [InlineStatRow] — an icon, a bold value, and a muted
/// label. No box, no border, no shadow: this replaces the app's previous
/// habit of wrapping every metric in its own bordered, colored tile.
class InlineStat {
  const InlineStat({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String value;
  final String label;

  /// Optional small accent color for the icon only (e.g. success/danger).
  /// Defaults to the theme's ink color when omitted.
  final Color? accent;
}

/// A flat row of metrics separated by hairlines instead of boxes.
class InlineStatRow extends StatelessWidget {
  const InlineStatRow({super.key, required this.items});

  final List<InlineStat> items;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : AppColors.ink;
    final muted = dark ? Colors.white60 : AppColors.muted;
    final divider = dark ? AppColors.darkStroke : AppColors.stroke;

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            width: 1,
            height: 34,
            color: divider,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
        );
      }
      final item = items[i];
      children.add(
        Expanded(
          child: Column(
            children: [
              Icon(item.icon, size: 18, color: item.accent ?? muted),
              const SizedBox(height: 6),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}
