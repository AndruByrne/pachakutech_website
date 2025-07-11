import 'package:flutter/material.dart';
import 'home_content.dart';
import 'hero_util.dart';

abstract class BaseDetailPage extends StatefulWidget {
  final String articleId;

  const BaseDetailPage({
    super.key,
    required this.articleId,
  });
}

abstract class BaseDetailPageState<T extends BaseDetailPage> extends State<T> {
  // Optional: Common internal scroll controller if needed by many subclasses
  final ScrollController _internalScrollController = ScrollController();
  abstract SubSectionMetaData subSectionMetaData; // Fetch or receive this
  // Potentially a ValueNotifier for its own scroll offset if needed for internal parallax
  late ValueNotifier<double> _detailPageScrollNotifier;

  @override
  void dispose() {
    _internalScrollController.dispose();
    _detailPageScrollNotifier.dispose();
    super.dispose();
  }

  // Abstract method for subclasses to provide their specific scrollable content (slivers)
  List<Widget> buildScrollableContent(BuildContext context);

  // Optional: Subclasses might want to customize physics
  ScrollPhysics getScrollPhysics() => const ClampingScrollPhysics();


  @override
  void initState() {
    super.initState();
    _detailPageScrollNotifier = ValueNotifier<double>(0.0);
    _internalScrollController.addListener(() {
      _detailPageScrollNotifier.value = _internalScrollController.offset;
    });
  }



  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
          // backgroundColor: Colors.transparent, // Consider if all detail pages need this
          body: Stack(
            children: [
              // --- Parallax Background ---
                Positioned.fill(
                  child: Hero(
                    tag: heroTag + subSectionMetaData.id,
                    createRectTween: (Rect? begin, Rect? end) {
                      print("Destination Hero (${subSectionMetaData.id}): CREATE_RECT_TWEEN");
                      print("  HERO-PROVIDED Begin Rect: $begin");
                      print("  HERO-PROVIDED End Rect: $end");
                      return CenterExpansionRectTween(begin: begin, end: end);
                    },
                    child: Image.asset(
                      subSectionMetaData.imageAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),

              // --- Scrollable Detail Content (provided by subclass) ---
              // Optional: Add Scrollbar if content is always scrollable
                CustomScrollView(
                  controller: _internalScrollController,
                  physics: getScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      title: Text(subSectionMetaData.title), // Or your dot logo
                      leading: canPop ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new), // Or your preferred back icon
                        onPressed: () => _handleCustomBackNavigation(context),
                      ) : null,
                      backgroundColor: Theme.of(context).colorScheme.secondary, // Collapsed header color
                      pinned: true, // Keeps it visible at the top
                      // floating: true, // If you want it to reappear quickly on scroll up
                      // snap: true, // Only with floating: true
                    ),
                    ...buildScrollableContent(context),
                  ],
                ),
            ],
          ),
        );
  }
  void _handleCustomBackNavigation(BuildContext context) {
    // For now, just a standard pop. We'll enhance this.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
