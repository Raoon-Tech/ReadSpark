import 'package:flutter_test/flutter_test.dart';

import 'package:readspark/presentation/reader/reader_search.dart';

import '../../helpers/fakes.dart';

void main() {
  final content = buildReaderContent('d1');

  List<ReaderMatch> search(String query) => findParagraphMatches(
        sections: content.sections,
        paragraphs: content.paragraphs,
        query: query,
      );

  test('finds case-insensitive substring matches in reading order (RF-12)',
      () {
    final matches = search('BUSCA');

    expect(matches, hasLength(1));
    expect(matches.single.paragraphIndex, 1);
    expect(matches.single.sectionIndex, 1);
  });

  test('returns every matching paragraph in order', () {
    final matches = search('paragraph');

    expect(matches.map((match) => match.paragraphIndex), [0, 1, 2]);
    expect(matches.map((match) => match.sectionIndex), [0, 1, 1]);
  });

  test('blank or non-matching queries return no matches', () {
    expect(search(''), isEmpty);
    expect(search('   '), isEmpty);
    expect(search('zzz-unfindable'), isEmpty);
  });
}
