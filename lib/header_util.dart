// lib/header_util.dart (or your preferred path like lib/utils/app_header_utils.dart)
import 'dart:ui' show lerpDouble; // Only lerpDouble is needed from dart:ui here
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:vector_math/vector_math.dart' show radians;

// Import MyHomePageState to access _currentHeaderVisualParams if needed by the shuttle
// This creates a slight coupling, but is pragmatic for the shuttle.
// Alternatively, use a state management solution to provide params.
import 'package:pachakutech_website/home_page.dart'; // Adjust import path as necessary

// --- HeaderVisualParams Data Class ---
class HeaderVisualParams {
  final double wheelDiameter;
  final Alignment wheelAlignment;
  final double dotLogoDiameter;
  final double wheelAngle1;
  final double wheelAngle2;
  final Color wheel1Color;
  final Color wheel2Color;
  final Color backgroundColor;

  HeaderVisualParams({
    required this.wheelDiameter,
    required this.wheelAlignment,
    required this.dotLogoDiameter,
    required this.wheelAngle1,
    required this.wheelAngle2,
    required this.wheel1Color,
    required this.wheel2Color,
    required this.backgroundColor,
  });

  static HeaderVisualParams lerp(
      HeaderVisualParams a, HeaderVisualParams b, double t) {
    return HeaderVisualParams(
      wheelDiameter: lerpDouble(a.wheelDiameter, b.wheelDiameter, t)!,
      wheelAlignment: Alignment.lerp(a.wheelAlignment, b.wheelAlignment, t)!,
      dotLogoDiameter: lerpDouble(a.dotLogoDiameter, b.dotLogoDiameter, t)!,
      wheelAngle1: lerpDouble(a.wheelAngle1, b.wheelAngle1, t)!,
      wheelAngle2: lerpDouble(a.wheelAngle2, b.wheelAngle2, t)!,
      wheel1Color: Color.lerp(a.wheel1Color, b.wheel1Color, t)!,
      wheel2Color: Color.lerp(a.wheel2Color, b.wheel2Color, t)!,
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
    );
  }
}

// --- Shared Widget Builder for the Animated Header Content ---
Widget buildAnimatedHeaderContent({
  required BuildContext context,
  required HeaderVisualParams params,
  VoidCallback? onLogoTap, // Optional: for the dot logo
  VoidCallback? onWheelsTap, // Optional: for the wheels
}) {
  // The dotLogo from MyHomePage had a GestureDetector, let's make it configurable
  Widget dotLogoWidget = SizedBox(
    width: params.dotLogoDiameter,
    height: params.dotLogoDiameter,
    child: Image.asset('assets/pachakutech_dot_logo_alpha.png'),
  );

  if (onLogoTap != null) {
    dotLogoWidget = GestureDetector(
      onTap: onLogoTap,
      child: dotLogoWidget,
    );
  }

  Widget wheelsWidget = Align(
    alignment: params.wheelAlignment,
    child: SizedBox(
      width: params.wheelDiameter,
      height: params.wheelDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: radians(params.wheelAngle1),
            child: SizedBox(
              width: params.wheelDiameter, // Wheel 1 full diameter
              height: params.wheelDiameter,
              child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                  colorFilter:
                      ColorFilter.mode(params.wheel1Color, BlendMode.srcIn)),
            ),
          ),
          Transform.rotate(
            angle: radians(params.wheelAngle2),
            child: SizedBox(
              width: params.wheelDiameter * 0.6, // Wheel 2 smaller diameter
              height: params.wheelDiameter * 0.6,
              child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                  colorFilter:
                      ColorFilter.mode(params.wheel2Color, BlendMode.srcIn)),
            ),
          ),
        ],
      ),
    ),
  );

  if (onWheelsTap != null) {
    wheelsWidget = Material(
      // For InkWell ripple effect
      color: Colors.transparent,
      child: params.wheelAngle1 == AppHeaderLogic.MAX_EFFECTIVE_WHEEL_ANGLE
          ? InkWell(
              // todo: remove unless in collapsed or near it
              onTap: onWheelsTap,
              customBorder: const CircleBorder(), // If wheels area is circular
              child: wheelsWidget,
            )
          : wheelsWidget,
    );
  }

  return Container(
    color: params.backgroundColor,
    child: Stack(
      alignment: Alignment.center, // Main stack alignment
      children: [
        wheelsWidget,
        dotLogoWidget, // Ensure dotLogo is drawn on top of wheels if centered
      ],
    ),
  );
}

