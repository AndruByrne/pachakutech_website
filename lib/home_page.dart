import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vector_math/vector_math.dart' show radians;
import 'dart:ui' show lerpDouble;
import 'dart:developer' as developer;

enum PagePhase {
  fullscreenRotating,
  transitioningToHeader,
  contentScrolling,
  transitioningToFullscreen,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScrollController _rotationScrollController = ScrollController();
  final ScrollController _contentScrollController = ScrollController();

  PagePhase _currentPhase = PagePhase.fullscreenRotating;
  double _wheelAngle = 0.0;

  double _maxScrollForRotation = 0.0;
  double _maxScrollForTransition =0.0;

  double _fullscreenWheelDiameter = 0;
  double _headerWheelDiameter = 0;
  final Alignment _fullscreenWheelAlignment = Alignment.center;
  final Alignment _headerWheelAlignment = const Alignment(-0.85, 0.0);

  Size _getScreenSize() =>
      MediaQuery
          .of(context)
          .size;

  double get _targetHeaderHeight => _getScreenSize().height * 0.1;

  @override
  void initState() {
    super.initState();
    developer.log("initState: Adding scroll listeners",
        name: "MyHomePageState.Lifecycle");
    _rotationScrollController.addListener(_handleScroll);
    _contentScrollController.addListener(_handleScroll);
    developer.log(
        "initState: Listeners added", name: "MyHomePageState.Lifecycle");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = _getScreenSize();
    _maxScrollForRotation = screenSize.height * 0.5; // e.g., half screen height for full rotation
    _maxScrollForTransition = screenSize.height * 0.3; // e.g., 30% of screen height for transition

    developer.log(
      "didChangeDependencies: Screen: $screenSize, FullscreenDiameter: $_fullscreenWheelDiameter, HeaderDiameter: $_headerWheelDiameter, maxScrollForRotation: $_maxScrollForRotation, maxScrollForTransition: $_maxScrollForTransition", // Add them to log
      name: "MyHomePageState.Dimensions",
    );

    _fullscreenWheelDiameter = screenSize.height;
    _headerWheelDiameter = _targetHeaderHeight * 0.8;
    developer.log(
      "didChangeDependencies: Screen: $screenSize, FullscreenDiameter: $_fullscreenWheelDiameter, HeaderDiameter: $_headerWheelDiameter",
      name: "MyHomePageState.Dimensions",
    );
  }

