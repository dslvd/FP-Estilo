import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/species.dart';

/// A failure that the UI can show to the user without leaking stack traces.
class ApiException implements Exception {
  final String message;

  /// True when the request never reached the server (airplane mode, no Wi-Fi,
  /// DNS failure). The UI uses this to show a "you are offline" state rather
  /// than blaming the server, and to offer a "Try again" button.
  final bool isOffline;

  const ApiException(this.message, {this.isOffline = false});

  @override
  String toString() => message;
}

/// Talks to the two public APIs the app depends on.
///
/// * **GBIF** (`api.gbif.org`) supplies the species search results.
/// * **Wikipedia REST** (`en.wikipedia.org`) supplies a photo and a short
///   description for a species the user opened.
///
/// Neither API needs a key, so there is no secret to ship in the app. We do
/// send a descriptive `User-Agent` because that is what both services ask of
/// scripted clients, and it makes our traffic identifiable in their logs.
class PlantApi {
  PlantApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _headers = {'User-Agent': 'PlantPal/1.0 (student project)'};

  /// GBIF taxon key for the plant kingdom; restricts results to plants.
  static const _plantaeKey = 6;

  /// How long to wait before giving up on a request.
  static const _timeout = Duration(seconds: 15);

  /// Searches GBIF for accepted plant species matching [query].
  ///
  /// Throws [ApiException] on network failure, timeout, or a non-200 reply.
  Future<List<Species>> search(String query) async {
    final uri = Uri.https('api.gbif.org', '/v1/species/search', {
      'q': query,
      'rank': 'SPECIES',
      'status': 'ACCEPTED',
      'highertaxonKey': '$_plantaeKey',
      'limit': '20',
    });

    final body = await _get(uri, what: 'search plants');
    final results = (body['results'] as List<dynamic>?) ?? const [];
    final species = results
        .map((e) => Species.fromGbif(e as Map<String, dynamic>))
        .toList();

    // GBIF frequently returns the same species several times under different
    // taxon keys, so collapse duplicates by scientific name.
    final seen = <String>{};
    return species.where((s) => seen.add(s.scientificName)).toList();
  }

  /// Loads the photo and description for [scientificName] from Wikipedia.
  ///
  /// A missing article is not an error — it returns an empty [SpeciesInfo]
  /// so the screen can simply hide the description.
  Future<SpeciesInfo> info(String scientificName) async {
    final title = Uri.encodeComponent(scientificName.replaceAll(' ', '_'));
    final uri = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/$title',
    );

    try {
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 404) return SpeciesInfo.empty;
      if (res.statusCode != 200) {
        throw ApiException(
          'Wikipedia could not load this species (HTTP ${res.statusCode}).',
        );
      }
      return SpeciesInfo.fromWikipedia(
        jsonDecode(res.body) as Map<String, dynamic>,
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw _classify(error);
    }
  }

  /// Shared GET + decode + error-mapping used by [search].
  Future<Map<String, dynamic>> _get(Uri uri, {required String what}) async {
    try {
      final res = await _client.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode != 200) {
        throw ApiException('Could not $what (HTTP ${res.statusCode}).');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw _classify(error);
    }
  }

  /// Turns a transport-level error into an [ApiException].
  ///
  /// The tricky part is that the same "no network" failure arrives as a
  /// different type depending on the platform: native builds throw
  /// `SocketException` from `dart:io`, while Flutter web throws
  /// `http.ClientException` wrapping a `ProgressEvent` (there is no `dart:io`
  /// on the web at all). Both are matched here so the UI reports "you are
  /// offline" consistently everywhere, rather than blaming the server.
  ApiException _classify(Object error) {
    if (error is TimeoutException) {
      return const ApiException(
        'The request took too long. Check your connection.',
        isOffline: true,
      );
    }
    if (error is FormatException) {
      return const ApiException('The server sent data we could not read.');
    }
    if (error is http.ClientException) {
      return const ApiException('No internet connection.', isOffline: true);
    }
    // SocketException lives in dart:io, which does not exist on the web, so it
    // is matched by name rather than imported.
    if (error.runtimeType.toString() == 'SocketException') {
      return const ApiException('No internet connection.', isOffline: true);
    }
    return const ApiException('Something went wrong. Please try again.');
  }

  void dispose() => _client.close();
}
