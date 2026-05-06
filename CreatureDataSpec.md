# D&D 5e Creature Data Specification

> Language-agnostic spec for Player Characters, NPCs, and Monsters. All types are described in a platform-neutral format suitable for JSON serialization, database schemas, or native model classes.

---

## 1. Shared Enumerations

### 1.1 CreatureSize

| Value | Description |
|---|---|
| `tiny` | Tiny |
| `small` | Small |
| `medium` | Medium |
| `large` | Large |
| `huge` | Huge |
| `gargantuan` | Gargantuan |

### 1.2 CreatureType

| Value | Description |
|---|---|
| `aberration` | Aberration |
| `beast` | Beast |
| `celestial` | Celestial |
| `construct` | Construct |
| `dragon` | Dragon |
| `elemental` | Elemental |
| `fey` | Fey |
| `fiend` | Fiend |
| `giant` | Giant |
| `humanoid` | Humanoid |
| `monstrosity` | Monstrosity |
| `ooze` | Ooze |
| `plant` | Plant |
| `undead` | Undead |

### 1.3 Alignment

| Value | Description |
|---|---|
| `lawful_good` | Lawful Good |
| `neutral_good` | Neutral Good |
| `chaotic_good` | Chaotic Good |
| `lawful_neutral` | Lawful Neutral |
| `true_neutral` | True Neutral |
| `chaotic_neutral` | Chaotic Neutral |
| `lawful_evil` | Lawful Evil |
| `neutral_evil` | Neutral Evil |
| `chaotic_evil` | Chaotic Evil |
| `unaligned` | Unaligned |

### 1.4 DamageType

| Value | Description |
|---|---|
| `slashing` | Slashing |
| `piercing` | Piercing |
| `bludgeoning` | Bludgeoning |
| `fire` | Fire |
| `cold` | Cold |
| `lightning` | Lightning |
| `thunder` | Thunder |
| `acid` | Acid |
| `poison` | Poison |
| `necrotic` | Necrotic |
| `radiant` | Radiant |
| `psychic` | Psychic |
| `force` | Force |

---

## 2. Shared Value Types

### 2.1 AbilityScores

Six ability scores. Modifier for any score = `(score - 10) / 2` (integer division, floor).

| Field | Type | Description |
|---|---|---|
| `strength` | int | STR |
| `dexterity` | int | DEX |
| `constitution` | int | CON |
| `intelligence` | int | INT |
| `wisdom` | int | WIS |
| `charisma` | int | CHA |

Computed modifiers (derived, not stored): `strMod`, `dexMod`, `conMod`, `intMod`, `wisMod`, `chaMod`.

### 2.2 MovementSpeed

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `walk` | int | Yes | — | Walking speed in feet |
| `swim` | int | No | null | Swimming speed |
| `fly` | int | No | null | Flying speed |
| `climb` | int | No | null | Climbing speed |
| `burrow` | int | No | null | Burrowing speed |
| `hover` | bool | No | false | Can hover while flying |

### 2.3 SavingThrowProficiencies

Boolean flags for each ability saving throw proficiency.

| Field | Type | Default |
|---|---|---|
| `strength` | bool | false |
| `dexterity` | bool | false |
| `constitution` | bool | false |
| `intelligence` | bool | false |
| `wisdom` | bool | false |
| `charisma` | bool | false |

### 2.4 Senses

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `darkvision` | int | No | null | Range in feet |
| `blindsight` | int | No | null | Range in feet |
| `tremorsense` | int | No | null | Range in feet |
| `truesight` | int | No | null | Range in feet |
| `passivePerception` | int | Yes | — | Passive Perception score |

### 2.5 SkillProficiency

| Field | Type | Description |
|---|---|---|
| `skill` | string | Skill name (see Skill Definitions below) |
| `isProficient` | bool | Whether the creature is proficient |
| `bonus` | int | Total bonus (ability modifier + proficiency bonus if proficient) |
| `abilityScore` | string | Associated ability abbreviation: STR, DEX, CON, INT, WIS, CHA |

#### Skill Definitions (18 standard skills)

| Skill | Ability |
|---|---|
| Acrobatics | DEX |
| Animal Handling | WIS |
| Arcana | INT |
| Athletics | STR |
| Deception | CHA |
| History | INT |
| Insight | WIS |
| Intimidation | CHA |
| Investigation | INT |
| Medicine | WIS |
| Nature | INT |
| Perception | WIS |
| Performance | CHA |
| Persuasion | CHA |
| Religion | INT |
| Sleight of Hand | DEX |
| Stealth | DEX |
| Survival | WIS |

