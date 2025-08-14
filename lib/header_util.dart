// lib/header_util.dart (or your preferred path like lib/utils/app_header_utils.dart)
import 'dart:ui' show lerpDouble; // Only lerpDouble is needed from dart:ui here
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:marquee/marquee.dart';
import 'package:vector_math/vector_math.dart' show radians;

import 'app_sections.dart';

const HOME_BUTTON_TEXT = 'HOME';
const NAV_BUTTON_FONT_SIZE = 16.0;
const NAV_HEADER_SPACING = 8.0;
const MARQUEE_VELOCITY = 60.0;
const double NAV_BUTTON_HORIZONTAL_PADDING = 4.0;
const double NAV_BUTTON_SPACING = 0.5; // Space between buttons
const double MARQUEE_FONT_SIZE = 16.0;

// --- HeaderVisualParams Data Class ---
class HeaderVisualParams {
  final double wheelDiameter;
  final Alignment wheelAlignment;
  final Alignment navButtonRowAlignment;
  final Alignment dotLogoAlignment;
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

  final AppSection? targetSection; // null for home
  final bool isCollapsedState;

  HeaderVisualParams({
    required this.wheelDiameter,
    required this.wheelAlignment,
    required this.dotLogoAlignment,
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
    required this.navButtonRowAlignment,
    this.targetSection,
    required this.isCollapsedState,
  });

  static HeaderVisualParams lerp(
      HeaderVisualParams a, HeaderVisualParams b, double t) {
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
      navButtonRowAlignment:
          Alignment.lerp(a.navButtonRowAlignment, b.navButtonRowAlignment, t)!,
      dotLogoAlignment:
          Alignment.lerp(a.dotLogoAlignment, b.dotLogoAlignment, t)!,
      targetSection: lerpedTargetSection,
      isCollapsedState: lerpedIsCollapsed,
    );
  }
}

