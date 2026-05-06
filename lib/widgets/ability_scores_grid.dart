import 'package:flutter/material.dart';

class AbilityScoresGrid extends StatelessWidget {
  final Map<String, int> abilities;
  final Map<String, int> modifiers;

  const AbilityScoresGrid({
    super.key,
    required this.abilities,
    required this.modifiers,
  });

  @override
  Widget build(BuildContext context) {
    final abilityOrder = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final orientation = MediaQuery.orientationOf(context);
        final columns = isTablet || orientation == Orientation.landscape ? 6 : 3;

        final itemWidth =
            (constraints.maxWidth - (columns - 1) * 8) / columns;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: abilityOrder.map((ability) {
            final score = abilities[ability] ?? 10;
            final mod = modifiers[ability] ?? 0;
            return _AbilityCard(
              ability: ability,
              score: score,
              modifier: mod,
              width: itemWidth,
            );
          }).toList(),
        );
      },
    );
  }
}

class _AbilityCard extends StatelessWidget {
  final String ability;
  final int score;
  final int modifier;
  final double width;

  const _AbilityCard({
    required this.ability,
    required this.score,
    required this.modifier,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final modString = modifier >= 0 ? '+$modifier' : '$modifier';

    return SizedBox(
      width: width,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ability,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  modString,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