Bonus calculation: `bonus = abilityModifier + (isProficient ? proficiencyBonus : 0)`

### 2.6 SpecialAbility

| Field | Type | Description |
|---|---|---|
| `name` | string | Ability name |
| `description` | string | Full description text |

### 2.7 Attack

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | UUID | Yes | auto-generated | Unique identifier |
| `name` | string | Yes | — | Attack name |
| `hitBonus` | int | Yes | — | Attack roll modifier |
| `reach` | string | Yes | — | e.g. "5 ft." or "60/120 ft." |
| `damageRoll` | string | Yes | — | Dice expression, e.g. "2d6+3" |
| `damageType` | DamageType | Yes | — | Type of damage dealt |
| `saveDC` | int | No | null | Saving throw DC (for save-based attacks) |
| `description` | string | No | null | Additional description |
| `maxUses` | int | No | null | Maximum uses per rest/period |
| `remainingUses` | int | No | null | Uses remaining |

### 2.8 LegendaryAction

| Field | Type | Description |
|---|---|---|
| `name` | string | Action name |
| `cost` | int | Legendary action points cost |
| `description` | string | Full description text |

### 2.9 SpellSlot

| Field | Type | Description |
|---|---|---|
| `level` | int | Spell level (1-9) |
| `max` | int | Maximum slots at this level |
| `available` | int | Slots currently available |

A creature's spell slots are represented as an array of `SpellSlot`, one entry per level the creature has slots for. Levels with 0 slots may be omitted or included with `max: 0, available: 0`.

### 2.10 StatusCondition

| Field | Type | Description |
|---|---|---|
| `name` | string | Condition name |
| `effect` | string | Short effect summary |
| `desc` | string | Full description |

---

## 3. Entity Types

All three entity types share a common core. Fields marked **(unique)** exist only on that specific type.

### 3.1 PlayerCharacter

Represents a player-controlled character.

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | UUID | Yes | auto-generated | Unique identifier |
| `name` | string | Yes | — | Character name |
| `race` | string | Yes | — | Race/species |
| `playerClass` | string | Yes | — | Class |
| `level` | int | Yes | — | Character level (1-20) |
| `background` | string | Yes | — | Background |
| `size` | CreatureSize | Yes | — | Creature size |
| `alignment` | Alignment | Yes | — | Moral alignment |
| `armorClass` | int | Yes | — | AC value |
| `armorSource` | string | Yes | — | Source of AC (e.g. "Leather Armor") |
| `currentHP` | int | Yes | — | Current hit points |
| `maxHP` | int | Yes | — | Maximum hit points |
| `hitDice` | string | Yes | — | e.g. "8d8" |
| `speed` | MovementSpeed | Yes | — | Movement speeds |
| `abilityScores` | AbilityScores | Yes | — | Six ability scores |
| `proficiencyBonus` | int | Yes | — | Proficiency bonus |
| `savingThrowProficiencies` | SavingThrowProficiencies | Yes | — | Saving throw proficiencies |
| `skills` | [SkillProficiency] | Yes | — | All 18 skills with bonuses |
| `damageVulnerabilities` | [DamageType] | Yes | [] | Damage types creature is vulnerable to |
| `damageResistances` | [DamageType] | Yes | [] | Damage types creature resists |
| `damageImmunities` | [DamageType] | Yes | [] | Damage types creature is immune to |
| `conditionImmunities` | [string] | Yes | [] | Status conditions immune to |
| `senses` | Senses | Yes | — | Senses and passive perception |
| `languages` | [string] | Yes | — | Known languages |
| `specialAbilities` | [SpecialAbility] | Yes | [] | Traits, features, passives |
| `actions` | [Attack] | Yes | [] | Attacks and action abilities |
| `spellSlots` | [SpellSlot] | Yes | [] | Available spell slots |
| `knownSpells` | [string] | Yes | [] | IDs/names of known spells |
| `initiative` | float | Yes | 0 | Rolled initiative value |
| `status` | [StatusCondition] | No | null | Active status conditions |

### 3.2 NPC

