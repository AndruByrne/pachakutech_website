// lib/header_util.dart (or your preferred path like lib/utils/app_header_utils.dart)
import 'dart:ui' show lerpDouble; // Only lerpDouble is needed from dart:ui here
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:marquee/marquee.dart';
import 'package:vector_math/vector_math.dart' show radians;

import 'app_sections.dart';

// --- HeaderVisualParams Data Class ---
class HeaderVisualParams {
  final double wheelDiameter;
  final Alignment wheelAlignment;
  final double wheelAngle1;
  final double wheelAngle2;
  final Color wheel1Color;
  final Color wheel2Color;
  final Color backgroundColor;
  final double dotLogoScaleFactor;
  final double navButtonOpacity;
  final Color navButtonColor;
  final double marqueeOpacity;
  final double marqueeWidthFraction;
  final double marqueeVelocity;
  final String marqueeText;

  // To indicate which section (if any) is the target for wheels, or if it's home
  final AppSection? targetSection; // null for home, or when buttons not visible
  final bool
      isCollapsedState; // True if header is fully collapsed or on detail page

  HeaderVisualParams({
    required this.wheelDiameter,
    required this.wheelAlignment,
    required this.wheelAngle1,
    required this.wheelAngle2,
    required this.wheel1Color,
    required this.wheel2Color,
    required this.backgroundColor,
    required this.dotLogoScaleFactor,
    required this.navButtonOpacity,
    required this.navButtonColor,
    required this.marqueeOpacity,
    required this.marqueeWidthFraction,
    required this.marqueeVelocity,
    required this.marqueeText,
    this.targetSection,
    required this.isCollapsedState,
  });

  static HeaderVisualParams lerp(
      HeaderVisualParams a, HeaderVisualParams b, double t) {
    // Ensure targetSection and isCollapsedState are handled appropriately.
    // Typically, these might not be lerped but taken from 'b' or based on 't'.
    // For simplicity, let's take them from 'b' if t is closer to 1.
    AppSection? lerpedTargetSection =
        t > 0.5 ? b.targetSection : a.targetSection;
    bool lerpedIsCollapsed = t > 0.5 ? b.isCollapsedState : a.isCollapsedState;

    return HeaderVisualParams(
      wheelDiameter: lerpDouble(a.wheelDiameter, b.wheelDiameter, t)!,
      wheelAlignment: Alignment.lerp(a.wheelAlignment, b.wheelAlignment, t)!,
      // dotLogoDiameter is now effectively controlled by dotLogoScaleFactor * baseSize
      dotLogoScaleFactor:
          lerpDouble(a.dotLogoScaleFactor, b.dotLogoScaleFactor, t)!,
      wheelAngle1: lerpDouble(a.wheelAngle1, b.wheelAngle1, t)!,
      wheelAngle2: lerpDouble(a.wheelAngle2, b.wheelAngle2, t)!,
      wheel1Color: Color.lerp(a.wheel1Color, b.wheel1Color, t)!,
      wheel2Color: Color.lerp(a.wheel2Color, b.wheel2Color, t)!,
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      navButtonOpacity: lerpDouble(a.navButtonOpacity, b.navButtonOpacity, t)!,
      navButtonColor: Color.lerp(a.navButtonColor, b.navButtonColor, t)!,
      marqueeOpacity: lerpDouble(a.marqueeOpacity, b.marqueeOpacity, t)!,
      marqueeWidthFraction:
          lerpDouble(a.marqueeWidthFraction, b.marqueeWidthFraction, t)!,
      marqueeVelocity: lerpDouble(a.marqueeVelocity, b.marqueeVelocity, t)!,
      marqueeText: t < 0.5 ? a.marqueeText : b.marqueeText,
      // Simple switch, could be smarter
      targetSection: lerpedTargetSection,
      isCollapsedState: lerpedIsCollapsed,
    );
  }
}

// --- Shared Widget Builder for the Animated Header Content ---
// In header_util.dart
// Import Marquee if not already: import 'package:marquee/marquee.dart';
// You'll also need your AppSection enum.
// import 'package:pachakutech_website/app_sections.dart';

