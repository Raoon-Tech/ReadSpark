import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:readspark/domain/documents/entities/document.dart';
import 'package:readspark/domain/settings/entities/app_settings.dart';
import 'package:readspark/presentation/app/providers.dart';
import 'package:readspark/presentation/reader/reader_search.dart';

/// Visual reader (Fase 5, RF-10..RF-14, §23): renders the common
/// `DocumentModel` regardless of the original format, with section
/// navigation, in-document search, font scaling and theme switching.
///
/// Rendering uses a single scroll view so every paragraph is reachable by
/// `Scrollable.ensureVisible` (search/page jumps). If large documents
/// measure slow, Fase 9 migrates to lazy list + pagination (§26: "no
/// optimizar prematuramente; medir primero").
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.documentId,
    this.documentTitle,
  });

  final String documentId;

  /// Shown on the app bar while the content loads (RF-02 metadata).
  final String? documentTitle;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final Future<DocumentContent?> _contentFuture;
  DocumentContent? _content;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final List<GlobalKey> _sectionKeys = [];
  final Map<int, GlobalKey> _paragraphKeys = {};

  int _sectionIndex = 0;
  bool _searchOpen = false;
  String _query = '';
  List<ReaderMatch> _matches = const [];
  int _matchCursor = -1;
  double? _fontScaleOverride;

  @override
  void initState() {
    super.initState();
    _contentFuture = ref
        .read(documentRepositoryProvider)
        .getContent(widget.documentId)
        .then((content) {
      if (mounted) {
        setState(() {
          _content = content;
          _sectionKeys
            ..clear()
            ..addAll([
              for (final _ in content?.sections ?? const <DocumentSection>[])
                GlobalKey(),
            ]);
        });
      }
      return content;
    });
    _scrollController.addListener(_trackCurrentSection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Navigation (RF-11) ────────────────────────────────────────────────

  void _trackCurrentSection() {
    final content = _content;
    if (content == null || _sectionKeys.isEmpty) return;
    final threshold = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    var current = 0;
    for (var index = 0; index < _sectionKeys.length; index++) {
      final renderObject = _sectionKeys[index].currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;
      final dy = renderObject.localToGlobal(Offset.zero).dy;
      if (dy <= threshold) {
        current = index;
      } else {
        break;
      }
    }
    if (current != _sectionIndex) {
      setState(() => _sectionIndex = current);
    }
  }

  void _jumpToSection(int index) {
    final content = _content;
    if (content == null) return;
    final target = index.clamp(0, content.sections.length - 1);
    if (target == _sectionIndex) return;
    setState(() => _sectionIndex = target);
    _reveal(_sectionKeys[target]);
  }

  void _reveal(GlobalKey key) {
    setState(() {}); // Rebuild so lazily created keys are attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  GlobalKey _paragraphKey(int index) =>
      _paragraphKeys.putIfAbsent(index, GlobalKey.new);

  Future<void> _pickSection() async {
    final content = _content;
    if (content == null || content.sections.isEmpty) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: content.sections.length,
          itemBuilder: (context, index) => ListTile(
            leading: Text('${index + 1}'),
            title: Text(
              content.sections[index].title.isEmpty
                  ? 'Inicio'
                  : content.sections[index].title,
            ),
            selected: index == _sectionIndex,
            onTap: () => Navigator.of(context).pop(index),
          ),
        ),
      ),
    );
    if (selected != null) _jumpToSection(selected);
  }

  Future<void> _jumpToPage() async {
    final content = _content;
    if (content == null || content.document.totalPages == null) return;
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ir a la página (1–${content.document.totalPages})'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Número de página'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ir'),
          ),
        ],
      ),
    );
    if (submitted != true) return;
    final pageNumber = int.tryParse(controller.text.trim());
    if (pageNumber == null || content.paragraphs.isEmpty) return;

    var target = -1;
    for (var index = 0; index < content.paragraphs.length; index++) {
      final page = content.paragraphs[index].pageNumber;
      if (page != null && page >= pageNumber) {
        target = index;
        break;
      }
    }
    if (target == -1) target = content.paragraphs.length - 1;
    _reveal(_paragraphKey(target));
  }

  // ── Search (RF-12) ────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    final content = _content;
    if (content == null) return;
    setState(() {
      _query = value;
      _matches = findParagraphMatches(
        sections: content.sections,
        paragraphs: content.paragraphs,
        query: value,
      );
      _matchCursor = _matches.isEmpty ? -1 : 0;
    });
    if (_matches.isNotEmpty) _revealCurrentMatch();
  }

  void _cycleMatch(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _matchCursor = (_matchCursor + delta) % _matches.length;
      if (_matchCursor < 0) _matchCursor += _matches.length;
    });
    _revealCurrentMatch();
  }

  void _revealCurrentMatch() {
    if (_matchCursor < 0 || _matchCursor >= _matches.length) return;
    _reveal(_paragraphKey(_matches[_matchCursor].paragraphIndex));
  }

  void _closeSearch() {
    setState(() {
      _searchOpen = false;
      _query = '';
      _matches = const [];
      _matchCursor = -1;
    });
    _searchController.clear();
  }

  // ── Preferences: font scale + theme (RF-13) ───────────────────────────

  double get _fontScale =>
      _fontScaleOverride ??
      ref.watch(appSettingsProvider).value?.fontScale ??
      1.0;

  void _changeFontScale(double delta) {
    final current = _fontScale;
    final next =
        double.parse((current + delta).clamp(0.8, 2.0).toStringAsFixed(2));
    setState(() => _fontScaleOverride = next);
    ref
        .read(settingsRepositoryProvider)
        .setAll({AppSettings.keyFontScale: next.toString()});
    ref.invalidate(appSettingsProvider);
  }

  void _cycleTheme() {
    final current =
        ref.read(appSettingsProvider).value?.theme ?? 'system';
    final next = switch (current) {
      'system' => 'light',
      'light' => 'dark',
      _ => 'system',
    };
    ref
        .read(settingsRepositoryProvider)
        .setAll({AppSettings.keyTheme: next});
    ref.invalidate(appSettingsProvider);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).value;
    final themeValue = settings?.theme ?? 'system';
    final content = _content;

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): () =>
            _jumpToSection(_sectionIndex - 1),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): () =>
            _jumpToSection(_sectionIndex + 1),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content?.document.title ?? widget.documentTitle ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (content != null)
                  Text(
                    _sectionLabel(content),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _searchOpen ? 'Cerrar búsqueda' : 'Buscar en el documento',
                icon: Icon(
                  _searchOpen ? Icons.search_off : Icons.search,
                ),
                onPressed: _searchOpen ? _closeSearch : _openSearch,
              ),
              IconButton(
                tooltip: 'Reducir tamaño de texto',
                icon: const Icon(Icons.text_decrease),
                onPressed: () => _changeFontScale(-0.1),
              ),
              IconButton(
                tooltip: 'Aumentar tamaño de texto',
                icon: const Icon(Icons.text_increase),
                onPressed: () => _changeFontScale(0.1),
              ),
              IconButton(
                tooltip: 'Tema: $themeValue (tocar para cambiar)',
                icon: Icon(switch (themeValue) {
                  'light' => Icons.light_mode,
                  'dark' => Icons.dark_mode,
                  _ => Icons.brightness_auto,
                }),
                onPressed: _cycleTheme,
              ),
            ],
          ),
          bottomNavigationBar: content == null || content.sections.isEmpty
              ? null
              : _controlsBar(content),
          body: _buildBody(),
        ),
      ),
    );
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
  }

  String _sectionLabel(DocumentContent content) {
    if (content.sections.isEmpty) return '';
    final title = content.sections[_sectionIndex].title;
    final name = title.isEmpty ? 'Inicio' : title;
    return '${_sectionIndex + 1}/${content.sections.length} · $name';
  }

  Widget _buildBody() {
    return FutureBuilder<DocumentContent?>(
      future: _contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final content = snapshot.data;
        if (content == null) {
          return _MessageView(
            icon: Icons.error_outline,
            title: 'No se pudo abrir el documento',
            message: 'Puede que se haya eliminado. Vuelve a la biblioteca.',
          );
        }
        if (content.paragraphs.isEmpty) {
          return content.document.textExtractable
              ? const _MessageView(
                  icon: Icons.menu_book_outlined,
                  title: 'Sin contenido',
                  message: 'Este documento no tiene texto para mostrar.',
                )
              : const _MessageView(
                  icon: Icons.document_scanner_outlined,
                  title: 'PDF escaneado',
                  message:
                      'Este PDF parece estar escaneado. Requiere OCR '
                      '(disponible en versiones futuras).',
                );
        }
        return Column(
          children: [
            if (_searchOpen) _searchBar(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: _ReaderContent(
                  content: content,
                  fontScale: _fontScale,
                  sectionKeys: _sectionKeys,
                  paragraphKey: _paragraphKey,
                  matches: _matches,
                  matchCursor: _matchCursor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _searchBar() {
    final hasQuery = _query.trim().isNotEmpty;
    final status = !hasQuery
        ? ''
        : _matches.isEmpty
            ? 'Sin resultados'
            : '${_matchCursor + 1}/${_matches.length}';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                  hintText: 'Buscar en el documento',
                ),
              ),
            ),
            if (status.isNotEmpty)
              Text(status, style: Theme.of(context).textTheme.labelMedium),
            IconButton(
              tooltip: 'Coincidencia anterior',
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: _matches.isEmpty ? null : () => _cycleMatch(-1),
            ),
            IconButton(
              tooltip: 'Coincidencia siguiente',
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: _matches.isEmpty ? null : () => _cycleMatch(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlsBar(DocumentContent content) {
    final totalPages = content.document.totalPages;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Sección anterior',
              icon: const Icon(Icons.chevron_left),
              onPressed: _sectionIndex > 0
                  ? () => _jumpToSection(_sectionIndex - 1)
                  : null,
            ),
            Expanded(
              child: TextButton(
                onPressed: _pickSection,
                child: Text(
                  _sectionLabel(content),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Sección siguiente',
              icon: const Icon(Icons.chevron_right),
              onPressed: _sectionIndex < content.sections.length - 1
                  ? () => _jumpToSection(_sectionIndex + 1)
                  : null,
            ),
            if (totalPages != null)
              TextButton.icon(
                onPressed: _jumpToPage,
                icon: const Icon(Icons.article_outlined, size: 18),
                label: Text('$totalPages págs'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Flattened rendering: a header per section plus its paragraphs.
class _ReaderContent extends StatelessWidget {
  const _ReaderContent({
    required this.content,
    required this.fontScale,
    required this.sectionKeys,
    required this.paragraphKey,
    required this.matches,
    required this.matchCursor,
  });

  final DocumentContent content;
  final double fontScale;
  final List<GlobalKey> sectionKeys;
  final GlobalKey Function(int index) paragraphKey;
  final List<ReaderMatch> matches;
  final int matchCursor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge ?? const TextStyle();
    final matchedIndexes = {for (final match in matches) match.paragraphIndex};
    final currentMatch =
        matchCursor >= 0 && matchCursor < matches.length
            ? matches[matchCursor].paragraphIndex
            : -1;

    final paragraphIndexBySection = <String, List<int>>{};
    for (var index = 0; index < content.paragraphs.length; index++) {
      final sectionId = content.paragraphs[index].sectionId;
      (paragraphIndexBySection[sectionId] ??= []).add(index);
    }

    final children = <Widget>[];
    for (final section in content.sections) {
      final key = sectionKeys.length > section.order
          ? sectionKeys[section.order]
          : GlobalKey();
      children.add(
        Container(
          key: key,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            section.title.isEmpty ? ' ' : section.title,
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
      for (final paragraphIndex
          in paragraphIndexBySection[section.id] ?? const <int>[]) {
        children.add(_ParagraphView(
          key: paragraphKey(paragraphIndex),
          text: content.paragraphs[paragraphIndex].text,
          style: baseStyle.copyWith(height: 1.6, fontSize: 16 * fontScale),
          highlighted: matchedIndexes.contains(paragraphIndex),
          current: paragraphIndex == currentMatch,
        ));
        children.add(const SizedBox(height: 10));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({
    super.key,
    required this.text,
    required this.style,
    required this.highlighted,
    required this.current,
  });

  final String text;
  final TextStyle style;
  final bool highlighted;
  final bool current;

  @override
  Widget build(BuildContext context) {
    if (!highlighted) return Text(text, style: style);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: current
            ? scheme.primaryContainer
            : scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(text, style: style),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
