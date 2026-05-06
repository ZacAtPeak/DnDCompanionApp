import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_data.dart';
import 'widgets/ability_scores_grid.dart';
import 'providers/campaign_state_provider.dart';
import 'services/networking/campaign_network_client.dart';
import 'services/networking/connection_state.dart' as net;
import 'services/networking/models.dart' as net_models;
import 'services/session_persistence.dart';
import 'models/models.dart' as models;
import 'widgets/network_session_picker.dart';

void main() {
  runApp(const DndCompanionApp());
}

class DndCompanionApp extends StatefulWidget {
  const DndCompanionApp({super.key});

  @override
  State<DndCompanionApp> createState() => _DndCompanionAppState();
}

class _DndCompanionAppState extends State<DndCompanionApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _lightSeedColor = Colors.deepPurple;
  Color _darkSeedColor = const Color(0xFFB39DDB);

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _setSeedColor(Color color, bool isDark) {
    setState(() {
      if (isDark) {
        _darkSeedColor = color;
      } else {
        _lightSeedColor = color;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    if (isCompact) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ));

    return MaterialApp(
      title: 'D&D Companion',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _lightSeedColor),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _darkSeedColor,
          brightness: Brightness.dark,
        ),
      ),
      home: MainScreen(
        onThemeChanged: _setThemeMode,
        themeMode: _themeMode,
        lightSeedColor: _lightSeedColor,
        darkSeedColor: _darkSeedColor,
        onSeedColorChanged: _setSeedColor,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode themeMode;
  final Color lightSeedColor;
  final Color darkSeedColor;
  final void Function(Color color, bool isDark) onSeedColorChanged;

  const MainScreen({
    super.key,
    required this.onThemeChanged,
    required this.themeMode,
    required this.lightSeedColor,
    required this.darkSeedColor,
    required this.onSeedColorChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CampaignNetworkClient _networkClient;
  late CampaignStateNotifier _campaignNotifier;
  final _persistence = SessionPersistenceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _networkClient = CampaignNetworkClient();
    _campaignNotifier = CampaignStateNotifier(client: _networkClient);

    _persistence.init().then((_) {
      if (!mounted) return;
      _initFromPersistence();
    });
  }

  void _initFromPersistence() {
    final savedClientID = _persistence.clientID;
    if (savedClientID != null) {
      _networkClient.restoreClientID(savedClientID);
    } else {
      _persistence.saveClientID(_networkClient.clientID);
    }

    final cachedState = _persistence.cachedState;
    if (cachedState != null) {
      _campaignNotifier.loadCachedState(
        state: cachedState,
        assignedPlayerID: _persistence.assignedPlayerID,
      );
    }

    if (_persistence.hasSavedSession) {
      _networkClient.setPersistence(_persistence);
      _networkClient.tryAutoReconnect();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _campaignNotifier.dispose();
    _networkClient.dispose();
    super.dispose();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SettingsPage(
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
        lightSeedColor: widget.lightSeedColor,
        darkSeedColor: widget.darkSeedColor,
        onSeedColorChanged: widget.onSeedColorChanged,
        networkClient: _networkClient,
        campaignNotifier: _campaignNotifier,
        persistence: _persistence,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = widget.themeMode == ThemeMode.dark ||
        (widget.themeMode == ThemeMode.system && platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            PersistentTopStrip(onSettings: _openSettings),
            ListenableBuilder(
              listenable: _campaignNotifier,
              builder: (context, _) {
                return InitiativeStrip(notifier: _campaignNotifier);
              },
            ),
            ListenableBuilder(
              listenable: _campaignNotifier,
              builder: (context, _) {
                return PlayerCharacterStatusBar(notifier: _campaignNotifier);
              },
            ),
            ListenableBuilder(
              listenable: _campaignNotifier,
              builder: (context, _) {
                final isReconnecting = _campaignNotifier.isShowingCachedState &&
                    _campaignNotifier.connectionState.status !=
                        net.ConnectionStatus.ready;
                if (!isReconnecting) return const SizedBox.shrink();
                final sessionName = _persistence.sessionName;
                return Material(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sessionName != null
                                ? 'Reconnecting to "$sessionName"...'
                                : 'Reconnecting to previous session...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            TabBar(
              isScrollable: true,
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.fitness_center), text: 'Abilities/Skills'),
                Tab(icon: Icon(Icons.gavel), text: 'Actions'),
                Tab(icon: Icon(Icons.auto_awesome), text: 'Spells'),
                Tab(icon: Icon(Icons.star), text: 'Features'),
                Tab(icon: Icon(Icons.inventory_2), text: 'Inventory'),
                Tab(icon: Icon(Icons.note), text: 'Notes'),
              ],
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _campaignNotifier,
                builder: (context, _) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      HomeTab(notifier: _campaignNotifier),
                      ActionsTab(notifier: _campaignNotifier),
                      SpellsTab(notifier: _campaignNotifier),
                      FeaturesTab(notifier: _campaignNotifier),
                      InventoryTab(notifier: _campaignNotifier),
                      NotesTab(notifier: _campaignNotifier),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersistentTopStrip extends StatelessWidget {
  final VoidCallback onSettings;

  const PersistentTopStrip({super.key, required this.onSettings});

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
                icon: const Icon(Icons.menu_book),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: onSettings,
              ),
              IconButton(
                icon: const Icon(Icons.search),
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
  final CampaignStateNotifier? notifier;

  const InitiativeStrip({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    final combatents = notifier?.combatents ?? [];
    final sortedCombatents = List.from(combatents)
      ..sort((a, b) => b.initiative.compareTo(a.initiative));

    if (sortedCombatents.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Text('No combatants'),
        ),
      );
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: sortedCombatents.map((combatent) {
          final isAssignedPlayer = combatent.entityID == notifier?.assignedPlayerID;
          return InitiativeSlot(
            name: combatent.name,
            currentHp: combatent.currentHP,
            maxHp: combatent.maxHP,
            isPlayerCharacter: combatent.entityType == 'player',
            isCurrentTurn: combatent.isTurn,
            isAssignedCharacter: isAssignedPlayer,
          );
        }).toList(),
      ),
    );
  }
}

class InitiativeSlot extends StatelessWidget {
  final String name;
  final int currentHp;
  final int maxHp;
  final bool isPlayerCharacter;
  final bool isCurrentTurn;
  final bool isAssignedCharacter;

  const InitiativeSlot({
    super.key,
    required this.name,
    required this.currentHp,
    required this.maxHp,
    this.isPlayerCharacter = false,
    this.isCurrentTurn = false,
    this.isAssignedCharacter = false,
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

    final isHighlighted = isAssignedCharacter || isCurrentTurn;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FittedBox(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isHighlighted
                ? Border.all(
                    color: isCurrentTurn
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
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
                    color: isPlayerCharacter
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isPlayerCharacter ? Icons.shield : Icons.person,
                      color: isDead ? Colors.grey : null,
                      size: 28,
                    ),
                    if (isCurrentTurn)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber,
                            width: 3,
                          ),
                        ),
                      ),
                  ],
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
              const SizedBox(height: 2),
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
      ),
    );
  }
}

