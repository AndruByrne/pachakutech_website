import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pachakutech_website/proto/blog_entry.pb.dart';
import 'package:url_launcher/url_launcher.dart';

class BlogEntryCard extends StatelessWidget {
  final BlogEntry? blogEntry;

  const BlogEntryCard({Key? key, required this.blogEntry}) : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => Card(
            margin: const EdgeInsets.all(4.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: StaggeredGrid.count(
                  crossAxisCount: constraints.maxWidth < 600 ? 2 : 4,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: [
                    ...blogEntry?.content
                            .map((block) => switch (block) {
                                  // Case: has title, link and image: link titled image
                                  BlogEntry_ContentBlock(
                                    title: final title,
                                    imageUrl: final imgUrl,
                                    linkUrl: final linkUrl
                                  )
                                      when block.hasTitle() &&
                                          title.isNotEmpty &&
                                          block.hasImageUrl() &&
                                          imgUrl.isNotEmpty &&
                                          block.hasLinkUrl() &&
                                          linkUrl.isNotEmpty =>
                                    StaggeredGridTile.count(
                                        crossAxisCellCount: 2,
                                        mainAxisCellCount: 3,
                                        child: InkWell(
                                          child: Column(
                                            children: [
                                              Image.network(imgUrl),
                                            ],
                                          ),
                                          onTap: () =>
                                              launchUrl(Uri.parse(linkUrl)),
                                        )),
                                  // Case: has image and title
                                  BlogEntry_ContentBlock(
                                    imageUrl: final imgUrl,
                                    title: final title
                                  )
                                      when block.hasImageUrl() &&
                                          imgUrl.isNotEmpty &&
                                          block.hasTitle() &&
                                          title.isNotEmpty =>
                                    StaggeredGridTile.count(
                                        crossAxisCellCount: 1,
                                        mainAxisCellCount: 3,
                                        child: Column(
                                          children: [
                                            Text(title),
                                            Image.network(imgUrl,
                                                errorBuilder:
                                                    (cx, err, stack) =>
                                                        Text(err.toString())),
                                          ],
                                        )),
                                  // Case: has title and link, no image: hyperlink or media link
                                  BlogEntry_ContentBlock(
                                    title: final title,
                                    linkUrl: final linkUrl
                                  )
                                      when block.hasTitle() &&
                                          title.isNotEmpty &&
                                          block.hasLinkUrl() &&
                                          linkUrl.isNotEmpty =>
                                    _wrapVideoLink(title, extractVideoId(linkUrl)) ??
                                        _wrapHyperlink(title, linkUrl),
                                  // Case: has image and link, no title (link image)
                                  BlogEntry_ContentBlock(
                                    imageUrl: final imgUrl,
                                    linkUrl: final linkUrl
                                  )
                                      when block.hasImageUrl() &&
                                          imgUrl.isNotEmpty &&
                                          block.hasLinkUrl() &&
                                          linkUrl.isNotEmpty =>
                                    StaggeredGridTile.count(
                                        crossAxisCellCount: 2,
                                        mainAxisCellCount: 2,
                                        child:
                                            _hyperlinkedImage(imgUrl, linkUrl)),
                                  // Case: image only
                                  BlogEntry_ContentBlock(imageUrl: final imgUrl)
                                      when block.hasImageUrl() &&
                                          imgUrl.isNotEmpty =>
                                    StaggeredGridTile.count(
                                      crossAxisCellCount: 2,
                                      mainAxisCellCount: 2,
                                      child: Image.network(imgUrl),
                                    ),
                                  // Case: title (text) only
                                  BlogEntry_ContentBlock(title: final title)
                                      when block.hasTitle() &&
                                          title.isNotEmpty =>
                                    StaggeredGridTile.fit(
                                      crossAxisCellCount: 1,
                                      child: Text('title ONLY: $title'),
                                    ),
                                  // Default case
                                  _ => StaggeredGridTile.count(
                                      crossAxisCellCount: 1,
                                      mainAxisCellCount: 1,
                                      child: Text('Unknown block type')),
                                })
                            .toList() ??
                        []
                  ]),
            ),
          ));

  StaggeredGridTile _wrapHyperlink(String title, String linkUrl) =>
      StaggeredGridTile.count(
        crossAxisCellCount: 2,
        mainAxisCellCount: 1,
        child: _addHyperlink(
            title.split('/'), () => launchUrl(Uri.parse(linkUrl))),
      );
}

_wrapVideoLink(title, extractVideoId) => extractVideoId == null
    ? null
    : StaggeredGridTile.count(
        crossAxisCellCount: 2,
        mainAxisCellCount: 2,
        child: _hyperlinkedImage(
            'https://img.youtube.com/vi/$extractVideoId/hqdefault.jpg',
            'https://www.youtube.com/watch?v=$extractVideoId'));

_addHyperlink(List<String> title, Function() launch) {
  if (title.isNotEmpty) {
    var indextoLink = title.length > 1 ? 1 : 0;
    return RichText(
        text: TextSpan(children: <TextSpan>[
          ...title.asMap().entries.map((entry) => entry.key == indextoLink
              ? wrapAsLink(entry.value, launch)
              : wrapAsBodyTextSpan(entry.value))
        ]),
        selectionColor: const Color(0xAF6694e8));
  } else {
    return Container();
  }
}

wrapAsLink(String text, Function() launch) => TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
      recognizer: TapGestureRecognizer()..onTap = () => launch(),
    );

wrapAsBodyTextSpan(String text) =>
    TextSpan(text: text, style: TextStyle(color: Colors.black));

InkWell _hyperlinkedImage(String imgUrl, String linkUrl) => InkWell(
      child: Column(
        children: [
          Image.network(imgUrl),
        ],
      ),
      onTap: () => launchUrl(Uri.parse(linkUrl)),
    );

// Only extracts YouTube ID's all other urls return null
extractVideoId(String url) {
  if (!url.contains("youtube.com/") && !url.contains("youtu.be/")) {
    return null; // Not a YouTube URL
  }

  Uri uri = Uri.parse(url);
  if (url.contains("youtu.be/")) {
    // Format: https://youtu.be/VIDEO_ID
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else if (url.contains("youtube.com/watch")) {
    // Format: https://www.youtube.com/watch?v=VIDEO_ID
    return uri.queryParameters['v'];
  } else if (url.contains("youtube.com/embed/")) {
    // Format: https://www.youtube.com/embed/VIDEO_ID
    return uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
  }
  return null; // Add more parsing rules if needed for other URL formats
}
