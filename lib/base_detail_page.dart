import 'package:flutter/material.dart';
import 'home_content.dart'; // Assuming SummarySectionData is here

// Define a common prefix for Hero tags if not already globally available
const String heroTag_detail_background_prefix = "detail_background_";

abstract class BaseDetailPage extends StatefulWidget {
  final SummarySectionData summaryData;
  final ValueNotifier<double> mainScrollNotifier;
  final double headerCollapseOffset;

  const BaseDetailPage({
    super.key,
    required this.summaryData,
    required this.mainScrollNotifier,
    required this.headerCollapseOffset,
  });
}

abstract class BaseDetailPageState<T extends BaseDetailPage> extends State<T> {
  // Optional: Common internal scroll controller if needed by many subclasses
  final ScrollController _internalScrollController = ScrollController();

  @override
  void dispose() {
    // internalScrollController.dispose();
    super.dispose();
  }

  // Abstract method for subclasses to provide their specific scrollable content (slivers)
  List<Widget> buildScrollableContent(BuildContext context);

  // Optional: Subclasses might want to customize physics
  ScrollPhysics getScrollPhysics() => const ClampingScrollPhysics();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.mainScrollNotifier,
      builder: (context, mainPageGlobalScrollOffset, child) {
        // --- Parallax Calculation for Detail Page Background (driven by main page scroll) ---
        double detailPageEffectiveScroll =
        (mainPageGlobalScrollOffset - widget.headerCollapseOffset)
            .clamp(0.0, double.infinity);
        double parallaxFactor = 0.4; // Common parallax factor
        double backgroundScrollOffsetForDetailPage =
            detailPageEffectiveScroll * parallaxFactor;

        // Attempt to get the rendered height of this widget for parallax calculation
        // Fallback to screen height if RenderBox not available yet (e.g., during first build)
        final renderBox = context.findRenderObject() as RenderBox?;
        double detailViewHeight = renderBox?.hasSize == true
            ? renderBox!.size.height
            : MediaQuery
            .of(context)
            .size
            .height;

        double parallaxTravel = detailViewHeight * parallaxFactor;
        // --- End of Parallax Calculation ---

        return Scaffold(
          // backgroundColor: Colors.transparent, // Consider if all detail pages need this
          body: Stack(
            children: [
              // --- Parallax Background ---
              Positioned(
                top: -backgroundScrollOffsetForDetailPage,
                left: 0,
                right: 0,
                // Ensure height is sufficient for the image and its travel
                height: detailViewHeight + parallaxTravel + 50,
                // Added buffer
                child: Hero(
                  tag: heroTag_detail_background_prefix + widget.summaryData.id,
                  child: Image.asset(
                    widget.summaryData.imageAsset,
                    // Ensure imageAsset is part of SummarySectionData
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),

              // --- Scrollable Detail Content (provided by subclass) ---
              // Optional: Add Scrollbar if content is always scrollable
              Scrollbar(
                controller: _internalScrollController,
                child: CustomScrollView(
                  controller: _internalScrollController,
                  physics: getScrollPhysics(),
                  slivers: buildScrollableContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}