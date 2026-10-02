String _two(int value) => value.toString().padLeft(2, '0');

/// `02/10 às 14:08` no fuso do aparelho.
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.day)}/${_two(local.month)} às '
      '${_two(local.hour)}:${_two(local.minute)}';
}

/// `14:08:26` no fuso do aparelho.
String formatTime(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
}

/// "agora", "há 5 min", "há 2 h" ou a data, relativo a [now].
String formatRelative(DateTime value, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(value);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inHours < 1) return 'há ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'há ${diff.inHours} h';
  return formatDateTime(value);
}
