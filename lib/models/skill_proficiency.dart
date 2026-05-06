class SkillProficiency {
  final String skill;
  final bool isProficient;
  final int bonus;
  final String abilityScore;

  const SkillProficiency({
    required this.skill,
    required this.isProficient,
    required this.bonus,
    required this.abilityScore,
  });

  Map<String, dynamic> toJson() => {
        'skill': skill,
        'isProficient': isProficient,
        'bonus': bonus,
        'abilityScore': abilityScore,
      };

  factory SkillProficiency.fromJson(Map<String, dynamic> json) =>
      SkillProficiency(
        skill: json['skill'] as String,
        isProficient: json['isProficient'] as bool,
        bonus: json['bonus'] as int,
        abilityScore: json['abilityScore'] as String,
      );

  static int calculateBonus(
    int abilityModifier,
    bool isProficient,
    int proficiencyBonus,
  ) {
    return abilityModifier + (isProficient ? proficiencyBonus : 0);
  }
}

const Map<String, String> kSkillAbilityMap = {
  'Acrobatics': 'DEX',
  'Animal Handling': 'WIS',
  'Arcana': 'INT',
  'Athletics': 'STR',
  'Deception': 'CHA',
  'History': 'INT',
  'Insight': 'WIS',
  'Intimidation': 'CHA',
  'Investigation': 'INT',
  'Medicine': 'WIS',
  'Nature': 'INT',
  'Perception': 'WIS',
  'Performance': 'CHA',
  'Persuasion': 'CHA',
  'Religion': 'INT',
  'Sleight of Hand': 'DEX',
  'Stealth': 'DEX',
  'Survival': 'WIS',
};

const List<String> kAllSkills = [
  'Acrobatics',
  'Animal Handling',
  'Arcana',
  'Athletics',
  'Deception',
  'History',
  'Insight',
  'Intimidation',
  'Investigation',
  'Medicine',
  'Nature',
  'Perception',
  'Performance',
  'Persuasion',
  'Religion',
  'Sleight of Hand',
  'Stealth',
  'Survival',
];