// In header_util.dart
Widget globalFlightShuttleBuilderInternal({
  required BuildContext flightContext,
  required Animation<double> animation,
  required HeaderVisualParams paramsAtAnimationStart,
  required HeaderVisualParams paramsAtAnimationEnd,
}) {
  final HeaderVisualParams interpolatedParams = HeaderVisualParams.lerp(
      paramsAtAnimationStart, paramsAtAnimationEnd, animation.value);

  // Log what's being interpolated
  print("  ShuttleInternal: t=${animation.value.toStringAsFixed(2)} "
      "FROM Align: ${paramsAtAnimationStart.wheelAlignment} Dia: ${paramsAtAnimationStart.wheelDiameter.toStringAsFixed(2)} "
      "TO Align: ${paramsAtAnimationEnd.wheelAlignment} Dia: ${paramsAtAnimationEnd.wheelDiameter.toStringAsFixed(2)}");

  return buildAnimatedHeaderContent(
    context: flightContext,
    params: interpolatedParams,
  );
}

// In header_util.dart
Widget globalFlightShuttleBuilder({
  required BuildContext flightContext,
  required Animation<double> animation,
  required HeroFlightDirection flightDirection,
  required BuildContext fromHeroContext,
  required BuildContext toHeroContext,
  HeaderVisualParams? homeParamsAtPush,
  HeaderVisualParams? homeParamsAtPopTarget,
}) {
  double t = animation.value;
  HeaderVisualParams actualParamsFrom, actualParamsTo;

  print(
      "globalFlightShuttleBuilder: Received homeParamsAtPush is ${homeParamsAtPush == null ? 'NULL' : 'NOT NULL (Align: ${homeParamsAtPush?.wheelAlignment})'}");
  print(
      "globalFlightShuttleBuilder: Received homeParamsAtPopTarget is ${homeParamsAtPopTarget == null ? 'NULL' : 'NOT NULL (Align: ${homeParamsAtPopTarget?.wheelAlignment})'}");

  if (flightDirection == HeroFlightDirection.push) {
    // PUSHING: fromHeroContext is Home, toHeroContext is Detail
    // We NEED Home's dynamic state for 'from'.
    // `homeParamsAtPush` is the best source if available (passed by MyHomePage's Hero).
    if (homeParamsAtPush != null) {
      actualParamsFrom = homeParamsAtPush;
      print("FlightShuttle (Push): Using explicit homeParamsAtPush.");
    } else {
      print(
          "FlightShuttle (Push): homeParamsAtPush was null. Falling back to Fullscreen for FromHero. This might be inaccurate.");
      actualParamsFrom =
          AppHeaderMetrics.getFullscreenHeaderVisualParams(fromHeroContext);
    }
    // "To" state for push is always the collapsed header of the detail page
    actualParamsTo =
        AppHeaderMetrics.getCollapsedHeaderVisualParams(toHeroContext);
  } else {
    // POPPING: fromHeroContext is Detail, toHeroContext is Home
    // "From" state for pop is always the collapsed header of the detail page
    actualParamsFrom =
        AppHeaderMetrics.getCollapsedHeaderVisualParams(fromHeroContext);
    print(
        "FlightShuttle (Pop): actualParamsFrom (Detail Page Collapsed) - Align: ${actualParamsFrom.wheelAlignment}");

    // We NEED Home's dynamic state for 'to'.
    // `homeParamsAtPopTarget` is the best source if available (passed by MyHomePage's Hero).
    if (homeParamsAtPopTarget != null) {
      actualParamsTo = homeParamsAtPopTarget;
      print("FlightShuttle (Pop): Using explicit homeParamsAtPopTarget.");
    } else {
      // If MyHomePage's Hero's shuttle wasn't used, or didn't pass params for the pop target,
      // this is a fallback. It might be incorrect if Home was scrolled.
      print(
          "FlightShuttle (Pop): homeParamsAtPopTarget was null. Falling back to Fullscreen for ToHero. This might be inaccurate.");
      actualParamsTo =
          AppHeaderMetrics.getFullscreenHeaderVisualParams(toHeroContext);
    }
    print(
        "FlightShuttle (Pop): Final actualParamsTo - Align: ${actualParamsTo.wheelAlignment}");
  }

  // Debugging the chosen parameters:
  // print("  FROM Params - Align: ${actualParamsFrom.wheelAlignment}, Dia: ${actualParamsFrom.wheelDiameter.toStringAsFixed(2)}");
  // print("  TO   Params - Align: ${actualParamsTo.wheelAlignment},   Dia: ${actualParamsTo.wheelDiameter.toStringAsFixed(2)}");

  final HeaderVisualParams interpolatedParams =
      HeaderVisualParams.lerp(actualParamsFrom, actualParamsTo, t);

  return buildAnimatedHeaderContent(
    context: flightContext, // Use the shuttle's own context for building
    params: interpolatedParams,
  );
}

