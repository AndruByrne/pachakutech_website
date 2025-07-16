import 'package:pachakutech_website/base_detail_page.dart';

// Contains firebase repo and a method by which a detail page can fetch from the appropriate repo
abstract class BaseFirebasePage extends BaseDetailPage {
  const BaseFirebasePage({super.key, required super.articleId, required super.homePageScrollOffset});
}
