class Senses {
  final int? darkvision;
  final int? blindsight;
  final int? tremorsense;
  final int? truesight;
  final int passivePerception;

  const Senses({
    this.darkvision,
    this.blindsight,
    this.tremorsense,
    this.truesight,
    required this.passivePerception,
  });

  Map<String, dynamic> toJson() => {
        'darkvision': darkvision,
        'blindsight': blindsight,
        'tremorsense': tremorsense,
        'truesight': truesight,
        'passivePerception': passivePerception,
      };

  factory Senses.fromJson(Map<String, dynamic> json) => Senses(
        darkvision: json['darkvision'] as int?,
        blindsight: json['blindsight'] as int?,
        tremorsense: json['tremorsense'] as int?,
        truesight: json['truesight'] as int?,
        passivePerception: json['passivePerception'] as int,
      );
}
