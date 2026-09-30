import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pachakutech_website/app_sections.dart';
import 'package:pachakutech_website/base_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

class PresenceIdeaPage extends BaseDetailPage {
  PresenceIdeaPage({
    super.key,
    required super.db,
    required super.articleId,
    required super.homePageScrollOffset,
  }) : super(appSection: AppSection.presence);

  @override
  State<PresenceIdeaPage> createState() => _ExtranetIdeaPageState();
}

class _ExtranetIdeaPageState extends BaseDetailPageState<PresenceIdeaPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  List<Widget> buildScrollableContent(BuildContext context) => [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                // Limits content width to a clean, readable desktop grid width
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Narrative Text Section
                    SelectableText(
                      """
A situated agentic presence runtime time-rectifies any variety of perceptual actors—sensors, computational models, AI agents—onto a shared, high-dimensional tensor interface with reality. Those actors don’t only see, but mutually reason over durable, queryable perceptual models (memories) that live in the same substrate as ingress and manifestation; that is how we get words out of the way.
Language remains a useful contract to the outside world; it is a poor substitute for a continuous interface to the environment agents and humans already share. This is the same intellectual foundation as approaches that put world models and grounded perception ahead of pure linguistic loops: the fastest way for systems like us to learn is to be in the stream—not narrated to about it after the fact.
""",
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Full-width phone-aspect image container
                    Center(
                      child: ConstrainedBox(
                        // Restricts aspect expansion on extreme desktop viewports
                        // while keeping phone aspect structure natural
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.95 > 750
                                  ? 750
                                  : MediaQuery.of(context).size.width * 0.95,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/nomind.jpg',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // MCP Repository Redirect Action Link
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse(
                              'https://github.com/Pachakutech/pachakutech-situated-ai-presence-mcp');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.code_rounded),
                        label: const Text('View Presence MCP on GitHub'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];

  @override
  String get backgroundImageAsset => widget.appSection.imageAsset;

  @override
  String get sectionId => widget.appSection.id;

  @override
  String get sectionTitle => widget.appSection.title;

  @override
  Future<String> get titleFuture =>
      widget.contentRepo.fetchSectionIntros().then((intros) =>
          intros[widget.appSection.id] ??
          'Presenting the ${widget.appSection.title}');
}
