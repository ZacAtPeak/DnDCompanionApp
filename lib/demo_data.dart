import 'models/models.dart';

class DemoData {
  static List<PlayerCharacter> allDemoCharacters() {
    return [
      createAldrin(),
      createMira(),
      createTheron(),
    ];
  }

  static UserCharacter createUserCharacter() {
    return UserCharacter(character: createMira());
  }

  static PlayerCharacter createAldrin() {
    return PlayerCharacter(
      name: 'Aldrin Lightfoot',
      race: 'Halfling',
      playerClass: 'Rogue',
      level: 5,
      background: 'Criminal',
      size: CreatureSize.small,
      alignment: Alignment.chaoticGood,
      armorClass: 16,
      armorSource: 'Leather Armor',
      currentHP: 32,
      maxHP: 45,
      hitDice: '5d8',
      speed: const MovementSpeed(walk: 25),
      abilityScores: const AbilityScores(
        strength: 8,
        dexterity: 18,
        constitution: 14,
        intelligence: 12,
        wisdom: 10,
        charisma: 14,
      ),
      proficiencyBonus: 3,
      savingThrowProficiencies: const SavingThrowProficiencies(
        dexterity: true,
        intelligence: true,
      ),
      skills: _buildRogueSkills(),
      damageVulnerabilities: const [],
      damageResistances: const [],
      damageImmunities: const [],
      conditionImmunities: const [],
      senses: const Senses(passivePerception: 14),
      languages: const ['Common', 'Halfling', "Thieves' Cant"],
      specialAbilities: const [
        SpecialAbility(
          name: 'Sneak Attack',
          description:
              'Once per turn, deal an extra 3d6 damage when you have advantage on the attack roll or when an ally is within 5 feet of the target.',
        ),
        SpecialAbility(
          name: 'Cunning Action',
          description:
              'You can take a bonus action on each of your turns to Dash, Disengage, or Hide.',
        ),
        SpecialAbility(
          name: 'Evasion',
          description:
              'When subjected to an effect that allows a Dexterity saving throw for half damage, you take no damage on a success and half on a failure.',
        ),
      ],
      actions: [
        Attack(
          name: 'Shortsword',
          hitBonus: 7,
          reach: '5 ft.',
          damageRoll: '1d6+4',
          damageType: DamageType.piercing,
        ),
        Attack(
          name: 'Shortbow',
          hitBonus: 7,
          reach: '80/320 ft.',
          damageRoll: '1d6+4',
          damageType: DamageType.piercing,
        ),
        Attack(
          name: 'Dagger',
          hitBonus: 7,
          reach: '5 ft.',
          damageRoll: '1d4+4',
          damageType: DamageType.piercing,
          description: 'Finesse, Light, Thrown (range 20/60)',
        ),
      ],
      spellSlots: const [],
      knownSpells: const [],
      initiative: 0.0,
    );
  }

