import 'package:flutter/material.dart';
import 'package:pachakutech_website/periodic_gradient_painter.dart';

import 'hero_util.dart';

class ContentSectionCard extends StatelessWidget {
  final String? imagePath; // Made optional
  final double height;
  final VoidCallback? onTap; // Made optional
  final Color? scrimColor; // Made optional
  final Widget titleWidget;
  final String? id; // Made optional

  const ContentSectionCard({
    super.key,
    required this.titleWidget,
    this.imagePath,
    required this.height,
    this.onTap,
    this.id,
    this.scrimColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap ?? () {}, // Default to no-op if onTap is null
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background (image or fallback)
            if (imagePath != null && id != null)
              Hero(
                tag: sectionHeroTag + id!,
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(color: Colors.grey[300]), // Fallback background
            // Scrim (optional)
            if (scrimColor != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scrimColor!.withValues(alpha: 0.7),
                      scrimColor!.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: titleWidget,
              ),
            ),
          ],
        ),
      ),
    );
}

class ConsultingCard extends ContentSectionCard {
  const ConsultingCard({
    super.key,
    required super.titleWidget,
    required super.height,
  }) : super(
          imagePath: null, // Not used
          onTap: null, // Not used
          id: null, // Not used
          scrimColor: null, // Not used
        );

  @override
  Widget build(BuildContext context) {
    // Periodic gradient background
    Widget periodicGradientBackground = CustomPaint(
      painter: PeriodicGradientPainter(
        itemCount: partnerLogoPaths.length,
        waveColors: [
          Colors.grey[600]!,
          Colors.white,
          Colors.grey[600]!,
          Colors.black,
          Colors.grey[600]!,
        ],
      ),
      child: Container(),
    );

    // Calculate logo row height
    double overallCardPadding = 16.0;
    double logoRowHeight = height * 0.5;
    if (logoRowHeight < 0) logoRowHeight = 0;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Custom gradient background
          Positioned.fill(
            child: periodicGradientBackground,
          ),
          // Partner logos
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: overallCardPadding),
              child: SizedBox(
                height: logoRowHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: partnerLogoPaths
                      .map((logoPath) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: overallCardPadding / 2),
                              child: Image.asset(
                                logoPath,
                                height: logoRowHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          // Reused title placement from parent
          Padding(
            padding: EdgeInsets.all(overallCardPadding),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: titleWidget,
            ),
          ),
        ],
      ),
    );
  }
}

final List<String> partnerLogoPaths = const [
  "assets/google_logo.png",
  "assets/atec_logo.png",
  "assets/hopkins_logo.png",
  "assets/canal_day_logo.png",
];