Widget buildAnimatedHeaderContent({
  required BuildContext context, // Added BuildContext
  required HeaderVisualParams params,
  Future<String>?
      tickerFuture, // Now optional, as params.marqueeText handles it
  VoidCallback? onHomeTap, // Replaces onLogoTap/onWheelsTap for clarity
  required ValueChanged<AppSection>
      onSectionTap, // Callback for section buttons
  // isPopAnimation is not directly used here now, params.isCollapsedState is more relevant
}) {
  // --- Wheels (Home Button) ---
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
            child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                colorFilter:
                    ColorFilter.mode(params.wheel1Color, BlendMode.srcIn)),
          ),
          Transform.rotate(
            angle: radians(params.wheelAngle2),
            child: SizedBox(
              width: params.wheelDiameter * 0.6,
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

  if (onHomeTap != null && params.isCollapsedState) {
    // Active when collapsed
    wheelsWidget = GestureDetector(
      onTap: onHomeTap,
      child: wheelsWidget,
    );
  }

  // --- Dot Logo (scales and fades) ---
  // The actual diameter is base size * scaleFactor
  final double baseDotLogoDiameter =
      AppHeaderMetrics.getBaseDotLogoDiameter(context);
  final double currentDotLogoDisplayDiameter =
      baseDotLogoDiameter * params.dotLogoScaleFactor;

  Widget dotLogoWidget = SizedBox(
    width: currentDotLogoDisplayDiameter,
    height: currentDotLogoDisplayDiameter,
    child: Image.asset('assets/pachakutech_dot_logo_alpha.png'),
  );

  List<Widget> navButtons = [
    params.targetSection == null
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: params.wheelDiameter,
              child: wheelsWidget,
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(3.0),
            child: createNavButtonForSection(
                context: context,
                section: null,
                isActive: false,
                currentParams: params,
                onTap: onHomeTap),
          )
  ];
  navButtons
      .addAll(AppSection.values.map((section) => section == params.targetSection
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: params.wheelDiameter,
                child: wheelsWidget,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(3.0),
              child: createNavButtonForSection(
                  context: context,
                  section: section,
                  isActive: false,
                  currentParams: params,
                  onTap: () => onSectionTap(section)),
            )));

  // --- Marquee ---
  Widget marqueeWidget = Opacity(
    opacity: params.marqueeOpacity,
    child: params.marqueeOpacity > 0.01 && params.marqueeWidthFraction > 0.01
        ? SizedBox(
            // Width is a fraction of available space AFTER wheels and buttons
            // This calculation is complex. For now, assume it's a fraction of total header width.
            // A Row/Expanded structure would be better for precise width allocation.
            // height: AppHeaderMetrics.getCollapsedHeaderHeight(context) * 0.5, // Example height
            child: Marquee(
              text: params.marqueeText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, // Adjust
                color: Theme.of(context)
                    .colorScheme
                    .primary, // Or params.navButtonColor
              ),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 20.0,
              velocity: params.marqueeVelocity,
              pauseAfterRound: Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          )
        : SizedBox.shrink(), // Don't build if invisible or zero width
  );

  // --- Layout ---
  // When collapsed, the layout is: Wheels | NavButtons | Marquee
  // When expanding, dot_logo is centered and fades/scales.
  // This requires careful stacking or conditional layouts.
