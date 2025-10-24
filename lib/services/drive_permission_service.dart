import 'dart:developer';

import 'package:divine_stream/helpers/app_helpers.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Lightweight guard that pings the Drive metadata endpoint to ensure a folder
/// or file is publicly reachable before we try to stream its contents.
class DrivePermissionService {
  DrivePermissionService();

  String get _apiKey => dotenv.env['GOOGLE_DRIVE_API_KEY'] ?? '';

  /// Returns true when the given folder ID responds with metadata using our
  /// public API key. Shows a toast when Google Drive denies access.
  Future<bool> ensureFolderAccess(String folderId) {
    return _ensureAccessible(folderId);
  }

  /// Returns true when the given file ID can be fetched with the public API key.
  /// This protects playback and auto-play from folders that are not shared.
  Future<bool> ensureFileAccess(String fileId) {
    return _ensureAccessible(fileId);
  }

  Future<bool> _ensureAccessible(String resourceId) async {
    if (resourceId.isEmpty || _apiKey.isEmpty) {
      // Without an ID or API key there is nothing useful to validate here.
      return true;
    }

    final uri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files/$resourceId',
      {
        'fields': 'id',
        'key': _apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      log('[DrivePermissionService] $resourceId accessible (200)');
      return true;
    }

    if (response.statusCode == 403 || response.statusCode == 404) {
      final bodyPreview = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      log('[DrivePermissionService] $resourceId denied (${response.statusCode}): $bodyPreview');
      Helpers.showToast(
        'Update the Google Drive sharing permissions and try again.',
      );
      return false;
    }

    log('[DrivePermissionService] $resourceId unexpected status ${response.statusCode}: ${response.body}');
    // Other errors (timeouts, 5xx) fall back to the existing error handlers so
    // unexpected issues aren't hidden behind the sharing toast.
    return true;
  }
}
