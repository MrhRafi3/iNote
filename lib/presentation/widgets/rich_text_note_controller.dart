import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Represents a character range `[start..end)` in the note text.
class TextSpanRange {
  final int start;
  final int end;

  const TextSpanRange(this.start, this.end);

  int get length => end - start;

  bool contains(int offset, {bool edgeInclusive = false}) {
    if (edgeInclusive) {
      return offset >= start && offset <= end;
    }
    return offset >= start && offset < end;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSpanRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start..$end]';
}

/// Helper class managing sorted, disjoint text span intervals.
class SpanRangeList {
  final List<TextSpanRange> _ranges = [];

  List<TextSpanRange> get ranges => List.unmodifiable(_ranges);

  void clear() => _ranges.clear();

  void add(int start, int end) {
    if (start >= end) return;
    final newRanges = <TextSpanRange>[];
    var curStart = start;
    var curEnd = end;

    for (final r in _ranges) {
      if (r.end < curStart) {
        newRanges.add(r);
      } else if (r.start > curEnd) {
        newRanges.add(TextSpanRange(curStart, curEnd));
        curStart = r.start;
        curEnd = r.end;
      } else {
        curStart = min(r.start, curStart);
        curEnd = max(r.end, curEnd);
      }
    }
    newRanges.add(TextSpanRange(curStart, curEnd));
    _ranges
      ..clear()
      ..addAll(newRanges);
  }

  void remove(int start, int end) {
    if (start >= end || _ranges.isEmpty) return;
    final newRanges = <TextSpanRange>[];

    for (final r in _ranges) {
      if (r.end <= start || r.start >= end) {
        newRanges.add(r);
      } else {
        if (r.start < start) {
          newRanges.add(TextSpanRange(r.start, start));
        }
        if (r.end > end) {
          newRanges.add(TextSpanRange(end, r.end));
        }
      }
    }
    _ranges
      ..clear()
      ..addAll(newRanges);
  }

  bool isCovered(int start, int end) {
    if (start >= end) return false;
    for (final r in _ranges) {
      if (r.start <= start && r.end >= end) return true;
    }
    return false;
  }

  void toggle(int start, int end) {
    if (isCovered(start, end)) {
      remove(start, end);
    } else {
      add(start, end);
    }
  }

  bool contains(int offset, {bool edgeInclusive = false}) {
    for (final r in _ranges) {
      if (r.contains(offset, edgeInclusive: edgeInclusive)) return true;
    }
    return false;
  }

  void onTextEdited({
    required int changeOffset,
    required int deletedCount,
    required int insertedCount,
    bool extendCoveringSpan = false,
  }) {
    if (deletedCount == 0 && insertedCount == 0) return;

    if (deletedCount > 0) {
      remove(changeOffset, changeOffset + deletedCount);
      final shifted = <TextSpanRange>[];
      for (final r in _ranges) {
        if (r.end <= changeOffset) {
          shifted.add(r);
        } else if (r.start >= changeOffset + deletedCount) {
          shifted.add(
            TextSpanRange(r.start - deletedCount, r.end - deletedCount),
          );
        } else {
          shifted.add(r);
        }
      }
      _ranges
        ..clear()
        ..addAll(shifted);
    }

    if (insertedCount > 0) {
      final shifted = <TextSpanRange>[];
      for (final r in _ranges) {
        if (r.end < changeOffset) {
          shifted.add(r);
        } else if (r.start > changeOffset) {
          shifted.add(
            TextSpanRange(r.start + insertedCount, r.end + insertedCount),
          );
        } else {
          // changeOffset is within or at boundary of r
          if (r.start == changeOffset) {
            shifted.add(
              TextSpanRange(r.start + insertedCount, r.end + insertedCount),
            );
          } else if (r.end == changeOffset) {
            if (extendCoveringSpan) {
              shifted.add(TextSpanRange(r.start, r.end + insertedCount));
            } else {
              shifted.add(r);
            }
          } else {
            shifted.add(TextSpanRange(r.start, r.end + insertedCount));
          }
        }
      }
      _ranges
        ..clear()
        ..addAll(shifted);
    }
  }

  List<TextSpanRange> copy() => List.of(_ranges);

