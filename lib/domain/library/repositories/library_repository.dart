import 'package:readspark/domain/library/entities/library_item.dart';

/// Read access to the library projection (ADR-005).
abstract interface class LibraryRepository {
  /// Emits the whole library whenever documents or progress change.
  Stream<List<LibraryItem>> watchItems();
}
