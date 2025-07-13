import 'package:flutter/widgets.dart';

const String sectionHeroTag = "detail_background_";
final String headerHeroTag = "appHeaderHero";

class CenterExpansionRectTween extends RectTween {
  final Rect? centerRect;

  CenterExpansionRectTween({
    required Rect? begin,
    required Rect? end,
    this.centerRect, // Optional: if you want to force an initial center point
  }) : super(begin: begin, end: end);

  // In CenterExpansionRectTween
  @override
  Rect? lerp(double t) {
    if (begin == null || end == null) {
      return Rect.lerp(begin, end, t);
    }

    final Offset sourceCenter = begin!.center;
    final Offset destinationCenter = end!.center;

    // Determine the progress of width/height expansion vs. center point travel.
    // We want width/height to expand "faster" initially, while the center stays put.

    // Let's use 't' directly for width/height expansion for now.
    final double currentWidth = lerpDouble(begin!.width, end!.width, t)!;
    final double currentHeight = lerpDouble(begin!.height, end!.height, t)!;

    // For the center, we want it to lag, or only start moving significantly
    // after some expansion has happened.
    // One way: use a curve for the center's interpolation.
    // For example, an EaseIn curve means it moves slowly at first, then faster.
    // Or, more simply, delay the start of its full travel.

    final double centerTravelT = t; // Simplest: linear travel for center.
    // To make it stay at source longer:
    // final double centerTravelT = Curves.easeIn.transform(t);
    // Or a custom curve: if (t < 0.5) { centerTravelT = 0; } else { centerTravelT = (t - 0.5) * 2; }

    final Offset currentCenter = Offset.lerp(
        sourceCenter, destinationCenter, centerTravelT)!;

    // What if the source card is small and the destination is large?
    // We want the expansion to *feel* like it's coming from the card.
    // The shuttle (the image being shown) will be clipped by this Rect.
    // If the shuttle is the destination image, and it's large, it will be
    // clipped to `currentWidth` and `currentHeight` centered at `currentCenter`.

    return Rect.fromCenter(
      center: currentCenter,
      width: currentWidth,
      height: currentHeight,
    );
  }

  // Helper to lerp double, handling nulls if necessary (though width/height shouldn't be null here)
  double? lerpDouble(num? a, num? b, double t) {
    if (a == null || b == null) {
      if (b != null) return b.toDouble();
      if (a != null) return a.toDouble();
      return null;
    }
    return a + (b - a) * t;
  }
}