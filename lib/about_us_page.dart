import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'blog_content_detail_page.dart';

class AboutUsPage extends BaseDetailPage {
  // The appSection is now defined here and passed to the super constructor
  AboutUsPage({
    super.key,
    required super.db, // db is still needed for BaseDetailPage's ContentRepository
    required super.articleId,
    required super.homePageScrollOffset,
  }) : super(appSection: AppSection.about_us); // Pass the specific AppSection

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends BaseDetailPageState<AboutUsPage> {
  late Future<String?> _tickerFuture;

  @override
  void initState() {
    super.initState();
    _tickerFuture = widget.contentRepo
        .fetchTickerMessages()
        .then((tickers) => tickers[widget.appSection.id]);
  }

  @override
  List<Widget> buildScrollableContent(BuildContext context) => [
        SliverToBoxAdapter(
          child: LayoutBuilder(builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final availableHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : screenHeight;
            final middleThirdHeight = availableHeight / 3;

            return Padding(
              padding: const EdgeInsets.all(86.0),
              child: Container(
                width: constraints.maxWidth,
                child: Center(
                    child: InkWell(
                      onTap: () => context.pop(),
                      child: ConstrainedBox(
                                        constraints:
                        BoxConstraints(maxWidth: constraints.maxWidth * .4),
                                        child: FutureBuilder(
                        future: _tickerFuture,
                        builder: (context, asyncSnapshot) {
                          return Text(
                            asyncSnapshot.hasData ? asyncSnapshot.data ?? '' : '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          );
                        }),
                                      ),
                    )),
              ),
            );
          }),
        ),
      ];

  @override
  String get backgroundImageAsset => widget.appSection.imageAsset;

  @override
  String get sectionId => widget.appSection.id;

  @override
  String get sectionTitle => widget.appSection.title;

  @override
  Future<String> get titleFuture =>
      widget.contentRepo.fetchSectionIntros().then((intros) =>
          intros[widget.appSection.id] ??
          'Welcome to ${widget.appSection.title}');
}