Widget buildAnimatedHeaderContent({
  required BuildContext context, // Added BuildContext
  required HeaderVisualParams params,
  Future<String>? tickerFuture,
  VoidCallback? onHomeTap,
  required ValueChanged<AppSection> onSectionTap,
  required Map<AppSection?, double> buttonCenterOffsetsX,
  required double uniformButtonSlotWidth,
}) {
  (AppSection.values.length) * NAV_BUTTON_SPACING; // Spaces between buttons
  final int numButtons = AppSection.values.length + 1;
  final double totalWidthOfButtonSlotsOnly =
      numButtons * uniformButtonSlotWidth;
  final double totalWidthOfSpacingBetweenButtons =
      (numButtons > 0 ? numButtons - 1 : 0) * NAV_BUTTON_SPACING;
  final double fixedButtonsWidth =
      totalWidthOfButtonSlotsOnly + totalWidthOfSpacingBetweenButtons;

// This is the width of buttons + spacer + remaining available space for marquee.
  final double screenPaddedWidth =
      MediaQuery.of(context).size.width - NAV_HEADER_SPACING * 2;
  final double fullTargetWidthOfBar =
      screenPaddedWidth; // The bar aims to fill the padded screen width eventually
// It's just the width of the buttons.
  final double initialWidthOfBar = fixedButtonsWidth;

  // The current animated width for the entire bar (buttons + marquee area).
// This width will be animated by lastHalfTurnLerp (which drives marqueeOpacity and navButtonRowAlignment).
// marqueeWidthFraction can be repurposed or used as this lerp value.
// Let's use params.marqueeOpacity as the lerp factor for width, since it goes 0 to 1.
  final double currentAnimatedBarWidth = lerpDouble(
    initialWidthOfBar,
    fullTargetWidthOfBar,
    params
        .marqueeOpacity, // Or lastHalfTurnLerp if marqueeOpacity isn't exactly 0-1 for this
  )!;

  // --- Calculate standard button slot width (text + padding) ---
  Widget visualWheels = SizedBox(
    // No Align here yet, alignment applied in the Stack
    width: params.wheelDiameter,
    height: params.wheelDiameter,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: radians(params.wheelAngle1),
          child: SizedBox(
            width: params.wheelDiameter,
            height: params.wheelDiameter,
            child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                colorFilter:
                    ColorFilter.mode(params.wheel1Color, BlendMode.srcIn)),
          ),
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
  );

  if (onHomeTap != null &&
      params.isCollapsedState &&
      params.targetSection == null) {
    // And perhaps params.navButtonOpacity > 0.5 to ensure it's "meant" to be a button
    visualWheels = GestureDetector(
      onTap: onHomeTap,
      behavior: HitTestBehavior.opaque, // Claim taps when it's the home button
      child: visualWheels,
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

  List<Widget> navButtons = [null, ...AppSection.values]
      .map((section) => Padding(
            padding: EdgeInsets.only(right: NAV_BUTTON_SPACING),
            child: createNavButtonForSection(
                context: context,
                section: section,
                currentParams: params,
                onTap: () {
                  if (section == null) {
                    if (onHomeTap != null) {
                      onHomeTap();
                    } else {
                      print(
                          '[buildAnimatedHeaderContent] WARNING: onHomeTap is NULL!');
                    }
                  } else {
                    onSectionTap(section);
                  }
                },
                buttonSlotWidth: uniformButtonSlotWidth,
                isTargetForWheels: (params.targetSection == section)),
          ))
      .toList();

  // --- Marquee ---
  final marqueeTextStyle = TextStyle(
    // fontWeight: FontWeight.bold,
    fontSize: MARQUEE_FONT_SIZE, // Adjust
    fontFamily: 'Pachakutech',
    fontWeight: FontWeight.bold ,
    color: Theme.of(context).colorScheme.primary,
  );
  Widget marqueeWidget = Opacity(
    opacity: params.marqueeOpacity,
    child: params.marqueeOpacity > 0.01 && params.marqueeWidthFraction > 0.01
        ? SizedBox(
            child: Material(
              color: params.backgroundColor,
              child: Marquee(
                text: params.marqueeText.isNotEmpty
                    ? params.marqueeText
                    : '        ',
                style: marqueeTextStyle,
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 0.0,
                velocity: MARQUEE_VELOCITY,
                pauseAfterRound: Duration(seconds: 1),
                startPadding: 0.0,
                showFadingOnlyWhenScrolling: true,
                //   fadingEdgeStartFraction: 0.1,
                //   fadingEdgeEndFraction: 0.1,
                accelerationDuration: Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
          )
        : SizedBox.shrink(), // Don't build if invisible or zero width
  );

  Widget internalBarContent = Row(
    mainAxisSize: MainAxisSize.min,
    // Important so Expanded knows its bounds from parent SizedBox
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      // Render buttons. They take up 'fixedButtonsWidth'
      ...navButtons,
      // Ensure navButtons are built correctly to sum up to fixedButtonsWidth

      // Marquee takes the rest of the space given by 'currentAnimatedBarWidth'
      // after buttons have taken their space.
      if (params.marqueeOpacity >
          0.01) // Only add Expanded if marquee is meant to be visible
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: NAV_HEADER_SPACING),
            // Spacer before marquee text
            child: marqueeWidget, // marqueeWidget has its own Opacity for text
          ),
        ),
    ],
  );

// This is the widget that will be ALIGNED. Its width is animated.
  Widget sizedAndAlignedBar = SizedBox(
    width: currentAnimatedBarWidth,
    child: Opacity(
      // Overall fade for the bar
      opacity: params.navButtonOpacity,
      child: internalBarContent,
    ),
  );

  Widget headerContent = Container(
    color: params.backgroundColor,
    padding: EdgeInsets.only(
      top: params.isCollapsedState ? MediaQuery.of(context).padding.top : 0,
      left: NAV_HEADER_SPACING,
      right: NAV_HEADER_SPACING,
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
            alignment: params.navButtonRowAlignment, child: sizedAndAlignedBar),
        Align(alignment: params.wheelAlignment, child: visualWheels),
        if (params.dotLogoScaleFactor > 0.001)
          Opacity(
            opacity: 1 - params.marqueeOpacity,
            child: Align(
              alignment: params.dotLogoAlignment,
              child: dotLogoWidget,
            ),
          ),
      ],
    ),
  );

  return headerContent;
}

