import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vector_math/vector_math.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _bodyKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  double _wheelAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        // Define scroll distance for a full 360-degree rotation
        const maxScrollForRotation = 1000.0; // Adjust as needed
        // Calculate angle: 0 to 360 degrees based on scroll offset
        double scrollOffset = _scrollController.offset.clamp(0.0, maxScrollForRotation);
        _wheelAngle = (scrollOffset / maxScrollForRotation) * 360.0;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final wheelHeight = screenHeight * 0.9; // Covers 90% of viewport height

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(200),
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Reserve space for the fixed wheels and logo
                SizedBox(height: wheelHeight),
                // Placeholder section
                Container(
                  height: screenHeight,
                  color: Theme.of(context).colorScheme.surface,
                  child: const Center(
                    child: Text(
                      'Placeholder Section\n(Add your content here)',
                      style: TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fixed wheels and logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: wheelHeight,
            child: Container(
              color: (_wheelAngle >= 223 && _wheelAngle <= 225)
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.surface,
              child: Stack(
                children: [
                  // First wheel
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(50.0),
                            child: Transform.rotate(
                              key: _bodyKey,
                              angle: radians(_wheelAngle),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SvgPicture.asset(
                                  'assets/pachakutech_wheel.svg',
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.secondary,
                                    BlendMode.srcIn,
                                  ),
                                  semanticsLabel: 'Pachakutech Wheel',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Second wheel (counter-rotating)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(150.0),
                            child: Transform.rotate(
                              angle: radians(90.0 - _wheelAngle),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SvgPicture.asset(
                                  'assets/pachakutech_wheel.svg',
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.secondary,
                                    BlendMode.srcIn,
                                  ),
                                  semanticsLabel: 'Pachakutech Wheel',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dot logo
                  Center(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset('assets/pachakutech_dot_logo_alpha.png'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}