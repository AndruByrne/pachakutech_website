import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/content_repo.dart';
import 'package:pachakutech_website/header_util.dart';
import 'home_content.dart';
import 'dart:developer' as developer;
import 'package:go_router/go_router.dart';
import 'hero_util.dart';
import 'author_controls.dart';
import 'package:flutter/foundation.dart' show kIsWeb, mapEquals;

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

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key});

  final db = FirebaseFirestore.instance;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final ScrollController _mainScrollController = ScrollController();
  late ValueNotifier<double> _mainScrollControllerNotifier;
  final Map<AppSection, GlobalKey> _sectionItemKeys = {
    for (var section in AppSection.values) section: GlobalKey()
  };
  bool _showAuthorUI = false;

  // nav flags
  AppSection? _pendingNavigationToSection;
  Object? _lastProcessedNavigationExtra;

  // nav button measurements
  Map<AppSection?, double> _buttonCenterOffsetsX = {};
  double _uniformButtonSlotWidth = 0;
  late Future<String> _tickerFuture;
  final TextStyle _navButtonTextStyle = const TextStyle(
      fontFamily: 'Pachakutech', fontSize: NAV_BUTTON_FONT_SIZE + 2);
  String _whitespaceForMarquee = '';

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_handleScroll);
    _mainScrollControllerNotifier = ValueNotifier<double>(0.0);

    _uniformButtonSlotWidth =
        AppHeaderMetrics.getMaxButtonTextWidth(_navButtonTextStyle);
    _buttonCenterOffsetsX = AppHeaderMetrics.calculateButtonCenterOffsets(
      textStyle: _navButtonTextStyle,
      uniformButtonSlotWidth: _uniformButtonSlotWidth,
    );

    _tickerFuture = ContentRepository(db: widget.db)
        .fetchHeaderTickers()
        .then((tickers) => tickers['home']);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _whitespaceForMarquee = AppHeaderLogic.getWhitespaceForMarquee(
        MediaQuery.of(context).size.width * 0.8);
    // Initialize visual properties based on scroll position (or 0 if not available yet)
    double initialScrollOffset = 0.0;
    if (_mainScrollController.hasClients &&
        _mainScrollController.position.haveDimensions) {
      initialScrollOffset = _mainScrollController.offset;
    }
    _mainScrollControllerNotifier.value = initialScrollOffset;
    _handleScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the widget is still mounted before proceeding,
      // as the callback fires after the frame.
      if (mounted) {
        _processNavigationExtras();
      }
    });
  }

  void _handleScroll() {
    if (!_mainScrollController.hasClients ||
        !_mainScrollController.position.haveDimensions) {
      return;
    }
    double currentGlobalScrollOffset = _mainScrollController.offset;
    _mainScrollControllerNotifier.value = currentGlobalScrollOffset;
    if (mounted) {
      setState(() {});
    }
  }

  void _handleWheelTap() => kIsWeb
      ? _handleHomeButtonTap()
      : setState(() {
          // replace main content with author UI
          _showAuthorUI = !_showAuthorUI;
        });

  void _handleSectionButtonTap(AppSection section) async {
    await scrollTo(section);

    final double currentScrollOffset = _mainScrollController.hasClients &&
            _mainScrollController.position.haveDimensions
        ? _mainScrollController.offset
        : 0.0;

    developer.log(
        "Section button tapped: ${section.title}. Passing scrollOffset: $currentScrollOffset",
        name: "MyHomePageState.Navigation");

    String path = '/${section.id}';
    context.push(path, extra: {
      'scrollOffset': currentScrollOffset, // TODO: this needs to be updated (or the shuttle params do)
      'targetSection': section,
      // Pass the target section for Hero animation hints
    });
  }

  void _handleHomeButtonTap() {
    if (_mainScrollController.offset > 0) {
      _mainScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    } else {
      developer.log("Home button tapped at top.",
          name: "MyHomePageState.Interaction");
      _onForwardTap();
    }
  }

  void _processNavigationExtras() {
    final GoRouterState state = GoRouterState.of(context);
    final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
    final AppSection? targetSectionFromExtra =
        extra?['navigateToAfterScroll'] as AppSection?;

    // Guard 1: Not already actively processing something different
    if (_pendingNavigationToSection != null &&
        _pendingNavigationToSection != targetSectionFromExtra) {
      developer.log(
          "ProcessNavigationExtras: Skipped, another navigation is already pending for ${_pendingNavigationToSection!.id}",
          name: "MyHomePage.Navigation");
      return;
    }

    // Guard 2: Have we already processed this exact 'navigateToAfterScroll' value from the extras?
    if (targetSectionFromExtra != null &&
        extra == _lastProcessedNavigationExtra) {
      developer.log(
          "ProcessNavigationExtras: Skipped, already processed this exact extra for ${targetSectionFromExtra.id}",
          name: "MyHomePage.Navigation");
      return;
    }

    if (targetSectionFromExtra != null) {
      developer.log(
          "ProcessNavigationExtras: New instruction for ${targetSectionFromExtra.id}. Setting as pending.",
          name: "MyHomePage.Navigation");
      if (mounted) {
        setState(() {
          _pendingNavigationToSection = targetSectionFromExtra;
          // Mark this specific 'extra' object as being initiated for processing.
          // We'll clear _lastProcessedNavigationExtra only when we truly leave MyHomePage
          // or a new, different 'extra' comes in that should override.
          _lastProcessedNavigationExtra = extra;
        });
      } else {
        return;
      }
      _initiateScrollAndNavigate();
    } else {
      // No 'navigateToAfterScroll' in extras, or it's different from what we last processed.
      // This means any previous "processed" state for an old extra is no longer relevant.
      if (_lastProcessedNavigationExtra != null &&
          extra?['navigateToAfterScroll'] == null) {
        developer.log(
            "ProcessNavigationExtras: Clearing _lastProcessedNavigationExtra as 'navigateToAfterScroll' is no longer present.",
            name: "MyHomePage.Navigation");
        if (mounted) {
          setState(() {
            _lastProcessedNavigationExtra = null;
          });
        }
      }
      if (_pendingNavigationToSection == null) {
        developer.log(
            "ProcessNavigationExtras: No 'navigateToAfterScroll' instruction.",
            name: "MyHomePage.Navigation");
      }
    }
  }

  Future<void> _initiateScrollAndNavigate() async {
    if (_pendingNavigationToSection == null || !mounted) {
      return;
    }
    final AppSection sectionToNavigate = _pendingNavigationToSection!;
    await scrollTo(sectionToNavigate);
    // ENSURE THE WIDGET IS STILL MOUNTED BEFORE ANY context.push
    if (!mounted) {
      developer.log(
          "InitiateScroll: Widget unmounted after scroll for ${_pendingNavigationToSection!.id}. Aborting navigation.",
          name: "MyHomePage.Navigation");
      // If unmounted, the pending state should ideally be cleared by dispose,
      // but good to clear here if we abort before push.
      // However, calling setState in an unmounted widget is an error.
      // The fact it's unmounted means we shouldn't try to clear _pendingNavigationToSection with setState.
      // It will be null when a new instance of MyHomePage is created.
      return;
    }

    final double currentScrollOffset = _mainScrollController.hasClients &&
            _mainScrollController.position.haveDimensions
        ? _mainScrollController.offset
        : 0.0; // Fallback

    if (sectionToNavigate != null) {
      developer.log(
          "Scroll/ensureVisible complete. Navigating to detail for ${sectionToNavigate.id} at offset $currentScrollOffset",
          name: "MyHomePage.Navigation");
      String path = '/${sectionToNavigate.id}';
      if (mounted) {
        setState(() {
          _pendingNavigationToSection = null; // setting singleton to null
        });
      }
      context.push(path, extra: {
        'scrollOffset': currentScrollOffset,
        'targetSection': sectionToNavigate,
      });
      developer.log(
          "InitiateScroll: Pushed to $path for ${sectionToNavigate.id}. _pendingNavigationToSection is now null.",
          name: "MyHomePage.Navigation");
    }
  }

  Future<void> scrollTo(AppSection sectionToNavigate,
      {double alignment = 0.25}) async {
    developer.log(
        "ScrollTo: Instructed to scroll to ${sectionToNavigate.id} with alignment $alignment",
        name: "MyHomePage.Navigation");

    final GlobalKey? sectionKey = _sectionItemKeys[sectionToNavigate];

    if (!_mainScrollController.hasClients) {
      developer.log(
          "ScrollTo: Scroll controller has no clients. Cannot scroll.",
          name: "MyHomePage.Navigation.Error");
      return;
    }

    // Phase 1: Check if already visible or context available
    if (sectionKey?.currentContext != null) {
      developer.log(
          "ScrollTo: Key context already available for ${sectionToNavigate.id}. Using ensureVisible directly.",
          name: "MyHomePage.Navigation");
      await Scrollable.ensureVisible(
        sectionKey!.currentContext!,
        duration: const Duration(milliseconds: 900), // Your desired duration
        curve: Curves.easeInOutCubic,
        alignment: alignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      developer.log(
          "ScrollTo: EnsureVisible complete for ${sectionToNavigate.id} (direct).",
          name: "MyHomePage.Navigation");
      return; // Done
    }

    // Phase 2: Context not available, item is likely off-screen. Attempt jump then ensure.
    developer.log(
        "ScrollTo: Key context NULL for ${sectionToNavigate.id}. Item likely off-screen. Attempting jump.",
        name: "MyHomePage.Navigation");

    final double averageItemHeight = getSectionHeaderHeight(context);
    int itemIndex = AppSection.values.toList().indexOf(sectionToNavigate);
    if (itemIndex == -1) {
      developer.log(
          "ScrollTo: Could not find index for ${sectionToNavigate.id}",
          name: "MyHomePage.Navigation.Error");
      return;
    }
    double estimatedScrollOffset =
        AppHeaderMetrics.getFullscreenHeaderHeight(context) +
            itemIndex * averageItemHeight;

    // Constrain jump to scroll extents
    estimatedScrollOffset = estimatedScrollOffset.clamp(
        _mainScrollController.position.minScrollExtent,
        _mainScrollController.position.maxScrollExtent);

    developer.log(
        "ScrollTo: Jumping to estimated offset $estimatedScrollOffset for ${sectionToNavigate.id}.",
        name: "MyHomePage.Navigation");

    // Using animateTo for a smoother initial movement than jumpTo.
    // If this animation is too slow and interferes with the perceived responsiveness,
    // you might use jumpTo() and accept a more jarring initial movement.
    await _mainScrollController.animateTo(
      estimatedScrollOffset,
      duration: const Duration(milliseconds: 1200),
      // Faster animation for the initial jump
      curve: Curves.easeInQuad,
    );
    // await Future.delayed(
    //     const Duration(milliseconds: 100)); // Allow time for items to build

    // Phase 3: Try Scrollable.ensureVisible again, hoping the item is now built
    if (mounted && sectionKey?.currentContext != null) {
      developer.log(
          "ScrollTo: Key context now available for ${sectionToNavigate.id} after jump. Using ensureVisible for precise alignment.",
          name: "MyHomePage.Navigation");
      await Scrollable.ensureVisible(
        sectionKey!.currentContext!,
        duration: const Duration(milliseconds: 400),
        // Slightly shorter than initial target if combined
        curve: Curves.easeOutQuad,
        alignment: alignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      // await Future.delayed(const Duration(milliseconds: 50)); // Settle delay
      developer.log(
          "ScrollTo: EnsureVisible complete for ${sectionToNavigate.id} (after jump).",
          name: "MyHomePage.Navigation");
    } else {
      developer.log(
          "ScrollTo: Key context STILL NULL for ${sectionToNavigate.id} after jump and delay. Scroll may be imprecise.",
          name: "MyHomePage.Navigation.Warning");
      // If it's still null, the estimation was too far off, or item heights vary wildly.
      // The user might see a jump and then the push without the fine-tuned scroll.
    }
  }

  HeaderVisualParams get currentHeaderVisualParams =>
      AppHeaderLogic.getDynamicHeaderVisualParams(
        context: context,
        scrollOffset: _mainScrollController.hasClients &&
                _mainScrollController.position.haveDimensions
            ? _mainScrollController.offset
            : 0.0,
        targetSectionForCollapsed: null,
        currentMarqueeText: _whitespaceForMarquee,
        buttonCenterOffsetsX: _buttonCenterOffsetsX,
      );

  @override
  void dispose() {
    _mainScrollController.removeListener(_handleScroll);
    _mainScrollControllerNotifier.dispose();
    _mainScrollController.dispose();
    _pendingNavigationToSection = null;
    _lastProcessedNavigationExtra = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
        future: _tickerFuture,
        builder: (ctx, tickerSnapshot) {
          final HeaderVisualParams currentParams =
              AppHeaderLogic.getDynamicHeaderVisualParams(
            context: context,
            scrollOffset: _mainScrollController.hasClients &&
                    _mainScrollController.position.haveDimensions
                ? _mainScrollController.offset
                : 0.0,
            targetSectionForCollapsed: null,
            currentMarqueeText:
                (tickerSnapshot.hasData ? tickerSnapshot.data ?? '' : ''),
            // currentMarqueeText: '',
            // Pass the resolved text
            buttonCenterOffsetsX: _buttonCenterOffsetsX,
          );

          Widget headerVisuals = buildAnimatedHeaderContent(
            context: context,
            params: currentParams,
            onHomeTap: _handleHomeButtonTap,
            onSectionTap: _handleSectionButtonTap,
            buttonCenterOffsetsX: _buttonCenterOffsetsX,
            uniformButtonSlotWidth: _uniformButtonSlotWidth,
            goingToAbout: false,
          );

          Widget headerContentWithNudgeDetector = GestureDetector(
            onTap: _onForwardTap,
            behavior: HitTestBehavior.translucent,
            child: headerVisuals,
          );

          Widget headerVisualsWithHero = Hero(
            tag: headerHeroTag,
            createRectTween: (begin, end) {
              return MaterialRectCenterArcTween(begin: begin, end: end);
            },
            flightShuttleBuilder: (
              BuildContext flightCtx,
              Animation<double> animation,
              HeroFlightDirection flightDirection,
              BuildContext fromHeroCtx, // Context of Hero from DetailPage
              BuildContext toHeroCtx, // Context of this Hero on HomePage
            ) {
              HeaderVisualParams paramsFrom;
              HeaderVisualParams paramsTo;

              if (flightDirection == HeroFlightDirection.push) {
                // PUSH: Home (fromHeroCtx) to Detail (toHeroCtx)
                paramsFrom =
                    currentHeaderVisualParams; // State at the moment of push

                developer.log('[Hero] pushing to detail using home shuttle');

                final GoRouterState state =
                    GoRouterState.of(fromHeroCtx); // or flightCtx
                final Map<String, dynamic>? extra =
                    state.extra as Map<String, dynamic>?;
                final AppSection? targetSection =
                    extra?['targetSection'] as AppSection?;

                paramsTo = AppHeaderMetrics.getCollapsedHeaderVisualParams(
                  toHeroCtx,
                  targetSection: targetSection,
                  marqueeText: _whitespaceForMarquee,
                  buttonCenterOffsetsX: _buttonCenterOffsetsX,
                );
              } else {
                // POP: Detail (fromHeroCtx) to Home (toHeroCtx)
                // `fromHeroCtx` is DetailPage. We need its collapsed params.
                developer.log('[Hero] popping to home using home shuttle');
                final GoRouterState state = GoRouterState.of(
                    context); // Get state from DetailPage context
                final Map<String, dynamic>? extra =
                    state.extra as Map<String, dynamic>?;
                final AppSection? detailPageSection =
                    extra?['targetSection'] as AppSection?;
                // You might need a more robust way to get the detail page's ticker if it's dynamic
                paramsFrom = AppHeaderMetrics.getCollapsedHeaderVisualParams(
                  fromHeroCtx, // Detail's context
                  targetSection: detailPageSection,
                  marqueeText: _whitespaceForMarquee,
                  buttonCenterOffsetsX: _buttonCenterOffsetsX,
                );

                paramsTo = AppHeaderLogic.getDynamicHeaderVisualParams(
                  context: toHeroCtx,
                  scrollOffset: _mainScrollController.offset,
                  // Animate to home page's fully expanded state
                  targetSectionForCollapsed: null,
                  // Home target
                  currentMarqueeText: _whitespaceForMarquee,
                  buttonCenterOffsetsX: _buttonCenterOffsetsX,
                );
              }

              return globalFlightShuttleBuilderInternal(
                flightContext: flightCtx,
                animation: animation,
                paramsAtAnimationStart: paramsFrom,
                paramsAtAnimationEnd: paramsTo,
                flightDirection: flightDirection,
                buttonCenterOffsetsX: _buttonCenterOffsetsX,
                maxButtonTextWidth: _uniformButtonSlotWidth,
              );
            },
            child: headerContentWithNudgeDetector,
          );

          Widget mainPageParallaxBackground = ValueListenableBuilder<double>(
            valueListenable: _mainScrollControllerNotifier,
            builder: (context, scrollOffset, child) {
              double backgroundScrollOffset =
                  scrollOffset * 0.3; // Parallax factor
              double screenHeight = MediaQuery.of(context).size.height;
              double estimatedMaxContentScroll = screenHeight * 2.5;
              double parallaxTravel = estimatedMaxContentScroll * 0.3;

              return Positioned(
                top: -backgroundScrollOffset,
                left: 0,
                right: 0,
                height: screenHeight + parallaxTravel,
                child: Image.asset(
                  'assets/main_page_background.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              );
            },
          );

          SliverPersistentHeader headerSliver = SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: _AnimatedHeaderDelegate(
              minHeight: AppHeaderMetrics.getCollapsedHeaderHeight(context),
              maxHeight: AppHeaderMetrics.getFullscreenHeaderHeight(context),
              child: headerVisualsWithHero, // Make sure this is the Hero widget
            ),
          );

          Widget contentSliver = SliverList(
            delegate: mainContentBuilder(
              getSectionHeaderHeight(context),
              _handleSectionButtonTap,
              ContentRepository(db: widget.db).fetchTickerMessages(),
              _sectionItemKeys,
            ),
          );

          return Scaffold(
            body: _showAuthorUI
                ? AuthorControls(db: widget.db)
                : Stack(
                    children: <Widget>[
                      mainPageParallaxBackground,
                      CustomScrollView(
                        controller: _mainScrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: <Widget>[
                          headerSliver,
                          contentSliver,
                        ],
                      ),
                    ],
                  ),
          );
        });
  }

  bool get _headerExpanded =>
      _mainScrollController.hasClients &&
      _mainScrollController.position.haveDimensions &&
      _mainScrollController.offset < 1.0;

  // Condition: Header is expanded (at/near the top)
  void _onForwardTap() {
    print('got onForwardTap');
    if (_headerExpanded) {
      // Small threshold

      final screenHeight = MediaQuery.of(context).size.height;
      final scrollAmount = screenHeight * 0.4;
      final maxScroll = _mainScrollController.position.maxScrollExtent;
      final targetScroll =
          (_mainScrollController.offset + scrollAmount).clamp(0.0, maxScroll);

      if (targetScroll > _mainScrollController.offset) {
        _mainScrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }
}

double getSectionHeaderHeight(BuildContext context) =>
    AppHeaderMetrics.getFullscreenHeaderHeight(context) * 0.65;
