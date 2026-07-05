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
}