// In header_util.dart
Widget globalFlightShuttleBuilderInternal({
  required BuildContext flightContext,
  required Animation<double> animation,
  required HeaderVisualParams paramsAtAnimationStart,
  required HeaderVisualParams paramsAtAnimationEnd,
  required HeroFlightDirection flightDirection,
  required Map<AppSection?, double> buttonCenterOffsetsX,
  required double maxButtonTextWidth,
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
              // Shuttle Dummy
              buttonCenterOffsetsX: buttonCenterOffsetsX,
              uniformButtonSlotWidth: maxButtonTextWidth,
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
      getFullscreenWheelDiameter(context) * 0.8; // Based on fullscreen wheel

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

  static double calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

  static double getButtonContentWidth(String text, TextStyle style) =>
      calculateTextWidth(text, style) + (3 * NAV_BUTTON_HORIZONTAL_PADDING);

  static Alignment getWheelAlignmentForSection(
    BuildContext context,
    AppSection? section,
    Map<AppSection?, double> buttonCenterOffsetsX,
    // TODO: Needs to be just a list
    // Key: section (null for Home), Value: center X offset
    double collapsedWheelDiameter,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double headerHorizontalPadding =
        8.0; // Padding of the header container itself

    double
        targetCenterX; // X-coordinate of the *center* of the target slot, relative to screen left

    if (section == null) {
      // Home
      targetCenterX = buttonCenterOffsetsX[null] ??
          (headerHorizontalPadding + collapsedWheelDiameter / 2.0);
    } else {
      targetCenterX = buttonCenterOffsetsX[section] ??
          (headerHorizontalPadding + collapsedWheelDiameter / 2.0);
    }

    // Convert this targetCenterX (from screen left) to an Alignment.x value.
    // The parent for Alignment calculation is the screenWidth.
    // The child is the wheel.
    // pixel_offset_from_screen_center = targetCenterX - (screenWidth / 2.0)
    double pixelOffsetFromScreenCenter = targetCenterX - (screenWidth / 2.0);

    double alignmentX;
    if (screenWidth - collapsedWheelDiameter <= 0) {
      // Avoid division by zero or negative
      alignmentX = 0;
    } else {
      // Alignment X = (2 * offset_from_center_of_parent) / (parent_width - child_width)
      alignmentX = (2 * pixelOffsetFromScreenCenter) /
          (screenWidth - collapsedWheelDiameter);
    }

    // print("Aligning to Section ${section?.id ?? 'HOME'}: targetCenterX=$targetCenterX, alignmentX=$alignmentX");

    return Alignment(alignmentX.clamp(-1.0, 1.0),
        0.0); // Y is 0.0 for vertical center in the row
  }

  static HeaderVisualParams getCollapsedHeaderVisualParams(
    BuildContext context, {
    AppSection? targetSection,
    String marqueeText = '',
    required Map<AppSection?, double> buttonCenterOffsetsX,
  }) {
    double targetWheelAngle1;
    final double collapsedWheelDia = getCollapsedWheelDiameter(context);
    Alignment targetWheelAlignment = getWheelAlignmentForSection(context,
        targetSection, buttonCenterOffsetsX, collapsedWheelDia); // Pass it here

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
    }

    return HeaderVisualParams(
      wheelDiameter: collapsedWheelDia,
      wheelAlignment: targetWheelAlignment,
      dotLogoScaleFactor: 0.0,
      wheelAngle1: targetWheelAngle1,
      wheelAngle2: 90.0 - targetWheelAngle1,
      wheel1Color: Theme.of(context).colorScheme.primary,
      wheel2Color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      navButtonOpacity: 1.0,
      navButtonColor: Theme.of(context).colorScheme.primary,
      marqueeOpacity: 1.0,
      marqueeWidthFraction: 1.0,
      marqueeVelocity: MARQUEE_VELOCITY,
      marqueeText: marqueeText,
      navButtonRowAlignment: Alignment.centerLeft,
      dotLogoAlignment: Alignment.centerLeft,
      targetSection: targetSection,
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
        marqueeVelocity: MARQUEE_VELOCITY,
        marqueeText: '',
        navButtonRowAlignment: Alignment.centerRight,
        dotLogoAlignment: Alignment.center,
        targetSection: null,
        // No target section in fullscreen home
        isCollapsedState: false,
      );

  // Example structure to hold calculated layout data
  static Map<AppSection?, double> calculateButtonCenterOffsets({
    required TextStyle textStyle,
    required double uniformButtonSlotWidth, // Max text width
  }) {
    final Map<AppSection?, double> offsets = {};
    double currentX = 0; // header's left padding is shared with wheel

    final List<AppSection?> allButtonSlots = [
      null,
      ...AppSection.values
    ]; // Home + other sections

    for (var section in allButtonSlots) {
      offsets[section] = currentX + (uniformButtonSlotWidth / 2.0);
      currentX += uniformButtonSlotWidth + NAV_BUTTON_SPACING;
    }
    return offsets;
  }

  static double getMaxButtonTextWidth(TextStyle textStyle) =>
      [HOME_BUTTON_TEXT, ...AppSection.values.map((s) => s.id)]
          .map((id) => getButtonContentWidth(id, textStyle))
          .reduce((v, e) => v > e ? v : e);
}

Widget createNavButtonForSection({
  required BuildContext context,
  required AppSection? section, // Null for Home
  required HeaderVisualParams currentParams,
  required VoidCallback? onTap,
  required double buttonSlotWidth,
  required bool isTargetForWheels,
}) =>
    GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: currentParams.navButtonOpacity,
        child: Visibility(
          visible: !isTargetForWheels,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Material(
            color: currentParams.backgroundColor,
            child: Container(
              width: buttonSlotWidth,
              padding: EdgeInsets.symmetric(
                  horizontal: NAV_BUTTON_HORIZONTAL_PADDING),
              alignment: Alignment.center,
              child: Text(
                section?.id ?? HOME_BUTTON_TEXT,
                style: TextStyle(
                    fontFamily: 'Pachakutech',
                    fontSize: NAV_BUTTON_FONT_SIZE,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

class AppHeaderLogic {
  static const double MAX_EFFECTIVE_WHEEL_ANGLE = 584.0;
  static const double LAST_HALF_TURN_START_ANGLE = 404.0;
  static const double DOT_LOGO_SCALE_END_ANGLE =
      LAST_HALF_TURN_START_ANGLE; // Explicitly for clarity
  static const double LAST_HALF_TURN_DURATION =
      MAX_EFFECTIVE_WHEEL_ANGLE - LAST_HALF_TURN_START_ANGLE;
  static const double TARGET_DOT_LOGO_TEXT_MATCH_SCALE = 0.2;
  static const double DOT_LOGO_ANIMATION_PHASE_SPLIT_POINT = 0.5;

  static String getWhitespaceForMarquee(double marqueeWidth) {
    final style =
        TextStyle(fontFamily: 'Pachakutech', fontSize: MARQUEE_FONT_SIZE);
    if (marqueeWidth <= 0) return "";
    // Estimate character width. This is a rough approximation.
    // For more accuracy, you might need a more sophisticated way to measure text
    // or use a fixed-width font for the whitespace if possible.
    final TextPainter charPainter = TextPainter(
      text: TextSpan(text: " ", style: style), // A single space
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    double avgCharWidth = charPainter.size.width;
    if (avgCharWidth <= 0)
      avgCharWidth = style.fontSize ?? 16.0 / 2; // Fallback

    int numSpaces = (marqueeWidth / avgCharWidth).ceil();
    return String.fromCharCodes(
        List.filled(numSpaces, 0x00A0)); // Non-breaking spaces
  }

  static HeaderVisualParams getDynamicHeaderVisualParams(
      {required BuildContext context,
      required double scrollOffset,
      AppSection? targetSectionForCollapsed,
      String? currentMarqueeText,
      required Map<AppSection?, double> buttonCenterOffsetsX}) {
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

    // The target collapsed state depends on whether we are aiming for "home" or a specific section.
    // This 'targetSectionForCollapsed' would typically be null on the home page during scroll,
    // and set during a Hero push to a detail page.
    final fsParams = AppHeaderMetrics.getFullscreenHeaderVisualParams(context);
    final colParams = AppHeaderMetrics.getCollapsedHeaderVisualParams(
      context,
      targetSection: targetSectionForCollapsed,
      marqueeText: (currentMarqueeText == null || currentMarqueeText.isEmpty)
          ? getWhitespaceForMarquee(MediaQuery.of(context).size.width)
          : getWhitespaceForMarquee(MediaQuery.of(context).size.width / 2) +
              currentMarqueeText,
      buttonCenterOffsetsX: buttonCenterOffsetsX,
    );

    var whitespaceForMarquee = getWhitespaceForMarquee(
      MediaQuery.of(context).size.width,
    );
    // Get baseline visual params for fullscreen and collapsed states
    // --- Wheel Values ---
    double currentWheelAngle1 = lerpDouble(fsParams.wheelAngle1,
        colParams.wheelAngle1, overallTransitionProgress)!;
    double currentWheelAngle2 = lerpDouble(fsParams.wheelAngle2,
        colParams.wheelAngle2, overallTransitionProgress)!;
    double currentWheelDiameter = lerpDouble(fsParams.wheelDiameter,
        colParams.wheelDiameter, overallTransitionProgress)!;
    Alignment currentWheelAlignment = Alignment.lerp(fsParams.wheelAlignment,
        colParams.wheelAlignment, overallTransitionProgress)!;

    // --- lastHalfTurnLerp (for colors, button fade, marquee fade) ---
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

    // --- Dot Logo Scale Calculation ---
    // Initial scale down progress as wheel approaches LAST_HALF_TURN_START_ANGLE
    double initialScaleProgress = 0.0;
    if (DOT_LOGO_SCALE_END_ANGLE > 0 &&
        currentWheelAngle1 <= DOT_LOGO_SCALE_END_ANGLE) {
      initialScaleProgress =
          (currentWheelAngle1 / DOT_LOGO_SCALE_END_ANGLE).clamp(0.0, 1.0);
    } else if (currentWheelAngle1 > DOT_LOGO_SCALE_END_ANGLE) {
      initialScaleProgress =
          1.0; // Fully progressed through initial scaling phase
    }

    double dotLogoScale = lerpDouble(
        fsParams.dotLogoScaleFactor, // Typically 1.0
        TARGET_DOT_LOGO_TEXT_MATCH_SCALE,
        // Scale towards this, or an intermediate value if you prefer
        Curves.easeIn.transform(overallTransitionProgress))!;

    Alignment bouncingDotLogoAlignment = Alignment.lerp(
      fsParams.dotLogoAlignment,
      Alignment(0.0, 0.0) - colParams.dotLogoAlignment,
      Curves.linear.transform(overallTransitionProgress.clamp(0.0, 0.7)) * 2,
      // BouncyOut().transform(overallTransitionProgress),
    )!;
    Alignment currentDotLogoAlignment = Alignment.lerp(
      fsParams.dotLogoAlignment,
      colParams.dotLogoAlignment,
      Curves.easeInQuad.transform(overallTransitionProgress) * 2,
    )!;
    // Alignment bouncingDotLogoAlignment = Alignment.lerp(
    //     fsParams.dotLogoAlignment,
    //     Alignment(0.0, 0.0) - colParams.dotLogoAlignment,
    //     Curves.easeOutQuad.transform(lastHalfTurnLerp > 0
    //         ? 1.0 - overallTransitionProgress
    //         : overallTransitionProgress))!;

    Color wheel1Color = Color.lerp(
        fsParams.wheel1Color, colParams.wheel1Color, lastHalfTurnLerp)!;
    Color wheel2Color = Color.lerp(
        fsParams.wheel2Color, colParams.wheel2Color, lastHalfTurnLerp)!;
    Color backgroundColor = Color.lerp(
        fsParams.backgroundColor, colParams.backgroundColor, lastHalfTurnLerp.clamp(0.15, 1.0))!;
    Alignment currentNavButtonRowAlignment = Alignment.lerp(
      fsParams.navButtonRowAlignment,
      colParams.navButtonRowAlignment,
      Curves.easeInQuint.transform(lastHalfTurnLerp),
    )!;
    double navButtonOpacity = lerpDouble(fsParams.navButtonOpacity,
        colParams.navButtonOpacity, lastHalfTurnLerp)!;
    Color navButtonColor = Color.lerp(
        fsParams.navButtonColor, colParams.navButtonColor, lastHalfTurnLerp)!;

    // Marquee translations
    double marqueeOpacity = lastHalfTurnLerp;
    double marqueeWidthFraction = lerpDouble(
        AppHeaderMetrics.getCollapsedLogoDiameter(context) /
            MediaQuery.of(context).size.width,
        colParams.marqueeWidthFraction,
        lastHalfTurnLerp)!;
    double marqueeVelocity = lerpDouble(
        fsParams.marqueeVelocity, colParams.marqueeVelocity, lastHalfTurnLerp)!;

    String currentMarqueeDisplayText =
        overallTransitionProgress < 0.95 && lastHalfTurnLerp < 0.95
            ? whitespaceForMarquee
            : colParams.marqueeText;

    return HeaderVisualParams(
      wheelDiameter: currentWheelDiameter,
      wheelAlignment: currentWheelAlignment,
      // This is now more precise
      dotLogoScaleFactor: dotLogoScale,
      wheelAngle1: currentWheelAngle1,
      wheelAngle2: currentWheelAngle2,
      wheel1Color: wheel1Color,
      wheel2Color: wheel2Color,
      backgroundColor: backgroundColor,
      navButtonOpacity: navButtonOpacity,
      navButtonColor: navButtonColor,
      marqueeOpacity: marqueeOpacity,
      marqueeWidthFraction: marqueeWidthFraction,
      marqueeVelocity: marqueeVelocity,
      marqueeText: currentMarqueeDisplayText,
      navButtonRowAlignment: currentNavButtonRowAlignment,
      dotLogoAlignment: currentDotLogoAlignment + bouncingDotLogoAlignment,
      targetSection:
          overallTransitionProgress == 1.0 ? targetSectionForCollapsed : null,
      isCollapsedState: overallTransitionProgress == 1.0,
    );
  }
}

class BouncyOut extends Curve {
  @override
  double transformInternal(double t) {
    if (t < 0.5) {
      // First half of the animation, apply easeIn
      // We need to remap t from [0, 0.5) to [0, 1) for Curves.easeIn
      return Curves.linear.transform(t * 2.0) *
          0.5; // Scale output back to [0, 0.5)
    } else {
      // Second half of the animation, apply elasticOut
      // Remap t from [0.5, 1.0] to [0, 1) for Curves.elasticOut
      // And scale output from [0,1] back to [0.5, 1.0]
      return 0.5 + (Curves.linear.transform((t - 0.5) * 2.0) * 0.5);
    }
  }
}
