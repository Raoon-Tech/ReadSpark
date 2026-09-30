import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readspark/core/errors/import_exception.dart';
import 'package:readspark/domain/library/entities/library_item.dart';
import 'package:readspark/presentation/app/providers.dart';
import 'package:readspark/presentation/library/library_filter.dart';
import 'package:readspark/presentation/library/library_providers.dart';
import 'package:readspark/presentation/library/widgets/document_tile.dart';
import 'package:readspark/presentation/reader/reader_placeholder_screen.dart';

/// Main screen: import, browse, search, sort and delete documents —
/// fully offline (CU-01, CU-02, RF-01..RF-07, "Fase 3: biblioteca 100%").
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(libraryTabProvider);
    final visible = ref.watch(visibleLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Importar documento',
        onPressed: () => _importDocument(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<LibraryTab>(
              segments: const [
                ButtonSegment(
                  value: LibraryTab.continueReading,
                  label: Text('Continuar'),
                  tooltip: 'Continuar leyendo',
                ),
                ButtonSegment(
                  value: LibraryTab.recent,
                  label: Text('Recientes'),
                ),
                ButtonSegment(
                  value: LibraryTab.favorites,
                  label: Text('Favoritos'),
                ),
                ButtonSegment(value: LibraryTab.all, label: Text('Todos')),
              ],
              selected: {tab},
              onSelectionChanged: (selection) => ref
                  .read(libraryTabProvider.notifier)
                  .select(selection.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar por título',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () =>
                      ref.read(librarySearchProvider.notifier).update(''),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (query) =>
                  ref.read(librarySearchProvider.notifier).update(query),
            ),
          ),
          Expanded(child: _buildList(context, ref, visible)),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LibraryItem>> visible,
  ) {
    return visible.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _ErrorView(
        onRetry: () => ref.invalidate(libraryItemsProvider),
      ),
      data: (items) {
        if (items.isEmpty) return const _EmptyView();
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return DocumentTile(
              item: item,
              onOpen: () => _open(context, ref, item),
              onToggleFavorite: () => _toggleFavorite(ref, item),
              onDelete: () => _confirmDelete(context, ref, item),
            );
          },
        );
      },
    );
  }

  Future<void> _importDocument(BuildContext context, WidgetRef ref) async {
    try {
      final document = await ref.read(importDocumentProvider)();
      if (document == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«${document.title}» añadido a la biblioteca')),
      );
    } on ImportException catch (exception) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(exception.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo importar el documento. Inténtalo de nuevo.'),
        ),
      );
    }
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    LibraryItem item,
  ) async {
    await ref
        .read(documentRepositoryProvider)
        .touchLastOpened(item.document.id);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderPlaceholderScreen(
          documentTitle: item.document.title,
        ),
      ),
    );
  }

  void _toggleFavorite(WidgetRef ref, LibraryItem item) {
    final document = item.document;
    ref
        .read(documentRepositoryProvider)
        .setFavorite(document.id, !document.isFavorite);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LibraryItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text(
          'Se eliminará «${item.document.title}» de tu biblioteca. '
          'Tu archivo original no se toca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(deleteDocumentProvider)(item.document.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el documento. Inténtalo de nuevo.'),
        ),
      );
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.library_books_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              'Tu biblioteca está vacía',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Importa un PDF, DOCX, Markdown o TXT con el botón «+».\n'
              'Todo funciona sin conexión.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la biblioteca.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
