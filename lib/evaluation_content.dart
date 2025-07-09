import 'package:flutter/material.dart';
import 'home_content.dart';

class EvaluationDetailPage extends StatefulWidget {
  final SummarySectionData summaryData;
  final ValueNotifier<double> mainScrollNotifier; // Accept the notifier
  final double headerCollapseOffset;

  const EvaluationDetailPage({
    super.key,
    required this.summaryData,
    required this.mainScrollNotifier,
    required this.headerCollapseOffset,
  });

  @override
  State<EvaluationDetailPage> createState() => _EvaluationDetailPageState();
}

class _EvaluationDetailPageState extends State<EvaluationDetailPage> {
  // Optional: Controller for the detail page's internal scroll
  // final ScrollController _internalScrollController = ScrollController();

  @override
  void dispose() {
    // _internalScrollController.dispose(); // Don't forget to dispose if you use it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.mainScrollNotifier,
      builder: (context, mainPageGlobalScrollOffset, child) {
        // --- Parallax Calculation for Detail Page Background (driven by main page scroll) ---
        double detailPageEffectiveScroll =
            (mainPageGlobalScrollOffset - widget.headerCollapseOffset)
                .clamp(0.0, double.infinity);
        double parallaxFactor = 0.4;
        double backgroundScrollOffsetForDetailPage =
            detailPageEffectiveScroll * parallaxFactor;

        double detailViewHeight =
            (context.findRenderObject() as RenderBox?)?.size.height ??
                MediaQuery.of(context).size.height;
        double parallaxTravel = detailViewHeight * parallaxFactor;
        // --- End of Parallax Calculation ---

        return Scaffold(
          body: Stack(
            children: [
              // --- Parallax Background ---
              Positioned(
                top: -backgroundScrollOffsetForDetailPage,
                left: 0,
                right: 0,
                height: detailViewHeight + parallaxTravel + 50,
                child: Hero(
                  tag: heroTag_background_prefix + widget.summaryData.id,
                  child: Image.asset(
                    widget.summaryData.imageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),

              // --- Scrollable Detail Content ---
              CustomScrollView(
                // controller: _internalScrollController, // Assign if using
                // MODIFIED: Enable scrolling and remove shrinkWrap
                physics: const ClampingScrollPhysics(),
                // Or AlwaysScrollableScrollPhysics()
                // shrinkWrap: false, // Default is false, usually what you want when scrolling
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0), // Restore padding
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
                        childCount: 20, // Restore your desired child count
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

const String heroTag_background_prefix = "detail_background_";
