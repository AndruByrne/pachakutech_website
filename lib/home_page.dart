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

  void _handleWheelsTap() {
    if (kIsWeb) {
      _handleBackTap();
    } else {
      setState(() {
        // replace main content with author UI
        _showAuthorUI = !_showAuthorUI;
      });
    }
  }

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
    }
  }

  void _handleSubsectionCardTap(AppSection appSection) {
    setState(() {
      final double currentScrollOffset = _mainScrollController.offset;

      developer.log(
          "Card tapped: ${appSection.title}. Passing scrollOffset: $currentScrollOffset",
          name: "MyHomePageState.Navigation");

      String path = '/${appSection.id}';
      context.push(path, extra: {
        'scrollOffset': currentScrollOffset,
      });
    });
  }

  HeaderVisualParams get currentHeaderVisualParams {
    double currentScroll = 0.0;
    if (_mainScrollController.hasClients &&
        _mainScrollController.position.haveDimensions) {
      currentScroll = _mainScrollController.offset;
    }
    return AppHeaderLogic.getDynamicHeaderVisualParams(
        context: context, scrollOffset: currentScroll);
  }

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
      params: currentParams,
      tickerFuture: Future.value(''),
      onLogoTap: _handleWheelsTap,
      onWheelsTap: _handleWheelsTap,
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
          // This case should ideally not happen if DetailPage's Hero is primary for push.
          // But if it does, `fromHeroCtx` is this page.
          // We'd need to know what `currentParams` *was* at the point of push.
          // This shuttle is for when HomePage is the DESTINATION (on POP).
          // For POP: fromHeroContext is DetailPage, toHeroContext is HomePage
          paramsFrom = AppHeaderMetrics.getCollapsedHeaderVisualParams(
              fromHeroCtx); // Detail's collapsed state
          paramsTo = currentHeaderVisualParams; // Home's current dynamic state
        } else {
          // POP (HomePage is destination)
          paramsFrom = AppHeaderMetrics.getCollapsedHeaderVisualParams(
              fromHeroCtx); // Detail's collapsed state
          paramsTo =
              currentHeaderVisualParams; // Home's current state (as it will be when animation ends)
        }

        return globalFlightShuttleBuilderInternal(
          flightContext: flightCtx,
          animation: animation,
          paramsAtAnimationStart: paramsFrom,
          // Corrected for POP
          paramsAtAnimationEnd: paramsTo,
          // Corrected for POP
          flightDirection: flightDirection,
        );
      },
      child: headerVisuals,
    );

    Widget mainPageParallaxBackground = ValueListenableBuilder<double>(
      valueListenable: _mainScrollControllerNotifier,

      // You'll need to create this
      builder: (context, scrollOffset, child) {
        double backgroundScrollOffset = scrollOffset * 0.3; // Parallax factor
        double screenHeight = MediaQuery.of(context).size.height;
        // Estimate how much "extra" height is needed for the parallax effect.
        // This is a rough estimate; maxScrollExtent isn't always known upfront easily.
        // Let's assume the content might scroll up to, say, twice the screen height for a long list.
        double estimatedMaxContentScroll = screenHeight * 2.5;
        double parallaxTravel = estimatedMaxContentScroll * 0.3;

        return Positioned(
          top: -backgroundScrollOffset,
          left: 0,
          right: 0,
          // Make the image container tall enough to show the initial screen height
          // plus the amount it will effectively "travel" due to parallax.
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
        child: headerVisualsWithHero,
      ),
    );

    Widget contentSliver = SliverList(
      delegate: mainContentBuilder(
        getSectionHeaderHeight(context),
        _handleSubsectionCardTap,
        ContentRepository(db: widget.db).fetchTickerMessages(),
      ),
    );

    return Scaffold(
      // Main Scaffold for MyHomePage
      body: _showAuthorUI
          ? AuthorControls(db: widget.db)
          : Stack(
              children: <Widget>[
                mainPageParallaxBackground, // Always show for MyHomePage
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
}

double getSectionHeaderHeight(BuildContext context) =>
    AppHeaderMetrics.getFullscreenHeaderHeight(context) * 0.65;
