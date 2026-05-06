class AbilityScores {
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  const AbilityScores({
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
  });

  int get strMod => _modifier(strength);
  int get dexMod => _modifier(dexterity);
  int get conMod => _modifier(constitution);
  int get intMod => _modifier(intelligence);
  int get wisMod => _modifier(wisdom);
  int get chaMod => _modifier(charisma);

  static int _modifier(int score) => ((score - 10) / 2).floor();

  int modifierFor(String ability) {
    switch (ability.toLowerCase()) {
      case 'str':
      case 'strength':
        return strMod;
      case 'dex':
      case 'dexterity':
        return dexMod;
      case 'con':
      case 'constitution':
        return conMod;
      case 'int':
      case 'intelligence':
        return intMod;
      case 'wis':
      case 'wisdom':
        return wisMod;
      case 'cha':
      case 'charisma':
        return chaMod;
      default:
        throw ArgumentError('Unknown ability: $ability');
    }
  }

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'charisma': charisma,
      };

  factory AbilityScores.fromJson(Map<String, dynamic> json) => AbilityScores(
        strength: json['strength'] as int,
        dexterity: json['dexterity'] as int,
        constitution: json['constitution'] as int,
        intelligence: json['intelligence'] as int,
        wisdom: json['wisdom'] as int,
        charisma: json['charisma'] as int,
      );
}
