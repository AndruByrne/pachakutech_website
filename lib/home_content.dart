import 'package:flutter/material.dart';
import 'app_sections.dart';
import 'hero_util.dart';
import 'periodic_gradient_painter.dart';

typedef OnCardTap = void Function(AppSection appSection);

SliverChildBuilderDelegate mainContentBuilder(
    double sectionHeight, OnCardTap onCardTap) {
  final List<AppSection> displayableSections = AppSection.values.toList();
  return SliverChildBuilderDelegate(
    (BuildContext context, int index) {
      final itemIndex = index ~/ 2;

      final bool isConsultingCard = itemIndex == displayableSections.length;

      TextAlign titleTextAlign;
      Alignment cardTitleAlignment;

      if (isConsultingCard) {
        cardTitleAlignment = Alignment.bottomLeft;
      } else {
        cardTitleAlignment = Alignment.bottomLeft;
      }

      if (cardTitleAlignment.x < -0.1) {
        titleTextAlign = TextAlign.left;
      } else if (cardTitleAlignment.x > 0.1) {
        titleTextAlign = TextAlign.right;
      } else {
        titleTextAlign = TextAlign.center;
      }

      if (index.isOdd) {
        if (itemIndex > displayableSections.length) return null;

        if (isConsultingCard) {
          final consultingTitleWidget = CardTitle(
            text: 'Consulting',
            textAlign: titleTextAlign,
          );
          return ConsultingCard(
            height: sectionHeight,
            titleAlignment: cardTitleAlignment,
            titleWidget: consultingTitleWidget,
          );
        }

        final AppSection section = displayableSections[itemIndex];
        final contentTitleWidget = CardTitle(
          text: section.title,
          textAlign: titleTextAlign,
        );
        return ContentSectionCard(
          titleWidget: contentTitleWidget,
          imagePath: section.imageAsset,
          height: sectionHeight,
          titleAlignment: cardTitleAlignment,
          onTap: () => onCardTap(section),
          id: section.id,
        );
      } else {
        return SizedBox(height: kToolbarHeight);
      }
    },
    childCount: ((displayableSections.length + 1) * 2),
  );
}

class ConsultingCard extends StatelessWidget {
  final double height;
  final Alignment titleAlignment;
  final Widget titleWidget;

  const ConsultingCard({
    super.key,
    required this.height,
    required this.titleWidget,
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

    return SizedBox(
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
            child: Align(
              alignment: titleAlignment,
              child: titleWidget,
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
    required this.titleWidget,
    required this.imagePath,
    required this.height,
    required this.onTap,
    required this.id,
    this.scrimColor = Colors.black54,
    this.titleAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: sectionHeroTag + id,
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

class CardTitle extends StatelessWidget {
  final String text;
  final TextAlign textAlign;

  const CardTitle({
    super.key,
    required this.text,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10.0,
              spreadRadius: 2.0,
              offset: Offset(2, 2),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              blurRadius: 12.0,
              spreadRadius: 1.0,
              offset: Offset(0, 0),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
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

abstract class BaseSectionData {
  final String title;

  BaseSectionData({required this.title});
}

final List<String> partnerLogoPaths = const [
  "assets/google_logo.png",
  "assets/atec_logo.png",
  "assets/hopkins_logo.png",
  "assets/canal_day_logo.png",
];
