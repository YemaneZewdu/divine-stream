
import 'package:divine_stream/models/audio_file.dart';

/// Compares two audio files by their leading numeric prefix (if any),
/// then alphabetically by full name.
int audioFileComparator(AudioFile a, AudioFile b) {
  final nameA = a.name;
  final nameB = b.name;

  // get the first word of each name
  final pA = nameA.split(' ').first;
  final pB = nameB.split(' ').first;

  // try parsing
  final nA = int.tryParse(pA);
  final nB = int.tryParse(pB);

  // both numbered? compare numerically
  if (nA != null && nB != null) {
    return nA.compareTo(nB);
  }

  // only A is numbered? A comes first
  if (nA != null) return -1;

  // only B is numbered? B comes first
  if (nB != null) return 1;

  // neither numbered? compare full names
  return nameA.compareTo(nameB);
}
