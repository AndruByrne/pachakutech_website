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
  final TextStyle _navButtonTextStyle =
      const TextStyle(fontFamily: 'Pachakutech', fontSize: NAV_BUTTON_FONT_SIZE);

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_handleScroll);
    _mainScrollControllerNotifier = ValueNotifier<double>(0.0);

    _uniformButtonSlotWidth = AppHeaderMetrics.getMaxButtonTextWidth(_navButtonTextStyle);
    _buttonCenterOffsetsX = AppHeaderMetrics.calculateButtonCenterOffsets(
      textStyle: _navButtonTextStyle,
      uniformButtonSlotWidth: _uniformButtonSlotWidth,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  void _handleBackTap() {
    // If the header is in a state where tapping it means "go back to top / main view"
    // With go_router, if we are on MyHomePage ('/'), tapping the logo when scrolled
    // might mean "scroll to top". If we were on a different page (not the case here
    // anymore since _activeDetailData is gone), it would mean context.go('/');
    if (_mainScrollController.offset > 0) {
      _mainScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        // Or your preferred duration
        curve: Curves.easeOutQuart,
      );
    } else {
      developer.log("Logo/Wheels tapped on main list view (already at top).",
          name: "MyHomePageState.Interaction");
      _onForwardTap();
    }
  }

  void _handleSubsectionCardTap(AppSection appSection) => setState(() {
        final double currentScrollOffset = _mainScrollController.offset;

        developer.log(
            "Card tapped: ${appSection.title}. Passing scrollOffset: $currentScrollOffset",
            name: "MyHomePageState.Navigation");

        String path = '/${appSection.id}';
        context.push(path, extra: {
          'scrollOffset': currentScrollOffset,
        });
      });

  void _handleSectionButtonTap(AppSection section) {
    final double currentScrollOffset = _mainScrollController.hasClients &&
            _mainScrollController.position.haveDimensions
        ? _mainScrollController.offset
        : 0.0;

    developer.log(
        "Section button tapped: ${section.title}. Passing scrollOffset: $currentScrollOffset",
        name: "MyHomePageState.Navigation");

    String path = '/${section.id}';
    context.push(path, extra: {
      'scrollOffset': currentScrollOffset,
      'targetSection': section,
      // Pass the target section for Hero animation hints
    });
  }

  // _handleWheelsTap might now be more of a "go to top" or general interaction
  // Renaming to _handleHomeButtonTap for clarity in collapsed state
  void _handleHomeButtonTap() {
    if (_mainScrollController.offset > 0) {
      _mainScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    } else {
      // If already at top, perhaps a subtle animation or nothing.
      developer.log("Home button tapped at top.",
          name: "MyHomePageState.Interaction");
      _onForwardTap(); // Or specific "nudge" behavior
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
    developer.log(
        "Returning to Home. Instructed to scroll to and navigate to: ${sectionToNavigate.id}",
        name: "MyHomePage.Navigation");

    final GlobalKey? sectionKey = _sectionItemKeys[sectionToNavigate];
    if (sectionKey?.currentContext != null &&
        _mainScrollController.hasClients) {
      await Scrollable.ensureVisible(
        sectionKey!.currentContext!,
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
        // Adjust this: 0.0 is top, 0.5 is center. Try to position it just below your sticky header.
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit, // Be precise
      );
      // Add a small delay for visual settlement and to ensure Hero has the right start conditions
      // await Future.delayed(
      //     const Duration(milliseconds: 150)); // Tune this delay
    } else {
      developer.log(
          "Could not find key or scroll controller for section ${sectionToNavigate!.id}. Jumping approximately.",
          name: "MyHomePage.Navigation");
      // Fallback to approximate jump if key not ready (should be rare)
    }
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
        'currentMarqueeText': "PACHAKUTECH", // Or dynamic
      });
      developer.log(
          "InitiateScroll: Pushed to $path for ${sectionToNavigate.id}. _pendingNavigationToSection is now null.",
          name: "MyHomePage.Navigation");
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
        currentMarqueeText: "PACHAKUTECH",
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
    final HeaderVisualParams currentParams = currentHeaderVisualParams;

    Widget headerVisuals = buildAnimatedHeaderContent(
      context: context,
      params: currentParams,
      // tickerFuture is not directly used by the new buildAnimatedHeaderContent
      // marqueeText is now part of currentParams
      onHomeTap: _handleHomeButtonTap,
      // For when wheels act as home
      onSectionTap: _handleSectionButtonTap,
      buttonCenterOffsetsX: _buttonCenterOffsetsX,
      uniformButtonSlotWidth: _uniformButtonSlotWidth,
    );

    // Apply the GestureDetector for the "nudge" directly to the header's content
    Widget headerContentWithNudgeDetector = GestureDetector(
      onTap: _onForwardTap,
      // HitTestBehavior.translucent allows taps to be "seen" by this detector
      // AND by widgets further down the tree if this one doesn't claim the gesture.
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
          // `fromHeroCtx` is MyHomePage. `currentHeaderVisualParams` is appropriate.
          paramsFrom = currentHeaderVisualParams; // State at the moment of push

          developer.log('[Hero] pushing to detail using home shuttle');

          // For `paramsTo`, we need info from the DetailPage.
          // This is where the `extra` data in go_router comes in handy.
          // We assume the DetailPage's Hero will primarily drive the PUSH.
          // This shuttle on HomePage is more critical for POP.
          // If this shuttle IS used for push, it means detail page hasn't specified its own target.
          // Fallback:
          final GoRouterState state =
              GoRouterState.of(fromHeroCtx); // or flightCtx
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final AppSection? targetSection =
              extra?['targetSection'] as AppSection?;

          paramsTo = AppHeaderMetrics.getCollapsedHeaderVisualParams(
            toHeroCtx, // context of the destination page
            targetSection: targetSection,
            // Target section for the detail page
            marqueeText:
                targetSection?.id ?? "pachakutech", // Detail page ticker
            buttonCenterOffsetsX: _buttonCenterOffsetsX,
          );
        } else {
          // POP: Detail (fromHeroCtx) to Home (toHeroCtx)
          // `fromHeroCtx` is DetailPage. We need its collapsed params.
          developer.log('[Hero] popping to home using home shuttle');
          final GoRouterState state =
              GoRouterState.of(context); // Get state from DetailPage context
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final AppSection? detailPageSection =
              extra?['targetSection'] as AppSection?;
          // You might need a more robust way to get the detail page's ticker if it's dynamic
          final String detailPageTicker =
              extra?['currentMarqueeText'] as String? ??
                  detailPageSection?.id ??
                  "pachakutech";

          paramsFrom = AppHeaderMetrics.getCollapsedHeaderVisualParams(
            fromHeroCtx, // Detail's context
            targetSection: detailPageSection,
            marqueeText: detailPageTicker,
            buttonCenterOffsetsX: _buttonCenterOffsetsX,
          );

          paramsTo = AppHeaderLogic.getDynamicHeaderVisualParams(
            context: toHeroCtx,
            scrollOffset: _mainScrollController.offset,
            // Animate to home page's fully expanded state
            targetSectionForCollapsed: null,
            // Home target
            currentMarqueeText: "pachakutech",
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
        double backgroundScrollOffset = scrollOffset * 0.3; // Parallax factor
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
        _handleSubsectionCardTap,
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

  void _calculateButtonLayouts() {
    if (!mounted) return; // Ensure widget is still in the tree

    final uniformButtonSlotWidth =
        AppHeaderMetrics.getMaxButtonTextWidth(_navButtonTextStyle);
    final buttonCenterOffsetsX = AppHeaderMetrics.calculateButtonCenterOffsets(
      textStyle: _navButtonTextStyle,
      uniformButtonSlotWidth: uniformButtonSlotWidth,
    );

    // Check if values changed to avoid unnecessary rebuilds if called multiple times
    if (_uniformButtonSlotWidth != uniformButtonSlotWidth ||
        !mapEquals(_buttonCenterOffsetsX, buttonCenterOffsetsX)) {
      // mapEquals from collection package
      setState(() {
        _uniformButtonSlotWidth = uniformButtonSlotWidth;
        _buttonCenterOffsetsX = buttonCenterOffsetsX;
      });
    }
  }
}

double getSectionHeaderHeight(BuildContext context) =>
    AppHeaderMetrics.getFullscreenHeaderHeight(context) * 0.65;
