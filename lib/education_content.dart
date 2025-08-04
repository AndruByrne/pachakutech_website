import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Make sure this is imported
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/blog_content_detail_page.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart'; // For BlogEntry type
import 'package:pachakutech_website/widgets/blog_entry_card.dart'; // Assuming path
import 'package:pachakutech_website/widgets/link_entry_card.dart'; // Assuming path

// No need for ContentRepository here if handled by BaseDetailPage, or keep if used elsewhere
// No need for BlogEntryCard or proto here directly if handled by BlogContentDetailPageState

class EducationDetailPage extends BlogContentDetailPage {
  // The appSection is now defined here and passed to the super constructor
  EducationDetailPage({
    super.key,
    required super.db, // db is still needed for BaseDetailPage's ContentRepository
    required super.articleId,
    required super.homePageScrollOffset,
  }) : super(appSection: AppSection.education); // Pass the specific AppSection

  @override
  State<EducationDetailPage> createState() => _EducationDetailPageState();
}

class _EducationDetailPageState
    extends BlogContentDetailPageState<EducationDetailPage> {
  @override
  Widget buildBlogContentGrid(
      BuildContext context,
      List<BlogEntry> blogEntries, // Received from the base class
      List<BlogEntry> linkTreeEntries, // Received from the base class
      ) {
    if (blogEntries.isEmpty && linkTreeEntries.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No educational content available yet.')),
      );
    }

    List<StaggeredGridTile> interleavedTiles = [];
    int bIdx = 0;
    int lIdx = 0;
    bool preferLinkNext = false; // For simple alternation

    // Define a base cross axis count for the grid.
    // Each item will span this entire count, effectively making it a single column
    // where items are aligned left or right.
    // For responsive behavior, you might still want this to be 1 on narrow screens
    // and maybe 2 on wider screens if you want the *alignment effect* to be more pronounced
    // within a two-column base grid (though each tile still spans all logical columns).
    // Let's stick to a simpler "single wide column for alignment" approach first.
    // const int gridInternalColumnCount = 1; // Each tile spans this many "logical" columns.
    // If this is 1, each tile *is* the column.

    // Let's reconsider: If we want the *appearance* of two columns where one item is on left
    // and next is on right, but they don't overlap in height, then a gridCrossAxisCount for
    // SliverAlignedGrid might be 2. Each tile would still be crossAxisCellCount: 2.
    // This part depends on the exact visual you want.

    // Simpler: treat it as a single wide column for items to align within.
    const int effectiveGridColumnCount = 1; // The AlignedGrid will behave like one column.

    // If you wanted a two-column *appearance* where items could be truly side-by-side
    // if short enough, you'd use gridCrossAxisCount: 2 and each tile would be crossAxisCellCount: 1.
    // But for "transparent on one side", making each tile full width is better.

    final double cardWidthFactor = MediaQuery.of(context).size.width > 700 ? 0.65 : 0.90; // Card takes 65% on wide, 90% on narrow

    while (bIdx < blogEntries.length || lIdx < linkTreeEntries.length) {
      if (preferLinkNext && lIdx < linkTreeEntries.length) {
        interleavedTiles.add(
          StaggeredGridTile.extent( // Use .extent for intrinsic height
            crossAxisCellCount: effectiveGridColumnCount, // Span the full effective width
            mainAxisExtent: _calculateCardHeight(context, linkTreeEntries[lIdx], true, cardWidthFactor), // Calculate or estimate height
            child: _buildAlignedTileContent(
              context,
              LinkEntryCard(blogEntry: linkTreeEntries[lIdx++]),
              Alignment.centerLeft,
              cardWidthFactor,
            ),
          ),
        );
        if (bIdx < blogEntries.length) preferLinkNext = false;
      } else if (!preferLinkNext && bIdx < blogEntries.length) {
        interleavedTiles.add(
          StaggeredGridTile.extent(
            crossAxisCellCount: effectiveGridColumnCount,
            mainAxisExtent: _calculateCardHeight(context, blogEntries[bIdx], false, cardWidthFactor),
            child: _buildAlignedTileContent(
              context,
              BlogEntryCard(blogEntry: blogEntries[bIdx++]),
              Alignment.centerRight,
              cardWidthFactor,
            ),
          ),
        );
        if (lIdx < linkTreeEntries.length) preferLinkNext = true;
      } else if (lIdx < linkTreeEntries.length) {
        interleavedTiles.add(
          StaggeredGridTile.extent(
            crossAxisCellCount: effectiveGridColumnCount,
            mainAxisExtent: _calculateCardHeight(context, linkTreeEntries[lIdx], true, cardWidthFactor),
            child: _buildAlignedTileContent(
              context,
              LinkEntryCard(blogEntry: linkTreeEntries[lIdx++]),
              Alignment.centerLeft,
              cardWidthFactor,
            ),
          ),
        );
      } else if (bIdx < blogEntries.length) {
        interleavedTiles.add(
          StaggeredGridTile.extent(
            crossAxisCellCount: effectiveGridColumnCount,
            mainAxisExtent: _calculateCardHeight(context, blogEntries[bIdx], false, cardWidthFactor),
            child: _buildAlignedTileContent(
              context,
              BlogEntryCard(blogEntry: blogEntries[bIdx++]),
              Alignment.centerRight,
              cardWidthFactor,
            ),
          ),
        );
      }
    }

    if (interleavedTiles.isEmpty) { // Should be caught by the first check, but good practice
      return const SliverFillRemaining(
        child: Center(child: Text('No items to display.')),
      );
    }

    // Using SliverAlignedGrid.count means crossAxisCount defines the number of logical columns
    // in the grid. If each tile then spans all these columns, it achieves the full-width tile.
    return SliverAlignedGrid.count(
      crossAxisCount: effectiveGridColumnCount, // Defines the grid's column structure
      mainAxisSpacing: 12.0, // Spacing between tiles vertically
      crossAxisSpacing: 0,   // No horizontal spacing if tiles are full width
      itemBuilder: (context, index) {
        return interleavedTiles[index];
      },
      itemCount: interleavedTiles.length,
    );
  }

  // Helper to build the content that goes inside each StaggeredGridTile
  Widget _buildAlignedTileContent(
      BuildContext context, Widget card, Alignment alignment, double widthFactor) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: card,
      ),
    );
  }

  // Placeholder for height calculation - THIS IS THE TRICKY PART for .extent
  // For StaggeredGridTile.extent, you NEED to provide mainAxisExtent.
  // Calculating this accurately without rendering can be very hard.
  // A simpler alternative is to use StaggeredGridTile.fit(crossAxisCellCount: N, child: YourCard())
  // and let the card determine its own height, but then alignment is harder.
  // OR StaggeredGridTile.count(crossAxisCellCount: N, mainAxisCellCount: M, child: YourCard())
  // where M is an estimate.
  //
  // For now, let's use a rough estimate or make cards have a somewhat fixed aspect ratio.
  // This function would ideally measure the card or use a consistent height.
  double _calculateCardHeight(BuildContext context, BlogEntry entry, bool isLinkEntry, double widthFactor) {
    // This is a VERY ROUGH estimate. You'd need a more robust way if heights vary wildly.
    // Perhaps your cards have a somewhat predictable height based on content?
    // Or you make them have a fixed aspect ratio.
    double screenWidth = MediaQuery.of(context).size.width;
    double cardContentWidth = screenWidth * widthFactor;

    // Example: Assume an aspect ratio for the card content of 3:2 (width:height)
    // This is a big assumption.
    double estimatedHeight = (cardContentWidth * 2.0) / 3.0;

    // Add some padding/margin estimates
    estimatedHeight += 32.0; // For card padding etc.

    // Minimum height
    if (isLinkEntry) {
      return estimatedHeight > 120 ? estimatedHeight : 120;
    } else {
      return estimatedHeight > 180 ? estimatedHeight : 180;
    }
  }
}