class SpellSlot {
  final int level;
  final int max;
  final int available;

  const SpellSlot({
    required this.level,
    required this.max,
    required this.available,
  });

  String get romanNumeral {
    switch (level) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      case 5:
        return 'V';
      case 6:
        return 'VI';
      case 7:
        return 'VII';
      case 8:
        return 'VIII';
      case 9:
        return 'IX';
      default:
        return level.toString();
    }
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'max': max,
        'available': available,
      };

  factory SpellSlot.fromJson(Map<String, dynamic> json) => SpellSlot(
        level: json['level'] as int,
        max: json['max'] as int,
        available: json['available'] as int,
      );
}
