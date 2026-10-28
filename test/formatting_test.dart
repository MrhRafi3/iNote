import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inote/data/models/note_model.dart';
import 'package:inote/data/repositories/notes_repository.dart';
import 'package:inote/data/repositories/preferences_repository.dart';
import 'package:inote/presentation/screens/note_editor_screen.dart';
import 'package:inote/presentation/widgets/rich_text_note_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotesRepository.instance.init();
    await PreferencesRepository.instance.init();
  });

  group('SpanRangeList Tests', () {
    test('Add and merge overlapping and adjacent ranges', () {
      final list = SpanRangeList();
      list.add(0, 5);
      expect(list.ranges.length, 1);
      expect(list.ranges.first, const TextSpanRange(0, 5));

      // Adjacent: [5..10] merges to [0..10]
      list.add(5, 10);
      expect(list.ranges.length, 1);
      expect(list.ranges.first, const TextSpanRange(0, 10));

      // Overlapping: [8..15] merges to [0..15]
      list.add(8, 15);
      expect(list.ranges.length, 1);
      expect(list.ranges.first, const TextSpanRange(0, 15));

      // Disjoint: [20..25]
      list.add(20, 25);
      expect(list.ranges.length, 2);
      expect(list.ranges[0], const TextSpanRange(0, 15));
      expect(list.ranges[1], const TextSpanRange(20, 25));
    });

    test('Remove ranges splits and trims intervals', () {
      final list = SpanRangeList();
      list.add(0, 20);

      // Cut middle: [5..10]
      list.remove(5, 10);
      expect(list.ranges.length, 2);
      expect(list.ranges[0], const TextSpanRange(0, 5));
      expect(list.ranges[1], const TextSpanRange(10, 20));

      // Remove overlapping start: [0..2]
      list.remove(0, 2);
      expect(list.ranges[0], const TextSpanRange(2, 5));

      // Remove entire right span
      list.remove(10, 20);
      expect(list.ranges.length, 1);
      expect(list.ranges[0], const TextSpanRange(2, 5));
    });

    test('Toggle ranges', () {
      final list = SpanRangeList();
      list.add(0, 10);

      expect(list.isCovered(0, 10), true);
      list.toggle(0, 10);
      expect(list.ranges.isEmpty, true);

      list.toggle(0, 10);
      expect(list.isCovered(0, 10), true);
    });

    test('Shift ranges on insertion and deletion', () {
      final list = SpanRangeList();
      list.add(5, 10);

      // Insertion before span: at offset 2, insert 3 chars -> span shifts from [5..10] to [8..13]
      list.onTextEdited(changeOffset: 2, deletedCount: 0, insertedCount: 3);
      expect(list.ranges.first, const TextSpanRange(8, 13));

      // Insertion inside span with extendCoveringSpan = true
      list.onTextEdited(
        changeOffset: 10,
        deletedCount: 0,
        insertedCount: 2,
        extendCoveringSpan: true,
      );
      expect(list.ranges.first, const TextSpanRange(8, 15));

      // Deletion before span: at offset 0, delete 4 chars -> shifts left to [4..11]
      list.onTextEdited(changeOffset: 0, deletedCount: 4, insertedCount: 0);
      expect(list.ranges.first, const TextSpanRange(4, 11));
    });
  });

  group('RichTextNoteController Unit Tests', () {
    test('Bold formatting does NOT insert literal ** into text', () {
      final controller = RichTextNoteController(text: 'Hello World');
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );

      // Apply bold to 'Hello'
      controller.toggleBold();

      // Text must remain completely clean plain text!
      expect(controller.text, 'Hello World');
      expect(controller.text.contains('*'), false);
      expect(controller.boldSpans.ranges.length, 1);
      expect(controller.boldSpans.ranges.first, const TextSpanRange(0, 5));
      expect(controller.isBoldActive, true);

      // Toggle bold off
      controller.toggleBold();
      expect(controller.boldSpans.ranges.isEmpty, true);
      expect(controller.isBoldActive, false);
    });

    test('Pending bold state when selection is collapsed', () {
      final controller = RichTextNoteController(text: 'Hi ');
      controller.selection = const TextSelection.collapsed(offset: 3);

      expect(controller.isBoldActive, false);
      controller.toggleBold();
      expect(controller.isBoldActive, true);
      expect(controller.pendingBold, true);

      // User types 'there'
      controller.value = const TextEditingValue(
        text: 'Hi there',
        selection: TextSelection.collapsed(offset: 8),
      );

      // 'there' [3..8] must be bold
      expect(controller.boldSpans.isCovered(3, 8), true);
      expect(controller.text, 'Hi there');
      expect(controller.text.contains('*'), false);
    });

    test('Italic formatting does NOT insert literal * into text', () {
      final controller = RichTextNoteController(text: 'Emphasis here');
      controller.selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 13,
      );

      controller.toggleItalic();
      expect(controller.text, 'Emphasis here');
      expect(controller.text.contains('*'), false);
      expect(controller.italicSpans.ranges.length, 1);
      expect(controller.italicSpans.ranges.first, const TextSpanRange(9, 13));
      expect(controller.isItalicActive, true);
    });

    test('Heading formatting toggles without inserting #', () {
      final controller = RichTextNoteController(text: 'Chapter One\nBody text');
      controller.selection = const TextSelection.collapsed(offset: 3);

      expect(controller.isHeadingActive, false);
      controller.toggleHeading();
      expect(controller.isHeadingActive, true);
      // No # inserted into the text!
      expect(controller.text.startsWith('#'), false);
      expect(controller.text, 'Chapter One\nBody text');

      // Move cursor to line 2
      controller.selection = const TextSelection.collapsed(offset: 14);
      expect(controller.isHeadingActive, false);

      // Back to line 1 and toggle heading off
      controller.selection = const TextSelection.collapsed(offset: 2);
      controller.toggleHeading();
      expect(controller.isHeadingActive, false);
    });

    test('Quote formatting toggles without inserting >', () {
      final controller = RichTextNoteController(text: 'Wisdom quote');
      controller.selection = const TextSelection.collapsed(offset: 2);

      controller.toggleQuote();
      expect(controller.isQuoteActive, true);
      expect(controller.text.startsWith('>'), false);
      expect(controller.text, 'Wisdom quote');

      controller.toggleQuote();
      expect(controller.isQuoteActive, false);
    });

    test('Bullet list toggle and Enter auto-continuation', () {
      final controller = RichTextNoteController(text: 'First item');
      controller.selection = const TextSelection.collapsed(offset: 5);

      // Toggle bullet list
      controller.toggleBulletList();
      expect(controller.text, '• First item');
      expect(controller.isBulletActive, true);

      // User presses Enter at the end of the line
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      controller.value = TextEditingValue(
        text: '${controller.text}\n',
        selection: TextSelection.collapsed(offset: controller.text.length + 1),
      );

      // Controller should auto-insert bullet for next line
      expect(controller.text, '• First item\n• ');
      expect(controller.selection.baseOffset, '• First item\n• '.length);

      // User presses Enter on the empty bullet -> exits list!
      controller.value = TextEditingValue(
        text: '${controller.text}\n',
        selection: TextSelection.collapsed(offset: controller.text.length + 1),
      );

      // Bullet prefix cleared naturally
      expect(controller.text, '• First item\n');
    });

    test('Markdown serialization and deserialization roundtrip', () {
      const sourceMarkdown =
          '## Main Heading\n\n- Task 1\n- Task 2\n\nThis is **bold** and *italic* with `code`.\n\n> Quotation';

      final controller = RichTextNoteController.fromMarkdown(sourceMarkdown);

      // In the editor text, NO #, NO **, NO *, NO ` appear!
      expect(controller.text.contains('##'), false);
      expect(controller.text.contains('**'), false);
      expect(controller.text.contains('`'), false);
      expect(controller.text.contains('>'), false);

      // Verify line styles & spans were accurately extracted
      controller.selection = const TextSelection.collapsed(offset: 0);
      expect(controller.isHeadingActive, true); // line 0 is heading
      expect(controller.boldSpans.ranges.isNotEmpty, true);
      expect(controller.italicSpans.ranges.isNotEmpty, true);
      expect(controller.codeSpans.ranges.isNotEmpty, true);

      // Line at end is quote
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      expect(controller.isQuoteActive, true);

      // Serialize back
      final serialized = controller.toMarkdown();
      expect(serialized.contains('## Main Heading'), true);
      expect(serialized.contains('**bold**'), true);
      expect(serialized.contains('*italic*'), true);
      expect(serialized.contains('`code`'), true);
      expect(serialized.contains('- Task 1'), true);
      expect(serialized.contains('> Quotation'), true);
    });
  });

  group('Editor Formatting Toolbar Widget Tests', () {
    testWidgets(
      'Bold and Heading toolbar buttons update visually without raw syntax',
      (WidgetTester tester) async {
        final note = await NotesRepository.instance.createNote(
          title: 'Design Ideas',
          content: 'Liquid glass styling is elegant',
        );

        await tester.pumpWidget(
          MaterialApp(home: NoteEditorScreen(initialNote: note)),
        );
        await tester.pumpAndSettle();

        // Find content TextField
        final contentField = find.byType(TextField).last;
        expect(contentField, findsOneWidget);

        // Verify initial text
        expect(find.text('Liquid glass styling is elegant'), findsOneWidget);

        // Tap Bold toolbar button
        final boldButton = find.byIcon(Icons.format_bold_rounded);
        expect(boldButton, findsOneWidget);
        await tester.tap(boldButton);
        await tester.pumpAndSettle();

        // Verify NO '**' was inserted into the text field
        final textFieldWidget = tester.widget<TextField>(contentField);
        expect(textFieldWidget.controller!.text.contains('**'), false);
        expect(textFieldWidget.controller!.text.contains('*'), false);

        // Tap Heading toolbar button
        final headingButton = find.byIcon(Icons.title_rounded);
        expect(headingButton, findsOneWidget);
        await tester.tap(headingButton);
        await tester.pumpAndSettle();

        // Verify NO '##' or '#' was inserted into the text field
        expect(textFieldWidget.controller!.text.contains('#'), false);
        expect(
          textFieldWidget.controller!.text,
          'Liquid glass styling is elegant',
        );

        // Tap Bullet List button
        final bulletButton = find.byIcon(Icons.format_list_bulleted_rounded);
        expect(bulletButton, findsOneWidget);
        await tester.tap(bulletButton);
        await tester.pumpAndSettle();

        // Verify bullet prefix is clean '• '
        expect(textFieldWidget.controller!.text.startsWith('• '), true);
      },
    );

    testWidgets(
      'Note cards preview snippet strips markdown for clean display',
      (WidgetTester tester) async {
        final noteWithMarkdown = NoteModel(
          id: 77,
          title: 'Roadmap',
          content: '## Overview\nThis is **crucial** and *urgent*.',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Preview snippet strips ## and ** for clean readable card excerpt
        expect(
          noteWithMarkdown.previewSnippet,
          'Overview\nThis is crucial and urgent.',
        );
      },
    );
  });
}
