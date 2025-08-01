import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'home_content.dart';
import 'base_detail_page.dart';

class ElevationDetailPage extends BaseDetailPage {
  final AppSection appSection = AppSection.elevation;
  ElevationDetailPage({
    super.key, required super.db, required super.articleId, required super.homePageScrollOffset,
  });

  @override
  State<ElevationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState
    extends BaseDetailPageState<ElevationDetailPage> {

  @override
  List<Widget> buildScrollableContent(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Elevation Details: ${sectionTitle}",
                        style: Theme.of(context).textTheme.headlineMedium),
                    SizedBox(height: 20),
                    Text("ID: ${sectionId}"),
                    SizedBox(height: 20),
                    Text("Content related to elevation and growth... " * 20),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.5),
                    Text("End of elevation content."),
                  ],
                ),
              );
            },
            childCount: 1, // Your desired child count
          ),
        ),
      ),
      // Add more slivers specific to EvaluationDetailPage here if needed
    ];
  }

// Optional: Override scroll physics if needed for this specific page
// @override
// ScrollPhysics getScrollPhysics() => const AlwaysScrollableScrollPhysics();
  @override
  String get backgroundImageAsset => widget.appSection.imageAsset; // Accesses the local appSection
  @override
  String get sectionId => widget.appSection.id;
  @override
  String get sectionTitle => widget.appSection.title;
}
