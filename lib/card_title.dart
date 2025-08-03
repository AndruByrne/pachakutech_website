import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class CardTitle extends StatelessWidget {
  final String title;
  final String ticker;
  final TextAlign textAlign;
  final String? image;

  const CardTitle({
    super.key,
    required this.title,
    required this.ticker,
    this.textAlign = TextAlign.left,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: squircleDecoration(Colors.black54),
          child: Text(
            title,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              // fontFamily: 'Pachakutech',
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
        ),
        if (ticker.isNotEmpty)
          Flexible(
            child: Container(
              height: 40,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: squircleDecoration(Colors.black26),
              child: LayoutBuilder(builder: (context, constraints) {
                final style = TextStyle(
                  color: Colors.white,
                );
                final textPainter = TextPainter(
                  text: TextSpan(text: ticker, style: style),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout();
                return textPainter.width > constraints.maxWidth
                    ? Marquee(
                        text: ticker,
                        style: style,
                        blankSpace: 20,
                        scrollAxis: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.end,
                      )
                    : Text(ticker, style: style);
              }),
            ),
          ),
        if (image != null)
          Padding(
              padding: const EdgeInsets.only(left: 28.0),
              child: SizedBox(
                  height: 40, child: Image.asset(image!, fit: BoxFit.contain)))
      ],
    );
  }
}

squircleDecoration(Color color) => BoxDecoration(
      color: color,
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
    );
