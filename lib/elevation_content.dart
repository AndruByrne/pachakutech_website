import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'blog_content_detail_page.dart';

class ElevationDetailPage extends BaseDetailPage {
  // The appSection is now defined here and passed to the super constructor
  ElevationDetailPage({
    super.key,
    required super.db, // db is still needed for BaseDetailPage's ContentRepository
    required super.articleId,
    required super.homePageScrollOffset,
  }) : super(appSection: AppSection.elevation); // Pass the specific AppSection

  @override
  State<ElevationDetailPage> createState() => _ElevationDetailPageState();
}

class _ElevationDetailPageState
    extends BaseDetailPageState<ElevationDetailPage> {
  @override
  List<Widget> buildScrollableContent(BuildContext context) => [
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
            child: Text(
              'Coming Soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            )),
      ),
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
