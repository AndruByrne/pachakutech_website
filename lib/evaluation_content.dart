import 'package:flutter/material.dart';
import 'base_detail_page.dart'; // Import the new base class

class EvaluationDetailPage extends BaseDetailPage {
  const EvaluationDetailPage({
    super.key,
    required super.summaryData,
    required super.mainScrollNotifier,
    required super.headerCollapseOffset,
  });

  @override
  State<EvaluationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState
    extends BaseDetailPageState<EvaluationDetailPage> {
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
                      "Detail Item ${index + 1} for ${widget.summaryData.title}"),
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
