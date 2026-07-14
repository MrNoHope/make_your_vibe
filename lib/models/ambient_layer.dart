class AmbientLayer {
  final String id;
  final String name;
  final String assetPath;
  final double volume;
  final bool active;

  const AmbientLayer({
    required this.id,
    required this.name,
    this.assetPath = '',
    this.volume = 0,
    this.active = false,
  });

  AmbientLayer copyWith({
    double? volume,
    bool? active,
  }) {
    return AmbientLayer(
      id: id,
      name: name,
      assetPath: assetPath,
      volume: volume ?? this.volume,
      active: active ?? this.active,
    );
  }
}