class PlayerCharacterStatusBar extends StatelessWidget {
  final CampaignStateNotifier? notifier;

  const PlayerCharacterStatusBar({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    final networkPlayer = notifier?.assignedPlayer;

    if (networkPlayer == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(
          child: Text('Not connected'),
        ),
      );
    }

    // Prefer combatant HP when the player is in an active encounter — the DM
    // drives HP changes there via combatentHitPointsChanged, which only updates
    // the combatant record, not the player record.
    final combatant = notifier?.assignedPlayerCombatant;
    final currentHP = combatant?.currentHP ?? networkPlayer.currentHP;
    final maxHP = combatant?.maxHP ?? networkPlayer.maxHP;

    final isDead = currentHP <= 0;
    final hpPercentage = maxHP > 0 ? currentHP / maxHP : 0;

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: const Icon(Icons.shield, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  networkPlayer.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Level ${networkPlayer.level} ${networkPlayer.race} ${networkPlayer.playerClass}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$currentHP / $maxHP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hpColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'AC ${networkPlayer.armorClass}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final Color lightSeedColor;
  final Color darkSeedColor;
  final void Function(Color color, bool isDark) onSeedColorChanged;
  final CampaignNetworkClient networkClient;
  final CampaignStateNotifier campaignNotifier;
  final SessionPersistenceService persistence;

  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.lightSeedColor,
    required this.darkSeedColor,
    required this.onSeedColorChanged,
    required this.networkClient,
    required this.campaignNotifier,
    required this.persistence,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _themeMode;
  late Color _lightSeedColor;
  late Color _darkSeedColor;
  late TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
    _lightSeedColor = widget.lightSeedColor;
    _darkSeedColor = widget.darkSeedColor;
    _displayNameController = TextEditingController(
      text: widget.networkClient.displayName,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  void _updateTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
    widget.onThemeChanged(mode);
  }

  void _updateSeedColor(Color color, bool isDark) {
    setState(() {
      if (isDark) {
        _darkSeedColor = color;
      } else {
        _lightSeedColor = color;
      }
    });
    widget.onSeedColorChanged(color, isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                _SettingsSection(
                  title: 'Appearance',
                  children: [
                    _ThemePickerTile(
                      themeMode: _themeMode,
                      onThemeChanged: _updateTheme,
                    ),
                    _ColorPickerTile(
                      lightSeedColor: _lightSeedColor,
                      darkSeedColor: _darkSeedColor,
                      onSeedColorChanged: _updateSeedColor,
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Gameplay',
                  children: [
                    _SettingsSwitchTile(
                      icon: Icons.casino,
                      title: 'Dice Roll Animations',
                      subtitle: 'Show animations when rolling dice',
                      value: true,
                      onChanged: (value) {},
                    ),
                    _SettingsSwitchTile(
                      icon: Icons.volume_up,
                      title: 'Sound Effects',
                      subtitle: 'Play sounds for dice rolls and actions',
                      value: true,
                      onChanged: (value) {},
                    ),
                    _SettingsTile(
                      icon: Icons.account_tree,
                      title: 'Initiative Order',
                      subtitle: 'Sort by initiative value',
                      onTap: () {},
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Campaign Network',
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'Name shown to other players',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            widget.networkClient.displayName = value;
                          }
                        },
                      ),
                    ),
                    _NetworkStatusTile(
                      networkClient: widget.networkClient,
                      campaignNotifier: widget.campaignNotifier,
                    ),
                    if (widget.persistence.hasSavedSession)
                      ListTile(
                        leading: const Icon(Icons.link_off),
                        title: const Text('Clear Saved Session'),
                        subtitle: Text(
                          widget.persistence.sessionName != null
                              ? 'Forget "${widget.persistence.sessionName}"'
                              : 'Forget the saved session',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await widget.persistence.clear();
                          await widget.networkClient.disconnect();
                          if (context.mounted) setState(() {});
                        },
                      ),
                  ],
                ),
                _SettingsSection(
                  title: 'Character',
                  children: [
                    _SettingsTile(
                      icon: Icons.person,
                      title: 'Manage Characters',
                      subtitle: 'View and edit your characters',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.save,
                      title: 'Auto-Save',
                      subtitle: 'Automatically save character changes',
                      onTap: () {},
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'About',
                  children: [
                    _SettingsTile(
                      icon: Icons.info,
                      title: 'Version',
                      subtitle: '1.0.0',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.help,
                      title: 'Help & Support',
                      subtitle: 'Get help with the app',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ThemePickerTile extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const _ThemePickerTile({
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

    return ExpansionTile(
      leading: const Icon(Icons.dark_mode),
      title: const Text('Theme Mode'),
      subtitle: Text(label),
      initiallyExpanded: false,
      children: [
        RadioListTile<ThemeMode>(
          title: const Text('System'),
          value: ThemeMode.system,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) onThemeChanged(value);
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Light'),
          value: ThemeMode.light,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) onThemeChanged(value);
          },
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Dark'),
          value: ThemeMode.dark,
          groupValue: themeMode,
          onChanged: (value) {
            if (value != null) onThemeChanged(value);
          },
        ),
      ],
    );
  }
}

class _ColorPickerTile extends StatelessWidget {
  final Color lightSeedColor;
  final Color darkSeedColor;
  final void Function(Color color, bool isDark) onSeedColorChanged;

  const _ColorPickerTile({
    required this.lightSeedColor,
    required this.darkSeedColor,
    required this.onSeedColorChanged,
  });

  static const _colorPairs = [
    (light: Colors.red, dark: Color(0xFFEF9A9A)),
    (light: Colors.pink, dark: Color(0xFFF48FB1)),
    (light: Colors.purple, dark: Color(0xFFCE93D8)),
    (light: Colors.deepPurple, dark: Color(0xFFB39DDB)),
    (light: Colors.indigo, dark: Color(0xFF9FA8DA)),
    (light: Colors.blue, dark: Color(0xFF90CAF9)),
    (light: Colors.lightBlue, dark: Color(0xFF81D4FA)),
    (light: Colors.cyan, dark: Color(0xFF80DEEA)),
    (light: Colors.teal, dark: Color(0xFF80CBC4)),
    (light: Colors.green, dark: Color(0xFFA5D6A7)),
    (light: Colors.lightGreen, dark: Color(0xFFC5E1A5)),
    (light: Colors.lime, dark: Color(0xFFE6EE9C)),
    (light: Colors.yellow, dark: Color(0xFFFFF59D)),
    (light: Colors.amber, dark: Color(0xFFFFE082)),
    (light: Colors.orange, dark: Color(0xFFFFCC80)),
    (light: Colors.deepOrange, dark: Color(0xFFFFAB91)),
    (light: Colors.brown, dark: Color(0xFFBCAAA4)),
    (light: Colors.blueGrey, dark: Color(0xFFB0BEC5)),
  ];

  @override
  Widget build(BuildContext context) {
    bool isSelected(Color color) =>
        color.toARGB32() == lightSeedColor.toARGB32();

    return ExpansionTile(
      leading: const Icon(Icons.color_lens),
      title: const Text('Color Theme'),
      subtitle: Text(_colorName(lightSeedColor)),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorPairs.map((pair) {
              final selected = isSelected(pair.light);
              return GestureDetector(
                onTap: () {
                  onSeedColorChanged(pair.light, false);
                  onSeedColorChanged(pair.dark, true);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [pair.dark, pair.light],
                          stops: const [0.5, 0.5],
                        ),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: selected ? 3 : 0,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _colorName(Color color) {
    return switch (color.toARGB32()) {
      0xFFF44336 => 'Red',
      0xFFE91E63 => 'Pink',
      0xFF9C27B0 => 'Purple',
      0xFF673AB7 => 'Deep Purple',
      0xFF3F51B5 => 'Indigo',
      0xFF2196F3 => 'Blue',
      0xFF03A9F4 => 'Light Blue',
      0xFF00BCD4 => 'Cyan',
      0xFF009688 => 'Teal',
      0xFF4CAF50 => 'Green',
      0xFF8BC34A => 'Light Green',
      0xFFCDDC39 => 'Lime',
      0xFFFFEB3B => 'Yellow',
      0xFFFFC107 => 'Amber',
      0xFFFF9800 => 'Orange',
      0xFFFF5722 => 'Deep Orange',
      0xFF795548 => 'Brown',
      0xFF607D8B => 'Blue Grey',
      _ => 'Custom',
    };
  }
}

class _NetworkStatusTile extends StatelessWidget {
  final CampaignNetworkClient networkClient;
  final CampaignStateNotifier campaignNotifier;

  const _NetworkStatusTile({
    required this.networkClient,
    required this.campaignNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: campaignNotifier,
      builder: (context, _) {
        final state = campaignNotifier.connectionState;
        IconData icon;
        switch (state.status) {
          case net.ConnectionStatus.ready:
            icon = Icons.wifi;
          case net.ConnectionStatus.stale:
            icon = Icons.wifi_off;
          case net.ConnectionStatus.connecting:
          case net.ConnectionStatus.connectedUnsynced:
          case net.ConnectionStatus.syncing:
            icon = Icons.wifi_find;
          case net.ConnectionStatus.browsing:
            icon = Icons.search;
          case net.ConnectionStatus.failed:
            icon = Icons.error_outline;
          case net.ConnectionStatus.idle:
            icon = Icons.wifi_tethering;
        }
        return ListTile(
          leading: Icon(icon),
          title: const Text('Campaign Network'),
          subtitle: Text(state.displayText),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => NetworkSessionPicker(
                client: networkClient,
                notifier: campaignNotifier,
              ),
            );
          },
        );
      },
    );
  }
}

List<models.SkillProficiency> _buildDefaultSkills(
  net_models.NetworkAbilityScores scores,
  int proficiencyBonus,
) {
  final abilityValues = {
    'STR': scores.strength,
    'DEX': scores.dexterity,
    'CON': scores.constitution,
    'INT': scores.intelligence,
    'WIS': scores.wisdom,
    'CHA': scores.charisma,
  };
  return models.kAllSkills.map((skillName) {
    final abilityKey = models.kSkillAbilityMap[skillName]!;
    final score = abilityValues[abilityKey]!;
    final mod = (score - 10) ~/ 2;
    return models.SkillProficiency(
      skill: skillName,
      isProficient: false,
      bonus: mod,
      abilityScore: abilityKey,
    );
  }).toList();
}

class HomeTab extends StatelessWidget {
  final CampaignStateNotifier? notifier;

  const HomeTab({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    final networkPlayer = notifier?.assignedPlayer;

    final userCharacter = networkPlayer != null
        ? models.UserCharacter(
            character: models.PlayerCharacter(
              id: networkPlayer.id,
              name: networkPlayer.name,
              race: networkPlayer.race,
              playerClass: networkPlayer.playerClass,
              level: networkPlayer.level,
              background: networkPlayer.background,
              size: models.CreatureSize.fromString(networkPlayer.size),
              alignment: models.Alignment.fromString(networkPlayer.alignment),
              armorClass: networkPlayer.armorClass,
              armorSource: networkPlayer.armorSource,
              currentHP: networkPlayer.currentHP,
              maxHP: networkPlayer.maxHP,
              hitDice: networkPlayer.hitDice,
              speed: models.MovementSpeed(
                walk: networkPlayer.speed.walk,
                swim: networkPlayer.speed.swim,
                fly: networkPlayer.speed.fly,
                climb: networkPlayer.speed.climb,
                burrow: networkPlayer.speed.burrow,
                hover: networkPlayer.speed.hover,
              ),
              abilityScores: models.AbilityScores(
                strength: networkPlayer.abilityScores.strength,
                dexterity: networkPlayer.abilityScores.dexterity,
                constitution: networkPlayer.abilityScores.constitution,
                intelligence: networkPlayer.abilityScores.intelligence,
                wisdom: networkPlayer.abilityScores.wisdom,
                charisma: networkPlayer.abilityScores.charisma,
              ),
              proficiencyBonus: networkPlayer.proficiencyBonus,
              savingThrowProficiencies: const models.SavingThrowProficiencies(),
              skills: networkPlayer.skills.isNotEmpty
                  ? networkPlayer.skills
                      .map((s) => models.SkillProficiency(
                            skill: s.skill,
                            isProficient: s.isProficient,
                            bonus: s.bonus,
                            abilityScore: s.abilityScore,
                          ))
                      .toList()
                  : _buildDefaultSkills(networkPlayer.abilityScores, networkPlayer.proficiencyBonus),
              senses: const models.Senses(passivePerception: 10),
              languages: networkPlayer.languages,
              actions: networkPlayer.actions
                  .map((a) => models.Attack(
                        id: a.id,
                        name: a.name,
                        hitBonus: a.hitBonus,
                        reach: a.reach,
                        damageRoll: a.damageRoll,
                        damageType: models.DamageType.fromString(a.damageType),
                        saveDC: a.saveDC,
                        description: a.description,
                        maxUses: a.maxUses,
                        remainingUses: a.remainingUses,
                      ))
                  .toList(),
              spellSlots: networkPlayer.spellSlots
                  .map((s) => models.SpellSlot(
                        level: s.level,
                        max: s.max,
                        available: s.available,
                      ))
                  .toList(),
              knownSpells: networkPlayer.knownSpells,
              status: networkPlayer.statuses
                  .map((s) => models.StatusCondition(
                        name: s.name,
                        effect: s.effect,
                        desc: s.desc,
                      ))
                  .toList(),
            ),
          )
        : DemoData.createUserCharacter();

    final character = userCharacter.character;
    final scores = character.abilityScores;

    final abilities = {
      'STR': scores.strength,
      'DEX': scores.dexterity,
      'CON': scores.constitution,
      'INT': scores.intelligence,
      'WIS': scores.wisdom,
      'CHA': scores.charisma,
    };

    final modifiers = {
      'STR': scores.strMod,
      'DEX': scores.dexMod,
      'CON': scores.conMod,
      'INT': scores.intMod,
      'WIS': scores.wisMod,
      'CHA': scores.chaMod,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ability Scores',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AbilityScoresGrid(
            abilities: abilities,
            modifiers: modifiers,
          ),
          const SizedBox(height: 24),
          const Text(
            'Skills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final orientation = MediaQuery.orientationOf(context);
              final columns = isWide || orientation == Orientation.landscape ? 2 : 1;

              if (columns == 2) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: character.skills.map((skill) {
                    return SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: _SkillRow(skill: skill),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: character.skills.map((skill) {
                  return _SkillRow(skill: skill);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final dynamic skill;

  const _SkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    final modString = '${skill.bonus >= 0 ? '+' : ''}${skill.bonus}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (skill.isProficient)
            const Icon(Icons.circle, size: 12, color: Colors.green)
          else
            const Icon(Icons.circle, size: 12, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              skill.skill,
              style: TextStyle(
                fontSize: 16,
                fontWeight: skill.isProficient ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}

class ActionsTab extends StatelessWidget {
  final CampaignStateNotifier? notifier;

  const ActionsTab({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Actions Tab'),
    );
  }
}

class SpellsTab extends StatelessWidget {
  final CampaignStateNotifier? notifier;

  const SpellsTab({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Spells Tab'),
    );
  }
}

class FeaturesTab extends StatelessWidget {
  final CampaignStateNotifier? notifier;

  const FeaturesTab({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Features Tab'),
    );
  }
}

class InventoryTab extends StatelessWidget {
  final CampaignStateNotifier? notifier;

  const InventoryTab({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Inventory Tab'),
    );
  }
}

class NotesTab extends StatelessWidget {
  final CampaignStateNotifier? notifier;

  const NotesTab({super.key, this.notifier});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Notes Tab'),
    );
  }
}
