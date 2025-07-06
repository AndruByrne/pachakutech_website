import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'home_content.dart';
import 'education_content.dart';
import 'evaluation_content.dart';
import 'elevation_content.dart';
import 'package:vector_math/vector_math.dart' show radians;
import 'dart:ui' show lerpDouble;
import 'dart:developer' as developer;

class _AnimatedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _AnimatedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // shrinkOffset: How much the header has scrolled up/shrunk.
    // 0 when fully expanded (maxHeight), increases up to (maxHeight - minHeight).
    // The 'child' widget is already built by _MyHomePageState with all necessary
    // transformations (rotation, size, alignment) based on the global scroll offset.
    // This delegate's primary job is to provide the correctly sized container for it.
    // The SliverPersistentHeader mechanism handles the actual shrinking and positioning.
    return child;
  }

  @override
  bool shouldRebuild(covariant _AnimatedHeaderDelegate oldDelegate) {
    // Rebuild if minHeight, maxHeight, or the child itself changes.
    // it rebuilds headerContentHolder with new visual properties.
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }

}

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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final ScrollController _mainScrollController = ScrollController();
  bool _isScrollingBack = false;
  BaseSectionData?
      _activeDetailData; // This holds the currently selected detail, or null for main list

  double _wheelAngle = 0.0;

  // Define scroll offset points where behavior changes *within the CustomScrollView's content*
  // These are not pixel heights of the header itself initially, but scroll distances.
  double _rotationEndScrollOffset = 0.0;
  double _transitionEndScrollOffset =
      0.0; // Point where header is fully collapsed and content is primary

  // Visual properties of the wheels/header, derived from scroll offset
  double _currentWheelDiameter = 0;
  Alignment _currentWheelAlignment = Alignment.center;
  double _currentHeaderVisualHeight =
      0; // The visual height of the header content area
  // (from fullscreen down to targetHeaderHeight)

  // Target heights
  double _fullscreenHeight = 0;
  double _targetHeaderHeightConstant = 0; // The final small header height

  // Diameters for interpolation
  double _fullscreenWheelDiameter = 0;
  double _headerWheelDiameter = 0;
  double _dotLogoFixedDiameter = 0;

  // Alignments for interpolation
  final Alignment _fullscreenWheelAlignment = Alignment.center;
  final Alignment _headerWheelAlignment =
      const Alignment(-0.85, 0.0);

  Size _getScreenSize() => MediaQuery.of(context).size;

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_handleScroll);
    developer.log("initState: Main scroll listener added",
        name: "MyHomePageState.Lifecycle");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = _getScreenSize();
    _fullscreenHeight = screenSize.height;
    _targetHeaderHeightConstant =
        screenSize.height * 0.18; // Example: 10% of screen height

    _rotationEndScrollOffset =
        _fullscreenHeight * 0.5; // Rotate over first 50% of header collapse
    _transitionEndScrollOffset = _fullscreenHeight -
        _targetHeaderHeightConstant; // Full collapse distance

    _fullscreenWheelDiameter = _fullscreenHeight * 0.9;
    _headerWheelDiameter = _targetHeaderHeightConstant * 0.8;
    // _dotLogoFixedDiameter = _fullscreenWheelDiameter * 0.5 ;
    _dotLogoFixedDiameter = _fullscreenWheelDiameter * 0.5;

    // Initialize visual properties based on no scroll
    _updateHeaderFromScroll(0.0); // Initial state before any scroll
  }

  void _handleScroll() {
    // The offset here is the overall scroll position of the CustomScrollView
    // However, for the header's animation, what matters is the `shrinkOffset`
    // of the SliverPersistentHeader.
    // The SliverPersistentHeader's shrinkOffset goes from 0 to (maxExtent - minExtent).
    // We use the controller's offset directly if it's within the header's shrink range.
    double currentGlobalScrollOffset =
        _mainScrollController.hasClients ? _mainScrollController.offset : 0.0;

    // We only care about the scroll offset relevant to the header's transformation range.
    // The header's max extent is _fullscreenHeight, min extent is _targetHeaderHeightConstant.
    // The maximum shrinkOffset is _fullscreenHeight - _targetHeaderHeightConstant.
    double headerRelevantScroll = currentGlobalScrollOffset.clamp(
        0.0, _fullscreenHeight - _targetHeaderHeightConstant);

    _updateHeaderFromScroll(headerRelevantScroll);
  }

  void _handleSummaryCardTap(SummarySectionData summaryData) {
    setState(() {
      developer.log("Card tapped: ${summaryData.title}",
          name: "MyHomePageState.Navigation");
      _activeDetailData = DetailSectionData(
        title: "Detail: ${summaryData.title}",
        originalSummary: summaryData,
        contentBuilder: (context) {
          if (summaryData.id == "edu") {
            return EducationDetailPage(summaryData: summaryData);
          } else if (summaryData.id == "eval") {
            return EvaluationDetailPage(summaryData: summaryData);
          } else if (summaryData.id == "elev") {
            return ElevationDetailPage(summaryData: summaryData);
          } else {
            return Center(
                child: Text("Details for ${summaryData.title}",
                    style: TextStyle(fontSize: 24)));
          }
        },
      );
      // Jump to the header's collapse point
      if (_mainScrollController.hasClients) {
        double targetScrollOffset =
            _fullscreenHeight - _targetHeaderHeightConstant;
        _mainScrollController.jumpTo(targetScrollOffset.clamp(
            0.0, _mainScrollController.position.maxScrollExtent));
        _updateHeaderFromScroll(targetScrollOffset);
      }
      developer.log(
          "Switched to detail view for ${summaryData.title}. Scroll offset: ${_mainScrollController.hasClients ? _mainScrollController.offset : 'N/A'}",
          name: "MyHomePageState.Navigation");
    });
  }

  Future<void> _goBackToMainList() async {
    if (_isScrollingBack || !_mainScrollController.hasClients) return;

    if (mounted) {
      setState(() {
        _isScrollingBack =
            true; // prevent re-entry into this method
      });
    }

    developer.log(
        "Starting animated scroll back to main list. Current scroll: ${_mainScrollController.hasClients ? _mainScrollController.offset : 'N/A'}",
        name: "MyHomePageState.Navigation");

    await _mainScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );

    // After animation completes and header is visually at the top:
    if (mounted) {
      setState(() {
        _activeDetailData = null; // NOW swap the content
        _isScrollingBack = false; // Reset the flag
      });
      // One final explicit call to ensure the header is perfectly synchronized
      // with the 0.0 scroll offset, especially if the last scroll event didn't coincide
      // perfectly or if no further scroll events fire after animation completion at 0.0.
      _updateHeaderFromScroll(0.0);
    }
  }

  void _updateHeaderFromScroll(double headerScrollAmount) {
    // headerScrollAmount is effectively the `shrinkOffset` for the header behavior.
    // It goes from 0 (fully expanded header) to `_transitionEndScrollOffset` (fully collapsed header).

    double newWheelAngle;
    double rotationProgressRatio = (_rotationEndScrollOffset == 0)
        ? 1.0
        : (headerScrollAmount / _rotationEndScrollOffset);
    newWheelAngle = rotationProgressRatio * 360.0;

    // Transition Progress (for header content: wheel size, alignment, and header visual bg)
    // This progress is for how much the header *content* has transitioned.
    // It should go from 0 (fullscreen appearance) to 1 (shrunken header appearance).
    // The transition happens over the entire collapse of the header,
    // from headerScrollAmount = 0 to headerScrollAmount = _transitionEndScrollOffset.
    double transitionProgress = 0.0;
    if (_transitionEndScrollOffset > 0) {
      transitionProgress =
          (headerScrollAmount / _transitionEndScrollOffset).clamp(0.0, 1.0);
    } else if (headerScrollAmount >= _transitionEndScrollOffset) {
      // Should only happen if _transitionEndScrollOffset is 0
      transitionProgress = 1.0;
    }

    // Wheel Diameter and Alignment based on transitionProgress
    double newWheelDiameter = lerpDouble(
        _fullscreenWheelDiameter, _headerWheelDiameter, transitionProgress)!;
    Alignment newWheelAlignment = Alignment.lerp(
        _fullscreenWheelAlignment, _headerWheelAlignment, transitionProgress)!;

    // Header Visual Height (for background, etc., if different from Sliver's extent)
    // This is how tall the *content area* of the header appears to be.
    // The SliverPersistentHeader itself will manage its actual extent from _fullscreenHeight down to _targetHeaderHeightConstant.
    // This `_currentHeaderVisualHeight` is for the container *inside* the sliver, if needed.
    double newHeaderVisualHeight = lerpDouble(
        _fullscreenHeight, _targetHeaderHeightConstant, transitionProgress)!;

    bool needsSetState = false;
    if (newWheelAngle != _wheelAngle) {
      _wheelAngle = newWheelAngle;
      needsSetState = true;
    }
    if (newWheelDiameter != _currentWheelDiameter) {
      _currentWheelDiameter = newWheelDiameter;
      needsSetState = true;
    }
    if (newWheelAlignment != _currentWheelAlignment) {
      _currentWheelAlignment = newWheelAlignment;
      needsSetState = true;
    }
    if (newHeaderVisualHeight != _currentHeaderVisualHeight) {
      _currentHeaderVisualHeight = newHeaderVisualHeight;
      needsSetState = true;
    }

    if (needsSetState) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mainScrollController.removeListener(_handleScroll);
    _mainScrollController.dispose();
    super.dispose();
    developer.log(
        "dispose: Main scroll listener removed and controller disposed",
        name: "MyHomePageState.Lifecycle");
  }

  @override
  Widget build(BuildContext context) {
    var lastHalfTurnLerp = _wheelAngle > 584
        ? 1.0
        : _wheelAngle < 404
            ? 0.0
            : (_wheelAngle - 404) / 180;

    // MODIFIED: Wrap dotLogo with GestureDetector
    Widget dotLogo = GestureDetector(
      // Wrap with GestureDetector
      onTap: () {
        if (_activeDetailData != null) {
          _goBackToMainList();
        } else {
          developer.log("Dot logo tapped on main list view.",
              name: "MyHomePageState.Interaction");
        }
      },
      child: SizedBox(
        width: _dotLogoFixedDiameter * (1 + lastHalfTurnLerp / 2),
        height: _dotLogoFixedDiameter * (1 + lastHalfTurnLerp / 2),
        child: Image.asset('assets/pachakutech_dot_logo_alpha.png'),
      ),
    );

    Widget rawDynamicRotatingWheels = Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: radians(_wheelAngle > 584 ? 584 : _wheelAngle),
          child: SizedBox(
            width: _currentWheelDiameter * 1.0,
            height: _currentWheelDiameter * 1.0,
            child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                colorFilter: ColorFilter.mode(
                    Color.lerp(
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.primary,
                            lastHalfTurnLerp) ??
                        Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn)),
          ),
        ),
        Transform.rotate(
          angle: radians(90.0 - (_wheelAngle > 584 ? 584 : _wheelAngle)),
          child: SizedBox(
            width: _currentWheelDiameter * 0.6,
            height: _currentWheelDiameter * 0.6,
            child: SvgPicture.asset('assets/pachakutech_wheel.svg',
                colorFilter: ColorFilter.mode(
                    _wheelAngle < 404
                        ? Theme.of(context).colorScheme.secondary
                        : Color.lerp(
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.primary,
                                lastHalfTurnLerp) ??
                            Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn)),
          ),
        ),
      ],
    );

    Widget interactiveRotatingWheels = Align(
      alignment: _currentWheelAlignment,
      child: SizedBox(
        width: _currentWheelDiameter,
        height: _currentWheelDiameter,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (_activeDetailData != null) {
                _goBackToMainList();
              } else {
                developer.log("Rotating wheels tapped on main list view.",
                    name: "MyHomePageState.Interaction");
              }
            },
            customBorder: CircleBorder(),
            splashColor: Theme.of(context).splashColor.withValues( alpha: 0.3),
            highlightColor: Theme.of(context).highlightColor.withValues(alpha: 0.2),
            child: rawDynamicRotatingWheels,
          ),
        ),
      ),
    );

    Widget headerVisuals = Container(
      color: (_wheelAngle >= 584)
          ? Theme.of(context).colorScheme.secondary
          : _wheelAngle < 404
              ? Theme.of(context).colorScheme.surface
              : Color.lerp(Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.secondary, lastHalfTurnLerp),
      child: Stack(
        alignment: Alignment.center,
        children: [
          interactiveRotatingWheels,
          dotLogo,
        ],
      ),
    );

    SliverPersistentHeader headerSliver = SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _AnimatedHeaderDelegate(
        minHeight: _targetHeaderHeightConstant,
        maxHeight: _fullscreenHeight,
        child: headerVisuals,
      ),
    );

    Widget contentSliver;
    if (_activeDetailData != null && _activeDetailData is DetailSectionData) {
      DetailSectionData detailData = _activeDetailData as DetailSectionData;
      contentSliver = SliverToBoxAdapter(
        child: detailData.contentBuilder(context),
      );
    } else {
      contentSliver = SliverList(
        delegate: mainContentBuilder(
          _getScreenSize().height * 0.7,
          _handleSummaryCardTap,
        ),
      );
    }

    return PopScope(
      canPop: _activeDetailData == null,
      // Allow pop if on main list, otherwise intercept
      onPopInvokedWithResult: (bool didPop, void result) async {
        if (didPop) {
          return;
        }
        if (_activeDetailData != null) {
          await _goBackToMainList();
        }
      },
      child: Scaffold(
          body: Scaffold(
        body: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            headerSliver,
            contentSliver,
          ],
        ),
      )),
    );
  }
}