// In header_util.dart (Continuing buildAnimatedHeaderContent)

  // --- Layout ---
  // When collapsed, the layout is: Wheels | NavButtons | Marquee
  // When expanding, dot_logo is centered and fades/scales.

  Widget headerContent;

  // Dot Logo Opacity: It should be fully visible when marquee is not, and fade out as marquee fades in.
  // params.dotLogoScaleFactor also goes to 0 when marquee is fully opaque.
  // The scale factor itself handles the "vanishing" act for the logo.
  // No explicit separate opacity widget needed for the logo if scale factor correctly goes to 0.

  if (params.isCollapsedState || params.marqueeOpacity > 0.01) {
    // Collapsed or transitioning to collapsed: Show Wheels | Buttons | Marquee
    // The dotLogo is effectively "gone" because its scale factor will be ~0 or actually 0.
    headerContent = Container(
      color: params.backgroundColor,
      padding: EdgeInsets.only(
        top: params.isCollapsedState
            ? MediaQuery.of(context).padding.top
            : 0, // Apply top padding only when fully collapsed
        left: 8,
        right: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Nav Buttons
          if (navButtons.isNotEmpty) ...navButtons,

          // Marquee
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: marqueeWidget,
            ),
          ),
        ],
      ),
    );
  } else {
    // Mostly expanded state: Wheels are moving to center, Dot Logo is primary visual.
    // Marquee and NavButtons are faded out (opacity ~0).
    headerContent = Container(
      color: params.backgroundColor,
      child: Stack(
        alignment: Alignment.center, // Main stack alignment for expanded view
        children: [
          // Wheels are aligned according to params.wheelAlignment,
          // which moves from center towards its collapsed position.
          wheelsWidget,
          // This instance does not need the tap handler here usually

          // Dot Logo - only visible if its scale factor is > 0
          if (params.dotLogoScaleFactor > 0.001)
            SizedBox(
              // Ensure it's centered if wheels are not perfectly center
              width: currentDotLogoDisplayDiameter,
              height: currentDotLogoDisplayDiameter,
              child: dotLogoWidget, // dotLogoWidget already has the image
            ),
        ],
      ),
    );
  }

  return headerContent;
}

