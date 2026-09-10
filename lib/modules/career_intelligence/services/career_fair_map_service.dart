import 'package:url_launcher/url_launcher.dart';

import '../models/career_fair.dart';

typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

class CareerFairMapService {
  CareerFairMapService({ExternalUriLauncher? launcher})
    : _launcher = launcher ?? _launchExternally;

  final ExternalUriLauncher _launcher;

  Uri? buildMapUri(CareerFair fair) {
    final String query;
    if (fair.hasCoordinates) {
      query = '${fair.latitude},${fair.longitude}';
    } else {
      final address = fair.address.trim();
      if (address.isEmpty) return null;
      query = address;
    }

    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  Future<bool> launchLocation(CareerFair fair) async {
    final uri = buildMapUri(fair);
    if (uri == null) return false;

    try {
      return await _launcher(uri);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
