import 'player_character.dart';

class UserCharacter {
  final PlayerCharacter character;
  final DateTime createdAt;
  final DateTime lastModified;

  UserCharacter({
    required this.character,
    DateTime? createdAt,
    DateTime? lastModified,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastModified = lastModified ?? DateTime.now();

  String get name => character.name;
  String get race => character.race;
  String get playerClass => character.playerClass;
  int get level => character.level;
  int get currentHP => character.currentHP;
  int get maxHP => character.maxHP;
  int get armorClass => character.armorClass;

  UserCharacter copyWith({
    PlayerCharacter? character,
    DateTime? lastModified,
  }) {
    return UserCharacter(
      character: character ?? this.character,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'character': character.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
      };

  factory UserCharacter.fromJson(Map<String, dynamic> json) => UserCharacter(
        character: PlayerCharacter.fromJson(
            json['character'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastModified: DateTime.parse(json['lastModified'] as String),
      );
}
