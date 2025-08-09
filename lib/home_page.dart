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
import 'package:flutter/foundation.dart' show kIsWeb;

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
  bool _showAuthorUI = false;
  AppSection? _pendingNavigationToSection;
  final Map<AppSection, GlobalKey> _sectionItemKeys = {
    for (var section in AppSection.values) section: GlobalKey()
  };

  @override
  void initState() {
    super.initState();
    _mainScrollController.addListener(_handleScroll);
    _mainScrollControllerNotifier = ValueNotifier<double>(0.0);
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
    _processNavigationExtras();
    _handleScroll();
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
      ? _handleBackTap()
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
    final double currentScrollOffset = _mainScrollController.hasClients && _mainScrollController.position.haveDimensions
        ? _mainScrollController.offset
        : 0.0;

    developer.log(
        "Section button tapped: ${section.title}. Passing scrollOffset: $currentScrollOffset",
        name: "MyHomePageState.Navigation");

    String path = '/${section.id}';
    context.push(path, extra: {
      'scrollOffset': currentScrollOffset,
      'targetSection': section, // Pass the target section for Hero animation hints
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
      developer.log("Home button tapped at top.", name: "MyHomePageState.Interaction");
      _onForwardTap(); // Or specific "nudge" behavior
    }
  }


  void _processNavigationExtras() {
    final GoRouterState state = GoRouterState.of(context);
    final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;

    if (extra != null && extra.containsKey('navigateToAfterScroll')) {
      final AppSection? targetSection = extra['navigateToAfterScroll'] as AppSection?;
      if (targetSection != null) {
        // Clear the extra so it's not processed again on subsequent rebuilds
        // This is a bit of a hack. A router-level state or event queue is cleaner.
        // For go_router, if you're on '/', context.go('/', extra: null) won't rebuild.
        // Consider using a flag in the state or a short-lived event.

        // Store it and trigger the scroll + navigation flow
        // Avoid doing it directly here if it causes rebuilds during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initiateScrollAndNavigate(targetSection);
        });
      }
      // How to "clear" the extra from go_router state is tricky without a full redirect.
      // One way is to navigate to the same path with extra: null, but that might have side effects.
      // A state variable in MyHomePage is safer.
      // context.go(state.location, extra: null); // Risky, might trigger loops or unwanted rebuilds
    }
  }

  Future<void> _initiateScrollAndNavigate(AppSection section) async {
    if (_pendingNavigationToSection == section) return; // Already processing
    setState(() {
      _pendingNavigationToSection = section;
    });
    developer.log("Returning to Home. Instructed to scroll to and navigate to: ${section.id}", name: "MyHomePage.Navigation");


    final GlobalKey? sectionKey = _sectionItemKeys[section];
    if (sectionKey?.currentContext != null && _mainScrollController.hasClients) {
      // Ensure the item is visible.
      // `alignment: 0.0` tries to bring the top of the item to the top of the viewport.
      // `alignment: 0.1` might be good to leave a small gap below the sticky header.
      // The duration here is for the scroll *to* the item.
      await Scrollable.ensureVisible(
        sectionKey!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.05, // Adjust this: 0.0 is top, 0.5 is center. Try to position it just below your sticky header.
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit, // Be precise
      );
      // Add a small delay for visual settlement and to ensure Hero has the right start conditions
      await Future.delayed(const Duration(milliseconds: 150)); // Tune this delay
    } else {
      developer.log("Could not find key or scroll controller for section ${section.id}. Jumping approximately.", name: "MyHomePage.Navigation");
      // Fallback to approximate jump if key not ready (should be rare)
    }

    final double currentScrollOffset = _mainScrollController.hasClients && _mainScrollController.position.haveDimensions
        ? _mainScrollController.offset
        : 0.0; // Fallback

    final AppSection? sectionToNavigate = _pendingNavigationToSection;
    setState(() {
      _pendingNavigationToSection = null;
    });

    if (sectionToNavigate != null) {
      developer.log("Scroll/ensureVisible complete. Navigating to detail for ${sectionToNavigate.id} at offset $currentScrollOffset", name: "MyHomePage.Navigation");
      String path = '/${sectionToNavigate.id}';
      context.push(path, extra: {
        'scrollOffset': currentScrollOffset,
        'targetSection': sectionToNavigate,
        'currentMarqueeText': "PACHAKUTECH", // Or dynamic
      });
    }
  }

  // THIS IS THE CRITICAL AND DIFFICULT FUNCTION TO IMPLEMENT
  double _getScrollOffsetForSection(AppSection section) {
  // Simpler (but less precise) for now: Approximate based on section index and an average item height.
    // This depends heavily on your `mainContentBuilder` structure.
    // Let's assume each section occupies roughly a certain height on the home page.
    final double screenHeight = MediaQuery.of(context).size.height;
    final double headerHeightAtTop = AppHeaderMetrics.getFullscreenHeaderHeight(context);
    // Estimate based on current structure.
    // This is a VERY ROUGH ESTIMATE. You'll need to tune this.

    int sectionIndex = AppSection.values.indexOf(section);
    if (sectionIndex < 0) return 0.0; // Should not happen

    // Offset calculation:
    final double singleSectionContentHeight = getSectionHeaderHeight(context); // This seems to be the height of the section "header" in the list


    // Placeholder for GlobalKeys strategy:
    // You would have a Map<AppSection, GlobalKey> in _MyHomePageState
    // Map<AppSection, GlobalKey> _sectionKeys = {
    //   AppSection.evaluation: GlobalKey(),
    //   AppSection.education: GlobalKey(),
    //   AppSection.elevation: GlobalKey(),
    // };
    // And pass these keys to your section card widgets.
    // Then:
    // GlobalKey? key = _sectionKeys[section];
    // if (key?.currentContext != null) {
    //   Scrollable.ensureVisible(key!.currentContext!,
    //       duration: const Duration(milliseconds: 700),
    //       curve: Curves.easeInOutCubic,
    //       alignment: 0.1); // 0.0 is top, 0.5 is center. Adjust alignment.
    //   // `ensureVisible` handles the scroll. The function would then just await it.
    //   // The `targetOffset` would not be directly calculated here.
    //   return _mainScrollController.offset; // This is problematic, ensureVisible is async
    // }
    // For now, returning a hardcoded approximation based on index:
    // This assumes the first section card is right after the fully expanded header, and subsequent cards follow.
    // And each "section slot" in the main list takes up roughly `screenHeight * 0.6` (very arbitrary).
    // This needs to be the offset of the scroll controller, not just raw heights.
    // Effective height of a section item on home page (guess)
    final double assumedSectionItemHeight = getSectionHeaderHeight(context); // From your code, seems like height of a section preview

    double calculatedOffset = 0;
    if (sectionIndex == 0) { // First section (e.g., Evaluation)
      calculatedOffset = AppHeaderMetrics.getTransitionEndScrollOffset(context) - (screenHeight * 0.1); // scroll past most of the header
    } else {
      calculatedOffset = AppHeaderMetrics.getTransitionEndScrollOffset(context) + (sectionIndex * assumedSectionItemHeight) - (kToolbarHeight/2);
    }

    // Ensure the offset is within valid scroll extents
    if (_mainScrollController.hasClients && _mainScrollController.position.haveDimensions) {
      return calculatedOffset.clamp(0.0, _mainScrollController.position.maxScrollExtent);
    }
    return calculatedOffset.clamp(0.0, 3000.0); // Fallback if no client, max 3000
  }

  HeaderVisualParams get currentHeaderVisualParams =>
      AppHeaderLogic.getDynamicHeaderVisualParams(
          context: context,
          scrollOffset: _mainScrollController.hasClients &&
                  _mainScrollController.position.haveDimensions
              ? _mainScrollController.offset
              : 0.0,targetSectionForCollapsed: null,currentMarqueeText: "PACHAKUTECH");

  @override
  void dispose() {
    _mainScrollController.removeListener(_handleScroll);
    _mainScrollControllerNotifier.dispose();
    _mainScrollController.dispose();
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
      onHomeTap: _handleWheelTap, // For when wheels act as home
      onSectionTap: _handleSectionButtonTap,
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

          // For `paramsTo`, we need info from the DetailPage.
          // This is where the `extra` data in go_router comes in handy.
          // We assume the DetailPage's Hero will primarily drive the PUSH.
          // This shuttle on HomePage is more critical for POP.
          // If this shuttle IS used for push, it means detail page hasn't specified its own target.
          // Fallback:
          final GoRouterState state = GoRouterState.of(fromHeroCtx); // or flightCtx
          final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
          final AppSection? targetSection = extra?['targetSection'] as AppSection?;

          paramsTo = AppHeaderMetrics.getCollapsedHeaderVisualParams(
              toHeroCtx, // context of the destination page
              targetSection: targetSection, // Target section for the detail page
              marqueeText: targetSection?.id ?? "pachakutech" // Detail page ticker
          );

        } else { // POP: Detail (fromHeroCtx) to Home (toHeroCtx)
          // `fromHeroCtx` is DetailPage. We need its collapsed params.
          final GoRouterState state = GoRouterState.of(context); // Get state from DetailPage context
          final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
          final AppSection? detailPageSection = extra?['targetSection'] as AppSection?;
          // You might need a more robust way to get the detail page's ticker if it's dynamic
          final String detailPageTicker = extra?['currentMarqueeText'] as String? ?? detailPageSection?.id ?? "pachakutech";


          paramsFrom = AppHeaderMetrics.getCollapsedHeaderVisualParams(
              fromHeroCtx, // Detail's context
              targetSection: detailPageSection,
              marqueeText: detailPageTicker
          );

          // `toHeroCtx` is MyHomePage. `currentHeaderVisualParams` represents its state
          // *IF* we were animating based on current scroll. But for a pop, we usually
          // want to animate to the fully expanded (scrollOffset = 0) or a specific target.
          // Let's assume pop animates to fully expanded home for simplicity.
          paramsTo = AppHeaderLogic.getDynamicHeaderVisualParams(
              context: toHeroCtx,
              scrollOffset: 0.0, // Animate to home page's fully expanded state
              targetSectionForCollapsed: null, // Home target
              currentMarqueeText: "pachakutech"
          );
        }

        return globalFlightShuttleBuilderInternal(
          flightContext: flightCtx,
          animation: animation,
          paramsAtAnimationStart: paramsFrom,
          paramsAtAnimationEnd: paramsTo,
          flightDirection: flightDirection,
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

  bool get _headerExpanded => _mainScrollController.hasClients &&
        _mainScrollController.position.haveDimensions &&
        _mainScrollController.offset < 1.0;

  // Condition: Header is expanded (at/near the top)
  void _onForwardTap() {
    print('got onForwardTap');
    if (_headerExpanded) { // Small threshold

      final screenHeight = MediaQuery.of(context).size.height;
      final scrollAmount = screenHeight * 0.4;
      final maxScroll = _mainScrollController.position.maxScrollExtent;
      final targetScroll = (_mainScrollController.offset + scrollAmount)
          .clamp(0.0, maxScroll);

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
