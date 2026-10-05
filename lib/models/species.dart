class Species {
  final int key;
  final String scientificName;
  final String? family;

  const Species({required this.key, required this.scientificName, this.family});

  factory Species.fromGbif(Map<String, dynamic> json) => Species(
        key: json['key'] as int,
        scientificName:
            (json['canonicalName'] ?? json['scientificName']) as String,
        family: json['family'] as String?,
      );
}

class SpeciesInfo {
  final String? description;
  final String? imageUrl;

  const SpeciesInfo({this.description, this.imageUrl});
}