  void restore(List<TextSpanRange> source) {
    _ranges
      ..clear()
      ..addAll(source);
  }
}

/// Rich-text controller for note editing that provides real formatting
/// (bold, italic, code, headings, quotes, bullet lists) without displaying
/// raw Markdown syntax characters in the editor canvas.
class RichTextNoteController extends TextEditingController {
  final SpanRangeList boldSpans = SpanRangeList();
  final SpanRangeList italicSpans = SpanRangeList();
  final SpanRangeList codeSpans = SpanRangeList();

  final Set<int> _headingLineIndices = {};
  final Set<int> _quoteLineIndices = {};

  bool _pendingBold = false;
  bool _pendingItalic = false;
  bool _pendingCode = false;

  bool _isInternalUpdating = false;

  RichTextNoteController({String? text}) : super(text: text ?? '');

  bool get pendingBold => _pendingBold;
  bool get pendingItalic => _pendingItalic;
  bool get pendingCode => _pendingCode;

  // ---------------------------------------------------------------------------
  // Active state queries for toolbar highlighting
  // ---------------------------------------------------------------------------

  int get currentLineIndex {
    final offset = selection.isValid ? selection.start : text.length;
    final clamped = offset.clamp(0, text.length);
    if (clamped == 0) return 0;
    return '\n'.allMatches(text.substring(0, clamped)).length;
  }

  bool get isBoldActive {
    if (_pendingBold) return true;
    if (!selection.isValid) return false;
    if (selection.isCollapsed) {
      return boldSpans.contains(selection.start, edgeInclusive: true);
    }
    return boldSpans.isCovered(selection.start, selection.end);
  }

  bool get isItalicActive {
    if (_pendingItalic) return true;
    if (!selection.isValid) return false;
    if (selection.isCollapsed) {
      return italicSpans.contains(selection.start, edgeInclusive: true);
    }
    return italicSpans.isCovered(selection.start, selection.end);
  }

  bool get isCodeActive {
    if (_pendingCode) return true;
    if (!selection.isValid) return false;
    if (selection.isCollapsed) {
      return codeSpans.contains(selection.start, edgeInclusive: true);
    }
    return codeSpans.isCovered(selection.start, selection.end);
  }

  bool get isHeadingActive => _headingLineIndices.contains(currentLineIndex);

  bool get isQuoteActive => _quoteLineIndices.contains(currentLineIndex);

  bool get isBulletActive {
    final line = _getCurrentLineText();
    return line.startsWith('• ') || line.startsWith('- ');
  }

  bool get isNumberedActive {
    final line = _getCurrentLineText();
    return RegExp(r'^\d+\.\s+').hasMatch(line);
  }

  String _getCurrentLineText() {
    final offset = selection.isValid ? selection.start : text.length;
    final clamped = offset.clamp(0, text.length);
    final before = text.substring(0, clamped);
    final after = text.substring(clamped);

    final lineStart = before.lastIndexOf('\n') == -1
        ? 0
        : before.lastIndexOf('\n') + 1;
    final newlineIdx = after.indexOf('\n');
    final lineEnd = newlineIdx == -1 ? text.length : clamped + newlineIdx;

    return text.substring(lineStart, lineEnd);
  }

  (int, int) _getCurrentLineRange() {
    final offset = selection.isValid ? selection.start : text.length;
    final clamped = offset.clamp(0, text.length);
    final before = text.substring(0, clamped);
    final after = text.substring(clamped);

    final lineStart = before.lastIndexOf('\n') == -1
        ? 0
        : before.lastIndexOf('\n') + 1;
    final newlineIdx = after.indexOf('\n');
    final lineEnd = newlineIdx == -1 ? text.length : clamped + newlineIdx;

    return (lineStart, lineEnd);
  }

  // ---------------------------------------------------------------------------
  // Formatting actions
  // ---------------------------------------------------------------------------

  void toggleBold() {
    if (!selection.isValid || selection.isCollapsed) {
      _pendingBold = !_pendingBold;
      notifyListeners();
      return;
    }
    boldSpans.toggle(selection.start, selection.end);
    _pendingBold = false;
    notifyListeners();
  }

