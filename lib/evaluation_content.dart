import 'package:flutter/material.dart';
import 'base_detail_page.dart';
import 'home_content.dart';

class EvaluationDetailPage extends BaseDetailPage {
  const EvaluationDetailPage({
    super.key,
    required super.articleId,
  });

  @override
  State<EvaluationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState
    extends BaseDetailPageState<EvaluationDetailPage> {

  @override
  SubSectionMetaData subSectionMetaData = myContentSectionsData[1]; // Fetch or receive this

  @override
  List<Widget> buildScrollableContent(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Card(
                child: ListTile(
                  title: Text(
                      "Detail Item ${index + 1} for ${subSectionMetaData.title}"),
                ),
              );
            },
            childCount: 20, // Your desired child count
          ),
        ),
      ),
      // Add more slivers specific to EvaluationDetailPage here if needed
    ];
  }

// Optional: Override scroll physics if needed for this specific page
// @override
// ScrollPhysics getScrollPhysics() => const AlwaysScrollableScrollPhysics();
}
