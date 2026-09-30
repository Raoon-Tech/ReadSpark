/// Small presentation labels (no external formatting deps).
abstract final class LibraryLabels {
  /// Human readable file size: `812 KB`, `1,4 MB`.
  static String size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '${_es(mb)} MB';
  }

  /// Relative date: `Hoy`, `Ayer`, `Hace 3 días`, `12/03/2026`.
  static String relativeDate(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final day = DateTime(date.year, date.month, date.day);
    final days = today.difference(day).inDays;

    if (days <= 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    if (days < 7) return 'Hace $days días';
    if (days < 14) return 'Hace 1 semana';
    if (days < 60) return 'Hace ${(days / 7).floor()} semanas';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Reading progress label: `45% leído` (or `null` when never read).
  static String? progress(double percentage) {
    if (percentage <= 0) return null;
    final rounded = (percentage * 100).round();
    return '$rounded% leído';
  }

  static String _es(String number) => number.replaceAll('.', ',');
}
