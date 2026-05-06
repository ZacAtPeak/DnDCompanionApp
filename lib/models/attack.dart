import 'package:uuid/uuid.dart';

import 'enums.dart';

class Attack {
  final String id;
  final String name;
  final int hitBonus;
  final String reach;
  final String damageRoll;
  final DamageType damageType;
  final int? saveDC;
  final String? description;
  final int? maxUses;
  final int? remainingUses;

  Attack({
    String? id,
    required this.name,
    required this.hitBonus,
    required this.reach,
    required this.damageRoll,
    required this.damageType,
    this.saveDC,
    this.description,
    this.maxUses,
    this.remainingUses,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hitBonus': hitBonus,
        'reach': reach,
        'damageRoll': damageRoll,
        'damageType': damageType.name,
        'saveDC': saveDC,
        'description': description,
        'maxUses': maxUses,
        'remainingUses': remainingUses,
      };

  factory Attack.fromJson(Map<String, dynamic> json) => Attack(
        id: json['id'] as String?,
        name: json['name'] as String,
        hitBonus: json['hitBonus'] as int,
        reach: json['reach'] as String,
        damageRoll: json['damageRoll'] as String,
        damageType: DamageType.fromString(json['damageType'] as String),
        saveDC: json['saveDC'] as int?,
        description: json['description'] as String?,
        maxUses: json['maxUses'] as int?,
        remainingUses: json['remainingUses'] as int?,
      );
}
