import 'package:flutter/material.dart';

import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/library/entities/library_item.dart';
import 'package:readspark/presentation/library/library_labels.dart';

/// One row of the library list: icon, title, metadata and actions
/// (RF-03, RF-07).
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  final LibraryItem item;
  final VoidCallback onOpen;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  static const _menuDelete = 'delete';

  @override
  Widget build(BuildContext context) {
    final document = item.document;
    final progress = LibraryLabels.progress(item.percentage);
    final lastOpened = document.lastOpenedAt;
    final dateLabel = LibraryLabels.relativeDate(
      lastOpened ?? document.addedAt,
    );
    final subtitle = <String>[
      formatLabel(document.format),
      LibraryLabels.size(document.fileSize),
      dateLabel,
      ?progress,
    ].join(' · ');

    return ListTile(
      leading: Icon(_formatIcon(document.format)),
      title: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              document.isFavorite ? Icons.star : Icons.star_border,
              color: document.isFavorite ? Colors.amber : null,
            ),
            tooltip: document.isFavorite
                ? 'Quitar de favoritos'
                : 'Añadir a favoritos',
            onPressed: onToggleFavorite,
          ),
          PopupMenuButton<String>(
            tooltip: 'Más acciones',
            onSelected: (value) {
              if (value == _menuDelete) onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _menuDelete, child: Text('Eliminar')),
            ],
          ),
        ],
      ),
      onTap: onOpen,
    );
  }

  static IconData _formatIcon(DocumentFormat format) {
    switch (format) {
      case DocumentFormat.pdf:
        return Icons.picture_as_pdf;
      case DocumentFormat.docx:
        return Icons.description;
      case DocumentFormat.markdown:
        return Icons.code;
      case DocumentFormat.txt:
        return Icons.text_snippet;
    }
  }

  static String formatLabel(DocumentFormat format) {
    switch (format) {
      case DocumentFormat.pdf:
        return 'PDF';
      case DocumentFormat.docx:
        return 'DOCX';
      case DocumentFormat.markdown:
        return 'MD';
      case DocumentFormat.txt:
        return 'TXT';
    }
  }
}
