import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: PlatformColors.primary),
        const SizedBox(width: PlatformSpacing.sm),
        Flexible(
          child: Text(
            title,
            style: PlatformTextStyles.title.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}