import 'package:flutter/material.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';
import 'package:pachakutech_website/widgets/blog_entry_card.dart'; // Assuming you have these
import 'package:pachakutech_website/widgets/link_entry_card.dart'; // Assuming you have these

// Abstract Widget for Blog Content Detail Pages
abstract class BlogContentDetailPage extends BaseDetailPage {
  final AppSection appSection; // Specific app section for this content page

  BlogContentDetailPage({
    super.key,
    required super.db,
    required super.articleId,
    required super.homePageScrollOffset,
    required this.appSection,
  }) : super(appSection: appSection);
}

// Abstract State for Blog Content Detail Pages
abstract class BlogContentDetailPageState<T extends BlogContentDetailPage>
    extends BaseDetailPageState<T> {
  late Future<List<dynamic>> _fetchedContentFuture;
  List<BlogEntry> _blogEntries = [];
  List<BlogEntry> _linkTreeEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchedContentFuture = Future.wait([
      widget.contentRepo.fetchBlogEntries(section: widget.appSection),
      widget.contentRepo.fetchLinkTree(section: widget.appSection),
    ]);
  }

  // Subclasses can override this if they need a different structure
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
    bool preferLinkNext = false; // Start with link on the left, for example

    // Determine the width factor for the cards
    // You might want this to be a bit less than 1.0 to show the "alignment"
    // e.g., 0.9 means the card takes 90% of the width, and Align positions it.
    // Or, if your cards have internal padding that creates the "space",
    // you could use a widthFactor of 1.0 and let Align do its job.
    // Let's try making the card take up a significant portion, e.g., 80-90%
    // and let Align shift it left or right within the full list item width.
    var pageWidth = MediaQuery.of(context).size.width;
    final double blogCardWidthFactor = pageWidth > 750 ? 0.70 : 0.90;
    final double screenWidth = pageWidth;
    // If you want cards to have a max width:
    // final double maxCardWidth = 600.0;
    // final double actualCardWidth = min(screenWidth * blogCardWidthFactor, maxCardWidth);

    final linkCardWidthFactor =
        blogCardWidthFactor * (screenWidth > 966 ? 2 / 3 : 1);

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

  @override
  List<Widget> buildScrollableContent(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: FutureBuilder<List<dynamic>>(
          future: _fetchedContentFuture,
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (asyncSnapshot.hasError) {
              return SliverFillRemaining(
                child: Center(child: Text('Error: ${asyncSnapshot.error}')),
              );
            }
            if (asyncSnapshot.hasData && asyncSnapshot.data!.length == 2) {
              _blogEntries = asyncSnapshot.data![0] as List<BlogEntry>;
              _linkTreeEntries = asyncSnapshot.data![1] as List<BlogEntry>;

              return buildBlogContentGrid(
                  context, _blogEntries, _linkTreeEntries);
            }
            return const SliverFillRemaining(
              child: Center(child: Text('No data loaded.')),
            );
          },
        ),
      ),
    ];
  }

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
