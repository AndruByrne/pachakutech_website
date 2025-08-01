import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'content_repo.dart';
import 'header_util.dart';
import 'home_content.dart';
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
  late Future<String> _tickerFuture;

  /// Provides the path to the background image asset for this detail page.
  String get backgroundImageAsset;

  /// Provides the unique ID for this section, used for Hero tags.
  String get sectionId;

  /// Provides the title for this section, potentially for the AppBar.
  String get sectionTitle;

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
                // TODO: how is back arrow still here?
                // title: Text(sectionTitle), // Can be removed if headerHero is the title
                // leading: canPop
                //     ? IconButton(
                //         icon: const Icon(Icons.arrow_back_ios_new),
                //         onPressed: () => _handleCustomBackNavigation(context),
                //       )
                //     : null,
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
                    BuildContext fromHeroCtx, // Context of Hero from HomePage
                    BuildContext toHeroCtx,
                    // Context of this Hero on DetailPage
                  ) {
                    // This builder is called when DetailPage is the DESTINATION (i.e., on PUSH)
                    print(
                        "BaseDetailPage Hero shuttle (DESTINATION ON PUSH): Anim Val: ${animation.value.toStringAsFixed(2)}");

                    HeaderVisualParams paramsFromHome;
                    final double homeScrollOffset =
                        widget.homePageScrollOffset; // Get from widget/extra

                    print(
                        "  BaseDetailShuttle (PUSH): Using PRECISE scrollOffset: $homeScrollOffset");
                    paramsFromHome =
                        AppHeaderLogic.getDynamicHeaderVisualParams(
                      context: fromHeroCtx,
                      scrollOffset: homeScrollOffset,
                    );
                    print(
                        "  Calculated precise paramsFromHome: Align: ${paramsFromHome.wheelAlignment}, Dia: ${paramsFromHome.wheelDiameter}, Angle1: ${paramsFromHome.wheelAngle1}");

                    // Parameters for the end of the animation (this DetailPage's collapsed header)
                    final paramsToDetail =
                        AppHeaderMetrics.getCollapsedHeaderVisualParams(
                            toHeroCtx);
                    print(
                        "  paramsToDetail (Push): Align: ${paramsToDetail.wheelAlignment}, Dia: ${paramsToDetail.wheelDiameter.toStringAsFixed(2)}, Angle1: ${paramsToDetail.wheelAngle1.toStringAsFixed(2)}, Color1: ${paramsToDetail.wheel1Color}, BgColor: ${paramsToDetail.backgroundColor}");

                    return globalFlightShuttleBuilderInternal(
                      flightContext: flightCtx,
                      animation: animation,
                      paramsAtAnimationStart: paramsFromHome,
                      paramsAtAnimationEnd: paramsToDetail,
                      flightDirection: flightDirection,
                    );
                  },
                  child: FutureBuilder<Widget>(
                      future: _tickerFuture.then((ticker) =>
                          buildAnimatedHeaderContent(
                              context: context,
                              params: detailHeaderParams,
                              ticker: ticker)),
                      builder: (context, asyncSnapshot) {
                        return asyncSnapshot.hasData
                            ? asyncSnapshot.data ??
                                Container(child: Text('null data'))
                            : Container(
                                child: Text('no data'),
                              );
                      }),
                ),
              ),
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