// In header_util.dart
Widget globalFlightShuttleBuilderInternal({
  required BuildContext flightContext,
  required Animation<double> animation,
  required HeaderVisualParams paramsAtAnimationStart,
  required HeaderVisualParams paramsAtAnimationEnd,
  required HeroFlightDirection flightDirection,
}) =>
    AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          HeaderVisualParams interpolatedDisplayParams;

          if (flightDirection == HeroFlightDirection.push) {
            // PUSH: Animate from Start (Home/Expanded) to End (Detail/Collapsed)
            interpolatedDisplayParams = HeaderVisualParams.lerp(
                paramsAtAnimationStart, paramsAtAnimationEnd, t);
          } else {
            // HeroFlightDirection.pop
            // POP:
            // Raw interpolated params go from Start (Detail/Collapsed) to End (Home/Expanded)
            // for POP, we want to lerp from paramsAtAnimationEnd (Home/Expanded)
            // to paramsAtAnimationStart (Detail/Collapsed) using t.
            interpolatedDisplayParams = HeaderVisualParams.lerp(
                paramsAtAnimationEnd,
                // Treat POP's destination (Home/Expanded) as the visual start
                paramsAtAnimationStart,
                // Treat POP's source (Detail/Collapsed) as the visual end
                t); // Use t directly (0 to 1)
          }

          return KeyedSubtree(
            // Keying based on flightDirection might still be good practice
            key: flightDirection == HeroFlightDirection.pop
                ? const ValueKey('pop_animation_context_fixed')
                : const ValueKey('push_animation_context_fixed'),
            child: buildAnimatedHeaderContent(
              context: flightContext,
              params: interpolatedDisplayParams,
              onSectionTap: (AppSection value) {},
            ),
          );
        });

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
      getFullscreenWheelDiameter(context) * 0.3; // Based on fullscreen wheel

  static double getCollapsedLogoDiameter(BuildContext context) =>
      getFullscreenWheelDiameter(context) * 0.5;

  // --- Alignments ---
  static Alignment getFullscreenWheelAlignment() => Alignment.center;

  static Alignment getCollapsedWheelAlignment() => const Alignment(-0.95, 0.0);

  // Target angles for sections when collapsed
  static const double WHEEL_ANGLE_HOME =
      AppHeaderLogic.MAX_EFFECTIVE_WHEEL_ANGLE; // 584.0
  static const double WHEEL_ANGLE_EVAL = 539.0;
  static const double WHEEL_ANGLE_EDU = 494.0;
  static const double WHEEL_ANGLE_ELEV = 449.0;
  static const double NAV_BUTTON_WIDTH_ESTIMATE =
      60.0; // Example, adjust to your actual button width
  static const double NAV_BUTTON_SPACING = 8.0; // Space between buttons

  static Alignment _getAlignmentForSlotIndex(
      BuildContext context, int slotIndex) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double collapsedWheelDiameter = getCollapsedWheelDiameter(context);

    // Total width taken by one wheel/button slot and its trailing space
    // (except for the last button, which has no trailing space relevant here)
    final double slotPlusSpaceWidth =
        NAV_BUTTON_WIDTH_ESTIMATE + NAV_BUTTON_SPACING;

    // Calculate the pixel X-coordinate for the *center* of the wheel in the desired slot.
    // Assume the row of buttons starts after some initial padding from the left edge (e.g., 8.0).
    final double leftPadding = 8.0;

    // X-coordinate of the center of the first slot (Home/Wheels)
    double targetCenterX = leftPadding + (NAV_BUTTON_WIDTH_ESTIMATE / 2.0);

    // Add widths for preceding slots
    targetCenterX += slotIndex * slotPlusSpaceWidth;

    // Convert this targetCenterX (from left edge) to an Alignment.x value.
    // The parent for Alignment calculation is the Row's width (effectively screenWidth if Row fills it).
    // The child is the wheel.
    // pixel_offset_from_screen_center = targetCenterX - (screenWidth / 2.0)
    double pixelOffsetFromScreenCenter = targetCenterX - (screenWidth / 2.0);

    // If the parent for Alignment is the screen width, and child is wheelDiameter:
    double alignmentX;
    if (screenWidth - collapsedWheelDiameter == 0) {
      // Avoid division by zero
      alignmentX = 0;
    } else {
      alignmentX = (2 * pixelOffsetFromScreenCenter) /
          (screenWidth - collapsedWheelDiameter);
    }

    // print("Slot $slotIndex: targetCenterX=$targetCenterX, screenWidth=$screenWidth, wheelDia=$collapsedWheelDiameter, alignmentX=$alignmentX");

    return Alignment(alignmentX.clamp(-1.0, 1.0),
        0.0); // Y is typically 0.0 for vertical center
  }

  // Placeholder: Define button width and padding to calculate wheel alignments
  // These would ideally be calculated dynamically or be constants
  static const double NAV_BUTTON_WIDTH = 60.0; // Example
  static const double NAV_BUTTON_PADDING = 8.0; // Example

  static Alignment getWheelAlignmentForSection(
      BuildContext context, AppSection? section) {
    if (section == null) {
      // Home section
      return _getAlignmentForSlotIndex(context, 0); // Slot 0 for Home
    }
    switch (section) {
      case AppSection.evaluation:
        return _getAlignmentForSlotIndex(context, 1); // Slot 1 for Eval
      case AppSection.education:
        return _getAlignmentForSlotIndex(context, 2); // Slot 2 for Edu
      case AppSection.elevation:
        return _getAlignmentForSlotIndex(context, 3); // Slot 3 for Elev
      default:
        return _getAlignmentForSlotIndex(context, 0); // Default to Home slot
    }
  }

  static HeaderVisualParams getCollapsedHeaderVisualParams(
    BuildContext context, {
    AppSection? targetSection,
    String marqueeText = "pachakutech",
  }) {
    double targetWheelAngle1;
    Alignment targetWheelAlignment =
        getWheelAlignmentForSection(context, targetSection);

    if (targetSection == null) {
      // Home page/section is active
      targetWheelAngle1 = WHEEL_ANGLE_HOME;
      // marqueeText might be default or "Pachakutech Home"
    } else {
      // A specific section (Eval, Edu, Elev) is active
      switch (targetSection) {
        case AppSection.evaluation:
          targetWheelAngle1 = WHEEL_ANGLE_EVAL;
          break;
        case AppSection.education:
          targetWheelAngle1 = WHEEL_ANGLE_EDU;
          break;
        case AppSection.elevation:
          targetWheelAngle1 = WHEEL_ANGLE_ELEV;
          break;
        default: // Should not happen
          targetWheelAngle1 = WHEEL_ANGLE_HOME;
      }
      // marqueeText is passed in and should be section-specific
    }

    return HeaderVisualParams(
      wheelDiameter: getCollapsedWheelDiameter(context),
      wheelAlignment: targetWheelAlignment,
      // <<< USES THE NEW DYNAMIC ALIGNMENT
      dotLogoScaleFactor: 0.0,
      wheelAngle1: targetWheelAngle1,
      wheelAngle2: 90.0 - targetWheelAngle1,
      wheel1Color: Theme.of(context).colorScheme.primary,
      wheel2Color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      navButtonOpacity: 1.0,
      // Buttons are generally visible
      navButtonColor: Theme.of(context).colorScheme.primary,
      marqueeOpacity: 1.0,
      marqueeWidthFraction: 1.0,
      marqueeVelocity: 20.0,
      marqueeText: marqueeText,
      targetSection: targetSection,
      // Crucial for knowing which section is active
      isCollapsedState: true,
    );
  }

  static HeaderVisualParams getFullscreenHeaderVisualParams(
          BuildContext context) =>
      HeaderVisualParams(
        wheelDiameter: getFullscreenWheelDiameter(context),
        wheelAlignment: getFullscreenWheelAlignment(),
        dotLogoScaleFactor: 1.0,
        // Dot logo at its initial scaled size (based on getBaseDotLogoDiameter)
        wheelAngle1: 0,
        wheelAngle2: 90,
        wheel1Color: Theme.of(context).colorScheme.secondary,
        wheel2Color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        navButtonOpacity: 0.0,
        navButtonColor: Colors.transparent,
        // Start transparent
        marqueeOpacity: 0.0,
        marqueeWidthFraction: 0.0,
        // Starts with zero effective width for marquee logic
        marqueeVelocity: 0.0,
        marqueeText: "pachakutech",
        // Default
        targetSection: null,
        // No target section in fullscreen home
        isCollapsedState: false,
      );
}