// lib/header_util.dart

// ... (HeaderVisualParams class remains the same) ...

class AppHeaderMetrics {
  // --- Core Heights ---
  static double getFullscreenHeaderHeight(BuildContext context) =>
      MediaQuery.of(context).size.height * 0.95;

  static double getCollapsedHeaderHeight(BuildContext context) =>
      kToolbarHeight + MediaQuery.of(context).padding.top;

  // --- Scroll Offset Distances for Transitions ---
  // Rotate over first 50% of the header's total collapse distance
  static double getRotationEndScrollOffset(BuildContext context) =>
      getFullscreenHeaderHeight(context) * 0.5;

  // This is the total scroll distance over which the header collapses
  // from its fullscreen height to its collapsed height.
  static double getTransitionEndScrollOffset(BuildContext context) =>
      getFullscreenHeaderHeight(context) - getCollapsedHeaderHeight(context);

  // --- Diameters ---
  static double getFullscreenWheelDiameter(BuildContext context) =>
      getFullscreenHeaderHeight(context) * 0.9;

  static double getCollapsedWheelDiameter(BuildContext context) =>
      getCollapsedHeaderHeight(context) * 0.8;

  static double getBaseDotLogoDiameter(BuildContext context) =>
      getFullscreenWheelDiameter(context) * 0.8; // Based on fullscreen wheel

  static double getCollapsedLogoDiameter(BuildContext context) =>
      getFullscreenWheelDiameter(context) *
      0.6; // TODO: base the logo size on height, not width!

  // --- Alignments ---
  static Alignment getFullscreenWheelAlignment() => Alignment.center;

  static Alignment getCollapsedWheelAlignment() => const Alignment(-0.85, 0.0);

  // --- Methods to get specific HeaderVisualParams states ---
  static HeaderVisualParams getCollapsedHeaderVisualParams(
          BuildContext context) =>
      HeaderVisualParams(
        wheelDiameter: getCollapsedWheelDiameter(context),
        wheelAlignment: getCollapsedWheelAlignment(),
        dotLogoDiameter: getCollapsedLogoDiameter(context),
        wheelAngle1: AppHeaderLogic.MAX_EFFECTIVE_WHEEL_ANGLE,
        // Max rotation
        wheelAngle2: 90.0 - AppHeaderLogic.MAX_EFFECTIVE_WHEEL_ANGLE,
        // Corresponding inner
        wheel1Color: Theme.of(context).colorScheme.primary,
        wheel2Color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      );

  static HeaderVisualParams getFullscreenHeaderVisualParams(
          BuildContext context) =>
      HeaderVisualParams(
        wheelDiameter: getFullscreenWheelDiameter(context),
        wheelAlignment: getFullscreenWheelAlignment(),
        dotLogoDiameter: getBaseDotLogoDiameter(context),
        // Dot logo is its base size, no pulse
        wheelAngle1: 0,
        wheelAngle2: 90,
        wheel1Color: Theme.of(context).colorScheme.secondary,
        wheel2Color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.surface,
      );
}

class AppHeaderLogic {
  static const double MAX_EFFECTIVE_WHEEL_ANGLE = 584.0;
  static const double LAST_HALF_TURN_START_ANGLE = 404.0;
  static const double LAST_HALF_TURN_DURATION =
      MAX_EFFECTIVE_WHEEL_ANGLE - LAST_HALF_TURN_START_ANGLE;

