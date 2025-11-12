import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// 앱 전용 버튼 위젯
class AppButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OngiTokens.radius),
          ),
          minimumSize: const Size(0, OngiTokens.minTouchTarget),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

