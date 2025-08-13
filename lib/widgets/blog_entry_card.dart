import 'package:flutter/material.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';
import '../entry_content_view.dart';

class BlogEntryCard extends StatelessWidget {
  final BlogEntry? blogEntry;

  const BlogEntryCard({Key? key, required this.blogEntry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder( // LayoutBuilder here is good!
        builder: (context, constraints) {
          // Determine the crossAxisCount for the inner grid based on the card's available width
          final int innerCrossAxisCount = constraints.maxWidth < 600 ? 2 : 4;

          return Card(
            color: Colors.black38,
            margin: const EdgeInsets.all(4.0),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme
                  .of(context)
                  .colorScheme
                  .outlineVariant, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: EntryContentView(
                blogEntry: blogEntry,
                defaultCrossAxisCount: innerCrossAxisCount,
              ),
            ),
          );
        }
    );
  }
}