import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.15,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.systemGrey6.withValues(alpha: opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: border
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
