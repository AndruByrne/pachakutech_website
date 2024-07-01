import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vector_math/vector_math.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var wheelAngle = getAngle(MediaQuery.of(context).size);
    print('wheel angle: $wheelAngle');
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(200),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        color: (223 < wheelAngle && wheelAngle < 225)
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.background,
        child: Stack(
          children: [
            Center(
              child: Column(
                // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
                // action in the IDE, or press "p" in the console), to see the
                // wireframe for each widget.
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(50.0),
                      child: Transform.rotate(
                        key: _bodyKey,
                        angle: radians(wheelAngle),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SvgPicture.asset(
                            'assets/pachakutech_wheel.svg',
                            colorFilter: ColorFilter.mode(
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withAlpha(200),
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(150.0),
                      child: Transform.rotate(
                        angle: radians(90.0 - wheelAngle),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SvgPicture.asset(
                            'assets/pachakutech_wheel.svg',
                            colorFilter: ColorFilter.mode(
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withAlpha(200),
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
            Center(
              child: Column(
                children: [
                  Expanded(
                      child:
                          Image.asset('assets/pachakutech_dot_logo_alpha.png')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

getAngle(Size size) {
  return (size.height * size.width / 10000) % 90 * 4;
}