  void toggleItalic() {
    if (!selection.isValid || selection.isCollapsed) {
      _pendingItalic = !_pendingItalic;
      notifyListeners();
      return;
    }
    italicSpans.toggle(selection.start, selection.end);
    _pendingItalic = false;
    notifyListeners();
  }

  void toggleCode() {
    if (!selection.isValid || selection.isCollapsed) {
      _pendingCode = !_pendingCode;
      notifyListeners();
      return;
    }
    codeSpans.toggle(selection.start, selection.end);
    _pendingCode = false;
    notifyListeners();
  }

  void toggleHeading() {
    final lineIdx = currentLineIndex;
    if (_headingLineIndices.contains(lineIdx)) {
      _headingLineIndices.remove(lineIdx);
    } else {
      _headingLineIndices.add(lineIdx);
      // Headings shouldn't be quotes
      _quoteLineIndices.remove(lineIdx);
    }
    notifyListeners();
  }

  void toggleQuote() {
    final lineIdx = currentLineIndex;
    if (_quoteLineIndices.contains(lineIdx)) {
      _quoteLineIndices.remove(lineIdx);
    } else {
      _quoteLineIndices.add(lineIdx);
      _headingLineIndices.remove(lineIdx);
    }
    notifyListeners();
  }

  void toggleBulletList() {
    final (start, end) = _getCurrentLineRange();
    final lineText = text.substring(start, end);

    if (lineText.startsWith('• ')) {
      // Remove bullet
      final newText =
          text.substring(0, start) +
          lineText.substring(2) +
          text.substring(end);
      final newOffset = max(
        start,
        (selection.isValid ? selection.start : start) - 2,
      );
      _updateTextDirectly(newText, TextSelection.collapsed(offset: newOffset));
    } else {
      // Add bullet
      final newText =
          '${text.substring(0, start)}• $lineText${text.substring(end)}';
      final newOffset = (selection.isValid ? selection.start : start) + 2;
      _updateTextDirectly(newText, TextSelection.collapsed(offset: newOffset));
    }
  }

  void toggleNumberedList() {
    final (start, end) = _getCurrentLineRange();
    final lineText = text.substring(start, end);
    final match = RegExp(r'^(\d+)\.\s+').firstMatch(lineText);

    if (match != null) {
      final prefixLen = match.group(0)!.length;
      final newText =
          text.substring(0, start) +
          lineText.substring(prefixLen) +
          text.substring(end);
      final newOffset = max(
        start,
        (selection.isValid ? selection.start : start) - prefixLen,
      );
      _updateTextDirectly(newText, TextSelection.collapsed(offset: newOffset));
    } else {
      final newText =
          '${text.substring(0, start)}1. $lineText${text.substring(end)}';
      final newOffset = (selection.isValid ? selection.start : start) + 3;
      _updateTextDirectly(newText, TextSelection.collapsed(offset: newOffset));
    }
  }

  void insertTimestamp() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ';
    final offset = selection.isValid ? selection.start : text.length;

    final before = text.substring(0, offset);
    final after = selection.isValid ? selection.textAfter(text) : '';
    final newText = before + timeStr + after;

