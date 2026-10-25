import 'package:flutter/material.dart';

/// Highlights occurrences of a search query in a text string.
class TextHighlighter {
  TextHighlighter._();

  static TextSpan buildHighlightedSpan({
    required String text,
    required String query,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty || !text.toLowerCase().contains(cleanQuery)) {
      return TextSpan(text: text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    int start = 0;

    while (true) {
      final matchIndex = lowerText.indexOf(cleanQuery, start);
      if (matchIndex < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        }
        break;
      }

      if (matchIndex > start) {
        spans.add(
          TextSpan(text: text.substring(start, matchIndex), style: baseStyle),
        );
      }

      final matchEnd = matchIndex + cleanQuery.length;
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchEnd),
          style: highlightStyle,
        ),
      );
      start = matchEnd;
    }

    return TextSpan(children: spans);
  }
}
