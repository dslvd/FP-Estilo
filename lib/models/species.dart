/// Models for the plant species data returned by the external APIs.
///
/// [Species] comes from the GBIF species search endpoint.
/// [SpeciesInfo] comes from the Wikipedia REST summary endpoint.
class Species {
  final int key;
  final String scientificName;
  final String? family;

  const Species({required this.key, required this.scientificName, this.family});

  /// Parses one entry of the GBIF `results` array.
  ///
  /// GBIF does not always supply `canonicalName`, so we fall back to the
  /// fuller `scientificName` (which includes the author, e.g. "K.Koch").
  factory Species.fromGbif(Map<String, dynamic> json) => Species(
    key: (json['key'] as num?)?.toInt() ?? 0,
    scientificName:
        (json['canonicalName'] ?? json['scientificName'] ?? 'Unknown')
            as String,
    family: json['family'] as String?,
  );

  @override
  String toString() => 'Species($key, $scientificName)';
}

/// The photo and description for a species, sourced from Wikipedia.
class SpeciesInfo {
  final String? description;
  final String? imageUrl;

  const SpeciesInfo({this.description, this.imageUrl});

  /// Parses the Wikipedia REST `page/summary` response body.
  factory SpeciesInfo.fromWikipedia(Map<String, dynamic> json) => SpeciesInfo(
    description: json['extract'] as String?,
    imageUrl:
        (json['thumbnail'] as Map<String, dynamic>?)?['source'] as String?,
  );

  static const empty = SpeciesInfo();
}