Represents a non-player character (ally, quest giver, or combatant).

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | UUID | Yes | auto-generated | Unique identifier |
| `name` | string | Yes | — | NPC name |
| `role` | string | Yes | — | Role/description (replaces race+class+level) |
| `size` | CreatureSize | Yes | — | Creature size |
| `alignment` | Alignment | Yes | — | Moral alignment |
| `biography` | string | Yes | — | Background/narrative text |
| `armorClass` | int | Yes | — | AC value |
| `armorSource` | string | Yes | — | Source of AC |
| `currentHP` | int | Yes | — | Current hit points |
| `maxHP` | int | Yes | — | Maximum hit points |
| `hitDice` | string | Yes | — | e.g. "8d8" |
| `speed` | MovementSpeed | Yes | — | Movement speeds |
| `abilityScores` | AbilityScores | Yes | — | Six ability scores |
| `proficiencyBonus` | int | Yes | — | Proficiency bonus |
| `savingThrowProficiencies` | SavingThrowProficiencies | Yes | — | Saving throw proficiencies |
| `skills` | [SkillProficiency] | Yes | — | Skills with bonuses |
| `damageResistances` | [DamageType] | Yes | [] | Damage types resisted |
| `damageImmunities` | [DamageType] | Yes | [] | Damage types immune to |
| `conditionImmunities` | [string] | Yes | [] | Status conditions immune to |
| `senses` | Senses | Yes | — | Senses and passive perception |
| `languages` | [string] | Yes | — | Known languages |
| `specialAbilities` | [SpecialAbility] | Yes | [] | Traits and features |
| `actions` | [Attack] | Yes | [] | Attacks and abilities |
| `spellSlots` | [SpellSlot] | Yes | [] | Available spell slots |
| `knownSpells` | [string] | Yes | [] | IDs/names of known spells |
| `initiative` | float | Yes | 0 | Rolled initiative value |
| `status` | [StatusCondition] | No | null | Active status conditions |

**Note:** NPC does NOT have `damageVulnerabilities`, `type`, `challengeRating`, `xp`, or `legendaryActions`.

### 3.3 Monster

Represents a creature from the bestiary / monster manual.

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | UUID | Yes | auto-generated | Unique identifier |
| `name` | string | Yes | — | Monster name |
| `size` | CreatureSize | Yes | — | Creature size |
| `type` | CreatureType | Yes | — | Creature type (unique) |
| `alignment` | Alignment | Yes | — | Moral alignment |
| `armorClass` | int | Yes | — | AC value |
| `armorSource` | string | Yes | — | Source of AC |
| `currentHP` | int | Yes | — | Current hit points |
| `maxHP` | int | Yes | — | Maximum hit points |
| `hitDice` | string | Yes | — | e.g. "8d8" |
| `speed` | MovementSpeed | Yes | — | Movement speeds |
| `abilityScores` | AbilityScores | Yes | — | Six ability scores |
| `proficiencyBonus` | int | Yes | — | Proficiency bonus |
| `savingThrowProficiencies` | SavingThrowProficiencies | Yes | — | Saving throw proficiencies |
| `skills` | [SkillProficiency] | Yes | — | Skills with bonuses |
| `damageVulnerabilities` | [DamageType] | Yes | [] | Damage types vulnerable to |
| `damageResistances` | [DamageType] | Yes | [] | Damage types resisted |
| `damageImmunities` | [DamageType] | Yes | [] | Damage types immune to |
| `conditionImmunities` | [string] | Yes | [] | Status conditions immune to |
| `senses` | Senses | Yes | — | Senses and passive perception |
| `languages` | [string] | Yes | — | Known languages |
| `challengeRating` | float | Yes | — | CR value (unique) |
| `xp` | int | Yes | — | Experience points awarded (unique) |
| `specialAbilities` | [SpecialAbility] | Yes | [] | Traits and features |
| `actions` | [Attack] | Yes | [] | Attacks and abilities |
| `legendaryActions` | [LegendaryAction] | No | null | Legendary actions (unique) |
| `legendaryActionCount` | int | No | null | Total legendary actions per round (unique) |
| `knownSpells` | [string] | Yes | [] | IDs/names of known spells |
| `initiative` | float | Yes | 0 | Rolled initiative value |
| `status` | [StatusCondition] | No | null | Active status conditions |

**Note:** Monster does NOT have `spellSlots` as a stored field (defaults to empty via extension), `race`, `playerClass`, `level`, `background`, `role`, or `biography`.

---

## 4. Field Comparison Matrix

