import 'package:flutter/material.dart';

/// Shown when a document is opened. The real reader lands in Phase 5
/// (Fase 5 — Lector visual).
class ReaderPlaceholderScreen extends StatelessWidget {
  const ReaderPlaceholderScreen({super.key, required this.documentTitle});

  final String documentTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(documentTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Documento abierto',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '«$documentTitle»\n'
                'El lector visual estará disponible en la Fase 5.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
