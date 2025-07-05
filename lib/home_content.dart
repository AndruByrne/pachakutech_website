import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

class SectionData {
  final String title;
  final String imageAsset;

  SectionData({required this.title, required this.imageAsset});
}

final List<SectionData> _myContentSectionsData = [
  SectionData(title: "Education", imageAsset: "assets/education.jpg"),
  SectionData(
      title: "Evaluation & Exploration", imageAsset: "assets/exploration.jpg"),
  SectionData(title: "Elevation", imageAsset: "assets/elevation.jpg"),
  // Add more sections as needed
];

final List<String> partnerLogoPaths = const [
  "assets/google_logo.png",
  "assets/atec_logo.png",
  "assets/hopkins_logo.png",
  "assets/canal_day_logo.png",
];

SliverChildBuilderDelegate mainContentBuilder(double sectionHeight) =>
    SliverChildBuilderDelegate(
          (BuildContext context, int index) {
        final itemIndex = index ~/ 2;

        if (index.isEven) {
          // print("printing for index $index, itemindex $itemIndex and content length ${_myContentSectionsData.length}");
          if (itemIndex > _myContentSectionsData.length) return null;
          if (itemIndex == _myContentSectionsData.length) {
            // print('printing consulting card');
            return ConsultingCard(
              height: sectionHeight,
              titleAlignment: Alignment
                  .bottomLeft, // Example: Main title at bottom-left
            );
          }
          final sectionData = _myContentSectionsData[itemIndex];
          return ContentSectionCard(
            title: sectionData.title,
            imagePath: sectionData.imageAsset,
            height: sectionHeight,
            titleAlignment: Alignment.bottomLeft,
          );
        } else {
          return Divider(
            color: Theme
                .of(context)
                .colorScheme
                .outlineVariant,
            height: 20,
            thickness: 0,
            indent: 16,
            endIndent: 16,
          );
        }
      },
      childCount: ((_myContentSectionsData.length + 1) * 2) - 1,
    );

class PeriodicGradientPainter extends CustomPainter {
  final int itemCount;
  final List<
      Color> waveColors; // Still here, but logic uses fixed colors for now
  // itemWidthFraction is removed as it wasn't actively used in the refined logic

  PeriodicGradientPainter({
    required this.itemCount,
    required this.waveColors,
  }) : assert(waveColors.length >= 3);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    List<Color> gradientColors = [];
    List<double> gradientStops = [];

    final Color grey = Colors.grey[600]!;
    final Color white = Colors.white;
    final Color black = Colors.black;

    gradientColors.add(grey);
    gradientStops.add(0.0);

    if (itemCount <= 0) {
      gradientColors.add(grey);
      gradientStops.add(1.0);
    } else {
      for (int i = 0; i < itemCount; i++) {
        double itemStartStop = (i.toDouble() / itemCount);
        double itemMidStop = itemStartStop + (1.0 / itemCount) * 0.5;
        double itemEndStop = ((i + 1).toDouble() / itemCount);

        if (i % 2 == 0) {
          gradientColors.add(white);
          gradientStops.add(itemMidStop);
        } else {
          gradientColors.add(black);
          gradientStops.add(itemMidStop);
        }
        gradientColors.add(grey);
        gradientStops.add(itemEndStop);
      }
    }

    if (gradientStops.isNotEmpty && gradientStops.last < 1.0) {
      gradientStops.last = 1.0;
    }

    if (gradientColors.length != gradientStops.length) {
      developer.log(
          "Warning: Correcting Gradient colors/stops mismatch. Colors: ${gradientColors
              .length}, Stops: ${gradientStops.length}",
          name: "PeriodicGradientPainter");
      if (gradientColors.length > gradientStops.length &&
          gradientStops.isNotEmpty) {
        gradientColors = gradientColors.sublist(0, gradientStops.length);
      } else if (gradientStops.length > gradientColors.length &&
          gradientColors.isNotEmpty) {
        gradientStops = gradientStops.sublist(0, gradientColors.length);
      }
      if (gradientColors.length < 2 ||
          gradientColors.length != gradientStops.length) {
        developer.log(
            "Fallback: Using default grey gradient due to persistent list mismatch.",
            name: "PeriodicGradientPainter");
        gradientColors = [Colors.grey[600]!, Colors.grey[700]!];
        gradientStops = [0.0, 1.0];
      }
    }

    // developer.log("Final Gradient Colors: $gradientColors", name: "PeriodicGradientPainter");
    // developer.log("Final Gradient Stops: $gradientStops", name: "PeriodicGradientPainter");

    if (gradientColors.length >= 2 &&
        gradientStops.length == gradientColors.length) {
      paint.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        gradientColors,
        gradientStops,
        ui.TileMode.clamp,
      );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else {
      developer.log(
          "Error: Not enough colors/stops or mismatch for gradient. Colors: ${gradientColors
              .length}, Stops: ${gradientStops.length}",
          name: "PeriodicGradientPainter");
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()
        ..color = Colors.grey[800]!);
    }
  }

  @override
  bool shouldRepaint(covariant PeriodicGradientPainter oldDelegate) {
    bool waveColorsChanged = oldDelegate.waveColors.length !=
        waveColors.length ||
        !waveColors
            .asMap()
            .entries
            .every((entry) => entry.value == oldDelegate.waveColors[entry.key]);
    return oldDelegate.itemCount != itemCount || waveColorsChanged;
  }
}

