import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'content_repo.dart';
import 'header_util.dart';
import 'hero_util.dart';

abstract class BaseDetailPage extends StatefulWidget {
  final String? articleId;
  final double homePageScrollOffset;
  final ContentRepository contentRepo;
  final AppSection appSection;

  BaseDetailPage({
    super.key,
    required db,
    required this.articleId,
    required this.homePageScrollOffset,
    required this.appSection,
  }) : contentRepo = ContentRepository(db: db);
}

abstract class BaseDetailPageState<T extends BaseDetailPage> extends State<T> {
  // Optional: Common internal scroll controller if needed by many subclasses
  final ScrollController _internalScrollController = ScrollController();

  // Potentially a ValueNotifier for its own scroll offset if needed for internal parallax
  late ValueNotifier<double> _detailPageScrollNotifier;

  /// Provides the path to the background image asset for this detail page.
  String get backgroundImageAsset;

  /// Provides the unique ID for this section, used for Hero tags.
  String get sectionId;

  /// Provides the title for this section, potentially for the AppBar.
  String get sectionTitle;

  Future<String> get titleCopy; // likely to be replaced by the marquee text

  late Future<String> _tickerFuture;

  @override
  void initState() {
    super.initState();
    _detailPageScrollNotifier = ValueNotifier<double>(0.0);
    _internalScrollController.addListener(() {
      _detailPageScrollNotifier.value = _internalScrollController.offset;
    });
    _tickerFuture = widget.contentRepo
        .fetchTickerMessages()
        .then((tickers) => tickers[sectionId] ?? '  err   ');
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    _detailPageScrollNotifier.dispose();
    super.dispose();
  }

  void _handleCustomBackNavigation(BuildContext context) {
    // For now, just a standard pop. We'll enhance this.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  List<Widget> buildScrollableContent(BuildContext context);

  ScrollPhysics getScrollPhysics() => const ClampingScrollPhysics();

  @override
  Widget build(BuildContext context) {
    final double detailAppBarHeight =
        AppHeaderMetrics.getCollapsedHeaderHeight(context);

    // Use a FutureBuilder for detailHeaderParams if marquee text is async
    return FutureBuilder<String>(
        future: _tickerFuture,
        builder: (context, marqueeSnapshot) {
          if (!marqueeSnapshot.hasData &&
              marqueeSnapshot.connectionState == ConnectionState.waiting) {
            // Provide a minimal loading state for the header itself if needed
            // Or use default text until loaded
          }
          final String currentMarqueeText =
              marqueeSnapshot.data ?? sectionTitle; // Fallback

          final HeaderVisualParams detailHeaderParams =
              AppHeaderMetrics.getCollapsedHeaderVisualParams(
            context,
            targetSection: widget.appSection, // From BlogContentDetailPage
            marqueeText: currentMarqueeText,
          );

          return Scaffold(
            body: Stack(
              children: [
                // ... Parallax Background Hero ...
                Positioned(
                  top: detailAppBarHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Hero(
                    tag: sectionHeroTag + sectionId,
                    createRectTween: (Rect? begin, Rect? end) =>
                        CenterExpansionRectTween(begin: begin, end: end),
                    child: Image.asset(
                      backgroundImageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),

                CustomScrollView(
                  controller: _internalScrollController,
                  physics: getScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      backgroundColor: Colors.transparent,
                      // Let Hero child provide color
                      pinned: true,
                      elevation: 0,
                      // Let Hero child provide elevation if needed via its container
                      toolbarHeight: detailAppBarHeight,
                      flexibleSpace: Hero(
                        tag: headerHeroTag,
                        createRectTween: (begin, end) {
                          return MaterialRectCenterArcTween(
                              begin: begin, end: end);
                        },
                        flightShuttleBuilder: (
                          BuildContext flightCtx,
                          Animation<double> animation,
                          HeroFlightDirection flightDirection,
                          BuildContext fromHeroCtx, // Source of flight
                          BuildContext toHeroCtx, // Destination of flight
                        ) {
                          HeaderVisualParams paramsFrom; // Animation Start
                          HeaderVisualParams paramsTo; // Animation End

                          if (flightDirection == HeroFlightDirection.push) {
                            // PUSH: Home (fromHeroCtx) to Detail (toHeroCtx)
                            // `fromHeroCtx` is HomePage. `homePageScrollOffset` gives its scroll.
                            paramsFrom =
                                AppHeaderLogic.getDynamicHeaderVisualParams(
                                    context: fromHeroCtx,
                                    scrollOffset: widget.homePageScrollOffset,
                                    targetSectionForCollapsed: null,
                                    // Home doesn't have a section target in this context
                                    currentMarqueeText:
                                        "pachakutech" // Home's default marquee
                                    );
                            // `toHeroCtx` is this DetailPage. `detailHeaderParams` is its target.
                            paramsTo =
                                detailHeaderParams; // Already calculated with correct section and marquee
                          } else {
                            // POP: Detail (fromHeroCtx) to Home (toHeroCtx)
                            // `fromHeroCtx` is this DetailPage.
                            paramsFrom =
                                detailHeaderParams; // Current state of detail page header

                            // `toHeroCtx` is HomePage. We want to animate to its expanded state.
                            paramsTo =
                                AppHeaderLogic.getDynamicHeaderVisualParams(
                                    context: toHeroCtx,
                                    scrollOffset: 0.0,
                                    // Target home's expanded state
                                    targetSectionForCollapsed: null,
                                    currentMarqueeText: "pachakutech");
                          }

                          return globalFlightShuttleBuilderInternal(
                            flightContext: flightCtx,
                            animation: animation,
                            paramsAtAnimationStart: paramsFrom,
                            paramsAtAnimationEnd: paramsTo,
                            flightDirection: flightDirection,
                          );
                        },
                        child: buildAnimatedHeaderContent(
                          context: context,
                          // Pass context
                          params: detailHeaderParams,
                          // tickerFuture no longer needed, marqueeText is in params
                          onHomeTap: () => _handleCustomBackNavigation(context),
                          onSectionTap: (tappedSection) {
                            // If on detail page, and a section button is tapped,
                            // navigate to that new section.
                            if (tappedSection != widget.appSection) {
                              // Avoid navigating to self
                              // Standard pop then push might be simplest, or a more custom transition.
                              // For now, let's assume we want to go back to home, then to new section.
                              // Or, if using go_router, you can context.push to the new section.
                              Navigator.of(context)
                                  .pop(); // Pop current detail page
                              // Then, from home, the user would click the new section, or:
                              // context.go('/'); // Go to home, then...
                              // This interaction needs defining: what happens when tapping 'edu' while on 'eval' page?
                              // Option 1: Go Home, then user clicks 'edu'
                              // Option 2: Directly transition from 'eval' detail to 'edu' detail (more complex hero)
                              // For now, let's make it go back home.
                              // If you want direct detail-to-detail, the Hero animations and router need more setup.
                              _handleCustomBackNavigation(
                                  context); // Goes back to Home
                              // TODO: Consider how to immediately trigger navigation to tappedSection from home if desired
                            }
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList.list(children: [
                          Card(
                            margin: const EdgeInsets.all(4.0),
                            child: FutureBuilder(
                                future: titleCopy,
                                builder: (context, snapshot) => Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          snapshot.hasData
                                              ? snapshot.data ?? ''
                                              : '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                    )),
                          ),
                        ])),
                    ...buildScrollableContent(context),
                  ],
                ),
              ],
            ),
          );
        });
  }
}
