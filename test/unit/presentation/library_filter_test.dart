import 'package:flutter_test/flutter_test.dart';
import 'package:readspark/domain/library/entities/library_item.dart';
import 'package:readspark/presentation/library/library_filter.dart';

import '../../helpers/fakes.dart';

LibraryItem _item(
  String id, {
  String? title,
  bool favorite = false,
  DateTime? lastOpenedAt,
  DateTime? lastReadAt,
  DateTime? addedAt,
}) {
  return LibraryItem(
    document: buildTestDocument(
      id,
      title: title,
      isFavorite: favorite,
      lastOpenedAt: lastOpenedAt,
      addedAt: addedAt,
    ),
    percentage: lastReadAt == null ? 0 : 0.5,
    lastReadAt: lastReadAt,
  );
}

void main() {
  final day1 = DateTime.utc(2026, 3, 1);
  final day2 = DateTime.utc(2026, 3, 2);
  final day3 = DateTime.utc(2026, 3, 3);

  late List<LibraryItem> items;

  setUp(() {
    items = [
      _item('a', title: 'Alpha', lastReadAt: day2, lastOpenedAt: day1),
      _item('b', title: 'beta', lastReadAt: day3),
      _item('c', title: 'Gamma', favorite: true, lastOpenedAt: day3),
      _item('d', title: 'delta'),
    ];
  });

  test('search matches titles case-insensitively (RF-05)', () {
    final result = applyLibraryView(
      items,
      tab: LibraryTab.all,
      search: 'ALP',
    );

    expect(result.map((i) => i.document.id), ['a']);
  });

  test('continue reading keeps only items with progress, newest first', () {
    final result = applyLibraryView(items, tab: LibraryTab.continueReading);

    expect(result.map((i) => i.document.id), ['b', 'a']);
  });

  test('recent orders by last opened, then by added (RF-04)', () {
    final result = applyLibraryView(items, tab: LibraryTab.recent);

    expect(result.map((i) => i.document.id), ['c', 'a', 'b', 'd']);
  });

  test('favorites keeps only favorites (RF-07)', () {
    final result = applyLibraryView(items, tab: LibraryTab.favorites);

    expect(result.map((i) => i.document.id), ['c']);
  });

  test('all sorts alphabetically', () {
    final result = applyLibraryView(items, tab: LibraryTab.all);

    expect(result.map((i) => i.document.title), ['Alpha', 'beta', 'delta', 'Gamma']);
  });

  test('does not mutate the input list', () {
    final before = items.map((i) => i.document.id).toList();

    applyLibraryView(items, tab: LibraryTab.continueReading, search: 'a');

    expect(items.map((i) => i.document.id), before);
  });
}
