class MovementSpeed {
  final int walk;
  final int? swim;
  final int? fly;
  final int? climb;
  final int? burrow;
  final bool hover;

  const MovementSpeed({
    required this.walk,
    this.swim,
    this.fly,
    this.climb,
    this.burrow,
    this.hover = false,
  });

  Map<String, dynamic> toJson() => {
        'walk': walk,
        'swim': swim,
        'fly': fly,
        'climb': climb,
        'burrow': burrow,
        'hover': hover,
      };

  factory MovementSpeed.fromJson(Map<String, dynamic> json) => MovementSpeed(
        walk: json['walk'] as int,
        swim: json['swim'] as int?,
        fly: json['fly'] as int?,
        climb: json['climb'] as int?,
        burrow: json['burrow'] as int?,
        hover: json['hover'] as bool? ?? false,
      );
}
