import 'package:flutter/material.dart';

void main() {
  runApp(const DndCompanionApp());
}

class DndCompanionApp extends StatelessWidget {
  const DndCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D&D Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const PersistentTopStrip(),
            const InitiativeStrip(),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.home), text: 'Home'),
                Tab(icon: Icon(Icons.people), text: 'Characters'),
                Tab(icon: Icon(Icons.casino), text: 'Dice'),
                Tab(icon: Icon(Icons.inventory_2), text: 'Inventory'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  HomeTab(),
                  CharactersTab(),
                  DiceTab(),
                  InventoryTab(),
                  SettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersistentTopStrip extends StatelessWidget {
  const PersistentTopStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'D&D Companion',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InitiativeStrip extends StatelessWidget {
  const InitiativeStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: const [
          InitiativeSlot(
            name: 'Aldrin',
            currentHp: 32,
            maxHp: 45,
          ),
          InitiativeSlot(
            name: 'Goblin A',
            currentHp: 7,
            maxHp: 7,
          ),
          InitiativeSlot(
            name: 'Mira',
            currentHp: 28,
            maxHp: 38,
          ),
          InitiativeSlot(
            name: 'Bugbear',
            currentHp: 15,
            maxHp: 27,
          ),
          InitiativeSlot(
            name: 'Theron',
            currentHp: 52,
            maxHp: 60,
          ),
          InitiativeSlot(
            name: 'Goblin B',
            currentHp: 0,
            maxHp: 7,
          ),
        ],
      ),
    );
  }
}

class InitiativeSlot extends StatelessWidget {
  final String name;
  final int currentHp;
  final int maxHp;

  const InitiativeSlot({
    super.key,
    required this.name,
    required this.currentHp,
    required this.maxHp,
  });

  @override
  Widget build(BuildContext context) {
    final isDead = currentHp <= 0;
    final hpPercentage = maxHp > 0 ? currentHp / maxHp : 0;

    Color hpColor;
    if (isDead) {
      hpColor = Colors.grey;
    } else if (hpPercentage > 0.5) {
      hpColor = Colors.green;
    } else if (hpPercentage > 0.25) {
      hpColor = Colors.orange;
    } else {
      hpColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FittedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                color: isDead ? Colors.grey : null,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isDead ? '$name (Dead)' : name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDead ? Colors.grey : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isDead)
              Text(
                '$currentHp / $maxHp',
                style: TextStyle(
                  fontSize: 10,
                  color: hpColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Tab'),
    );
  }
}

class CharactersTab extends StatelessWidget {
  const CharactersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Characters Tab'),
    );
  }
}

class DiceTab extends StatelessWidget {
  const DiceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Dice Tab'),
    );
  }
}

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Inventory Tab'),
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Tab'),
    );
  }
}
