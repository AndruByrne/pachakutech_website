// blog_content_detail_page.dart (NEW FILE)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // For the improved grid
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
  });
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
      widget.contentRepo.fetchBlogEntries(appSection: widget.appSection),
      widget.contentRepo.fetchLinkTree(appSection: widget.appSection),
    ]);
  }

  // Subclasses can override this if they need a different structure
  Widget buildBlogContentGrid(
    BuildContext context,
    List<BlogEntry> blogEntries,
    List<BlogEntry> linkTreeEntries,
  ) {
    var crossAxisCount = MediaQuery.of(context).size.width > 700 ? 2 : 1;

    List<Widget> items = [];
    int maxLength = max(blogEntries.length, linkTreeEntries.length);

    for (int i = 0; i < maxLength; i++) {
      if (i < linkTreeEntries.length) {
        items.add(LinkEntryCard(blogEntry: linkTreeEntries[i]));
      }
      if (i < blogEntries.length) {
        items.add(BlogEntryCard(blogEntry: blogEntries[i]));
      }
    }

    if (items.isEmpty) {
      return SliverFillRemaining(
        child: Center(
            child:
                Text('No content available for ${widget.appSection.title}.')),
      );
    }

    return SliverMasonryGrid.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      itemBuilder: (context, index) {
        return items[index];
      },
      childCount: items.length,
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
  Future<String> get titleCopy =>
      widget.contentRepo.fetchSectionIntros().then((intros) =>
          intros[widget.appSection.id] ??
          'Welcome to ${widget.appSection.title}');
}