| Field | PlayerCharacter | NPC | Monster |
|---|:---:|:---:|:---:|
| `id` | ✓ | ✓ | ✓ |
| `name` | ✓ | ✓ | ✓ |
| `race` | ✓ | — | — |
| `playerClass` | ✓ | — | — |
| `level` | ✓ | — | — |
| `background` | ✓ | — | — |
| `role` | — | ✓ | — |
| `biography` | — | ✓ | — |
| `size` | ✓ | ✓ | ✓ |
| `type` | — | — | ✓ |
| `alignment` | ✓ | ✓ | ✓ |
| `armorClass` | ✓ | ✓ | ✓ |
| `armorSource` | ✓ | ✓ | ✓ |
| `currentHP` | ✓ | ✓ | ✓ |
| `maxHP` | ✓ | ✓ | ✓ |
| `hitDice` | ✓ | ✓ | ✓ |
| `speed` | ✓ | ✓ | ✓ |
| `abilityScores` | ✓ | ✓ | ✓ |
| `proficiencyBonus` | ✓ | ✓ | ✓ |
| `savingThrowProficiencies` | ✓ | ✓ | ✓ |
| `skills` | ✓ | ✓ | ✓ |
| `damageVulnerabilities` | ✓ | — | ✓ |
| `damageResistances` | ✓ | ✓ | ✓ |
| `damageImmunities` | ✓ | ✓ | ✓ |
| `conditionImmunities` | ✓ | ✓ | ✓ |
| `senses` | ✓ | ✓ | ✓ |
| `languages` | ✓ | ✓ | ✓ |
| `challengeRating` | — | — | ✓ |
| `xp` | — | — | ✓ |
| `specialAbilities` | ✓ | ✓ | ✓ |
| `actions` | ✓ | ✓ | ✓ |
| `legendaryActions` | — | — | ✓ |
| `legendaryActionCount` | — | — | ✓ |
| `spellSlots` | ✓ | ✓ | — |
| `knownSpells` | ✓ | ✓ | ✓ |
| `initiative` | ✓ | ✓ | ✓ |
| `status` | ✓ | ✓ | ✓ |

---

## 5. JSON Schema Reference

### 5.1 PlayerCharacter (JSON)

```json
{
  "id": "uuid-string",
  "name": "string",
  "race": "string",
  "playerClass": "string",
  "level": 1,
  "background": "string",
  "size": "Tiny|Small|Medium|Large|Huge|Gargantuan",
  "alignment": "Lawful Good|Neutral Good|Chaotic Good|Lawful Neutral|True Neutral|Chaotic Neutral|Lawful Evil|Neutral Evil|Chaotic Evil|Unaligned",
  "armorClass": 10,
  "armorSource": "string",
  "currentHP": 10,
  "maxHP": 10,
  "hitDice": "1d8",
  "speed": {
    "walk": 30,
    "swim": null,
    "fly": null,
    "climb": null,
    "burrow": null,
    "hover": false
  },
  "abilityScores": {
    "strength": 10,
    "dexterity": 10,
    "constitution": 10,
    "intelligence": 10,
    "wisdom": 10,
    "charisma": 10
  },
  "proficiencyBonus": 2,
  "savingThrowProficiencies": {
    "strength": false,
    "dexterity": false,
    "constitution": false,
    "intelligence": false,
    "wisdom": false,
    "charisma": false
  },
  "skills": [
    {
      "skill": "Acrobatics",
      "isProficient": false,
      "bonus": 0,
      "abilityScore": "DEX"
    }
  ],
  "damageVulnerabilities": [],
  "damageResistances": [],
  "damageImmunities": [],
  "conditionImmunities": [],
  "senses": {
    "darkvision": null,
    "blindsight": null,
    "tremorsense": null,
    "truesight": null,
    "passivePerception": 10
  },
  "languages": ["Common"],
  "specialAbilities": [
    { "name": "string", "description": "string" }
  ],
  "actions": [
    {
      "id": "uuid-string",
      "name": "string",
      "hitBonus": 0,
      "reach": "5 ft.",
      "damageRoll": "1d6",
      "damageType": "slashing",
      "saveDC": null,
      "description": null,
      "maxUses": null,
      "remainingUses": null
    }
  ],
  "spellSlots": [
    { "level": 1, "max": 2, "available": 2 }
  ],
  "knownSpells": [],
  "initiative": 0.0,
  "status": []
}
```

### 5.2 NPC (JSON)

```json
{
  "id": "uuid-string",
  "name": "string",
  "role": "string",
  "size": "Tiny|Small|Medium|Large|Huge|Gargantuan",
  "alignment": "Lawful Good|...|Unaligned",
  "biography": "string",
  "armorClass": 10,
  "armorSource": "string",
  "currentHP": 10,
  "maxHP": 10,
  "hitDice": "1d8",
  "speed": { "walk": 30, "swim": null, "fly": null, "climb": null, "burrow": null, "hover": false },
  "abilityScores": { "strength": 10, "dexterity": 10, "constitution": 10, "intelligence": 10, "wisdom": 10, "charisma": 10 },
  "proficiencyBonus": 2,
  "savingThrowProficiencies": { "strength": false, "dexterity": false, "constitution": false, "intelligence": false, "wisdom": false, "charisma": false },
  "skills": [],
  "damageResistances": [],
  "damageImmunities": [],
  "conditionImmunities": [],
  "senses": { "darkvision": null, "blindsight": null, "tremorsense": null, "truesight": null, "passivePerception": 10 },
  "languages": ["Common"],
  "specialAbilities": [],
  "actions": [],
  "spellSlots": [],
  "knownSpells": [],
  "initiative": 0.0,
  "status": []
}
```

