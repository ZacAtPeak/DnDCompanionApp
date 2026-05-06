import 'package:uuid/uuid.dart';

import 'ability_scores.dart';
import 'attack.dart';
import 'enums.dart';
import 'movement_speed.dart';
import 'saving_throw_proficiencies.dart';
import 'senses.dart';
import 'skill_proficiency.dart';
import 'special_ability.dart';
import 'spell_slot.dart';
import 'status_condition.dart';

class PlayerCharacter {
  final String id;
  final String name;
  final String race;
  final String playerClass;
  final int level;
  final String background;
  final CreatureSize size;
  final Alignment alignment;
  final int armorClass;
  final String armorSource;
  final int currentHP;
  final int maxHP;
  final String hitDice;
  final MovementSpeed speed;
  final AbilityScores abilityScores;
  final int proficiencyBonus;
  final SavingThrowProficiencies savingThrowProficiencies;
  final List<SkillProficiency> skills;
  final List<DamageType> damageVulnerabilities;
  final List<DamageType> damageResistances;
  final List<DamageType> damageImmunities;
  final List<String> conditionImmunities;
  final Senses senses;
  final List<String> languages;
  final List<SpecialAbility> specialAbilities;
  final List<Attack> actions;
  final List<SpellSlot> spellSlots;
  final List<String> knownSpells;
  final double initiative;
  final List<StatusCondition>? status;

  PlayerCharacter({
    String? id,
    required this.name,
    required this.race,
    required this.playerClass,
    required this.level,
    required this.background,
    required this.size,
    required this.alignment,
    required this.armorClass,
    required this.armorSource,
    required this.currentHP,
    required this.maxHP,
    required this.hitDice,
    required this.speed,
    required this.abilityScores,
    required this.proficiencyBonus,
    required this.savingThrowProficiencies,
    required this.skills,
    this.damageVulnerabilities = const [],
    this.damageResistances = const [],
    this.damageImmunities = const [],
    this.conditionImmunities = const [],
    required this.senses,
    required this.languages,
    this.specialAbilities = const [],
    this.actions = const [],
    this.spellSlots = const [],
    this.knownSpells = const [],
    this.initiative = 0.0,
    this.status,
  }) : id = id ?? const Uuid().v4();

  static int proficiencyBonusForLevel(int level) {
    if (level <= 4) return 2;
    if (level <= 8) return 3;
    if (level <= 12) return 4;
    if (level <= 16) return 5;
    return 6;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'race': race,
        'playerClass': playerClass,
        'level': level,
        'background': background,
        'size': size.name,
        'alignment': alignment.name,
        'armorClass': armorClass,
        'armorSource': armorSource,
        'currentHP': currentHP,
        'maxHP': maxHP,
        'hitDice': hitDice,
        'speed': speed.toJson(),
        'abilityScores': abilityScores.toJson(),
        'proficiencyBonus': proficiencyBonus,
        'savingThrowProficiencies': savingThrowProficiencies.toJson(),
        'skills': skills.map((s) => s.toJson()).toList(),
        'damageVulnerabilities': damageVulnerabilities.map((d) => d.name).toList(),
        'damageResistances': damageResistances.map((d) => d.name).toList(),
        'damageImmunities': damageImmunities.map((d) => d.name).toList(),
        'conditionImmunities': conditionImmunities,
        'senses': senses.toJson(),
        'languages': languages,
        'specialAbilities': specialAbilities.map((a) => a.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'spellSlots': spellSlots.map((s) => s.toJson()).toList(),
        'knownSpells': knownSpells,
        'initiative': initiative,
        'status': status?.map((s) => s.toJson()).toList(),
      };

  factory PlayerCharacter.fromJson(Map<String, dynamic> json) =>
      PlayerCharacter(
        id: json['id'] as String?,
        name: json['name'] as String,
        race: json['race'] as String,
        playerClass: json['playerClass'] as String,
        level: json['level'] as int,
        background: json['background'] as String,
        size: CreatureSize.fromString(json['size'] as String),
        alignment: Alignment.fromString(json['alignment'] as String),
        armorClass: json['armorClass'] as int,
        armorSource: json['armorSource'] as String,
        currentHP: json['currentHP'] as int,
        maxHP: json['maxHP'] as int,
        hitDice: json['hitDice'] as String,
        speed: MovementSpeed.fromJson(json['speed'] as Map<String, dynamic>),
        abilityScores:
            AbilityScores.fromJson(json['abilityScores'] as Map<String, dynamic>),
        proficiencyBonus: json['proficiencyBonus'] as int,
        savingThrowProficiencies: SavingThrowProficiencies.fromJson(
            json['savingThrowProficiencies'] as Map<String, dynamic>),
        skills: (json['skills'] as List<dynamic>)
            .map((s) => SkillProficiency.fromJson(s as Map<String, dynamic>))
            .toList(),
        damageVulnerabilities: (json['damageVulnerabilities'] as List<dynamic>)
            .map((d) => DamageType.fromString(d as String))
            .toList(),
        damageResistances: (json['damageResistances'] as List<dynamic>)
            .map((d) => DamageType.fromString(d as String))
            .toList(),
        damageImmunities: (json['damageImmunities'] as List<dynamic>)
            .map((d) => DamageType.fromString(d as String))
            .toList(),
        conditionImmunities:
            (json['conditionImmunities'] as List<dynamic>).cast<String>(),
        senses: Senses.fromJson(json['senses'] as Map<String, dynamic>),
        languages: (json['languages'] as List<dynamic>).cast<String>(),
        specialAbilities: (json['specialAbilities'] as List<dynamic>)
            .map((a) => SpecialAbility.fromJson(a as Map<String, dynamic>))
            .toList(),
        actions: (json['actions'] as List<dynamic>)
            .map((a) => Attack.fromJson(a as Map<String, dynamic>))
            .toList(),
        spellSlots: (json['spellSlots'] as List<dynamic>)
            .map((s) => SpellSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
        knownSpells: (json['knownSpells'] as List<dynamic>).cast<String>(),
        initiative: (json['initiative'] as num).toDouble(),
        status: json['status'] != null
            ? (json['status'] as List<dynamic>)
                .map((s) =>
                    StatusCondition.fromJson(s as Map<String, dynamic>))
                .toList()
            : null,
      );
}
