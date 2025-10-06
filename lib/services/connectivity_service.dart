import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:divine_stream/helpers/app_helpers.dart';

/// Centralizes lightweight connectivity checks so network-bound features can
/// bail out gracefully before hitting remote APIs.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Returns true when the device reports an active network connection.
  /// Optionally shows a default toast when connectivity is missing.
  Future<bool> ensureConnection({bool showToast = true}) async {
    final status = await _connectivity.checkConnectivity();
    final hasConnection = status != ConnectivityResult.none;

    if (!hasConnection && showToast) {
      Helpers.showToast('Poor network connection. Please try again.');
    }

    return hasConnection;
  }
}
