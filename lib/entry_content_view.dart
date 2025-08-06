import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart'; // Your proto import
import 'package:url_launcher/url_launcher.dart';

enum EntryContentLayoutStyle {
  staggeredGrid,
  compactLink,
}

StaggeredGridTile _wrapVideoLinkForEntry(String title, TextTheme textTheme,
    String? videoId) {
  if (videoId == null) {
    // Fallback if it's not a video or ID extraction fails
    return _wrapHyperlinkForEntry(
        title, textTheme,
        'https://www.youtube.com/results?search_query=$title');
  }
  return StaggeredGridTile.count(
    crossAxisCellCount: 2,
    mainAxisCellCount: 2,
    child: _hyperlinkedImageForEntry(
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        'https://www.youtube.com/watch?v=$videoId'),
  );
}

StaggeredGridTile _wrapHyperlinkForEntry(String title, TextTheme textTheme,
    String linkUrl) =>
    StaggeredGridTile.count(
      crossAxisCellCount: 1, // Default, can be overridden by specific cards
      mainAxisCellCount: 1, // Default, can be overridden by specific cards
      child: _addHyperlinkForEntry(
          title.split('/'), textTheme, () => launchUrl(Uri.parse(linkUrl))),
    );

Widget _addHyperlinkForEntry(List<String> titleParts, TextTheme textTheme,
    Function() launch) {
  if (titleParts.isNotEmpty) {
    var indexToLink = titleParts.length > 1 ? 1 : 0;
    return Padding(
      // Add some padding for better text appearance in a grid
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      child: RichText(
          text: TextSpan(style: textTheme.bodyMedium, children: <TextSpan>[
            ...titleParts
                .asMap()
                .entries
                .map((entry) =>
            entry.key == indexToLink
                ? _wrapAsLinkSpan(entry.value, launch)
                : _wrapAsBodyTextSpan(entry.value))
          ])),
    );
  }
  return Container(); // Should ideally be SizedBox.shrink() or similar
}

TextSpan _wrapAsLinkSpan(String text, Function() launch) =>
    TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () => launch(),
    );

TextSpan _wrapAsBodyTextSpan(String text) =>
    TextSpan(text: '$text '); // Added space for readability

Widget _hyperlinkedImageForEntry(String imgUrl, String linkUrl) =>
    InkWell(
      child: Image.network(
        imgUrl,
        fit: BoxFit.fitWidth,
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

  Widget _buildCompactLinkView(BuildContext context,
      BlogEntry_ContentBlock block) {
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
                    blockTitle.split('/'),
                    Theme
                        .of(context)
                        .textTheme,
                        () => launchUrl(Uri.parse(linkUrl))),
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

  Widget _buildStaggeredTileContent_TitleImageLink(BuildContext context,
      BlogEntry_ContentBlock block) {
    return Stack(
      alignment: Alignment.center,
      // Default alignment for non-positioned children
      children: [
        // Base Image (takes up the full space of the Stack by default)
        _hyperlinkedImageForEntry(block.imageUrl, block.linkUrl),

        // Positioned Title Overlay
        Positioned(
          top: 8.0, // Adjust spacing from the top
          left: 8.0, // Add some horizontal padding from the edges
          right: 8.0, // Add some horizontal padding from the edges
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6), // Semi-transparent black
              borderRadius: BorderRadius.circular(
                  8.0), // Optional: rounded corners
            ),
            child: Text(
              block.title,
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                color: Colors
                    .white, // Ensure title text is visible on dark background
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Optional: Limit title lines
              overflow: TextOverflow.ellipsis, // Optional: Handle long titles
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaggeredTileContent_ImageTitle(BuildContext context,
      BlogEntry_ContentBlock block) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            block.title,
            style: Theme
                .of(context)
                .textTheme
                .titleSmall,
            textAlign: TextAlign.center,
          ),
        ),
        // Image without link in this specific original branch
        Image.network(
          block.imageUrl,
          fit: BoxFit.fitWidth,
          errorBuilder: (cx, err, stack) => Text(err.toString()),
        ),
      ],
    );
  }

// Consider if _wrapHyperlinkForEntry and _wrapVideoLinkForEntry
// should return Widgets instead of StaggeredGridTiles,
// and then _buildStaggeredGridTileForBlock wraps them in the appropriate tile.
// For now, let's keep them as they are if they define their own tile structure.

  StaggeredGridTile _buildStaggeredGridTileForBlock(BuildContext context,
      BlogEntry_ContentBlock block) {
    final hasTitle = block.hasTitle() && block.title.isNotEmpty;
    final hasImage = block.hasImageUrl() && block.imageUrl.isNotEmpty;
    final hasLink = block.hasLinkUrl() && block.linkUrl.isNotEmpty;

    // Case 1: Title, Image, and Link
    if (hasTitle && hasImage && hasLink) {
      return StaggeredGridTile.fit(
        crossAxisCellCount: defaultCrossAxisCount,
        child: _buildStaggeredTileContent_TitleImageLink(context, block),
      );
    }
    // Case 2: Image and Title (original logic had specific cell counts)
    else if (hasImage && hasTitle) {
      return StaggeredGridTile.fit(
        crossAxisCellCount: 1, // Or defaultCrossAxisCount if it should be wider
        child: _buildStaggeredTileContent_ImageTitle(context, block),
      );
    }
    // Case 3: Title and Link (Video or simple link)
    else if (hasTitle && hasLink) {
      final videoId = extractVideoId(block.linkUrl);
      if (videoId != null) {
        // _wrapVideoLinkForEntry already returns a StaggeredGridTile
        return _wrapVideoLinkForEntry(
            block.title,
            Theme
                .of(context)
                .textTheme,
            videoId);
      } else {
        // _wrapHyperlinkForEntry already returns a StaggeredGridTile
        return _wrapHyperlinkForEntry(
            block.title,
            Theme
                .of(context)
                .textTheme,
            block.linkUrl);
      }
    }
    // Case 4: Image and Link (No Title)
    else if (hasImage && hasLink) {
      return StaggeredGridTile.fit(
        crossAxisCellCount: defaultCrossAxisCount,
        child: _hyperlinkedImageForEntry(block.imageUrl, block.linkUrl),
      );
    }
    // Case 5: Image Only
    else if (hasImage) {
      return StaggeredGridTile.fit(
        // Assuming you want image to define height
        crossAxisCellCount: defaultCrossAxisCount,
        child: Image.network(
          block.imageUrl,
          fit: BoxFit.fitWidth,
          errorBuilder: (cx, err, stack) => Text(err.toString()),
        ),
      );
    }
    // Case 6: Title Only
    else if (hasTitle) {
      return StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            block.title,
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge,
          ),
        ),
      );
    }

    // Fallback for empty or unrecognized block
    return StaggeredGridTile.count(
      crossAxisCellCount: 1,
      mainAxisCellCount: 1,
      child: const Center(child: Text('N/A')),
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
          crossAxisCount: defaultCrossAxisCount, // This is passed to the grid
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: blogEntry!.content
              .map((block) => _buildStaggeredGridTileForBlock(context, block))
              .toList(),
        );
    }
  }
}
