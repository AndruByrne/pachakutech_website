import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class PeriodicGradientPainter extends CustomPainter {
  final int itemCount;
  final List<Color>
      waveColors; // Still here, but logic uses fixed colors for now

  PeriodicGradientPainter({
    required this.itemCount,
    required this.waveColors,
  }) : assert(waveColors.length >= 3);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    List<Color> gradientColors = [];
    List<double> gradientStops = [];

    final Color grey = Colors.grey[600]!;
    final Color white = Colors.white;
    final Color black = Colors.black;

    gradientColors.add(grey);
    gradientStops.add(0.0);

    if (itemCount <= 0) {
      gradientColors.add(grey);
      gradientStops.add(1.0);
    } else {
      for (int i = 0; i < itemCount; i++) {
        double itemStartStop = (i.toDouble() / itemCount);
        double itemMidStop = itemStartStop + (1.0 / itemCount) * 0.5;
        double itemEndStop = ((i + 1).toDouble() / itemCount);

        if (i % 2 == 0) {
          gradientColors.add(white);
          gradientStops.add(itemMidStop);
        } else {
          gradientColors.add(black);
          gradientStops.add(itemMidStop);
        }
        gradientColors.add(grey);
        gradientStops.add(itemEndStop);
      }
    }

    if (gradientStops.isNotEmpty && gradientStops.last < 1.0) {
      gradientStops.last = 1.0;
    }

    if (gradientColors.length != gradientStops.length) {
      developer.log(
          "Warning: Correcting Gradient colors/stops mismatch. Colors: ${gradientColors.length}, Stops: ${gradientStops.length}",
          name: "PeriodicGradientPainter");
      if (gradientColors.length > gradientStops.length &&
          gradientStops.isNotEmpty) {
        gradientColors = gradientColors.sublist(0, gradientStops.length);
      } else if (gradientStops.length > gradientColors.length &&
          gradientColors.isNotEmpty) {
        gradientStops = gradientStops.sublist(0, gradientColors.length);
      }
      if (gradientColors.length < 2 ||
          gradientColors.length != gradientStops.length) {
        developer.log(
            "Fallback: Using default grey gradient due to persistent list mismatch.",
            name: "PeriodicGradientPainter");
        gradientColors = [Colors.grey[600]!, Colors.grey[700]!];
        gradientStops = [0.0, 1.0];
      }
    }

    if (gradientColors.length >= 2 &&
        gradientStops.length == gradientColors.length) {
      paint.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        gradientColors,
        gradientStops,
        ui.TileMode.clamp,
      );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else {
      developer.log(
          "Error: Not enough colors/stops or mismatch for gradient. Colors: ${gradientColors.length}, Stops: ${gradientStops.length}",
          name: "PeriodicGradientPainter");
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = Colors.grey[800]!);
    }
  }

  @override
  bool shouldRepaint(covariant PeriodicGradientPainter oldDelegate) {
    bool waveColorsChanged = oldDelegate.waveColors.length !=
            waveColors.length ||
        !waveColors
            .asMap()
            .entries
            .every((entry) => entry.value == oldDelegate.waveColors[entry.key]);
    return oldDelegate.itemCount != itemCount || waveColorsChanged;
  }
}
