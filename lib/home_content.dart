import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:developer' as developer;

final String heroTag = "detail_background_image_";

typedef OnCardTap = void Function(SummarySectionData summaryData);

SliverChildBuilderDelegate mainContentBuilder(
        double sectionHeight, OnCardTap onCardTap) =>
    SliverChildBuilderDelegate(
      (BuildContext context, int index) {
        final itemIndex = index ~/ 2;
        final bool isConsultingCard =
            itemIndex == _myContentSectionsData.length;

        // Determine textAlign for CardTitle based on titleAlignment for the card
        // Assuming titleAlignment.x < 0 is left, titleAlignment.x > 0 is right, else center
        TextAlign titleTextAlign;
        Alignment cardTitleAlignment; // Alignment for the whole card

        if (isConsultingCard) {
          cardTitleAlignment =
              Alignment.bottomLeft; // As specified for ConsultingCard
        } else {
          cardTitleAlignment =
              Alignment.bottomLeft; // As specified for ContentSectionCard
        }

        if (cardTitleAlignment.x < -0.1) {
          // Allowing for some tolerance around 0 for center
          titleTextAlign = TextAlign.left;
        } else if (cardTitleAlignment.x > 0.1) {
          titleTextAlign = TextAlign.right;
        } else {
          titleTextAlign = TextAlign.center;
        }

        if (index.isOdd) {
          if (itemIndex > _myContentSectionsData.length) return null;

          if (isConsultingCard) {
            final consultingTitleWidget = CardTitle(
              text: 'Consulting',
              textAlign: titleTextAlign,
            );
            return ConsultingCard(
              height: sectionHeight,
              titleAlignment: cardTitleAlignment,
              titleWidget: consultingTitleWidget, // Pass the widget
            );
          }

          final summaryData = _myContentSectionsData[itemIndex];
          final contentTitleWidget = CardTitle(
            text: summaryData.title,
            textAlign: titleTextAlign,
          );
          return ContentSectionCard(
            // title: summaryData.title, // REMOVED
            titleWidget: contentTitleWidget,
            // Pass the widget
            imagePath: summaryData.imageAsset,
            height: sectionHeight,
            titleAlignment: cardTitleAlignment,
            onTap: () => onCardTap(summaryData),
            id: summaryData.id,
          );
        } else {
          return SizedBox(height: kToolbarHeight);
        }
      },
      childCount: ((_myContentSectionsData.length + 1) * 2),
    );

class PeriodicGradientPainter extends CustomPainter {
  final int itemCount;
  final List<Color>
      waveColors; // Still here, but logic uses fixed colors for now
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
          "Warning: Correcting Gradient colors/stops mismatch. Colors: ${gradientColors.length}, Stops: ${gradientStops.length}",
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
          "Error: Not enough colors/stops or mismatch for gradient. Colors: ${gradientColors.length}, Stops: ${gradientStops.length}",
          name: "PeriodicGradientPainter");
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
          Paint()..color = Colors.grey[800]!);
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
  final Alignment titleAlignment;
  final Widget titleWidget; // ADDED

  const ConsultingCard({
    super.key,
    required this.height,
    required this.titleWidget, // ADDED
    this.titleAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    Widget periodicGradientBackground = CustomPaint(
      painter: PeriodicGradientPainter(
        itemCount: partnerLogoPaths.length,
        waveColors: [
          Colors.grey[600]!,
          Colors.white,
          Colors.grey[600]!,
          Colors.black,
          Colors.grey[600]!
        ],
      ),
      child: Container(),
    );

    double overallCardPadding = 16.0;
    double logoRowHeight = height * 0.5;
    if (logoRowHeight < 0) logoRowHeight = 0;

    Widget partnerLogosRow = Row(
      // ... (partnerLogosRow remains the same)
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: partnerLogoPaths.map((logoPath) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: overallCardPadding / 2),
            child: Image.asset(
              logoPath,
              height: logoRowHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: logoRowHeight,
                color: Colors.grey[300]?.withValues(alpha: 0.5),
                child: Center(
                    child: Icon(Icons.broken_image,
                        size: logoRowHeight * 0.5, color: Colors.grey[700])),
              ),
            ),
          ),
        );
      }).toList(),
    );

    return Container(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: periodicGradientBackground,
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: overallCardPadding),
              child: SizedBox(
                height: logoRowHeight,
                child: partnerLogosRow,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(overallCardPadding),
            // Use overallCardPadding
            child: Align(
              alignment: titleAlignment,
              // child: Text( // REMOVED
              //   'Consulting',
              //   ...
              // ),
              child: titleWidget, // ADDED
            ),
          ),
        ],
      ),
    );
  }
}

class ContentSectionCard extends StatelessWidget {
  final String imagePath;
  final double height;
  final VoidCallback onTap;
  final Color scrimColor;
  final Widget titleWidget;
  final Alignment titleAlignment;
  final String id;

  const ContentSectionCard({
    super.key,
    // required this.title, // REMOVED
    required this.titleWidget, // ADDED
    required this.imagePath,
    required this.height,
    required this.onTap,
    required this.id,
    this.scrimColor = Colors.black54,
    this.titleAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag + id,
              child: Image.asset(
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
            ),
            Container(
              // Scrim for ContentSectionCard title area
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
                    end: titleAlignment.y < -0.5
                        ? Alignment.bottomCenter
                        : titleAlignment.y > 0.5
                            ? Alignment.topCenter
                            : Alignment.centerRight,
                    stops: [0.0, 0.8]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0), // Consistent padding
              child: Align(
                alignment: titleAlignment,
                // child: Text( // REMOVED
                //   title,
                //   ...
                // ),
                child: titleWidget, // ADDED
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const CardTitle({
    Key? key,
    required this.text,
    this.textAlign = TextAlign.left, // Default, can be overridden
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        // Semi-transparent background
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10.0,
            spreadRadius: 2.0,
            offset: Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.15), // Subtle outer glow
            blurRadius: 12.0,
            spreadRadius: 1.0,
            offset: Offset(0, 0),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3), // Faint border
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.black.withValues(alpha: 0.7),
              offset: Offset(1.0, 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class BaseSectionData {
  final String title;

  BaseSectionData({required this.title});
}

class SummarySectionData extends BaseSectionData {
  final String imageAsset;
  final String id;

  SummarySectionData({
    required String title,
    required this.imageAsset,
    required this.id,
  }) : super(title: title);
}

typedef DetailWidgetBuilder = Widget Function(BuildContext context);

class DetailSectionData extends BaseSectionData {
  final DetailWidgetBuilder contentBuilder;
  final SummarySectionData
      originalSummary; // Keep a reference to what was clicked

  DetailSectionData({
    required String title,
    required this.contentBuilder,
    required this.originalSummary,
  }) : super(title: title);
}

final List<SummarySectionData> _myContentSectionsData = [
  SummarySectionData(
      id: 'edu', title: "Education", imageAsset: "assets/education.jpg"),
  SummarySectionData(
      id: 'eval',
      title: "Evaluation & Exploration",
      imageAsset: "assets/exploration.jpg"),
  SummarySectionData(
      id: 'elev', title: "Elevation", imageAsset: "assets/elevation.jpg"),
  // Add more sections as needed
];

final List<String> partnerLogoPaths = const [
  "assets/google_logo.png",
  "assets/atec_logo.png",
  "assets/hopkins_logo.png",
  "assets/canal_day_logo.png",
];
