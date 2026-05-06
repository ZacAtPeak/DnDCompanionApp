class SavingThrowProficiencies {
  final bool strength;
  final bool dexterity;
  final bool constitution;
  final bool intelligence;
  final bool wisdom;
  final bool charisma;

  const SavingThrowProficiencies({
    this.strength = false,
    this.dexterity = false,
    this.constitution = false,
    this.intelligence = false,
    this.wisdom = false,
    this.charisma = false,
  });

  List<String> get proficientAbilities {
    final proficiencies = <String>[];
    if (strength) proficiencies.add('STR');
    if (dexterity) proficiencies.add('DEX');
    if (constitution) proficiencies.add('CON');
    if (intelligence) proficiencies.add('INT');
    if (wisdom) proficiencies.add('WIS');
    if (charisma) proficiencies.add('CHA');
    return proficiencies;
  }

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'charisma': charisma,
      };

  factory SavingThrowProficiencies.fromJson(Map<String, dynamic> json) =>
      SavingThrowProficiencies(
        strength: json['strength'] as bool? ?? false,
        dexterity: json['dexterity'] as bool? ?? false,
        constitution: json['constitution'] as bool? ?? false,
        intelligence: json['intelligence'] as bool? ?? false,
        wisdom: json['wisdom'] as bool? ?? false,
        charisma: json['charisma'] as bool? ?? false,
      );
}
