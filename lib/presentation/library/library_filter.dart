import 'package:readspark/domain/library/entities/library_item.dart';

/// Sections of the library screen (RF-04, §22).
enum LibraryTab {
  /// "Continuar leyendo": documents with saved progress, most recent first.
  continueReading,

  /// "Recientes": everything ordered by last opened (fallback: added).
  recent,

  /// "Favoritos": only favorites, most recently opened first.
  favorites,

  /// "Todos": every document, alphabetical by title.
  all,
}

/// Pure filter + sort for the visible library list (RF-04, RF-05).
/// Returns a new list; never mutates [items].
List<LibraryItem> applyLibraryView(
  List<LibraryItem> items, {
  required LibraryTab tab,
  String search = '',
}) {
  var visible = items;

  final query = search.trim().toLowerCase();
  if (query.isNotEmpty) {
    visible = [
      for (final item in visible)
        if (item.document.title.toLowerCase().contains(query)) item,
    ];
  }

  visible = [...visible];
  switch (tab) {
    case LibraryTab.continueReading:
      visible.retainWhere((item) => item.hasProgress);
      visible.sort(_byLastRead);
    case LibraryTab.recent:
      visible.sort(_byRecency);
    case LibraryTab.favorites:
      visible.retainWhere((item) => item.document.isFavorite);
      visible.sort(_byRecency);
    case LibraryTab.all:
      visible.sort(_byTitle);
  }
  return visible;
}

int _byTitle(LibraryItem a, LibraryItem b) =>
    a.document.title.toLowerCase().compareTo(b.document.title.toLowerCase());

int _byLastRead(LibraryItem a, LibraryItem b) {
  final aDate = a.lastReadAt;
  final bDate = b.lastReadAt;
  if (aDate == null && bDate == null) return _byTitle(a, b);
  if (aDate == null) return 1; // nulls last
  if (bDate == null) return -1;
  final byDate = bDate.compareTo(aDate);
  return byDate != 0 ? byDate : _byTitle(a, b);
}

int _byRecency(LibraryItem a, LibraryItem b) {
  final aDate = a.document.lastOpenedAt ?? a.document.addedAt;
  final bDate = b.document.lastOpenedAt ?? b.document.addedAt;
  final byDate = bDate.compareTo(aDate);
  return byDate != 0 ? byDate : _byTitle(a, b);
}
