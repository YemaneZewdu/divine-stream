import 'package:divine_stream/models/audio_file.dart';

/// Shared comparator that orders strings by leading numbers before
/// falling back to text
int numericAwareNameCompare(String? rawA, String? rawB) {
  final nameA = rawA ?? '';
  final nameB = rawB ?? '';

  int? leadingNumber(String value) {
    final match = RegExp(r'^\s*(\d+)').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  final numberA = leadingNumber(nameA);
  final numberB = leadingNumber(nameB);

  if (numberA != null && numberB != null) {
    final numericCompare = numberA.compareTo(numberB);
    if (numericCompare != 0) {
      return numericCompare;
    }
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  }

  if (numberA != null) return -1;
  if (numberB != null) return 1;

  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
}

/// Reuses the shared comparator so track sorting stays consistent everywhere.
int audioFileComparator(AudioFile a, AudioFile b) {
  return numericAwareNameCompare(a.name, b.name);
}
