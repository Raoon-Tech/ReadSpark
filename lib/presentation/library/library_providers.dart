import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readspark/domain/library/entities/library_item.dart';
import 'package:readspark/presentation/app/providers.dart';
import 'package:readspark/presentation/library/library_filter.dart';

/// Currently selected library section (RF-04).
final libraryTabProvider =
    NotifierProvider<LibraryTabController, LibraryTab>(
  LibraryTabController.new,
);

class LibraryTabController extends Notifier<LibraryTab> {
  @override
  LibraryTab build() => LibraryTab.continueReading;

  void select(LibraryTab tab) => state = tab;
}

/// Current title search text (RF-05).
final librarySearchProvider = NotifierProvider<LibrarySearchController, String>(
  LibrarySearchController.new,
);

class LibrarySearchController extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

/// Full library, reactive (emits on import/delete/favorite/progress).
final libraryItemsProvider = StreamProvider<List<LibraryItem>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchItems(),
);

/// What the screen shows: search + section applied to [libraryItemsProvider].
final visibleLibraryProvider = Provider<AsyncValue<List<LibraryItem>>>((ref) {
  final items = ref.watch(libraryItemsProvider);
  final tab = ref.watch(libraryTabProvider);
  final search = ref.watch(librarySearchProvider);
  return items.whenData(
    (all) => applyLibraryView(all, tab: tab, search: search),
  );
});
