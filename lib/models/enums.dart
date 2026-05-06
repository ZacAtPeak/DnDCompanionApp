enum CreatureSize {
  tiny,
  small,
  medium,
  large,
  huge,
  gargantuan;

  String get displayName {
    switch (this) {
      case CreatureSize.tiny:
        return 'Tiny';
      case CreatureSize.small:
        return 'Small';
      case CreatureSize.medium:
        return 'Medium';
      case CreatureSize.large:
        return 'Large';
      case CreatureSize.huge:
        return 'Huge';
      case CreatureSize.gargantuan:
        return 'Gargantuan';
    }
  }

  static CreatureSize fromString(String value) {
    switch (value.toLowerCase()) {
      case 'tiny':
        return tiny;
      case 'small':
        return small;
      case 'medium':
        return medium;
      case 'large':
        return large;
      case 'huge':
        return huge;
      case 'gargantuan':
        return gargantuan;
      default:
        throw ArgumentError('Unknown CreatureSize: $value');
    }
  }
}

enum CreatureType {
  aberration,
  beast,
  celestial,
  construct,
  dragon,
  elemental,
  fey,
  fiend,
  giant,
  humanoid,
  monstrosity,
  ooze,
  plant,
  undead;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  static CreatureType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'aberration':
        return aberration;
      case 'beast':
        return beast;
      case 'celestial':
        return celestial;
      case 'construct':
        return construct;
      case 'dragon':
        return dragon;
      case 'elemental':
        return elemental;
      case 'fey':
        return fey;
      case 'fiend':
        return fiend;
      case 'giant':
        return giant;
      case 'humanoid':
        return humanoid;
      case 'monstrosity':
        return monstrosity;
      case 'ooze':
        return ooze;
      case 'plant':
        return plant;
      case 'undead':
        return undead;
      default:
        throw ArgumentError('Unknown CreatureType: $value');
    }
  }
}

enum Alignment {
  lawfulGood,
  neutralGood,
  chaoticGood,
  lawfulNeutral,
  trueNeutral,
  chaoticNeutral,
  lawfulEvil,
  neutralEvil,
  chaoticEvil,
  unaligned;

  String get displayName {
    switch (this) {
      case Alignment.lawfulGood:
        return 'Lawful Good';
      case Alignment.neutralGood:
        return 'Neutral Good';
      case Alignment.chaoticGood:
        return 'Chaotic Good';
      case Alignment.lawfulNeutral:
        return 'Lawful Neutral';
      case Alignment.trueNeutral:
        return 'True Neutral';
      case Alignment.chaoticNeutral:
        return 'Chaotic Neutral';
      case Alignment.lawfulEvil:
        return 'Lawful Evil';
      case Alignment.neutralEvil:
        return 'Neutral Evil';
      case Alignment.chaoticEvil:
        return 'Chaotic Evil';
      case Alignment.unaligned:
        return 'Unaligned';
    }
  }

  static Alignment fromString(String value) {
    switch (value.toLowerCase().replaceAll(' ', '_')) {
      case 'lawful_good':
        return lawfulGood;
      case 'neutral_good':
        return neutralGood;
      case 'chaotic_good':
        return chaoticGood;
      case 'lawful_neutral':
        return lawfulNeutral;
      case 'true_neutral':
        return trueNeutral;
      case 'chaotic_neutral':
        return chaoticNeutral;
      case 'lawful_evil':
        return lawfulEvil;
      case 'neutral_evil':
        return neutralEvil;
      case 'chaotic_evil':
        return chaoticEvil;
      case 'unaligned':
        return unaligned;
      default:
        throw ArgumentError('Unknown Alignment: $value');
    }
  }
}

enum DamageType {
  slashing,
  piercing,
  bludgeoning,
  fire,
  cold,
  lightning,
  thunder,
  acid,
  poison,
  necrotic,
  radiant,
  psychic,
  force;

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  static DamageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'slashing':
        return slashing;
      case 'piercing':
        return piercing;
      case 'bludgeoning':
        return bludgeoning;
      case 'fire':
        return fire;
      case 'cold':
        return cold;
      case 'lightning':
        return lightning;
      case 'thunder':
        return thunder;
      case 'acid':
        return acid;
      case 'poison':
        return poison;
      case 'necrotic':
        return necrotic;
      case 'radiant':
        return radiant;
      case 'psychic':
        return psychic;
      case 'force':
        return force;
      default:
        throw ArgumentError('Unknown DamageType: $value');
    }
  }
}
