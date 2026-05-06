class LegendaryAction {
  final String name;
  final int cost;
  final String description;

  const LegendaryAction({
    required this.name,
    required this.cost,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'cost': cost,
        'description': description,
      };

  factory LegendaryAction.fromJson(Map<String, dynamic> json) =>
      LegendaryAction(
        name: json['name'] as String,
        cost: json['cost'] as int,
        description: json['description'] as String,
      );
}