    _updateTextDirectly(
      newText,
      TextSelection.collapsed(offset: offset + timeStr.length),
    );
  }

  void _updateTextDirectly(String newText, TextSelection newSelection) {
    _isInternalUpdating = true;
    try {
      value = TextEditingValue(text: newText, selection: newSelection);
    } finally {
      _isInternalUpdating = false;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Handling user edits, list continuation, and span updates
  // ---------------------------------------------------------------------------

  @override
  set value(TextEditingValue newValue) {
    if (_isInternalUpdating) {
      super.value = newValue;
      return;
    }

    final oldText = text;
    final newText = newValue.text;

    // Detect common prefix and suffix
    int prefixLen = 0;
    while (prefixLen < oldText.length &&
        prefixLen < newText.length &&
        oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    int oldSuffixLen = 0;
    int newSuffixLen = 0;
    while (oldSuffixLen < oldText.length - prefixLen &&
        newSuffixLen < newText.length - prefixLen &&
        oldText[oldText.length - 1 - oldSuffixLen] ==
            newText[newText.length - 1 - newSuffixLen]) {
      oldSuffixLen++;
      newSuffixLen++;
    }

    final changeOffset = prefixLen;
    final deletedCount = oldText.length - prefixLen - oldSuffixLen;
    final insertedCount = newText.length - prefixLen - newSuffixLen;

    // Check for newline insertion and list continuation
    if (deletedCount == 0 &&
        insertedCount == 1 &&
        newText.length > changeOffset &&
        newText[changeOffset] == '\n') {
      final lineStart = oldText.lastIndexOf('\n', changeOffset - 1) == -1
          ? 0
          : oldText.lastIndexOf('\n', changeOffset - 1) + 1;
      final lineBeforeNewline = oldText.substring(lineStart, changeOffset);

      // 1. Bullet list handling
      if (lineBeforeNewline.startsWith('• ')) {
        if (lineBeforeNewline.trim() == '•') {
          // Empty bullet line: exit list by clearing bullet prefix
          final fixedText =
              oldText.substring(0, lineStart) + oldText.substring(changeOffset);
          _isInternalUpdating = true;
          try {
            super.value = TextEditingValue(
              text: fixedText,
              selection: TextSelection.collapsed(offset: lineStart),
            );
          } finally {
            _isInternalUpdating = false;
          }
          _updateLineIndicesAfterNewlineChange(
            changeOffset,
            isInsertion: false,
          );
          notifyListeners();
          return;
        } else {
          // Continue bullet list
          const bullet = '• ';
          final adjustedText =
              newText.substring(0, changeOffset + 1) +
              bullet +
              newText.substring(changeOffset + 1);
          final adjustedSelection = TextSelection.collapsed(
            offset: changeOffset + 1 + bullet.length,
          );

          _applyTextChangeToSpans(
            changeOffset,
            deletedCount,
            insertedCount + bullet.length,
          );
          _updateLineIndicesAfterNewlineChange(changeOffset, isInsertion: true);

          _isInternalUpdating = true;
          try {
            super.value = TextEditingValue(
              text: adjustedText,
              selection: adjustedSelection,
            );
          } finally {
            _isInternalUpdating = false;
          }
          notifyListeners();
          return;
        }
      }

      // 2. Numbered list handling
      final numMatch = RegExp(r'^(\d+)\.\s+').firstMatch(lineBeforeNewline);
      if (numMatch != null) {
        if (lineBeforeNewline.trim() == numMatch.group(0)!.trim()) {
          // Empty numbered line: exit list
          final fixedText =
              oldText.substring(0, lineStart) + oldText.substring(changeOffset);
          _isInternalUpdating = true;
          try {
            super.value = TextEditingValue(
              text: fixedText,
              selection: TextSelection.collapsed(offset: lineStart),
            );
          } finally {
            _isInternalUpdating = false;
          }
          _updateLineIndicesAfterNewlineChange(
            changeOffset,
            isInsertion: false,
          );
          notifyListeners();
          return;
        } else {
          final nextNum = int.parse(numMatch.group(1)!) + 1;
          final nextPrefix = '$nextNum. ';
          final adjustedText =
              newText.substring(0, changeOffset + 1) +
              nextPrefix +
              newText.substring(changeOffset + 1);
          final adjustedSelection = TextSelection.collapsed(
            offset: changeOffset + 1 + nextPrefix.length,
          );

          _applyTextChangeToSpans(
            changeOffset,
            deletedCount,
            insertedCount + nextPrefix.length,
          );
          _updateLineIndicesAfterNewlineChange(changeOffset, isInsertion: true);

          _isInternalUpdating = true;
          try {
            super.value = TextEditingValue(
              text: adjustedText,
              selection: adjustedSelection,
            );
          } finally {
            _isInternalUpdating = false;
          }
          notifyListeners();
          return;
        }
      }
    }

    _applyTextChangeToSpans(changeOffset, deletedCount, insertedCount);

    // Apply pending styles to inserted characters
    if (insertedCount > 0) {
      final insertEnd = changeOffset + insertedCount;
      if (_pendingBold) {
        boldSpans.add(changeOffset, insertEnd);
      }
      if (_pendingItalic) {
        italicSpans.add(changeOffset, insertEnd);
      }
      if (_pendingCode) {
        codeSpans.add(changeOffset, insertEnd);
      }
    }

    // Check if newlines changed
    final oldNewlines = '\n'.allMatches(oldText).length;
    final newNewlines = '\n'.allMatches(newText).length;
    if (oldNewlines != newNewlines) {
      _realignLineStyles(newText);
    }

    super.value = newValue;
  }

  void _applyTextChangeToSpans(
    int changeOffset,
    int deletedCount,
    int insertedCount,
  ) {
    boldSpans.onTextEdited(
      changeOffset: changeOffset,
      deletedCount: deletedCount,
      insertedCount: insertedCount,
      extendCoveringSpan: _pendingBold,
    );
    italicSpans.onTextEdited(
      changeOffset: changeOffset,
      deletedCount: deletedCount,
      insertedCount: insertedCount,
      extendCoveringSpan: _pendingItalic,
    );
    codeSpans.onTextEdited(
      changeOffset: changeOffset,
      deletedCount: deletedCount,
      insertedCount: insertedCount,
      extendCoveringSpan: _pendingCode,
    );
  }

  void _updateLineIndicesAfterNewlineChange(
    int offset, {
    required bool isInsertion,
  }) {
    final lineIdx = '\n'
        .allMatches(text.substring(0, min(offset, text.length)))
        .length;
    final delta = isInsertion ? 1 : -1;

    final newHeadings = <int>{};
    for (final idx in _headingLineIndices) {
      if (idx < lineIdx) {
        newHeadings.add(idx);
      } else if (idx >= lineIdx) {
        final shifted = idx + delta;
        if (shifted >= 0) newHeadings.add(shifted);
      }
    }
    _headingLineIndices
      ..clear()
      ..addAll(newHeadings);

    final newQuotes = <int>{};
    for (final idx in _quoteLineIndices) {
      if (idx < lineIdx) {
        newQuotes.add(idx);
      } else if (idx >= lineIdx) {
        final shifted = idx + delta;
        if (shifted >= 0) newQuotes.add(shifted);
      }
    }
    _quoteLineIndices
      ..clear()
      ..addAll(newQuotes);
  }

  void _realignLineStyles(String newText) {
    final maxLines = '\n'.allMatches(newText).length + 1;
    _headingLineIndices.removeWhere((idx) => idx >= maxLines);
    _quoteLineIndices.removeWhere((idx) => idx >= maxLines);
  }

  // ---------------------------------------------------------------------------
  // Rich Text Rendering (TextSpan tree construction)
  // ---------------------------------------------------------------------------

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle =
        style ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          height: 1.6,
        );

    if (text.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final children = <InlineSpan>[];
    final lines = text.split('\n');
    int lineStartOffset = 0;

    for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final lineStr = lines[lineIdx];
      final lineEndOffset = lineStartOffset + lineStr.length;

      final isHeading = _headingLineIndices.contains(lineIdx);
      final isQuote = _quoteLineIndices.contains(lineIdx);

      TextStyle lineBaseStyle = baseStyle;
      if (isHeading) {
        lineBaseStyle = baseStyle.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.35,
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        );
      } else if (isQuote) {
        lineBaseStyle = baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        );
      }

      if (lineStr.isEmpty) {
        // Empty line
        if (lineIdx < lines.length - 1) {
          children.add(TextSpan(text: '\n', style: lineBaseStyle));
        }
        lineStartOffset = lineEndOffset + 1;
        continue;
      }

      // Break line into style segments
      final points = <int>{0, lineStr.length};
      for (final r in boldSpans.ranges) {
        if (r.end > lineStartOffset && r.start < lineEndOffset) {
          points.add(max(0, r.start - lineStartOffset));
          points.add(min(lineStr.length, r.end - lineStartOffset));
        }
      }
      for (final r in italicSpans.ranges) {
        if (r.end > lineStartOffset && r.start < lineEndOffset) {
          points.add(max(0, r.start - lineStartOffset));
          points.add(min(lineStr.length, r.end - lineStartOffset));
        }
      }
      for (final r in codeSpans.ranges) {
        if (r.end > lineStartOffset && r.start < lineEndOffset) {
          points.add(max(0, r.start - lineStartOffset));
          points.add(min(lineStr.length, r.end - lineStartOffset));
        }
      }

      final sortedPoints = points.toList()..sort();

      for (int i = 0; i < sortedPoints.length - 1; i++) {
        final segStart = sortedPoints[i];
        final segEnd = sortedPoints[i + 1];
        if (segStart >= segEnd) continue;

        final globalSegStart = lineStartOffset + segStart;
        final segText = lineStr.substring(segStart, segEnd);

        final isBold = boldSpans.contains(globalSegStart);
        final isItalic = italicSpans.contains(globalSegStart);
        final isCode = codeSpans.contains(globalSegStart);

        TextStyle segStyle = lineBaseStyle;
        if (isBold) {
          segStyle = segStyle.copyWith(fontWeight: FontWeight.w700);
        }
        if (isItalic) {
          segStyle = segStyle.copyWith(fontStyle: FontStyle.italic);
        }
        if (isCode) {
          segStyle = segStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.08),
          );
        }

        // Highlight bullet prefix attractively
        if (segStart == 0 && (segText.startsWith('• ') || segText == '•')) {
          children.add(
            TextSpan(
              text: segText,
              style: segStyle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        } else {
          children.add(TextSpan(text: segText, style: segStyle));
        }
      }

      if (lineIdx < lines.length - 1) {
        children.add(TextSpan(text: '\n', style: lineBaseStyle));
      }

      lineStartOffset = lineEndOffset + 1;
    }

    return TextSpan(children: children);
  }

  // ---------------------------------------------------------------------------
  // Markdown Serialization and Deserialization for Storage Compatibility
  // ---------------------------------------------------------------------------

  /// Convert current rich editor state to clean Markdown for database storage.
  String toMarkdown() {
    if (text.isEmpty) return '';

    final lines = text.split('\n');
    final markdownLines = <String>[];
    int lineStartOffset = 0;

    for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final lineStr = lines[lineIdx];
      final lineEndOffset = lineStartOffset + lineStr.length;

      final isHeading = _headingLineIndices.contains(lineIdx);
      final isQuote = _quoteLineIndices.contains(lineIdx);

      // Extract spans within this line
      String processedLine = '';
      final points = <int>{0, lineStr.length};
      for (final r in boldSpans.ranges) {
        if (r.end > lineStartOffset && r.start < lineEndOffset) {
          points.add(max(0, r.start - lineStartOffset));
          points.add(min(lineStr.length, r.end - lineStartOffset));
        }
      }
      for (final r in italicSpans.ranges) {
        if (r.end > lineStartOffset && r.start < lineEndOffset) {
          points.add(max(0, r.start - lineStartOffset));
          points.add(min(lineStr.length, r.end - lineStartOffset));
        }
      }
      for (final r in codeSpans.ranges) {
        if (r.end > lineStartOffset && r.start < lineEndOffset) {
          points.add(max(0, r.start - lineStartOffset));
          points.add(min(lineStr.length, r.end - lineStartOffset));
        }
      }

      final sortedPoints = points.toList()..sort();

      for (int i = 0; i < sortedPoints.length - 1; i++) {
        final segStart = sortedPoints[i];
        final segEnd = sortedPoints[i + 1];
        if (segStart >= segEnd) continue;

        final globalSegStart = lineStartOffset + segStart;
        var segText = lineStr.substring(segStart, segEnd);

        final isBold = boldSpans.contains(globalSegStart);
        final isItalic = italicSpans.contains(globalSegStart);
        final isCode = codeSpans.contains(globalSegStart);

        if (isCode) {
          segText = '`$segText`';
        }
        if (isItalic) {
          segText = '*$segText*';
        }
        if (isBold) {
          segText = '**$segText**';
        }

        processedLine += segText;
      }

      // Convert bullet list prefix
      if (processedLine.startsWith('• ')) {
        processedLine = '- ${processedLine.substring(2)}';
      }

      // Apply line styles
      if (isHeading) {
        processedLine = '## $processedLine';
      } else if (isQuote) {
        processedLine = '> $processedLine';
      }

      markdownLines.add(processedLine);
      lineStartOffset = lineEndOffset + 1;
    }

    return markdownLines.join('\n');
  }

  /// Construct a [RichTextNoteController] from stored note Markdown or plain text.
  static RichTextNoteController fromMarkdown(String markdown) {
    final controller = RichTextNoteController();
    controller.loadMarkdown(markdown);
    return controller;
  }

  /// Populate this controller from a Markdown string.
  void loadMarkdown(String markdown, {bool preserveSelection = false}) {
    final previousSelection = selection;

    boldSpans.clear();
    italicSpans.clear();
    codeSpans.clear();
    _headingLineIndices.clear();
    _quoteLineIndices.clear();
    _pendingBold = false;
    _pendingItalic = false;
    _pendingCode = false;

    if (markdown.isEmpty) {
      _isInternalUpdating = true;
      try {
        text = '';
      } finally {
        _isInternalUpdating = false;
      }
      return;
    }

    final rawLines = markdown.split('\n');
    final parsedLines = <String>[];
    int currentGlobalOffset = 0;

    for (int lineIdx = 0; lineIdx < rawLines.length; lineIdx++) {
      var line = rawLines[lineIdx];

      // 1. Detect headings
      if (line.startsWith(RegExp(r'^#+\s+'))) {
        _headingLineIndices.add(lineIdx);
        line = line.replaceFirst(RegExp(r'^#+\s+'), '');
      } else if (line.startsWith(RegExp(r'^>\s+'))) {
        _quoteLineIndices.add(lineIdx);
        line = line.replaceFirst(RegExp(r'^>\s+'), '');
      }

      // 2. Detect bullet list markers (- or * to •)
      if (line.startsWith(RegExp(r'^[-*]\s+'))) {
        line = '• ${line.substring(2)}';
      }

      // 3. Parse inline styles (bold, italic, code)
      // We parse tokens sequentially into a clean plain-text line
      final cleanLineBuffer = StringBuffer();
      int i = 0;

      while (i < line.length) {
        if (line.startsWith('**', i)) {
          final closeIdx = line.indexOf('**', i + 2);
          if (closeIdx != -1) {
            final inner = line.substring(i + 2, closeIdx);
            final startOffset = currentGlobalOffset + cleanLineBuffer.length;
            cleanLineBuffer.write(inner);
            final endOffset = currentGlobalOffset + cleanLineBuffer.length;
            boldSpans.add(startOffset, endOffset);
            i = closeIdx + 2;
            continue;
          }
        } else if (line.startsWith('*', i)) {
          final closeIdx = line.indexOf('*', i + 1);
          if (closeIdx != -1) {
            final inner = line.substring(i + 1, closeIdx);
            final startOffset = currentGlobalOffset + cleanLineBuffer.length;
            cleanLineBuffer.write(inner);
            final endOffset = currentGlobalOffset + cleanLineBuffer.length;
            italicSpans.add(startOffset, endOffset);
            i = closeIdx + 1;
            continue;
          }
        } else if (line.startsWith('`', i)) {
          final closeIdx = line.indexOf('`', i + 1);
          if (closeIdx != -1) {
            final inner = line.substring(i + 1, closeIdx);
            final startOffset = currentGlobalOffset + cleanLineBuffer.length;
            cleanLineBuffer.write(inner);
            final endOffset = currentGlobalOffset + cleanLineBuffer.length;
            codeSpans.add(startOffset, endOffset);
            i = closeIdx + 1;
            continue;
          }
        }

        cleanLineBuffer.write(line[i]);
        i++;
      }

      final parsedLine = cleanLineBuffer.toString();
      parsedLines.add(parsedLine);
      currentGlobalOffset += parsedLine.length + 1; // +1 for '\n'
    }

    final newPlainText = parsedLines.join('\n');
    _isInternalUpdating = true;
    try {
      final targetSelection = preserveSelection && previousSelection.isValid
          ? TextSelection(
              baseOffset: min(
                previousSelection.baseOffset,
                newPlainText.length,
              ),
              extentOffset: min(
                previousSelection.extentOffset,
                newPlainText.length,
              ),
            )
          : TextSelection.collapsed(offset: newPlainText.length);

      value = TextEditingValue(text: newPlainText, selection: targetSelection);
    } finally {
      _isInternalUpdating = false;
    }
  }
}
