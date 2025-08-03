import 'package:flutter/material.dart';

class LoopingTextScroll extends StatefulWidget {
  final String text;

  final String fontFamily;

  final double fontSize;

  final Color fontColor;

  const LoopingTextScroll(
      {Key? key,
      required this.text,
      this.fontFamily = 'Roboto',
      this.fontSize = 24,
      this.fontColor = Colors.white})
      : super(key: key);

  @override
  _LoopingTextScrollState createState() => _LoopingTextScrollState();
}

class _LoopingTextScrollState extends State<LoopingTextScroll> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLoopingScroll();
    });
  }

  void _startLoopingScroll() async {
    while (_scrollController.hasClients) {
      await Future.delayed(
          const Duration(seconds: 1)); // Delay before scrolling
      if (!_scrollController.hasClients) return; // Check again after delay

      // Scroll to the end
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 5), // Adjust scroll speed
        curve: Curves.linear,
      );

      if (!_scrollController.hasClients) return;

      // Jump back to the beginning to create the loop effect
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Text(
          widget.text,
          style: TextStyle(
              fontSize: widget.fontSize,
              fontFamily: widget.fontFamily,
              color: widget.fontColor),
        ),
      );
}
