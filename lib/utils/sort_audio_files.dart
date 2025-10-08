import 'package:divine_stream/models/audio_file.dart';

/// Compares two audio files by their leading numeric prefix (if any),
/// then alphabetically by full name.
int audioFileComparator(AudioFile a, AudioFile b) {
  final nameA = a.name;
  final nameB = b.name;

  // Extract leading digits like "01", "1.", "1-" etc. Splitting on spaces used
  // to miss names such as "1. Song", causing a lexical (1, 10, 11...) order.
  int? leadingNumber(String value) {
    final match = RegExp(r'^\s*(\d+)').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  final numberA = leadingNumber(nameA);
  final numberB = leadingNumber(nameB);

  // When both names start with digits, compare the numeric value so "2" comes
  // before "10" regardless of padding. Fall back to the text so duplicate
  // numbers stay alphabetised.
  if (numberA != null && numberB != null) {
    final numericCompare = numberA.compareTo(numberB);
    if (numericCompare != 0) {
      return numericCompare;
    }
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }

  // Prefer numbered tracks when only one of the names has a numeric prefix.
  if (numberA != null) return -1;
  if (numberB != null) return 1;

  // No leading digits on either name – fall back to a case-insensitive compare.
  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
}
