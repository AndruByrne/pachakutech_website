import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // For Future<void>

// Library-private Enum
enum _MediaType {
  audio,
  video,
  image,
  pdfLink,
  externalWebLink,
  unsupported,
}

// Library-private Helper Class
class _MediaHelper {
  static _MediaType getMediaType(String url) {
    if (url.isEmpty) return _MediaType.unsupported;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.path.isEmpty) return _MediaType.unsupported;

    String path = uri.path.toLowerCase();
    if (path.endsWith('.mp3') || path.endsWith('.wav') ||
        path.endsWith('.ogg')) {
      return _MediaType.audio;
    } else if (path.endsWith('.mp4') || path.endsWith('.webm') ||
        path.endsWith('.mov')) {
      return _MediaType.video;
    } else if (path.endsWith('.jpg') || path.endsWith('.jpeg') ||
        path.endsWith('.png') || path.endsWith('.gif') ||
        path.endsWith('.webp')) {
      return _MediaType.image;
    } else if (path.endsWith('.pdf')) {
      return _MediaType.pdfLink;
    } else if (uri.scheme.startsWith('http')) {
      return _MediaType.externalWebLink;
    }
    return _MediaType.unsupported;
  }
}

// Public Widget - This is the only thing intended for use outside this library file.
class MediaPlayerWidget extends StatefulWidget {
  final String mediaUrl;
  final bool isVisited;
  final Function(String)? onLinkClicked;

  const MediaPlayerWidget({
    super.key,
    required this.mediaUrl,
    this.isVisited = false,
    this.onLinkClicked,
  });

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  VideoPlayerController? _videoController;
  _MediaType _mediaType = _MediaType.unsupported; // Uses the private enum

  @override
  void initState() {
    super.initState();
    // Uses the private helper and private enum
    _mediaType = _MediaHelper.getMediaType(widget.mediaUrl);

    if (_mediaType == _MediaType.audio || _mediaType == _MediaType.video) {
      _videoController =
      VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        }).catchError((error) {
          if (mounted) {
            print("Error initializing video/audio player for ${widget
                .mediaUrl}: $error");
            setState(() {
              _mediaType = _MediaType.unsupported;
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    widget.onLinkClicked?.call(url);
    if (!await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank')) {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_mediaType) { // Uses the private enum
      case _MediaType.audio:
      // ... implementation ...
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Column(/* ... */);
        } else if (_videoController?.value.hasError ?? false) {
          return _buildLinkFallback("Error loading audio: ${Uri
              .parse(widget.mediaUrl)
              .pathSegments
              .lastOrNull ?? widget.mediaUrl}");
        }
        return const Center(child: CircularProgressIndicator());

      case _MediaType.video:
      // ... implementation ...
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Column(/* ... */);
        } else if (_videoController?.value.hasError ?? false) {
          return _buildLinkFallback("Error loading video: ${Uri
              .parse(widget.mediaUrl)
              .pathSegments
              .lastOrNull ?? widget.mediaUrl}");
        }
        return const Center(child: CircularProgressIndicator());

      case _MediaType.image:
        return CachedNetworkImage(
          imageUrl: widget.mediaUrl,
          placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              _buildLinkFallback("Image: ${Uri
                  .parse(url)
                  .pathSegments
                  .lastOrNull ?? widget.mediaUrl}"),
          fit: BoxFit.contain,
        );

      case _MediaType.pdfLink:
      case _MediaType.externalWebLink:
        return _buildLinkFallback(widget.mediaUrl);

      case _MediaType.unsupported:
      default:
        if (widget.mediaUrl.startsWith('http')) {
          return _buildLinkFallback("Link: ${widget.mediaUrl}");
        }
        return Text("Unsupported media or invalid URL: ${widget.mediaUrl}",
            style: TextStyle(color: Colors.grey));
    }
  }

  Widget _buildLinkFallback(String displayText) {
    bool isPotentiallyVeryLongUrl = displayText.startsWith('http') &&
        displayText.length > 80;
    // Heuristic for making a display string for very long URLs
    String displayUrlText = isPotentiallyVeryLongUrl &&
        displayText.contains('/')
        ? Uri
        .parse(displayText)
        .host + Uri
        .parse(displayText)
        .path
        .split('/')
        .lastWhere((s) => s.isNotEmpty, orElse: () => displayText)
        : displayText;
    if (displayUrlText.length > 60 && displayUrlText.contains(
        '?')) { // if it still has params, try to shorten
      displayUrlText = displayUrlText.substring(0, displayUrlText.indexOf('?'));
    }
    if (displayUrlText.length > 60) { // if it's still too long, truncate
      displayUrlText =
      '${displayUrlText.substring(0, 35)}...${displayUrlText.substring(
          displayUrlText.length - 15)}';
    }


    return InkWell(
      onTap: () => _launchUrl(widget.mediaUrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          displayUrlText,
          style: TextStyle(
            color: widget.isVisited ? Colors.purple : Colors.blue,
            decoration: TextDecoration.underline,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}