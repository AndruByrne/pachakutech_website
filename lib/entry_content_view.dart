import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart'; // Your proto import
import 'package:url_launcher/url_launcher.dart';

enum EntryContentLayoutStyle {
  staggeredGrid,
  compactLink,
}

StaggeredGridTile _wrapVideoLinkForEntry(String title, String? videoId) {
  if (videoId == null) {
    // Fallback if it's not a video or ID extraction fails
    return _wrapHyperlinkForEntry(
        title, 'https://www.youtube.com/results?search_query=$title');
  }
  return StaggeredGridTile.count(
    crossAxisCellCount: 2,
    mainAxisCellCount: 2,
    child: _hyperlinkedImageForEntry(
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        'https://www.youtube.com/watch?v=$videoId'),
  );
}

StaggeredGridTile _wrapHyperlinkForEntry(String title, String linkUrl) =>
    StaggeredGridTile.count(
      crossAxisCellCount: 2, // Default, can be overridden by specific cards
      mainAxisCellCount: 1, // Default, can be overridden by specific cards
      child: _addHyperlinkForEntry(
          title.split('/'), () => launchUrl(Uri.parse(linkUrl))),
    );

Widget _addHyperlinkForEntry(List<String> titleParts, Function() launch) {
  if (titleParts.isNotEmpty) {
    var indexToLink = titleParts.length > 1 ? 1 : 0;
    return Padding(
      // Add some padding for better text appearance in a grid
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      child: RichText(
          text: TextSpan(
              style: TextStyle(
                // Default text style from theme might be better
                color: Colors
                    .black, // Consider using Theme.of(context).textTheme.bodyMedium?.color
              ),
              children: <TextSpan>[
            ...titleParts.asMap().entries.map((entry) =>
                entry.key == indexToLink
                    ? _wrapAsLinkSpan(entry.value, launch)
                    : _wrapAsBodyTextSpan(entry.value))
          ])),
    );
  }
  return Container(); // Should ideally be SizedBox.shrink() or similar
}

TextSpan _wrapAsLinkSpan(String text, Function() launch) => TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.blue, // Consider Theme.of(context).colorScheme.primary
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()..onTap = () => launch(),
    );

TextSpan _wrapAsBodyTextSpan(String text) =>
    TextSpan(text: '$text '); // Added space for readability

Widget _hyperlinkedImageForEntry(String imgUrl, String linkUrl) => InkWell(
      child: Image.network(
        imgUrl,
        fit: BoxFit.fitWidth, // Ensure image covers the tile appropriately
        errorBuilder: (context, error, stackTrace) =>
            Center(child: Icon(Icons.broken_image)),
      ),
      onTap: () => launchUrl(Uri.parse(linkUrl)),
    );

String? extractVideoId(String url) {
  // Made return type nullable explicitly
  if (!url.contains("youtube.com/") && !url.contains("youtu.be/")) {
    return null;
  }
  Uri uri = Uri.parse(url);
  if (url.contains("youtu.be/")) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else if (url.contains("youtube.com/watch")) {
    return uri.queryParameters['v'];
  } else if (url.contains("youtube.com/embed/")) {
    return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
  }
  return null;
}

class EntryContentView extends StatelessWidget {
  final BlogEntry? blogEntry;
  final int defaultCrossAxisCount;
  final int defaultMainAxisCount;
  final EntryContentLayoutStyle layoutStyle; // New parameter

  const EntryContentView({
    Key? key,
    required this.blogEntry,
    this.defaultCrossAxisCount = 2,
    this.defaultMainAxisCount = 2,
    this.layoutStyle = EntryContentLayoutStyle.staggeredGrid, // Default style
  }) : super(key: key);

  Widget _buildCompactLinkView(
      BuildContext context, BlogEntry_ContentBlock block) {
    // This assumes 'block' has a title and a link.
    // The image might be derived from the link (e.g., YouTube thumbnail).
    final String linkUrl = block.linkUrl;
    final String blockTitle =
        block.hasTitle() ? block.title : linkUrl; // Fallback title

    Widget linkRepresentation;

    // No video, just a generic link icon or placeholder
    linkRepresentation = InkWell(
      onTap: () => launchUrl(Uri.parse(linkUrl)),
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.link, size: 40), // Standard link icon
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      // Important for Column to not take excessive space
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _addHyperlinkForEntry(
                    blockTitle.split('/'), () => launchUrl(Uri.parse(linkUrl))),
              ),
              block.imageUrl.isNotEmpty
                  ? Image.network(block.imageUrl)
                  : linkRepresentation,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (blogEntry == null || blogEntry!.content.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (layoutStyle) {
      // For compact link, we expect usually one content block, or we'll iterate
      // and lay them out as compact link rows.
      case EntryContentLayoutStyle.compactLink:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: blogEntry!.content.map((block) {
            return Padding(
              // Add padding between multiple link items if any
              padding: const EdgeInsets.only(top: 4.0),
              child: _buildCompactLinkView(context, block),
            );
          }).toList(),
        );

      case EntryContentLayoutStyle.staggeredGrid:
        return StaggeredGrid.count(
          crossAxisCount: defaultCrossAxisCount,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            ...blogEntry!.content.map((block) {
              final hasTitle = block.hasTitle() && block.title.isNotEmpty;
              final hasImage = block.hasImageUrl() && block.imageUrl.isNotEmpty;
              final hasLink = block.hasLinkUrl() && block.linkUrl.isNotEmpty;

              if (hasTitle && hasImage && hasLink) {
                return StaggeredGridTile.count(
                  crossAxisCellCount: defaultCrossAxisCount,
                  // Full width of card
                  mainAxisCellCount: 3,
                  // Example
                  child:
                      _hyperlinkedImageForEntry(block.imageUrl, block.linkUrl),
                );
              } else if (hasImage && hasTitle) {
                return StaggeredGridTile.count(
                  crossAxisCellCount: 1,
                  mainAxisCellCount: 3, // Example
                  child: Column(
                    children: [
                      Text(block.title,
                          style: Theme.of(context).textTheme.titleSmall),
                      Expanded(
                          child: Image.network(block.imageUrl,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (cx, err, stack) =>
                                  Text(err.toString()))),
                    ],
                  ),
                );
              } else if (hasTitle && hasLink) {
                final videoId = extractVideoId(block.linkUrl);
                return _wrapVideoLinkForEntry(
                    block.title, videoId); // Uses helper
              } else if (hasImage && hasLink) {
                return StaggeredGridTile.count(
                  crossAxisCellCount: defaultCrossAxisCount,
                  mainAxisCellCount: defaultMainAxisCount,
                  child:
                      _hyperlinkedImageForEntry(block.imageUrl, block.linkUrl),
                );
              } else if (hasImage) {
                return StaggeredGridTile.count(
                  crossAxisCellCount: defaultCrossAxisCount,
                  mainAxisCellCount: defaultMainAxisCount,
                  child: Image.network(block.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (cx, err, stack) => Text(err.toString())),
                );
              } else if (hasTitle) {
                return StaggeredGridTile.fit(
                  // fit for text
                  crossAxisCellCount: defaultCrossAxisCount,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${block.title}',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              }
              return StaggeredGridTile.count(
                crossAxisCellCount: 1,
                mainAxisCellCount: 1,
                child: const Center(child: Text('N/A')),
              );
            }).toList(),
          ],
        );
    }
  }
}
