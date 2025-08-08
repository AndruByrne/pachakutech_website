import 'package:flutter/material.dart';
import 'content_repo.dart';
import 'header_util.dart';
import 'hero_util.dart';

abstract class BaseDetailPage extends StatefulWidget {
  final String? articleId;
  final double homePageScrollOffset;
  final ContentRepository contentRepo;

  BaseDetailPage({
    super.key,
    required db,
    required this.articleId,
    required this.homePageScrollOffset,
  }) : contentRepo = ContentRepository(db: db);
}

abstract class BaseDetailPageState<T extends BaseDetailPage> extends State<T> {
  // Optional: Common internal scroll controller if needed by many subclasses
  final ScrollController _internalScrollController = ScrollController();

  // Potentially a ValueNotifier for its own scroll offset if needed for internal parallax
  late ValueNotifier<double> _detailPageScrollNotifier;
  late Future<Map<String, dynamic>> _tickerFuture;

  /// Provides the path to the background image asset for this detail page.
  String get backgroundImageAsset;

  /// Provides the unique ID for this section, used for Hero tags.
  String get sectionId;

  /// Provides the title for this section, potentially for the AppBar.
  String get sectionTitle;

  Future<String> get titleCopy;

  @override
  void initState() {
    super.initState();
    _detailPageScrollNotifier = ValueNotifier<double>(0.0);
    _internalScrollController.addListener(() {
      _detailPageScrollNotifier.value = _internalScrollController.offset;
    });
    _tickerFuture = widget.contentRepo.fetchTickerMessages();
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    _detailPageScrollNotifier.dispose();
    super.dispose();
  }

  List<Widget> buildScrollableContent(BuildContext context);

  ScrollPhysics getScrollPhysics() => const ClampingScrollPhysics();

  @override
  Widget build(BuildContext context) {
    final double detailAppBarHeight =
        AppHeaderMetrics.getCollapsedHeaderHeight(context);

    final HeaderVisualParams detailHeaderParams =
        AppHeaderMetrics.getCollapsedHeaderVisualParams(context);

    return Scaffold(
      body: Stack(
        children: [
          // --- Parallax Background ---
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

          // --- Scrollable Detail Content (provided by subclass) ---
          CustomScrollView(
            controller: _internalScrollController,
            physics: getScrollPhysics(),
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                // Or your desired collapsed header bg
                pinned: true,
                elevation: 2,
                toolbarHeight: detailAppBarHeight,
                flexibleSpace: Hero(
                  tag: headerHeroTag, // <<<---- THIS IS THE HEADER HERO
                  createRectTween: (begin, end) {
                    return MaterialRectCenterArcTween(begin: begin, end: end);
                  },
                  flightShuttleBuilder: (
                    BuildContext flightCtx,
                    Animation<double> animation,
                    HeroFlightDirection flightDirection,
                    BuildContext fromHeroCtx,
                    BuildContext toHeroCtx,
                  ) {
                    HeaderVisualParams paramsFromHome;
                    final double homeScrollOffset =
                        widget.homePageScrollOffset; // Get from widget/extra
                    paramsFromHome =
                        AppHeaderLogic.getDynamicHeaderVisualParams(
                      context: fromHeroCtx,
                      scrollOffset: homeScrollOffset,
                    );

                    // Parameters for the end of the animation (this DetailPage's collapsed header)
                    final paramsToDetail =
                        AppHeaderMetrics.getCollapsedHeaderVisualParams(
                            toHeroCtx);

                    return globalFlightShuttleBuilderInternal(
                      flightContext: flightCtx,
                      animation: animation,
                      paramsAtAnimationStart: paramsFromHome,
                      paramsAtAnimationEnd: paramsToDetail,
                      flightDirection: flightDirection,
                    );
                  },
                  child: buildAnimatedHeaderContent(
                    params: detailHeaderParams,
                    tickerFuture: widget.contentRepo
                        .fetchTickerMessages()
                        .then((tickers) => tickers[sectionId]),
                    onLogoTap: () => _handleCustomBackNavigation(context),
                  ),
                  // child: Container(),
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
                                    snapshot.hasData ? snapshot.data ?? '' : '',
                                    style: Theme.of(context).textTheme.titleLarge,
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
  }

  void _handleCustomBackNavigation(BuildContext context) {
    // For now, just a standard pop. We'll enhance this.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
