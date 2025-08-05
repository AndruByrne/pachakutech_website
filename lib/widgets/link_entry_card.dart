// link_entry_card.dart

import 'package:flutter/material.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';
import '../entry_content_view.dart'; // Import the new view

class LinkEntryCard extends StatelessWidget {
  final BlogEntry? blogEntry;

  const LinkEntryCard({Key? key, required this.blogEntry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool useCompactStyle = true; // most links should be compact
    if (blogEntry != null && blogEntry!.content.isNotEmpty) {
      if (
          blogEntry!.content.first.hasLinkUrl() &&
          blogEntry!.content.first.linkUrl.isNotEmpty &&
          (extractVideoId(blogEntry!.content.first.linkUrl) != null)
      ) { // is a video link
        useCompactStyle = false;
      } else if (blogEntry!.content.every((block) =>
      block.hasLinkUrl() && block.linkUrl.isNotEmpty)) {
        // If ALL blocks are links, use compact style.
        useCompactStyle = true;
      }
    }

    return Card(
      margin: const EdgeInsets.all(4.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme
            .of(context)
            .colorScheme
            .outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        // Slightly more padding for compact view
        child: EntryContentView(
          blogEntry: blogEntry,
          layoutStyle: useCompactStyle
              ? EntryContentLayoutStyle.compactLink
              : EntryContentLayoutStyle.staggeredGrid,
          // defaults for grid layout
          defaultCrossAxisCount: 2,
          defaultMainAxisCount: 2,
        ),
      ),
    );
  }
}