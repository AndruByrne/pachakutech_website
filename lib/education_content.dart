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
    List<BlogEntry> blogEntries,
    List<BlogEntry> linkTreeEntries,
  ) {
    print('EDU_GRID: Building with SliverList for alternating alignment.');

    if (blogEntries.isEmpty && linkTreeEntries.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No educational content available yet.')),
      );
    }

    List<Widget> interleavedItems = [];
    int bIdx = 0;
    int lIdx = 0;
    bool preferLinkNext = true; // Start with link on the left, for example

    // Determine the width factor for the cards
    // You might want this to be a bit less than 1.0 to show the "alignment"
    // e.g., 0.9 means the card takes 90% of the width, and Align positions it.
    // Or, if your cards have internal padding that creates the "space",
    // you could use a widthFactor of 1.0 and let Align do its job.
    // Let's try making the card take up a significant portion, e.g., 80-90%
    // and let Align shift it left or right within the full list item width.
    var pageWidth = MediaQuery.of(context).size.width;
    final double blogCardWidthFactor = pageWidth > 1000
        ? 0.70
        : pageWidth > 900
            ? 0.75
            : pageWidth > 800
                ? .80
                : pageWidth > 700
                    ? .85
                    : pageWidth > 600
                        ? .90
                        : 0.95;
    final double screenWidth = pageWidth;
    // If you want cards to have a max width:
    // final double maxCardWidth = 600.0;
    // final double actualCardWidth = min(screenWidth * blogCardWidthFactor, maxCardWidth);

    final linkCardWidthFactor =
        blogCardWidthFactor * (screenWidth > 933 ? 2 / 3 : 1);

    while (bIdx < blogEntries.length || lIdx < linkTreeEntries.length) {
      if (preferLinkNext && lIdx < linkTreeEntries.length) {
        interleavedItems.add(
          _buildAlignedListItem(
            context: context,
            card: LinkEntryCard(blogEntry: linkTreeEntries[lIdx++]),
            alignment: Alignment.centerLeft,
            widthFactor: linkCardWidthFactor,
            // screenWidth: screenWidth, // If using fixed width + alignment
            // itemWidth: actualCardWidth,  // If using fixed width + alignment
          ),
        );
        if (bIdx < blogEntries.length) preferLinkNext = false;
      } else if (!preferLinkNext && bIdx < blogEntries.length) {
        interleavedItems.add(
          _buildAlignedListItem(
            context: context,
            card: BlogEntryCard(blogEntry: blogEntries[bIdx++]),
            alignment: Alignment.centerRight,
            widthFactor: blogCardWidthFactor,
            // screenWidth: screenWidth,
            // itemWidth: actualCardWidth,
          ),
        );
        if (lIdx < linkTreeEntries.length) preferLinkNext = true;
      } else if (lIdx < linkTreeEntries.length) {
        // Remaining links
        interleavedItems.add(
          _buildAlignedListItem(
            context: context,
            card: LinkEntryCard(blogEntry: linkTreeEntries[lIdx++]),
            alignment: Alignment.centerLeft,
            // Or maintain last preferLinkNext state
            widthFactor: linkCardWidthFactor,
            // screenWidth: screenWidth,
            // itemWidth: actualCardWidth,
          ),
        );
      } else if (bIdx < blogEntries.length) {
        // Remaining blogs
        interleavedItems.add(
          _buildAlignedListItem(
            context: context,
            card: BlogEntryCard(blogEntry: blogEntries[bIdx++]),
            alignment: Alignment.centerRight,
            // Or maintain last preferLinkNext state
            widthFactor: blogCardWidthFactor,
            // screenWidth: screenWidth,
            // itemWidth: actualCardWidth,
          ),
        );
      }
    }

    if (interleavedItems.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No items to display.')),
      );
    }

    // Use SliverList with a delegate
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          // Add some padding around each list item if desired
          return Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 8.0, horizontal: 16.0), // Adjust padding as needed
            child: interleavedItems[index],
          );
        },
        childCount: interleavedItems.length,
      ),
    );
  }

// Helper to build each aligned list item
  Widget _buildAlignedListItem({
    required BuildContext context,
    required Widget card,
    required Alignment alignment,
    required double widthFactor,
    // double? screenWidth, // For fixed width approach
    // double? itemWidth,   // For fixed width approach
  }) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        // Card takes this fraction of the available width
        child: card,
      ),
      // Alternative for fixed width with alignment:
      // child: SizedBox(
      //   width: itemWidth, // Use the calculated fixed width
      //   child: card,
      // ),
    );
  }
}