  static PlayerCharacter createMira() {
    return PlayerCharacter(
      name: 'Mira Sunwhisper',
      race: 'Half-Elf',
      playerClass: 'Wizard',
      level: 7,
      background: 'Sage',
      size: CreatureSize.medium,
      alignment: Alignment.neutralGood,
      armorClass: 13,
      armorSource: 'Mage Armor',
      currentHP: 28,
      maxHP: 38,
      hitDice: '7d6',
      speed: const MovementSpeed(walk: 30),
      abilityScores: const AbilityScores(
        strength: 8,
        dexterity: 14,
        constitution: 12,
        intelligence: 18,
        wisdom: 12,
        charisma: 10,
      ),
      proficiencyBonus: 3,
      savingThrowProficiencies: const SavingThrowProficiencies(
        intelligence: true,
        wisdom: true,
      ),
      skills: _buildWizardSkills(),
      damageVulnerabilities: const [],
      damageResistances: const [],
      damageImmunities: const [],
      conditionImmunities: const [],
      senses: const Senses(passivePerception: 11),
      languages: const ['Common', 'Elven', 'Celestial', 'Draconic'],
      specialAbilities: const [
        SpecialAbility(
          name: 'Arcane Recovery',
          description:
              'Once per day when you finish a short rest, choose expended spell slots whose combined level is 4 or less. You regain those slots.',
        ),
        SpecialAbility(
          name: 'Spellcasting Focus',
          description:
              'You use a crystal orb as your spellcasting focus.',
        ),
        SpecialAbility(
          name: 'Fey Ancestry',
          description:
              'You have advantage on saving throws against being charmed, and magic cannot put you to sleep.',
        ),
      ],
      actions: [
        Attack(
          name: 'Quarterstaff',
          hitBonus: 1,
          reach: '5 ft.',
          damageRoll: '1d6-1',
          damageType: DamageType.bludgeoning,
        ),
        Attack(
          name: 'Fire Bolt (Cantrip)',
          hitBonus: 7,
          reach: '120 ft.',
          damageRoll: '2d10',
          damageType: DamageType.fire,
        ),
        Attack(
          name: 'Ray of Frost (Cantrip)',
          hitBonus: 7,
          reach: '60 ft.',
          damageRoll: '2d8',
          damageType: DamageType.cold,
          description: 'Reduces target speed by 10 feet until start of your next turn.',
        ),
      ],
      spellSlots: const [
        SpellSlot(level: 1, max: 4, available: 4),
        SpellSlot(level: 2, max: 3, available: 3),
        SpellSlot(level: 3, max: 3, available: 3),
        SpellSlot(level: 4, max: 1, available: 1),
      ],
      knownSpells: const [
        'Fire Bolt',
        'Ray of Frost',
        'Prestidigitation',
        'Mage Hand',
        'Shield',
        'Magic Missile',
        'Detect Magic',
        'Identify',
        'Misty Step',
        'Scorching Ray',
        'Counterspell',
        'Fireball',
        'Lightning Bolt',
        'Dimension Door',
      ],
      initiative: 0.0,
    );
  }

  static PlayerCharacter createTheron() {
    return PlayerCharacter(
      name: 'Theron Ironscale',
      race: 'Dragonborn',
      playerClass: 'Paladin',
      level: 8,
      background: 'Soldier',
      size: CreatureSize.medium,
      alignment: Alignment.lawfulGood,
      armorClass: 18,
      armorSource: 'Plate Armor',
      currentHP: 52,
      maxHP: 60,
      hitDice: '8d10',
      speed: const MovementSpeed(walk: 30),
      abilityScores: const AbilityScores(
        strength: 18,
        dexterity: 10,
        constitution: 14,
        intelligence: 10,
        wisdom: 12,
        charisma: 16,
      ),
      proficiencyBonus: 3,
      savingThrowProficiencies: const SavingThrowProficiencies(
        wisdom: true,
        charisma: true,
      ),
      skills: _buildPaladinSkills(),
      damageVulnerabilities: const [],
      damageResistances: const [],
      damageImmunities: const [],
      conditionImmunities: const [],
      senses: const Senses(passivePerception: 11),
      languages: const ['Common', 'Draconic'],
      specialAbilities: const [
        SpecialAbility(
          name: 'Divine Sense',
          description:
              'You can detect celestials, fiends, or undead within 60 feet. Uses equal to 1 + Charisma modifier per long rest.',
        ),
        SpecialAbility(
          name: 'Lay on Hands',
          description:
              'You have a pool of 40 healing points. As an action, touch a creature and restore HP from the pool.',
        ),
        SpecialAbility(
          name: 'Divine Smite',
          description:
              'When you hit with a melee weapon attack, expend a spell slot to deal an extra 2d8 radiant damage (plus 1d8 per spell level above 1st).',
        ),
        SpecialAbility(
          name: 'Dragon Breath (Fire)',
          description:
              'As an action, exhale fire in a 15-foot cone. DC 13 Dexterity save, 2d10 fire damage.',
        ),
        SpecialAbility(
          name: 'Aura of Protection',
          description:
              'You and friendly creatures within 10 feet gain a bonus to saving throws equal to your Charisma modifier (+3).',
        ),
      ],
      actions: [
        Attack(
          name: 'Longsword',
          hitBonus: 7,
          reach: '5 ft.',
          damageRoll: '1d8+4',
          damageType: DamageType.slashing,
          description: 'Versatile (1d10)',
        ),
        Attack(
          name: 'Javelin',
          hitBonus: 7,
          reach: '30/120 ft.',
          damageRoll: '1d6+4',
          damageType: DamageType.piercing,
          description: 'Thrown',
        ),
      ],
      spellSlots: const [
        SpellSlot(level: 1, max: 4, available: 4),
        SpellSlot(level: 2, max: 3, available: 3),
      ],
      knownSpells: const [
        'Bless',
        'Shield of Faith',
        'Command',
        'Compelled Duel',
        'Protection from Evil and Good',
        'Aid',
        'Branding Smite',
      ],
      initiative: 0.0,
    );
  }

