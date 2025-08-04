import 'package:flutter/material.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';
import '../entry_content_view.dart'; // Import the new view

class LinkEntryCard extends StatelessWidget {
  final BlogEntry? blogEntry; // Using the same model

  const LinkEntryCard({Key? key, required this.blogEntry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // For LinkEntryCard, maybe we always want a simpler, more compact layout
          // Let's say it's typically used in a narrower column or as a list item.
          final int innerCrossAxisCount = constraints.maxWidth < 350
              ? 1
              : 2; // Different logic

          return Card(
            margin: const EdgeInsets.all(4.0),
            // Maybe LinkEntryCard has different padding or visual treatment
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme
                  .of(context)
                  .colorScheme
                  .outlineVariant, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Different padding
              child: EntryContentView(
                blogEntry: blogEntry,
                // LinkEntryCard might want its internal content to be mostly single column
                defaultCrossAxisCount: innerCrossAxisCount,
                // And maybe items are generally shorter
                defaultMainAxisCount: 1,
              ),
            ),
          );
        }
    );
  }
}