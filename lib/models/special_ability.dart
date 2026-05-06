class SpecialAbility {
  final String name;
  final String description;

  const SpecialAbility({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };

  factory SpecialAbility.fromJson(Map<String, dynamic> json) => SpecialAbility(
        name: json['name'] as String,
        description: json['description'] as String,
      );
}