  static NPC createDemoNPC() {
    return NPC(
      name: 'Brother Marcus',
      role: 'Village Priest of Lathander',
      size: CreatureSize.medium,
      alignment: Alignment.neutralGood,
      biography:
          'Brother Marcus has served the Morninglord for over 30 years. He tends to the small temple in Oakhaven, providing healing and guidance to travelers. Though elderly, his faith grants him considerable power. He has recently grown concerned about reports of undead activity in the nearby crypts.',
      armorClass: 13,
      armorSource: 'Robes of Protection',
      currentHP: 22,
      maxHP: 22,
      hitDice: '4d8',
      speed: const MovementSpeed(walk: 30),
      abilityScores: const AbilityScores(
        strength: 10,
        dexterity: 10,
        constitution: 12,
        intelligence: 13,
        wisdom: 16,
        charisma: 14,
      ),
      proficiencyBonus: 2,
      savingThrowProficiencies: const SavingThrowProficiencies(
        wisdom: true,
        charisma: true,
      ),
      skills: [
        const SkillProficiency(
          skill: 'Medicine',
          isProficient: true,
          bonus: 5,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Religion',
          isProficient: true,
          bonus: 3,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Insight',
          isProficient: true,
          bonus: 5,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Persuasion',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'History',
          isProficient: false,
          bonus: 1,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Perception',
          isProficient: false,
          bonus: 3,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Acrobatics',
          isProficient: false,
          bonus: 0,
          abilityScore: 'DEX',
        ),
        const SkillProficiency(
          skill: 'Animal Handling',
          isProficient: false,
          bonus: 3,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Arcana',
          isProficient: false,
          bonus: 1,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Athletics',
          isProficient: false,
          bonus: 0,
          abilityScore: 'STR',
        ),
        const SkillProficiency(
          skill: 'Deception',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'Intimidation',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'Investigation',
          isProficient: false,
          bonus: 1,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Nature',
          isProficient: false,
          bonus: 1,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Performance',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'Sleight of Hand',
          isProficient: false,
          bonus: 0,
          abilityScore: 'DEX',
        ),
        const SkillProficiency(
          skill: 'Stealth',
          isProficient: false,
          bonus: 0,
          abilityScore: 'DEX',
        ),
        const SkillProficiency(
          skill: 'Survival',
          isProficient: false,
          bonus: 3,
          abilityScore: 'WIS',
        ),
      ],
      damageResistances: const [],
      damageImmunities: const [],
      conditionImmunities: const [],
      senses: const Senses(passivePerception: 13),
      languages: const ['Common', 'Celestial'],
      specialAbilities: const [
        SpecialAbility(
          name: 'Divine Eminence',
          description:
              'As a bonus action, Marcus can expend a spell slot to cause his melee weapon to deal an extra 2d8 radiant damage.',
        ),
      ],
      actions: [
        Attack(
          name: 'Mace',
          hitBonus: 2,
          reach: '5 ft.',
          damageRoll: '1d6',
          damageType: DamageType.bludgeoning,
        ),
        Attack(
          name: 'Sacred Flame (Cantrip)',
          hitBonus: 0,
          reach: '60 ft.',
          damageRoll: '2d8',
          damageType: DamageType.radiant,
          saveDC: 13,
          description: 'Dexterity saving throw',
        ),
      ],
      spellSlots: const [
        SpellSlot(level: 1, max: 4, available: 4),
        SpellSlot(level: 2, max: 3, available: 3),
      ],
      knownSpells: const [
        'Sacred Flame',
        'Thaumaturgy',
        'Light',
        'Cure Wounds',
        'Shield of Faith',
        'Lesser Restoration',
        'Spiritual Weapon',
        'Prayer of Healing',
      ],
      initiative: 0.0,
    );
  }

