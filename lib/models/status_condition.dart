class StatusCondition {
  final String name;
  final String effect;
  final String desc;

  const StatusCondition({
    required this.name,
    required this.effect,
    required this.desc,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'effect': effect,
        'desc': desc,
      };

  factory StatusCondition.fromJson(Map<String, dynamic> json) =>
      StatusCondition(
        name: json['name'] as String,
        effect: json['effect'] as String,
        desc: json['desc'] as String,
      );
}