  static HeaderVisualParams getDynamicHeaderVisualParams({
    required BuildContext context,
    required double scrollOffset,
  }) {
    // Get transition definition points from AppHeaderMetrics
    final double rotationEndScrollOffset =
        AppHeaderMetrics.getRotationEndScrollOffset(context);
    final double transitionEndScrollOffset =
        AppHeaderMetrics.getTransitionEndScrollOffset(context);

    // This is the crucial value: how much the header has effectively shrunk/scrolled.
    // It should go from 0 (fully expanded) up to transitionEndScrollOffset (fully collapsed).
    double headerEffectiveShrinkOffset =
        scrollOffset.clamp(0.0, transitionEndScrollOffset);

    // --- Calculate overall progress for most lerps (diameter, alignment, base logo size) ---
    double overallTransitionProgress = 0.0;
    if (transitionEndScrollOffset > 0) {
      overallTransitionProgress =
          (headerEffectiveShrinkOffset / transitionEndScrollOffset)
              .clamp(0.0, 1.0);
    } else if (headerEffectiveShrinkOffset >= transitionEndScrollOffset) {
      // Catches case where transitionEndScrollOffset is 0
      overallTransitionProgress = 1.0;
    }

    // Get baseline visual params for fullscreen and collapsed states
    final fsParams = AppHeaderMetrics.getFullscreenHeaderVisualParams(context);
    final colParams = AppHeaderMetrics.getCollapsedHeaderVisualParams(context);

    // --- Wheel Angles ---
    double currentWheelAngle1 = lerpDouble(fsParams.wheelAngle1,
        colParams.wheelAngle1, overallTransitionProgress)!;
    double currentWheelAngle2 = lerpDouble(fsParams.wheelAngle2,
        colParams.wheelAngle2, overallTransitionProgress)!;

    // --- Lerp general properties using overallTransitionProgress ---
    double currentWheelDiameter = lerpDouble(fsParams.wheelDiameter,
        colParams.wheelDiameter, overallTransitionProgress)!;
    Alignment currentWheelAlignment = Alignment.lerp(fsParams.wheelAlignment,
        colParams.wheelAlignment, overallTransitionProgress)!;

    double lastHalfTurnLerp = 0.0;
    if (currentWheelAngle1 >= MAX_EFFECTIVE_WHEEL_ANGLE) {
      lastHalfTurnLerp = 1.0;
    } else if (currentWheelAngle1 > LAST_HALF_TURN_START_ANGLE) {
      lastHalfTurnLerp = ((currentWheelAngle1 - LAST_HALF_TURN_START_ANGLE) /
              LAST_HALF_TURN_DURATION)
          .clamp(0.0, 1.0);
    }
    // else it remains 0.0 if effectiveWheelAngle <= LAST_HALF_TURN_START_ANGLE

    // Lerp base dot logo diameter
    double currentBaseDotLogoDiameter = lerpDouble(
        fsParams.dotLogoDiameter, colParams.dotLogoDiameter, lastHalfTurnLerp)!;

    // Colors: Lerp based on lastHalfTurnLerp for the color switch effect
    Color wheel1Color = Color.lerp(
        fsParams.wheel1Color, colParams.wheel1Color, lastHalfTurnLerp)!;
    Color wheel2Color = Color.lerp(
        fsParams.wheel2Color, colParams.wheel2Color, lastHalfTurnLerp)!;
    Color backgroundColor = Color.lerp(
        fsParams.backgroundColor, colParams.backgroundColor, lastHalfTurnLerp)!;

    // Debugging for scrollOffset = 0 (or any specific value of interest)
    if (scrollOffset < 1.0 && scrollOffset >= 0) {
      // Check for effectively zero
      print("AppHeaderLogic (scrollOffset~0):");
      print("  headerEffectiveShrinkOffset: $headerEffectiveShrinkOffset");
      print("  overallTransitionProgress: $overallTransitionProgress");
      print("  currentWheelAngle1: $currentWheelAngle1");
      print("  lastHalfTurnLerp: $lastHalfTurnLerp");
      print(
          "  fsParams: wheel1Color=${fsParams.wheel1Color}, bgColor=${fsParams.backgroundColor}, logoDia=${fsParams.dotLogoDiameter}");
      print(
          "  colParams: wheel1Color=${colParams.wheel1Color}, bgColor=${colParams.backgroundColor}, logoDia=${colParams.dotLogoDiameter}");
      print(
          "  Calculated: wheel1Color=$wheel1Color, bgColor=$backgroundColor, finalLogoDia=$currentBaseDotLogoDiameter, angle1=$currentWheelAngle1, angle2=$currentWheelAngle2");
    }

    return HeaderVisualParams(
      wheelDiameter: currentWheelDiameter,
      wheelAlignment: currentWheelAlignment,
      dotLogoDiameter: currentBaseDotLogoDiameter,
      wheelAngle1: currentWheelAngle1,
      wheelAngle2: currentWheelAngle2,
      wheel1Color: wheel1Color,
      wheel2Color: wheel2Color,
      backgroundColor: backgroundColor,
    );
  }
}