  void _logState(String contextMsg, double rOffset, double cOffset,
      PagePhase oldP, PagePhase newP, double oldA, double newA) {
    developer.log(
        "$contextMsg | rOffset: ${rOffset.toStringAsFixed(
            2)}, cOffset: ${cOffset.toStringAsFixed(
            2)} | Phase: $oldP -> $newP | Angle: ${oldA.toStringAsFixed(
            2)} -> ${newA.toStringAsFixed(2)}",
        name: "MyHomePageState.ScrollLogic"
    );
  }

  void _handleScroll() {
    // This is the primary entry point for scroll detection.
    // If this isn't logged when you scroll, the controllers aren't firing.
    developer.log(
        "_handleScroll CALLED. R_Offset: ${_rotationScrollController.hasClients
            ? _rotationScrollController.offset.toStringAsFixed(2)
            : 'N/A'}, C_Offset: ${_contentScrollController.hasClients
            ? _contentScrollController.offset.toStringAsFixed(2)
            : 'N/A'}",
        name: "MyHomePageState.ScrollEvent"
    );

    final double rOffset = _rotationScrollController.hasClients
        ? _rotationScrollController.offset
        : 0.0;
    final double cOffset = _contentScrollController.hasClients
        ? _contentScrollController.offset
        : 0.0;

    PagePhase oldPhase = _currentPhase;
    double oldAngle = _wheelAngle;

    PagePhase newPhase = _currentPhase;
    double newWheelAngle = _wheelAngle;

    switch (_currentPhase) {
      case PagePhase.fullscreenRotating:
        newWheelAngle =
            (rOffset.clamp(0.0, _maxScrollForRotation) / _maxScrollForRotation) *
                360.0;
        developer.log(
            "PHASE CHECK (fullscreenRotating): " +
                "rOffset: ${rOffset.toStringAsFixed(2)}, " +
                "maxScrollForRotation: ${_maxScrollForRotation.toStringAsFixed(2)}, " +
                "Condition (rOffset >= maxScrollForRotation): ${rOffset >= _maxScrollForRotation}",
            name: "MyHomePageState.PhaseLogic"
        );
        if (rOffset >= _maxScrollForRotation) {
          newPhase = PagePhase.transitioningToHeader;
          newWheelAngle = 360.0;
          developer.log( // ---- ADD LOG CONFIRMING PHASE CHANGE INTENTION ----
              "Phase change triggered: TO transitioningToHeader",
              name: "MyHomePageState.PhaseLogic"
          );
        }
        break;
      case PagePhase.transitioningToHeader:
        final double transitionDelta = rOffset - _maxScrollForRotation;
        newWheelAngle = 360.0;
        if (transitionDelta >= _maxScrollForTransition) {
          newPhase = PagePhase.contentScrolling;
          if (_contentScrollController.hasClients &&
              _contentScrollController.offset != 0) {
            _contentScrollController.jumpTo(0);
          }
        } else if (transitionDelta < 0) {
          newPhase = PagePhase.fullscreenRotating;
          newWheelAngle = (rOffset.clamp(0.0, _maxScrollForRotation) /
              _maxScrollForRotation) * 360.0;
        }
        break;
      case PagePhase.contentScrolling:
        newWheelAngle = 360.0;
        if (cOffset <= 0 && (_contentScrollController.hasClients &&
            _contentScrollController.position.atEdge &&
            _contentScrollController.position.pixels == 0)) {
          newPhase = PagePhase.transitioningToFullscreen;
          if (_rotationScrollController.hasClients &&
              _rotationScrollController.offset !=
                  (_maxScrollForRotation + _maxScrollForTransition)) {
            _rotationScrollController.jumpTo(
                _maxScrollForRotation + _maxScrollForTransition);
          }
        }
        break;
      case PagePhase.transitioningToFullscreen:
        final double transitionDelta = rOffset - _maxScrollForRotation;
        newWheelAngle = 360.0;
        if (transitionDelta <= 0) {
          newPhase = PagePhase.fullscreenRotating;
          newWheelAngle = (rOffset.clamp(0.0, _maxScrollForRotation) /
              _maxScrollForRotation) * 360.0;
        } else if (transitionDelta > _maxScrollForTransition) {
          newPhase = PagePhase.contentScrolling;
          if (_contentScrollController.hasClients &&
              _contentScrollController.offset != 0) {
            _contentScrollController.jumpTo(0);
          }
        }
        break;
    }

    if (newPhase != _currentPhase || newWheelAngle != _wheelAngle) {
      _logState(
          "StateChange DETECTED",
          rOffset,
          cOffset,
          oldPhase,
          newPhase,
          oldAngle,
          newWheelAngle);
      setState(() {
        _currentPhase = newPhase;
        _wheelAngle = newWheelAngle;
        developer.log(
            "setState: Phase updated to $_currentPhase, Angle to ${_wheelAngle
                .toStringAsFixed(2)}",
            name: "MyHomePageState.SetState"
        );
      });
    } else
    if (rOffset != 0 || cOffset != 0) { // Log if scrolling but no state change
      _logState(
          "No StateChange (still scrolling)",
          rOffset,
          cOffset,
          oldPhase,
          newPhase,
          oldAngle,
          newWheelAngle);
    }
  }

  @override
  void dispose() {
    developer.log("dispose: Removing listeners and disposing controllers",
        name: "MyHomePageState.Lifecycle");
    _rotationScrollController.removeListener(_handleScroll);
    _contentScrollController.removeListener(_handleScroll);
    _rotationScrollController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = _getScreenSize();
    // This is the total distance we map to animation progress
    final double totalAnimationScrollDistance = _maxScrollForRotation + _maxScrollForTransition;

    // The content of the driver needs to be tall enough so that when it's scrolled
    // to its "end", the controller's offset can reach totalAnimationScrollDistance.
    // The viewport is screenSize.height.
    // If child height is H, max offset is H - screenSize.height.
    // We want max offset to be at least totalAnimationScrollDistance.
    // So, H - screenSize.height >= totalAnimationScrollDistance
    // Which means H >= screenSize.height + totalAnimationScrollDistance
    final double driverContentHeight = screenSize.height + totalAnimationScrollDistance;

    developer.log(
        "build() - ScrollDriver SizedBox height: $driverContentHeight (TotalAnimationScroll: $totalAnimationScrollDistance, ScreenHeight: ${screenSize.height})",
        name: "MyHomePageState.BuildLayout");

    developer.log(
        "build(): Phase: $_currentPhase, Angle: ${_wheelAngle.toStringAsFixed(
            2)}, R_Offset: ${_rotationScrollController.hasClients
            ? _rotationScrollController.offset.toStringAsFixed(2)
            : 'N/A'}",
        name: "MyHomePageState.Build"
    );
    developer.log(
        "build() check: R_Controller.hasClients: ${_rotationScrollController
            .hasClients}, C_Controller.hasClients: ${_contentScrollController
            .hasClients}",
        name: "MyHomePageState.ControllerClients"
    );

    double currentWheelDiameter;
    Alignment currentWheelAlignment;
    double currentWheelRotationAngle = _wheelAngle;
    double transitionProgress = 0.0;

    switch (_currentPhase) {
      case PagePhase.fullscreenRotating:
        currentWheelDiameter = _fullscreenWheelDiameter;
        currentWheelAlignment = _fullscreenWheelAlignment;
        transitionProgress = 0.0;
        break;
      case PagePhase.transitioningToHeader:
        final scrollDeltaInTransition = (_rotationScrollController.hasClients
            ? _rotationScrollController.offset
            : _maxScrollForRotation) - _maxScrollForRotation;
        transitionProgress =
            (scrollDeltaInTransition / _maxScrollForTransition).clamp(0.0, 1.0);
        currentWheelDiameter = lerpDouble(
            _fullscreenWheelDiameter, _headerWheelDiameter,
            transitionProgress)!;
        currentWheelAlignment = Alignment.lerp(
            _fullscreenWheelAlignment, _headerWheelAlignment,
            transitionProgress)!;
        currentWheelRotationAngle = 360.0;
        break;
      case PagePhase.contentScrolling:
        currentWheelDiameter = _headerWheelDiameter;
        currentWheelAlignment = _headerWheelAlignment;
        currentWheelRotationAngle = 360.0;
        transitionProgress = 1.0;
        break;
      case PagePhase.transitioningToFullscreen:
        final double scrollOffsetInUpTransition = (_rotationScrollController
            .hasClients
            ? _rotationScrollController.offset
            : (_maxScrollForRotation + _maxScrollForTransition)) -
            _maxScrollForRotation;
        transitionProgress =
            (scrollOffsetInUpTransition / _maxScrollForTransition).clamp(
                0.0, 1.0);
        // Corrected lerp for diameter and alignment when transitioning to Fullscreen
        // Progress goes 0 (header) to 1 (full) as scrollOffsetInUpTransition goes from maxScrollForTransition to 0
        // So, we need to invert the progress for the lerp if we consider progress from 0 (header) to 1 (full)
        // Or, more simply, transitionProgress already represents 0 (full) to 1 (header) as defined by scroll offset.
        // So, we want to lerp from Full to Header based on this progress.
        currentWheelDiameter = lerpDouble(
            _fullscreenWheelDiameter, _headerWheelDiameter,
            transitionProgress)!;
        currentWheelAlignment = Alignment.lerp(
            _fullscreenWheelAlignment, _headerWheelAlignment,
            transitionProgress)!;
        currentWheelRotationAngle = 360.0;
        break;
    }
    developer.log(
        "build() - Calculated Props: Diameter: ${currentWheelDiameter
            .toStringAsFixed(
            2)}, Align: $currentWheelAlignment, Angle: ${currentWheelRotationAngle
            .toStringAsFixed(2)}, Progress: ${transitionProgress
            .toStringAsFixed(2)}",
        name: "MyHomePageState.BuildProps"
    );

    Widget dynamicRotatingWheels = Align(
      alignment: currentWheelAlignment,
      child: SizedBox(
        width: currentWheelDiameter,
        height: currentWheelDiameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: radians(currentWheelRotationAngle),
              child: SizedBox(
                width: currentWheelDiameter * 0.9,
                height: currentWheelDiameter * 0.9,
                child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                    colorFilter: ColorFilter.mode(Theme
                        .of(context)
                        .colorScheme
                        .secondary, BlendMode.srcIn)),
              ),
            ),
            Transform.rotate(
              angle: radians(90.0 - currentWheelRotationAngle),
              child: SizedBox(
                width: currentWheelDiameter * 0.5,
                height: currentWheelDiameter * 0.5,
                child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                    colorFilter: ColorFilter.mode(Theme
                        .of(context)
                        .colorScheme
                        .secondary, BlendMode.srcIn)),
              ),
            ),
            SizedBox(
              width: currentWheelDiameter * 0.3,
              height: currentWheelDiameter * 0.3,
              child: Image.asset('assets/pachakutech_dot_logo_alpha.png'),
            ),
          ],
        ),
      ),
    );

    Widget mainContentSection = SingleChildScrollView(
      controller: _contentScrollController,
      // physics: (_currentPhase == PagePhase.contentScrolling ||
      //     _currentPhase == PagePhase.transitioningToFullscreen)
      //     ? const BouncingScrollPhysics() // Allow content to scroll
      //     : const NeverScrollableScrollPhysics(),
      // // Prevent content scroll in other phases
      physics: (_currentPhase == PagePhase.contentScrolling)
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(height: screenSize.height * 0.8,
              color: Colors.blueGrey.shade100,
              child: Center(child: Text("Content Section 1", style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium))),
          Container(height: screenSize.height * 0.8,
              color: Colors.blueGrey.shade200,
              child: Center(child: Text("Content Section 2", style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium))),
          Container(height: screenSize.height * 0.8,
              color: Colors.blueGrey.shade300,
              child: Center(child: Text("Content Section 3", style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium))),
        ],
      ),
    );

    // This is the SCROLL DRIVER for rotation and transition phases.
    // It should capture scrolls when content is not scrolling.
    Widget rotationAndTransitionScrollDriver = SingleChildScrollView(
      controller: _rotationScrollController,
      // CRITICAL: This physics determines when this ScrollView can be scrolled.
      // It should be scrollable if:
      // 1. Not in contentScrolling phase OR
      // 2. In contentScrolling phase BUT the content scroll is at the very top (to allow transitioning back up)
      //    OR in transitioningToFullscreen phase (which is driven by this controller)
      // TEMPORARY CHANGE:
      physics: (_currentPhase == PagePhase.contentScrolling &&
          _contentScrollController.hasClients &&
          _contentScrollController.position.pixels > 0)
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(), // Or AlwaysScrollableScrollPhysics if Bouncing gives issues at edges
      child: SizedBox(
        // This height needs to be sufficient for maxScrollForRotation + maxScrollForTransition
        height: driverContentHeight, // +100 for some overscroll buffer
        // You can add a visible child for debugging its hit area:
        child: Container(
          color: Colors.yellow.withOpacity(0.3), // So you can see it
          alignment: Alignment.topCenter, // So text is visible if height is large
          child: const Center(child: Text("Scroll Driver Area")),
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Content Section
          Positioned.fill(
            top: (_currentPhase == PagePhase.fullscreenRotating &&
                transitionProgress == 0.0)
                ? screenSize
                .height // Fully off-screen initially or when fully fullscreen
                : lerpDouble(
                screenSize.height, // Starts off-screen
                _targetHeaderHeight, // Moves up to header position
                // Progress: 0 (wheels full, content off-screen) to 1 (wheels header, content visible)
                _currentPhase == PagePhase.transitioningToFullscreen
                    ? (1.0 -
                    transitionProgress) // As wheels grow (prog 1->0), content moves down (top 1->0)
                    : transitionProgress // As wheels shrink (prog 0->1), content moves up (top 0->1)
            )!.clamp(_targetHeaderHeight, screenSize.height),
            child: mainContentSection,
          ),

          // Dynamic Rotating Wheels / Header
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            // For smooth container resize
            top: 0,
            left: 0,
            right: 0,
            height: (_currentPhase == PagePhase.contentScrolling ||
                (_currentPhase == PagePhase.transitioningToHeader &&
                    transitionProgress >= 1.0) ||
                (_currentPhase == PagePhase.transitioningToFullscreen &&
                    transitionProgress >=
                        1.0) // Still considered "header height" during this part of transition
            )
                ? _targetHeaderHeight
                : screenSize.height,
            child: Container(
              // Background for the wheels/header area
              color: (_currentPhase == PagePhase.contentScrolling ||
                  (_currentPhase == PagePhase.transitioningToHeader &&
                      transitionProgress >= 1.0))
                  ? Theme
                  .of(context)
                  .colorScheme
                  .surface
                  .withOpacity(0.9) // Header bg
                  : (_currentPhase == PagePhase.fullscreenRotating &&
                  transitionProgress == 0.0)
                  ? Theme
                  .of(context)
                  .colorScheme
                  .surface // Fullscreen bg
                  : Colors.transparent, // Transparent during transitions
              child: dynamicRotatingWheels,
            ),
          ),

          // Scroll Driver for Rotation and Transition - Occupies full screen to capture events
          Positioned.fill(
            child: rotationAndTransitionScrollDriver,
          ),
        ],
      ),
    );
  }
}