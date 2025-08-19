import 'package:flutter/material.dart';
import 'package:pachakutech_website/section_card.dart';
import 'app_sections.dart';
import 'widgets/card_title.dart';

typedef OnCardTap = void Function(AppSection appSection);

SliverChildBuilderDelegate mainContentBuilder(
  double sectionHeight,
  OnCardTap onCardTap,
  Future<Map<String, dynamic>> sectionTickers,
    Map<AppSection, GlobalKey> sectionItemKeys,
) {
  final List<AppSection> displayableSections = AppSection.values.toList();
  return SliverChildBuilderDelegate(
    (BuildContext context, int index) {
      if (index.isEven) {
        return SizedBox(
          height: kToolbarHeight,
          child: Container(
            // color: Colors.white12,
          ),
        );
      }
      final itemIndex = index ~/ 2;
      final bool isConsultingCard = itemIndex == displayableSections.length-1;

      if (itemIndex > displayableSections.length) return null;

      final AppSection section = displayableSections[itemIndex];
      if (isConsultingCard) {
        return ConsultingCard(
          height: sectionHeight,
          titleWidget: CardTitle(
            title: section.title,
            ticker: '',
            image: 'pach_at_gmail.png',
          ),
          onTap: () => onCardTap(section),
        );
      }

      return ContentSectionCard(
        key: sectionItemKeys[section],
        titleWidget: FutureBuilder(
          future: sectionTickers,
          builder: (_, snapshot) => CardTitle(
                title: section.title,
                ticker:
                    snapshot.hasData ? (snapshot.data?[section.id] ?? '') : '',
              )),
        imagePath: section.imageAsset,
        height: sectionHeight,
        onTap: () => onCardTap(section),
        id: section.id,
      );
    },
    childCount: ((displayableSections.length) * 2),
  );
}