Widget createNavButtonForSection({
  required BuildContext context,
  required AppSection? section, // Null for Home
  required bool
      isActive, // Though with wheels obscuring, this might not be needed for styling
  required HeaderVisualParams currentParams,
  required VoidCallback? onTap,
}) =>
    GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: currentParams.navButtonOpacity,
        child: Text(section?.id ?? 'HOME',
            style: TextStyle(
                fontFamily: 'Pachakutech',
                fontSize: 20,
                color: Theme.of(context).primaryColor)),
      ),
    );

class AppHeaderLogic {
  static const double MAX_EFFECTIVE_WHEEL_ANGLE = 584.0;
  static const double LAST_HALF_TURN_START_ANGLE = 404.0;
  static const double DOT_LOGO_SCALE_END_ANGLE =
      LAST_HALF_TURN_START_ANGLE; // Explicitly for clarity
  static const double LAST_HALF_TURN_DURATION =
      MAX_EFFECTIVE_WHEEL_ANGLE - LAST_HALF_TURN_START_ANGLE;

  static HeaderVisualParams getDynamicHeaderVisualParams({
    required BuildContext context,
    required double scrollOffset,
    AppSection?
        targetSectionForCollapsed, // hint for final state if collapsing towards a section
    String? currentMarqueeText, // for detail pages to provide their ticker
  }) {
    final double transitionEndScrollOffset =
        AppHeaderMetrics.getTransitionEndScrollOffset(context);
    double headerEffectiveShrinkOffset =
        scrollOffset.clamp(0.0, transitionEndScrollOffset);
    double overallTransitionProgress = 0.0;

    if (transitionEndScrollOffset > 0) {
      overallTransitionProgress =
          (headerEffectiveShrinkOffset / transitionEndScrollOffset)
              .clamp(0.0, 1.0);
    } else if (headerEffectiveShrinkOffset >= transitionEndScrollOffset) {
      overallTransitionProgress = 1.0;
    }

    // Get baseline visual params for fullscreen and collapsed states
    // The target collapsed state depends on whether we are aiming for "home" or a specific section.
    // This 'targetSectionForCollapsed' would typically be null on the home page during scroll,
    // and set during a Hero push to a detail page.
    final fsParams = AppHeaderMetrics.getFullscreenHeaderVisualParams(context);
    final colParams = AppHeaderMetrics.getCollapsedHeaderVisualParams(context,
        targetSection: targetSectionForCollapsed,
        // This is key for flight animations
        marqueeText: currentMarqueeText ??
            "pachakutech" // Use specific ticker if available
        );

    // --- Wheel Values ---
    double currentWheelAngle1 = lerpDouble(fsParams.wheelAngle1,
        colParams.wheelAngle1, overallTransitionProgress)!;
    double currentWheelAngle2 = lerpDouble(fsParams.wheelAngle2,
        colParams.wheelAngle2, overallTransitionProgress)!;
    double currentWheelDiameter = lerpDouble(fsParams.wheelDiameter,
        colParams.wheelDiameter, overallTransitionProgress)!;
    Alignment currentWheelAlignment = Alignment.lerp(fsParams.wheelAlignment,
        colParams.wheelAlignment, overallTransitionProgress)!;

    // Scale from 1.0 down to 0.0 (fully replaced by marquee) over the DOT_LOGO_SCALE_END_ANGLE
    double dotLogoScaleProgress = 0.0;
    if (currentWheelAngle1 <= DOT_LOGO_SCALE_END_ANGLE &&
        DOT_LOGO_SCALE_END_ANGLE > 0) {
      // This progress goes from 0 (start, full size) to 1 (at DOT_LOGO_SCALE_END_ANGLE, scaled down size)
      dotLogoScaleProgress =
          (currentWheelAngle1 / DOT_LOGO_SCALE_END_ANGLE).clamp(0.0, 1.0);
    } else if (currentWheelAngle1 > DOT_LOGO_SCALE_END_ANGLE) {
      dotLogoScaleProgress =
          1.0; // Fully scaled down for the transition to marquee
    }

    const double intermediateDotLogoVisualScale =
        0.6; // Scale at DOT_LOGO_SCALE_END_ANGLE
    double currentDotLogoVisualScale = lerpDouble(
        fsParams.dotLogoScaleFactor, // Should be 1.0 (full base size)
        intermediateDotLogoVisualScale,
        dotLogoScaleProgress)!;

    // --- lastHalfTurnLerp (for colors, button fade, marquee fade) ---
    // This lerp controls animations from LAST_HALF_TURN_START_ANGLE to MAX_EFFECTIVE_WHEEL_ANGLE
    double lastHalfTurnLerp = 0.0;
    if (currentWheelAngle1 >= MAX_EFFECTIVE_WHEEL_ANGLE) {
      // Or colParams.wheelAngle1 if target isn't home
      lastHalfTurnLerp = 1.0;
    } else if (currentWheelAngle1 > LAST_HALF_TURN_START_ANGLE &&
        LAST_HALF_TURN_DURATION > 0) {
      // Normalize based on the actual target angle for this specific lerp
      // The `colParams.wheelAngle1` is the actual target angle for the current context (home or section)
      // The lerp should go from 0 to 1 as currentWheelAngle1 moves from LAST_HALF_TURN_START_ANGLE to `colParams.wheelAngle1`
      double effectiveEndAngleForLerp =
          colParams.wheelAngle1; // Could be 584, 539, 494, 449
      double durationForThisLerp =
          effectiveEndAngleForLerp - LAST_HALF_TURN_START_ANGLE;
      if (durationForThisLerp > 0) {
        lastHalfTurnLerp = ((currentWheelAngle1 - LAST_HALF_TURN_START_ANGLE) /
                durationForThisLerp)
            .clamp(0.0, 1.0);
      } else if (currentWheelAngle1 >= effectiveEndAngleForLerp) {
        lastHalfTurnLerp = 1.0;
      } else {
        lastHalfTurnLerp =
            0.0; // Should not happen if currentWheelAngle1 > LAST_HALF_TURN_START_ANGLE
      }
    }
    // else it remains 0.0

    // --- Apply lastHalfTurnLerp for transitions ---
    Color wheel1Color = Color.lerp(
        fsParams.wheel1Color, colParams.wheel1Color, lastHalfTurnLerp)!;
    Color wheel2Color = Color.lerp(
        fsParams.wheel2Color, colParams.wheel2Color, lastHalfTurnLerp)!;
    Color backgroundColor = Color.lerp(
        fsParams.backgroundColor, colParams.backgroundColor, lastHalfTurnLerp)!;

    // Nav Buttons: Opacity and Color
    double navButtonOpacity = lerpDouble(fsParams.navButtonOpacity,
        colParams.navButtonOpacity, lastHalfTurnLerp)!;
    Color navButtonColor = Color.lerp(
        fsParams.navButtonColor, colParams.navButtonColor, lastHalfTurnLerp)!;

    // Marquee: Opacity, Width, Velocity
    // Marquee opacity is inverse of dot logo's effective opacity during this phase
    double marqueeOpacity = lastHalfTurnLerp; // Fades IN with lastHalfTurnLerp
    // Dot logo opacity effectively fades OUT with lastHalfTurnLerp
    double dotLogoOpacityDuringLastHalfTurn = 1.0 - lastHalfTurnLerp;

    // The actual dotLogoScaleFactor to pass to HeaderVisualParams should consider both:
    // 1. The pre-LHTL scaling (currentDotLogoVisualScale)
    // 2. The LHTL fade-out (dotLogoOpacityDuringLastHalfTurn effectively acting as an additional scale factor for opacity)
    // For simplicity, let's assume dotLogoScaleFactor in params is purely for size, and we'll use Opacity widget for fade.
    // So, currentDotLogoVisualScale is the size scale.
    // And dotLogoOpacityDuringLastHalfTurn is its opacity.
    // HeaderVisualParams needs a new field: dotLogoOpacity.
    // Let's adjust: dotLogoScaleFactor will be the visual scale. Opacity will be controlled by marqueeOpacity's inverse.

    double marqueeWidthFraction = lerpDouble(
        // Marquee starts with a width comparable to the dot logo it's replacing
        // This is tricky. If fsParams.marqueeWidthFraction is 0, it means it starts from 0 width.
        // Or, it could be a small fraction representing the scaled dotLogoDiameter.
        // Let's refine `fsParams.marqueeWidthFraction` to be related to `colParams.dotLogoDiameter` (its size before vanishing)
        // This needs careful thought on how marqueeWidthFraction is defined.
        // For now, let's say it starts at a small fraction and grows.
        AppHeaderMetrics.getCollapsedLogoDiameter(context) /
            MediaQuery.of(context).size.width, // Approx starting width %
        colParams.marqueeWidthFraction, // Target full width fraction
        lastHalfTurnLerp)!;

    double marqueeVelocity = lerpDouble(
        fsParams.marqueeVelocity, colParams.marqueeVelocity, lastHalfTurnLerp)!;

    // Determine effective dotLogoScaleFactor:
    // Before LHTL starts, it's `currentDotLogoVisualScale`.
    // During LHTL, it should visually "cross-fade". So if marquee is 20% visible, dotlogo is 80%.
    // The `dotLogoScaleFactor` passed to `HeaderVisualParams` should represent its current visual scale.
    // The cross-fade means that as marqueeOpacity goes 0->1, dotLogo's effective presence goes 1->0.
    // So, actualDotLogoScaleFactor = currentDotLogoVisualScale * (1 - marqueeOpacity)
    double finalDotLogoScaleFactor =
        currentDotLogoVisualScale * (1 - marqueeOpacity);

    return HeaderVisualParams(
      wheelDiameter: currentWheelDiameter,
      wheelAlignment: currentWheelAlignment,
      dotLogoScaleFactor: finalDotLogoScaleFactor,
      //This is the visual scale factor for the dot logo image
      wheelAngle1: currentWheelAngle1,
      wheelAngle2: currentWheelAngle2,
      wheel1Color: wheel1Color,
      wheel2Color: wheel2Color,
      backgroundColor: backgroundColor,
      navButtonOpacity: navButtonOpacity,
      navButtonColor: navButtonColor,
      marqueeOpacity: marqueeOpacity,
      marqueeWidthFraction: marqueeWidthFraction,
      // This is a fraction of available space
      marqueeVelocity: marqueeVelocity,
      marqueeText:
          (overallTransitionProgress < 1.0 || targetSectionForCollapsed == null)
              ? "pachakutech"
              : colParams.marqueeText,
      // Use specific text only when fully collapsed for a section
      targetSection:
          overallTransitionProgress == 1.0 ? targetSectionForCollapsed : null,
      isCollapsedState: overallTransitionProgress == 1.0,
    );
  }
}
