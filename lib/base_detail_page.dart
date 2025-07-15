import 'package:flutter/material.dart';
import 'header_util.dart';
import 'home_content.dart';
import 'hero_util.dart';

abstract class BaseDetailPage extends StatefulWidget {
  final String articleId;
  final double homePageScrollOffset;

  const BaseDetailPage({
    super.key,
    required this.articleId, required this.homePageScrollOffset,
  });
}

abstract class BaseDetailPageState<T extends BaseDetailPage> extends State<T> {
  // Optional: Common internal scroll controller if needed by many subclasses
  final ScrollController _internalScrollController = ScrollController();
  abstract SubSectionMetaData subSectionMetaData; // Fetch or receive this
  // Potentially a ValueNotifier for its own scroll offset if needed for internal parallax
  late ValueNotifier<double> _detailPageScrollNotifier;

  @override
  void initState() {
    super.initState();
    _detailPageScrollNotifier = ValueNotifier<double>(0.0);
    _internalScrollController.addListener(() {
      _detailPageScrollNotifier.value = _internalScrollController.offset;
    });
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
    final canPop = Navigator.of(context).canPop();
    final double detailAppBarHeight =
        AppHeaderMetrics.getCollapsedHeaderHeight(context);

    final HeaderVisualParams detailHeaderParams =
        AppHeaderMetrics.getCollapsedHeaderVisualParams(context);
    Widget smallHeaderVisual = buildAnimatedHeaderContent(
        context: context, params: detailHeaderParams);

    return Scaffold(
      // backgroundColor: Colors.transparent, // Consider if all detail pages need this

      body: Stack(
        children: [
          // --- Parallax Background ---
          Positioned(
            top: detailAppBarHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Hero(
              tag: sectionHeroTag + subSectionMetaData.id,
              createRectTween: (Rect? begin, Rect? end) =>
                  CenterExpansionRectTween(begin: begin, end: end),
              child: Image.asset(
                subSectionMetaData.imageAsset,
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
                // title: Text(subSectionMetaData.title), // Can be removed if headerHero is the title
                leading: canPop
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => _handleCustomBackNavigation(context),
                      )
                    : null,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                // Or your desired collapsed header bg
                pinned: true,
                elevation: 2,
                // Or your preferred elevation for the small header
                // Use flexibleSpace to house the Hero widget for the header.
                // The height of the SliverAppBar when collapsed will be determined by
                // the AppBar's default height or `toolbarHeight` property if set.
                // `expandedHeight` is not strictly needed if not making a collapsing FlexibleSpaceBar,
                // but setting `toolbarHeight` can ensure the Hero's container has a known height.
                toolbarHeight: detailAppBarHeight,
                // Ensure consistent height for the Hero
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
                      BuildContext toHeroCtx,   // Context of this Hero on DetailPage
                      ) {
                    // This builder is called when DetailPage is the DESTINATION (i.e., on PUSH)
                    print("BaseDetailPage Hero shuttle (DESTINATION ON PUSH): Anim Val: ${animation.value.toStringAsFixed(2)}");

                    HeaderVisualParams paramsFromHome;
                    final double? homeScrollOffset = widget.homePageScrollOffset; // Get from widget/extra

                    if (homeScrollOffset != null) {
                      print("  BaseDetailShuttle (PUSH): Using PRECISE scrollOffset: $homeScrollOffset");
                      paramsFromHome= AppHeaderLogic.getDynamicHeaderVisualParams(
                        context: fromHeroCtx,
                        scrollOffset: homeScrollOffset,
                      );
                      print("  Calculated precise paramsFromHome: Align: ${paramsFromHome.wheelAlignment}, Dia: ${paramsFromHome.wheelDiameter}, Angle1: ${paramsFromHome.wheelAngle1}");

                    } else {
                      print("  BaseDetailShuttle (PUSH): homePageScrollOffset is NULL. Using Fullscreen FALLBACK.");
                      paramsFromHome= AppHeaderMetrics.getFullscreenHeaderVisualParams(fromHeroCtx);
                    }
                    // Parameters for the end of the animation (this DetailPage's collapsed header)
                    final paramsToDetail = AppHeaderMetrics.getCollapsedHeaderVisualParams(toHeroCtx);
                    print("  paramsToDetail (Push): Align: ${paramsToDetail.wheelAlignment}, Dia: ${paramsToDetail.wheelDiameter.toStringAsFixed(2)}, Angle1: ${paramsToDetail.wheelAngle1.toStringAsFixed(2)}, Color1: ${paramsToDetail.wheel1Color}, BgColor: ${paramsToDetail.backgroundColor}");

                    return globalFlightShuttleBuilderInternal(
                      flightContext: flightCtx,
                      animation: animation,
                      paramsAtAnimationStart: paramsFromHome,
                      paramsAtAnimationEnd: paramsToDetail,
                      flightDirection: flightDirection,
                    );
                  },
                  child: smallHeaderVisual,
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