class ConsultingCard extends StatelessWidget {
  final double height;

  // scrimColor is removed as the main title will sit directly on the periodic gradient
  final Alignment titleAlignment;

  const ConsultingCard({
    Key? key,
    required this.height,
    this.titleAlignment = Alignment
        .center, // Default alignment for "Consulting" title
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The periodic gradient will be the base background for the entire card
    Widget periodicGradientBackground = CustomPaint(
      painter: PeriodicGradientPainter(
        itemCount: partnerLogoPaths.length,
        waveColors: [
          // These are passed but painter's internal logic uses fixed colors
          Colors.grey[600]!,
          Colors.white,
          Colors.grey[600]!,
          Colors.black,
          Colors.grey[600]!
        ],
      ),
      child: Container(), // CustomPaint needs a child for sizing
    );

    double overallCardPadding = 16.0;
    // Calculate logo row height. Since "Partners" label is removed,
    // logos can potentially take more vertical space, or be centered differently.
    // Let's make the logo row take a significant portion of the height,
    // and be centered vertically, with the "Consulting" title overlaid.

    // Assuming the "Consulting" title might be at top/bottom/center.
    // The logos should be clearly visible.
    // Let's allocate roughly 50-60% of the card height for the logos, centered.
    double logoRowHeight = height * 0.5; // Adjust as needed
    if (logoRowHeight < 0) logoRowHeight = 0;


    Widget partnerLogosRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: partnerLogoPaths.map((logoPath) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: overallCardPadding / 2),
            // Some horizontal spacing
            child: Image.asset(
              logoPath,
              height: logoRowHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    height: logoRowHeight,
                    color: Colors.grey[300]?.withValues(alpha: 0.5),
                    child: Center(
                        child: Icon(Icons.broken_image,
                            size: logoRowHeight * 0.5, color: Colors
                                .grey[700])),
                  ),
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      height: height,
      // The Stack will manage children fitting to this container's size
      child: Stack(
        fit: StackFit.expand, // Make children expand to fill the Stack
        children: [
          // 1. Periodic Gradient Background - Fills the entire card
          Positioned.fill(
            child: periodicGradientBackground,
          ),

          // 2. Partner Logos Row - Centered on top of the gradient
          // We'll use Align or Center to position the logos row.
          // The "Consulting" title will then be placed according to its alignment.
          Center( // Center the logos row within the available space
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: overallCardPadding),
              // Horizontal padding for the logo row
              child: SizedBox( // Constrain the height of the logo row
                height: logoRowHeight,
                child: partnerLogosRow,
              ),
            ),
          ),


          // 3. Main "Consulting" Title Text - Positioned on top of everything
          Padding(
            padding: EdgeInsets.all(overallCardPadding),
            // Overall padding for the title
            child: Align(
              alignment: titleAlignment,
              child: Text(
                'Consulting',
                textAlign: titleAlignment == Alignment.center
                    ? TextAlign.center
                    : (titleAlignment.x < 0 ? TextAlign.left : TextAlign.right),
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  color: Colors.white, // White text should stand out
                  fontWeight: FontWeight.bold,
                  shadows: [ // Shadow for readability against varying gradient
                    Shadow(
                      blurRadius: 6.0,
                      color: Colors.black.withValues(alpha: 0.7), // Darker shadow
                      offset: Offset(1.0, 1.0),
                    ),
                    Shadow( // Optional lighter glow for pop
                      blurRadius: 8.0,
                      color: Colors.white.withValues(alpha: 0.3),
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContentSectionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final double height;
  final Color scrimColor;
  final Alignment titleAlignment;

  const ContentSectionCard({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.height,
    this.scrimColor = Colors.black54,
    this.titleAlignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Center(
                    child: Icon(Icons.broken_image,
                        size: 50, color: Colors.grey[600])),
              );
            },
          ),
          Container( // Scrim for ContentSectionCard title
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    scrimColor.withValues(alpha: 0.7),
                    scrimColor.withValues(alpha: 0.3)
                  ],
                  begin: titleAlignment.y < -0.5 // More towards top
                      ? Alignment.topCenter
                      : titleAlignment.y > 0.5 // More towards bottom
                      ? Alignment.bottomCenter
                      : Alignment.centerLeft,
                  // Default for center y or side alignments
                  end: titleAlignment.y < -0.5
                      ? Alignment.bottomCenter
                      : titleAlignment.y > 0.5
                      ? Alignment.topCenter
                      : Alignment.centerRight,
                  stops: [0.0, 0.8]), // Scrim falloff
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Align(
              alignment: titleAlignment,
              child: Text(
                title,
                textAlign: titleAlignment == Alignment.center
                    ? TextAlign.center
                    : (titleAlignment.x < 0 ? TextAlign.left : TextAlign.right),
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}