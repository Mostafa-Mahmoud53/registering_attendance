import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// Responsive Breakpoint Scale
/// ──────────────────────────────────────────────────────────────────────────────
///  < 600px  → Mobile Layout   (isMobileSmall) — single-column, compact spacing
///  < 850px  → Mobile Layout   (isMobile)      — single-column, standard spacing
///  850–1099 → Tablet Layout   (isTablet)      — 2-column grid, mid-range sizing
///  ≥ 1100px → Desktop Layout  (isDesktop)     — multi-column grid, full sizing
/// ──────────────────────────────────────────────────────────────────────────────
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // ── Breakpoint Helpers ─────────────────────────────────────────────────────

  /// Mobile Layout: width < 600px — smallest phones, single column, minimum padding
  static bool isMobileSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Mobile Layout: width < 850px — all phone-sized screens
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 850;

  /// Tablet Layout: 850px ≤ width < 1100px
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width < 1100 &&
      MediaQuery.of(context).size.width >= 850;

  /// Desktop Layout: width ≥ 1100px — full desktop experience
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  // ── Widget Builder ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= 1100) {
      return desktop; // Desktop Layout
    } else if (width >= 850 && tablet != null) {
      return tablet!;  // Tablet Layout
    } else {
      return mobile;   // Mobile Layout
    }
  }

  // ── Static Layout Utilities ────────────────────────────────────────────────

  /// Desktop Layout: wraps [child] in a centered, max-width constrained box
  static Widget constrainedContent({required Widget child, double maxWidth = 1000}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  /// Returns column count for responsive grids.
  /// Mobile Layout: [base] cols / Desktop Layout: [base]+4 cols
  static int getGridCount(BuildContext context, {int base = 2}) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1400) return base + 4; // Desktop Layout
    if (width > 1100) return base + 2; // Desktop Layout
    if (width > 850)  return base + 1; // Tablet Layout
    return base;                        // Mobile Layout
  }
}

