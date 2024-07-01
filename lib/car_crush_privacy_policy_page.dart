import 'package:flutter/material.dart';

class CarCrushPrivacyPolicyPage extends StatefulWidget {
  const CarCrushPrivacyPolicyPage({super.key});

  @override
  State<CarCrushPrivacyPolicyPage> createState() => _PrivacyPolicyPage();
}

class _PrivacyPolicyPage extends State<CarCrushPrivacyPolicyPage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(200),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('Car Crush Privacy Policy'),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.secondary,
        child: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: ListView(
              children: [
                FutureBuilder(
                  future: DefaultAssetBundle.of(context)
                      .loadString('assets/car_crush_privacy_policy.txt'),
                  builder: (context, snapshot) => snapshot.hasData
                      ? Text(
                          snapshot.data!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                      : const Text('...'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