  static Monster createDemoMonster() {
    return Monster(
      name: 'Young Green Dragon',
      size: CreatureSize.large,
      type: CreatureType.dragon,
      alignment: Alignment.lawfulEvil,
      armorClass: 18,
      armorSource: 'Natural Armor',
      currentHP: 136,
      maxHP: 136,
      hitDice: '16d10',
      speed: const MovementSpeed(
        walk: 40,
        fly: 80,
        swim: 40,
      ),
      abilityScores: const AbilityScores(
        strength: 19,
        dexterity: 12,
        constitution: 17,
        intelligence: 16,
        wisdom: 13,
        charisma: 15,
      ),
      proficiencyBonus: 3,
      savingThrowProficiencies: const SavingThrowProficiencies(
        dexterity: true,
        constitution: true,
        wisdom: true,
        charisma: true,
      ),
      skills: [
        const SkillProficiency(
          skill: 'Perception',
          isProficient: true,
          bonus: 7,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Stealth',
          isProficient: true,
          bonus: 5,
          abilityScore: 'DEX',
        ),
        const SkillProficiency(
          skill: 'Acrobatics',
          isProficient: false,
          bonus: 1,
          abilityScore: 'DEX',
        ),
        const SkillProficiency(
          skill: 'Animal Handling',
          isProficient: false,
          bonus: 1,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Arcana',
          isProficient: false,
          bonus: 3,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Athletics',
          isProficient: false,
          bonus: 4,
          abilityScore: 'STR',
        ),
        const SkillProficiency(
          skill: 'Deception',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'History',
          isProficient: false,
          bonus: 3,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Insight',
          isProficient: false,
          bonus: 1,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Intimidation',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'Investigation',
          isProficient: false,
          bonus: 3,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Medicine',
          isProficient: false,
          bonus: 1,
          abilityScore: 'WIS',
        ),
        const SkillProficiency(
          skill: 'Nature',
          isProficient: false,
          bonus: 3,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Performance',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'Persuasion',
          isProficient: false,
          bonus: 2,
          abilityScore: 'CHA',
        ),
        const SkillProficiency(
          skill: 'Religion',
          isProficient: false,
          bonus: 3,
          abilityScore: 'INT',
        ),
        const SkillProficiency(
          skill: 'Sleight of Hand',
          isProficient: false,
          bonus: 1,
          abilityScore: 'DEX',
        ),
        const SkillProficiency(
          skill: 'Survival',
          isProficient: false,
          bonus: 1,
          abilityScore: 'WIS',
        ),
      ],
      damageVulnerabilities: const [],
      damageResistances: const [],
      damageImmunities: const [DamageType.poison],
      conditionImmunities: const ['Poisoned'],
      senses: const Senses(
        blindsight: 30,
        darkvision: 120,
        passivePerception: 17,
      ),
      languages: const ['Common', 'Draconic'],
      challengeRating: 8,
      xp: 3900,
      specialAbilities: const [
        SpecialAbility(
          name: 'Amphibious',
          description: 'The dragon can breathe air and water.',
        ),
        SpecialAbility(
          name: 'Poison Breath (Recharge 5-6)',
          description:
              'The dragon exhales poisonous gas in a 30-foot cone. Each creature in that area must make a DC 15 Constitution saving throw, taking 42 (12d6) poison damage on a failure, or half as much on a success.',
        ),
      ],
      actions: [
        Attack(
          name: 'Bite',
          hitBonus: 8,
          reach: '10 ft.',
          damageRoll: '2d10+4',
          damageType: DamageType.piercing,
        ),
        Attack(
          name: 'Claw',
          hitBonus: 8,
          reach: '5 ft.',
          damageRoll: '2d6+4',
          damageType: DamageType.slashing,
        ),
        Attack(
          name: 'Tail',
          hitBonus: 8,
          reach: '15 ft.',
          damageRoll: '2d8+4',
          damageType: DamageType.bludgeoning,
        ),
      ],
      legendaryActions: const [
        LegendaryAction(
          name: 'Detect',
          cost: 1,
          description: 'The dragon makes a Wisdom (Perception) check.',
        ),
        LegendaryAction(
          name: 'Tail Attack',
          cost: 1,
          description: 'The dragon makes a tail attack.',
        ),
        LegendaryAction(
          name: 'Wing Attack (Costs 2)',
          cost: 2,
          description:
              'The dragon beats its wings. Each creature within 10 feet must make a DC 16 Dexterity saving throw or take 2d6+4 bludgeoning damage and be knocked prone.',
        ),
      ],
      legendaryActionCount: 3,
      knownSpells: const [],
      initiative: 0.0,
    );
  }

