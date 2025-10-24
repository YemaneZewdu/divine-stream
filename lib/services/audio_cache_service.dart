import 'dart:developer';
import 'dart:convert';
import 'dart:io';

import 'package:divine_stream/models/audio_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

//  Downloads and stores audio files in the OS temporary directory so playback
//  can reuse local copies instead of repeatedly streaming from Firebase/Drive.
class AudioCacheService {
  final Map<String, String> _cache = {};
  final Set<String> _inFlight = {};
  final Set<String> _recentFailures = {};

  // Returns a cached file path when it already exists on disk.
  String? cachedPathFor(String audioId) => _cache[audioId];

  // Ensures the given audio file is cached locally. When successful the
  // absolute file path is returned; otherwise `null` indicates the remote copy
  // should be streamed instead (e.g. Drive returned 403).
  Future<String?> ensureCached(AudioFile file, String remoteUrl) async {
    if (_cache.containsKey(file.id)) {
      return _cache[file.id];
    }

    // Reuse a previous download that still exists on disk.
    final existing = await _locateExistingFile(file.id);
    if (existing != null) {
      _cache[file.id] = existing;
      return existing;
    }

    if (_inFlight.contains(file.id)) {
      // Another request is already downloading the same asset.
      return null;
    }

    _inFlight.add(file.id);
    try {
      final downloadPath = await _downloadToTemp(file.id, remoteUrl);
      if (downloadPath != null) {
        _cache[file.id] = downloadPath;
      }
      return downloadPath;
    } finally {
      _inFlight.remove(file.id);
    }
  }

  //  Prefetch a slice of upcoming tracks sequentially so we stay ahead of
  //  user playback without hammering the backing storage API.
  Future<void> prefetch(
    List<AudioFile> files,
    List<String> remoteUrls, {
    required int startIndex,
    int count = 3,
    Duration throttle = const Duration(seconds: 2),
  }) async {
    if (files.isEmpty) return;

    var start = startIndex < 0 ? 0 : startIndex;
    if (start >= files.length) return;

    var end = start + count;
    if (end > files.length) {
      end = files.length;
    }
    for (var i = start; i < end; i++) {
      if (_recentFailures.contains(files[i].id)) {
        // Skip items that recently failed to avoid spamming Drive while quota is tight.
        continue;
      }

      final result = await ensureCached(files[i], remoteUrls[i]);
      if (result == null) {
        _recentFailures.add(files[i].id);
      }

      if (throttle > Duration.zero) {
        await Future.delayed(throttle);
      }
    }

    // Let failures be retried later by clearing the marker after a delay.
    if (_recentFailures.isNotEmpty) {
      Future.delayed(const Duration(minutes: 5), _recentFailures.clear);
    }
  }

  Future<String?> _locateExistingFile(String audioId) async {
    final dir = await getTemporaryDirectory();
    final candidate = File('${dir.path}/${_fileNameFor(audioId)}');
    if (await candidate.exists()) {
      return candidate.path;
    }
    return null;
  }

  Future<String?> _downloadToTemp(String audioId, String remoteUrl) async {
    try {
      final uri = Uri.parse(remoteUrl);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        log('[AudioCacheService] Download failed for $audioId (${response.statusCode})');
        return null;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${_fileNameFor(audioId)}');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      log('[AudioCacheService] Cached $audioId at ${file.path}');
      return file.path;
    } catch (e) {
      log('[AudioCacheService] Exception while caching $audioId: $e');
      return null;
    }
  }

  String _fileNameFor(String audioId) {
    //  Avoid filesystem edge cases (spaces, unicode, slashes) by hashing the id.
    final hash = base64Url.encode(utf8.encode(audioId)).replaceAll('=', '');
    final extension = _extensionFrom(audioId);
    if (extension != null) {
      //  Preserve the original audio extension so iOS can recognise the downloaded file.
      return '$hash$extension';
    }
    return '$hash.cache';
  }

  String? _extensionFrom(String value) {
    final dotIndex = value.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == value.length - 1) {
      return null;
    }

    final candidate = value.substring(dotIndex);
    if (candidate.length > 6) {
      //  Ignore suspiciously long "extensions" that probably include query params.
      return null;
    }
    return candidate;
  }
}
