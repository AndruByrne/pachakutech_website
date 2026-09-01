import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'dart:ui_web' as ui_web; // Use 'dart:ui' if using older Flutter versions
import 'package:web/web.dart' as web; // Modern Flutter web package

class ExtranetIdeaPage extends BaseDetailPage {
  // The appSection is now defined here and passed to the super constructor
  ExtranetIdeaPage({
    super.key,
    required super.db, // db is still needed for BaseDetailPage's ContentRepository
    required super.articleId,
    required super.homePageScrollOffset,
  }) : super(appSection: AppSection.extranet); // Pass the specific AppSection

  @override
  State<ExtranetIdeaPage> createState() => _ExtranetIdeaPageState();
}

class _ExtranetIdeaPageState extends BaseDetailPageState<ExtranetIdeaPage> {
  // late Future<String?> _tickerFuture;

  @override
  void initState() {
    super.initState();
    // _tickerFuture = widget.contentRepo
    //     .fetchTickerMessages()
    //     .then((tickers) => tickers[widget.appSection.id]);
    registerPdfView();
  }

  void registerPdfView() {
    ui_web.platformViewRegistry.registerViewFactory(
      'pdf-viewer-html',
      (int viewId) {
        final element = web.HTMLIFrameElement()
          ..src = 'documents/Extranet.pdf#navpanes=0&toolbar=0'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return element;
      },
    );
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
              // padding: const EdgeInsets.all(86.0),
              padding: const EdgeInsets.all(6.0),
              child: Container(
                width: constraints.maxWidth,
                child: Center(
                    child: InkWell(
                  onTap: () => context.pop(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.9),
                    child: Center(
                      child: SizedBox(
                        height: screenHeight * 0.9,
                        // maxWidth: 800, // Keeps a nice desktop reading width
                        child: HtmlElementView(viewType: 'pdf-viewer-html'),
                      ),
                    ),
                    //                 child: FutureBuilder(
                    // future: _tickerFuture,
                    // builder: (context, asyncSnapshot) {
                    //   return Text(
                    //     asyncSnapshot.hasData ? asyncSnapshot.data ?? '' : '',
                    //     textAlign: TextAlign.center,
                    //     style: TextStyle(
                    //         fontSize: 18,
                    //         fontWeight: FontWeight.bold,
                    //         color: Colors.green),
                    //   );
                    // }),
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
          'Presenting the ${widget.appSection.title}');
}