  static List<SkillProficiency> _buildRogueSkills() {
    return [
      const SkillProficiency(
        skill: 'Acrobatics',
        isProficient: true,
        bonus: 7,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Animal Handling',
        isProficient: false,
        bonus: 0,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Arcana',
        isProficient: false,
        bonus: 1,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Athletics',
        isProficient: false,
        bonus: -1,
        abilityScore: 'STR',
      ),
      const SkillProficiency(
        skill: 'Deception',
        isProficient: true,
        bonus: 5,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'History',
        isProficient: false,
        bonus: 1,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Insight',
        isProficient: false,
        bonus: 0,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Intimidation',
        isProficient: false,
        bonus: 2,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Investigation',
        isProficient: true,
        bonus: 4,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Medicine',
        isProficient: false,
        bonus: 0,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Nature',
        isProficient: false,
        bonus: 1,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Perception',
        isProficient: true,
        bonus: 3,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Performance',
        isProficient: false,
        bonus: 2,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Persuasion',
        isProficient: false,
        bonus: 2,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Religion',
        isProficient: false,
        bonus: 1,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Sleight of Hand',
        isProficient: true,
        bonus: 7,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Stealth',
        isProficient: true,
        bonus: 7,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Survival',
        isProficient: false,
        bonus: 0,
        abilityScore: 'WIS',
      ),
    ];
  }

  static List<SkillProficiency> _buildWizardSkills() {
    return [
      const SkillProficiency(
        skill: 'Acrobatics',
        isProficient: false,
        bonus: 2,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Animal Handling',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Arcana',
        isProficient: true,
        bonus: 7,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Athletics',
        isProficient: false,
        bonus: -1,
        abilityScore: 'STR',
      ),
      const SkillProficiency(
        skill: 'Deception',
        isProficient: false,
        bonus: 0,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'History',
        isProficient: true,
        bonus: 7,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Insight',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Intimidation',
        isProficient: false,
        bonus: 0,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Investigation',
        isProficient: true,
        bonus: 7,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Medicine',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Nature',
        isProficient: true,
        bonus: 7,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Perception',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Performance',
        isProficient: false,
        bonus: 0,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Persuasion',
        isProficient: false,
        bonus: 0,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Religion',
        isProficient: true,
        bonus: 7,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Sleight of Hand',
        isProficient: false,
        bonus: 2,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Stealth',
        isProficient: false,
        bonus: 2,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Survival',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
    ];
  }

  static List<SkillProficiency> _buildPaladinSkills() {
    return [
      const SkillProficiency(
        skill: 'Acrobatics',
        isProficient: false,
        bonus: 0,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Animal Handling',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Arcana',
        isProficient: false,
        bonus: 0,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Athletics',
        isProficient: true,
        bonus: 7,
        abilityScore: 'STR',
      ),
      const SkillProficiency(
        skill: 'Deception',
        isProficient: false,
        bonus: 3,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'History',
        isProficient: false,
        bonus: 0,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Insight',
        isProficient: true,
        bonus: 4,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Intimidation',
        isProficient: true,
        bonus: 6,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Investigation',
        isProficient: false,
        bonus: 0,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Medicine',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Nature',
        isProficient: false,
        bonus: 0,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Perception',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
      const SkillProficiency(
        skill: 'Performance',
        isProficient: false,
        bonus: 3,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Persuasion',
        isProficient: true,
        bonus: 6,
        abilityScore: 'CHA',
      ),
      const SkillProficiency(
        skill: 'Religion',
        isProficient: true,
        bonus: 3,
        abilityScore: 'INT',
      ),
      const SkillProficiency(
        skill: 'Sleight of Hand',
        isProficient: false,
        bonus: 0,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Stealth',
        isProficient: false,
        bonus: 0,
        abilityScore: 'DEX',
      ),
      const SkillProficiency(
        skill: 'Survival',
        isProficient: false,
        bonus: 1,
        abilityScore: 'WIS',
      ),
    ];
  }
}