### 5.3 Monster (JSON)

```json
{
  "id": "uuid-string",
  "name": "string",
  "size": "Tiny|Small|Medium|Large|Huge|Gargantuan",
  "type": "Aberration|Beast|Celestial|Construct|Dragon|Elemental|Fey|Fiend|Giant|Humanoid|Monstrosity|Ooze|Plant|Undead",
  "alignment": "Lawful Good|...|Unaligned",
  "armorClass": 10,
  "armorSource": "string",
  "currentHP": 10,
  "maxHP": 10,
  "hitDice": "1d8",
  "speed": { "walk": 30, "swim": null, "fly": null, "climb": null, "burrow": null, "hover": false },
  "abilityScores": { "strength": 10, "dexterity": 10, "constitution": 10, "intelligence": 10, "wisdom": 10, "charisma": 10 },
  "proficiencyBonus": 2,
  "savingThrowProficiencies": { "strength": false, "dexterity": false, "constitution": false, "intelligence": false, "wisdom": false, "charisma": false },
  "skills": [],
  "damageVulnerabilities": [],
  "damageResistances": [],
  "damageImmunities": [],
  "conditionImmunities": [],
  "senses": { "darkvision": null, "blindsight": null, "tremorsense": null, "truesight": null, "passivePerception": 10 },
  "languages": ["Common"],
  "challengeRating": 0.25,
  "xp": 50,
  "specialAbilities": [],
  "actions": [],
  "legendaryActions": [
    { "name": "string", "cost": 1, "description": "string" }
  ],
  "legendaryActionCount": 3,
  "knownSpells": [],
  "initiative": 0.0,
  "status": []
}
```

---

## 6. Computed Values & Rules

### 6.1 Ability Modifier

```
modifier(score) = floor((score - 10) / 2)
```

Examples: 8 → -1, 10 → 0, 12 → +1, 14 → +2, 18 → +4, 20 → +5.

### 6.2 Skill Bonus

```
skillBonus = abilityModifier + (isProficient ? proficiencyBonus : 0)
```

### 6.3 Proficiency Bonus by Level

| Level Range | Proficiency Bonus |
|---|---|
| 1-4 | +2 |
| 5-8 | +3 |
| 9-12 | +4 |
| 13-16 | +5 |
| 17-20 | +6 |

### 6.4 Spell Slot Roman Numerals

Spell levels 1-9 are commonly displayed as Roman numerals: I, II, III, IV, V, VI, VII, VIII, IX. Cantrips are level 0.

### 6.5 Initiative

Initiative is a rolled value (typically `1d20 + Dexterity modifier`). Stored as a float to support tie-breaking with decimal precision. Default value is `0`.

### 6.6 Dice Roll Expressions

Damage rolls and similar values use the format `XdY+Z` where:
- `X` = number of dice
- `Y` = number of sides per die
- `Z` = optional modifier (can be negative)

Examples: `1d6`, `2d8+3`, `4d10-1`, `3d6+1d8+5`.

---

## 7. Design Notes

### 7.1 Why Three Separate Types

- **PlayerCharacter** carries player-specific metadata (race, class, level, background) and includes `damageVulnerabilities`.
- **NPC** replaces race/class/level with a free-form `role` and adds `biography` for narrative context. It does NOT have `damageVulnerabilities` (NPCs rarely have them in 5e rules).
- **Monster** carries bestiary-specific fields (`type`, `challengeRating`, `xp`, `legendaryActions`) and omits player/NPC narrative fields.

### 7.2 Shared Combat State

All three types carry `initiative` (float, default 0) and `status` (optional array of `StatusCondition`). These fields track runtime combat state and should be reset between encounters or on a long rest.

### 7.3 Spell Management

`knownSpells` stores references (IDs or names) to spells defined in a separate spell database. `spellSlots` tracks available casting resources. Monsters do not store `spellSlots` directly in this spec (they may use innate spellcasting via the `actions` array instead).

### 7.4 HP Tracking

Both `currentHP` and `maxHP` are stored explicitly. `currentHP` may exceed `maxHP` (temporary HP is handled separately by the consuming application). `currentHP` should never go below 0.
